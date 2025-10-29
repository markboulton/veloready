# VeloReady Startup Performance Optimization Plan

## 🎯 Goal: <2 Second Startup with Graceful Loading

**Current Performance:** 8.5 seconds to first interactive UI  
**Target Performance:** <2 seconds with progressive enhancement  
**Strategy:** Instant Display → Progressive Enhancement

---

## 📊 Current Performance Analysis (From Logs)

### Critical Bottlenecks Identified:

1. **8.5s delay before UI appears** - Full-screen spinner blocking everything
2. **Duplicate calculations** - Sleep score calculated 3x simultaneously
3. **No cache utilization on startup** - Fresh calculations every time
4. **Baseline recalculation** - 7-day HRV/RHR averages computed on every score
5. **Fetching 365 days of activities** - 182 activities on startup (overkill!)
6. **Phase 3 starts too early** - Background tasks compete with critical UI
7. **Synchronous HealthKit queries** - Sequential instead of parallel
8. **Token refresh blocking** - Supabase auth delays data fetching

### Performance Timeline (Current):

```
0.0s  App Launch
2.0s  🎯 PHASE 1: Branded loading screen appears
8.5s  ✅ UI finally appears (TOO SLOW!)
16.0s Background sync completes
```

---

## 📋 **Complete 3-Phase Architecture**

### **Phase 1: Instant Display (0-200ms)** ⚡
**Goal:** Show UI immediately with yesterday's/cached data

**What to show:**
- Recovery ring: Yesterday's score (or "Calculating...")
- Sleep ring: Last night's score (cached)
- Strain ring: Yesterday's final score
- Activity feed: Cached activities
- Steps/calories: Cached from last update

**Implementation:**
```swift
func loadInitialUI() async {
    // 1. Load ONLY cached data (no calculation, no network)
    let cachedRecovery = await cacheManager.get("score:recovery:\(today)")
    let cachedStrain = await cacheManager.get("strain:v3:\(today)")
    let cachedSleep = await cacheManager.get("score:sleep:\(today)")
    
    // 2. If cache miss, show yesterday's data or empty state
    if cachedRecovery == nil {
        recovery = await cacheManager.get("score:recovery:\(yesterday)") ?? 0
        showRecoveryAsStale = true  // Subtle indicator
    }
    
    // 3. Show UI immediately
    showUI()  // <100ms
    
    // 4. Trigger Phase 2 in background
    Task.detached {
        await updateCriticalScores()
    }
}
```

**Visual behavior:**
- Rings appear instantly with smooth animation
- Subtle shimmer or "Updating..." badge if stale
- No full-screen spinner

---

### **Phase 2: Critical Updates (200ms - 2s)** 🔄
**Goal:** Update today's scores in background, animate changes

**What to update:**
1. **Recovery Score** (highest priority - affects recommendations)
2. **Strain Score** (real-time - changes throughout day)
3. **Sleep Score** (if not calculated yet today)

**Implementation:**
```swift
func updateCriticalScores() async {
    // Run in parallel, show results as they complete
    async let recovery = updateRecoveryScore()
    async let strain = updateStrainScore()
    async let sleep = updateSleepScore()
    
    // Animate each update as it arrives
    await withTaskGroup(of: Void.self) { group in
        group.addTask {
            if let score = await recovery {
                await MainActor.run {
                    animateRingUpdate(recovery: score)  // Smooth 0.5s animation
                }
            }
        }
        
        group.addTask {
            if let score = await strain {
                await MainActor.run {
                    animateRingUpdate(strain: score)
                }
            }
        }
        
        group.addTask {
            if let score = await sleep {
                await MainActor.run {
                    animateRingUpdate(sleep: score)
                }
            }
        }
    }
}

func updateRecoveryScore() async -> Int? {
    // OPTIMIZATION: Use cached baselines if < 1 hour old
    let baselines = await getCachedOrFreshBaselines()
    
    // OPTIMIZATION: Parallel HealthKit queries
    async let hrv = healthKit.fetch(.hrv, for: today)
    async let rhr = healthKit.fetch(.rhr, for: today)
    async let sleepScore = cacheManager.get("score:sleep:\(today)")
    
    let (hrvVal, rhrVal, sleepVal) = await (hrv, rhr, sleepScore)
    
    // Quick calculation (already in VeloReadyCore!)
    let score = RecoveryCalculations.calculateRecoveryScore(
        hrv: hrvVal,
        rhr: rhrVal,
        sleep: sleepVal,
        baselines: baselines
    )
    
    await cacheManager.store("score:recovery:\(today)", score)
    return score
}
```

**Optimizations:**
- **Reuse cached baselines** (HRV/RHR/Sleep 7-day averages) if < 1 hour old
- **Parallel HealthKit queries** (not sequential!)
- **Skip if already calculated today** (check cache first!)
- **Debounce duplicate calls** (fix the "already in progress" spam)

---

### **Phase 3: Full Data Sync (2s - 10s, background only)** 📊
**Goal:** Fetch everything else, update incrementally

**What to fetch (in priority order):**
1. **Today's activities** (last 24h, not 365 days!)
2. **Training load** (CTL/ATL for charts)
3. **Illness detection** (non-critical)
4. **FTP/Zone computation** (can wait)
5. **Historical CTL/ATL backfill** (lowest priority)

**Implementation:**
```swift
func backgroundDataSync() async {
    // Priority 1: Today's activities only
    await fetchRecentActivities(days: 1)  // Not 365!
    
    // Priority 2: This week's activities (for load calculations)
    await fetchRecentActivities(days: 7)
    
    // Priority 3: Everything else (user might not even see this)
    await Task.detached(priority: .background) {
        await fetchHistoricalActivities(days: 42)
        await computeZones()
        await backfillCTL_ATL()
        await detectIllness()
    }.value
}

func fetchRecentActivities(days: Int) async {
    // CRITICAL FIX: Don't fetch 365 days on startup!
    let cacheKey = "strava:activities:\(days)"
    
    // Use cache if < 15 min old
    if let cached = await cacheManager.get(cacheKey, maxAge: 900) {
        activities = cached
        return
    }
    
    // Only fetch what we need
    let fresh = await stravaService.fetchActivities(daysBack: days)
    await cacheManager.store(cacheKey, fresh, ttl: 900)
    activities = fresh
}
```

**Optimizations:**
- **Incremental updates:** Show activities as they load
- **Smart caching:** Don't refetch if < 15 min old
- **Prioritization:** Critical data first, nice-to-have later
- **Cancellation:** Stop if user navigates away

---

## 🔧 **Critical Fixes to Implement**

### **Fix 1: Stop Duplicate Calculations**

**Problem:**
```
🔄 Starting sleep score calculation
🔄 Starting sleep score calculation  ← Duplicate!
⚠️ Sleep score calculation already in progress, skipping...
```

**Solution:**
```swift
// Add to ViewModel
private var calculationTasks: [String: Task<Int?, Never>] = [:]

func calculateScore(type: String) async -> Int? {
    // Deduplicate: return existing task if already running
    if let existing = calculationTasks[type] {
        return await existing.value
    }
    
    // Create new task
    let task = Task {
        defer { calculationTasks[type] = nil }
        return await performCalculation(type)
    }
    
    calculationTasks[type] = task
    return await task.value
}
```

---

### **Fix 2: Cache Yesterday's Scores Overnight**

**Problem:** Cache misses on every startup
```
🌐 [Cache MISS] score:recovery:2025-10-29T00:00:00Z - fetching...
```

**Solution:**
```swift
// When calculating scores, also cache them with longer TTL
func saveScoreToCache(_ score: Int, type: String, date: Date) {
    let key = "score:\(type):\(date.ISO8601)"
    
    // Cache for 48 hours (not just today)
    cacheManager.store(key, score, ttl: 172800)
    
    // Also cache with "yesterday" key for next startup
    if date.isToday {
        let yesterdayKey = "score:\(type):yesterday"
        cacheManager.store(yesterdayKey, score, ttl: 86400)
    }
}
```

---

### **Fix 3: Baseline Caching (1 hour TTL)**

**Problem:** Recalculating 7-day baselines on every score calculation
```
🔄 Calculating fresh baselines...  ← Every time!
📊 HRV Baseline (7-day avg): 41.87 from 83 samples
📊 RHR Baseline (7-day avg): 61.36 from 11 samples
```

**Solution:**
```swift
func getBaselines() async -> Baselines {
    let cacheKey = "baselines:7day"
    
    // Use cached if < 1 hour old
    if let cached = await cacheManager.get(cacheKey, maxAge: 3600) {
        print("📱 Using cached baselines (age: \(cached.age))")
        return cached
    }
    
    // Calculate fresh
    print("🔄 Calculating fresh baselines...")
    let fresh = await calculateBaselines()
    await cacheManager.store(cacheKey, fresh, ttl: 3600)
    return fresh
}
```

---

### **Fix 4: Don't Fetch 365 Days on Startup**

**Problem:**
```
🟠 [Strava] Fetching activities (365 days, Pro: true)
🌐 [Cache MISS] strava:activities:365 - fetching...
✅ [NetworkClient] Fetched 182 Strava activities
```

**Solution:**
```swift
// Phase 1: Show cached activities (instant)
// Phase 2: Fetch today only (fast)
// Phase 3: Fetch 7 days (for load calc)
// Phase 4: Fetch 365 days (background, user may never need this)

func loadActivities() async {
    // Instant: Show cached
    if let cached = await cache.get("activities:recent") {
        activities = cached
        showUI()
    }
    
    // Fast: Fetch today (1-2 activities)
    let today = await fetchActivities(days: 1)
    updateUI(today)
    
    // Background: Fetch more only if needed
    if needsTrainingLoad {
        let week = await fetchActivities(days: 7)
        updateUI(week)
    }
    
    // Very low priority: Historical data
    if needsHistorical {
        Task.detached(priority: .background) {
            await fetchActivities(days: 365)
        }
    }
}
```

---

### **Fix 5: Prevent Phase 3 from Starting Too Early**

**Problem:** Background tasks start before Phase 1 completes
```
🎯 PHASE 1: 2-second branded loading
🌐 [VeloReady API] Fetching activities...  ← Should wait!
🔄 [Supabase] Refreshing access token...  ← Should wait!
```

**Solution:**
```swift
func loadInitialUI() async {
    // Phase 1: Show cached data
    await showCachedData()  // <100ms
    
    // Phase 2: Update critical scores
    await updateCriticalScores()  // 1-2s
    
    // Phase 3: Only start after Phase 2 completes
    Task.detached(priority: .background) {
        await backgroundDataSync()
    }
}
```

---

## 📊 **Expected Performance After Fixes**

| Phase | Current | Target | What User Sees |
|-------|---------|--------|----------------|
| **Phase 1: Display** | 8.5s ❌ | 0.1-0.2s ✅ | UI appears instantly with yesterday's data |
| **Phase 2: Critical** | — | 1-2s ✅ | Rings smoothly update to today's values |
| **Phase 3: Background** | 16s ❌ | 3-10s ✅ | Activities/charts populate (user may not notice) |
| **Total to Interactive** | **8.5s** | **<2s** | **4x faster!** |

---

## 🎬 **Visual UX Flow**

```
0.0s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      App launches, logo fades in
      
0.1s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ✅ UI appears with yesterday's rings
      (Recovery: 90, Sleep: 84, Strain: 8)
      Small "Updating..." badge fades in
      
0.5s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      🔄 Sleep ring updates: 84 → 84 ✓
      Badge changes to "Updated 5s ago"
      
1.2s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      🔄 Strain ring updates: 8 → 2 ↓
      Smooth animation, green pulse
      
1.8s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      🔄 Recovery ring updates: 90 → 92 ↑
      Smooth animation, badge disappears
      ✅ USER CAN NOW INTERACT!
      
3-10s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      (Background) Activities populate
      (Background) Charts update
      (Background) Historical data syncs
```

---

## ✅ **Implementation Checklist**

### **Phase 1: Instant Display (High Priority)**
- [ ] Create `loadCachedScores()` method in ViewModel
- [ ] Add "yesterday" fallback when today's cache misses
- [ ] Remove full-screen spinner from initial load
- [ ] Add subtle "Updating..." badge to rings
- [ ] Show cached activities immediately
- [ ] Defer Phase 2/3 until after UI appears

### **Phase 2: Critical Updates (High Priority)**
- [ ] Fix 1: Deduplicate score calculations (stop the spam)
- [ ] Fix 3: Cache baselines for 1 hour (stop recalculating)
- [ ] Parallelize HealthKit queries (HRV + RHR + Sleep)
- [ ] Animate ring updates smoothly (0.5s transition)
- [ ] Add haptic feedback when scores update
- [ ] Show timestamp "Updated 5s ago"

### **Phase 3: Background Sync (Medium Priority)**
- [ ] Fix 4: Fetch only today's activities first (not 365 days)
- [ ] Fix 5: Delay Phase 3 until Phase 2 completes
- [ ] Implement incremental activity loading (1 day → 7 days → 42 days)
- [ ] Add cancellation if user navigates away
- [ ] Progressive chart updates as data loads

### **Supporting Fixes (Medium Priority)**
- [ ] Fix 2: Cache yesterday's scores overnight (48h TTL)
- [ ] Add cache hit/miss logging for debugging
- [ ] Implement skeleton loaders for activity cards
- [ ] Add pull-to-refresh for manual sync

### **Nice to Have (Low Priority)**
- [ ] Progressive image loading for activity maps
- [ ] Prefetch critical data in background app refresh
- [ ] Add "Synced X minutes ago" indicator
- [ ] Optimize HealthKit query batch sizes

---

## 🚀 **Implementation Order**

### **Day 1: Phase 1 - Instant Display**
1. Implement cached data loading
2. Add yesterday's score fallback
3. Remove blocking spinner
4. Test on device

**Expected result:** App shows UI in <200ms

### **Day 2: Phase 2 - Critical Updates**
1. Fix duplicate calculations
2. Add baseline caching
3. Parallelize HealthKit queries
4. Implement smooth animations

**Expected result:** Scores update within 2s

### **Day 3: Phase 3 - Background Sync**
1. Implement incremental activity fetching
2. Delay background tasks
3. Add proper task prioritization
4. Test full flow

**Expected result:** Full sync completes in background, user doesn't notice

### **Day 4: Polish & Testing**
1. Add visual indicators
2. Test on slow network
3. Test airplane mode
4. Performance profiling

**Expected result:** Sub-2s startup in 95% of cases

---

## 📈 **Success Metrics**

### **Before Optimization:**
- Time to UI: **8.5 seconds**
- Cache hit rate: **<10%**
- Duplicate calculations: **3x per score**
- Activities fetched on startup: **182 (365 days)**
- User perception: "App is slow" 😞

### **After Optimization:**
- Time to UI: **<200ms** (42x faster!)
- Cache hit rate: **>80%**
- Duplicate calculations: **0** (eliminated)
- Activities fetched on startup: **~5 (today only)**
- User perception: "App is instant!" 🚀

---

## 🔍 **Monitoring & Debugging**

### **Add Performance Logging:**
```swift
func logPerformance(_ phase: String, duration: TimeInterval) {
    print("⚡ [\(phase)] completed in \(String(format: "%.3f", duration))s")
    
    // Track in analytics
    Analytics.track("startup_performance", [
        "phase": phase,
        "duration_ms": Int(duration * 1000)
    ])
}
```

### **Key Metrics to Track:**
- Phase 1 completion time (target: <200ms)
- Phase 2 completion time (target: <2s)
- Cache hit rate (target: >80%)
- HealthKit query time (baseline: measure first)
- Network request count (target: <5 on startup)

---

## 📝 **Notes**

- All calculations use `VeloReadyCore` (already tested with 40 unit tests!)
- Cache implementation uses `UnifiedCacheManager` (actor-based, thread-safe)
- HealthKit queries can be parallelized safely
- Animations should be smooth (60fps) with Core Animation
- Offline mode already supported by cache fallback

**This optimization maintains 100% feature parity while being 4x faster!**

