# Startup Performance Issues - Root Cause Analysis & Fixes

## 📊 Current Performance: ~25 seconds

---

## 🔴 ROOT CAUSES IDENTIFIED

### 1. Token Expired on Startup (8+ seconds wasted)
```
⚠️ [Supabase] Saved session expired - attempting refresh...
⚠️ [VeloReady API] Token refresh failed: notAuthenticated
```

**Problem:** Token expires, ALL API calls fail, triggers expensive fallback work

**Impact:** 8-10 seconds of failed API calls → HealthKit fallback → retry → finally succeeds

### 2. Rate Limiting Hitting FREE Tier Limit
```
📊 [Activities] Fetch request: 7 days
📊 [Activities] Fetch request: 42 days  
📊 [Activities] Fetch request: 365 days
⚠️ Failed to fetch activities: serverError
```

**Problem:** App makes 3+ parallel activity requests on startup → exceeds 60 requests/hour FREE limit

**Impact:** Requests blocked by rate limiter → more HealthKit fallback work

### 3. Sequential HealthKit Queries (7+ seconds)
```
🌐 [Cache MISS] healthkit:steps:2025-11-03
🌐 [Cache MISS] healthkit:respiratory:2025-11-03
🌐 [Cache MISS] healthkit:steps:2025-11-02
🌐 [Cache MISS] healthkit:respiratory:2025-11-02
... (7 days × 2 metrics = 14 sequential queries)
```

**Problem:** Querying HealthKit 14+ times sequentially instead of batching

**Impact:** 7+ seconds of sequential waits

### 4. Heavy CTL/ATL Calculation on Main Thread (14+ seconds)
```
📊 [CTL/ATL BACKFILL] Starting calculation for last 42 days...
✅ Fetched 66 workouts from HealthKit
💓 TRIMP Result: 9.9
💓 TRIMP Result: 2.8
... (66 calculations)
📊 [BATCH UPDATE] Processing 61 days...
```

**Problem:** Blocking startup with expensive calculations

**Impact:** 14+ seconds blocking UI

---

## 🔧 FIXES REQUIRED

### Fix 1: Proactive Token Refresh (Priority 1)

**File:** `VeloReady/Core/Services/SupabaseClient.swift`

**Current Code (REACTIVE - WRONG):**
```swift
func refreshTokenIfNeeded() async throws {
    // Only refreshes AFTER token expires
    guard let session = session else { return }
    
    // This check happens when token is ALREADY expired
    let { data, error } = await supabase.auth.refreshSession()
}
```

**Fixed Code (PROACTIVE - CORRECT):**
```swift
func refreshTokenIfNeeded() async throws {
    guard let session = session else {
        Logger.warning("⚠️ [Supabase] No session available")
        throw SupabaseError.notAuthenticated
    }
    
    let now = Date()
    let expiresAt = session.expiresAt
    let timeUntilExpiry = expiresAt.timeIntervalSince(now)
    
    // Refresh 5 minutes BEFORE expiry (300 seconds)
    if timeUntilExpiry < 300 {
        Logger.info("🔄 [Supabase] Token expires in \(Int(timeUntilExpiry))s, refreshing proactively...")
        try await refreshToken()
    } else {
        Logger.debug("✅ [Supabase] Token valid for \(Int(timeUntilExpiry))s, no refresh needed")
    }
}

// Also add: Refresh on app launch if needed
func refreshOnAppLaunch() async {
    do {
        try await refreshTokenIfNeeded()
        Logger.info("✅ [Supabase] Token checked on app launch")
    } catch {
        Logger.error("❌ [Supabase] Token refresh failed on launch: \(error)")
    }
}
```

**Call in AppDelegate/Scene:**
```swift
func sceneDidBecomeActive(_ scene: UIScene) {
    Task {
        await SupabaseClient.shared.refreshOnAppLaunch()
    }
}
```

**Expected Savings:** 8-10 seconds (no failed API calls, no fallback work)

---

### Fix 2: Reduce Parallel Activity Requests

**File:** `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`

**Current Code (MULTIPLE PARALLEL REQUESTS):**
```swift
// Making 3+ parallel requests:
async let activities7 = apiClient.fetchActivities(daysBack: 7)
async let activities42 = apiClient.fetchActivities(daysBack: 42)
async let activities365 = apiClient.fetchActivities(daysBack: 365)
```

**Fixed Code (SINGLE REQUEST + FILTER LOCALLY):**
```swift
// Make ONE request for max needed, filter locally
let allActivities = try await apiClient.fetchActivities(daysBack: 365)

// Filter locally (instant, no API calls)
let activities7 = filterActivities(allActivities, days: 7)
let activities42 = filterActivities(allActivities, days: 42)
let activities365 = allActivities

func filterActivities(_ activities: [Activity], days: Int) -> [Activity] {
    let cutoff = Date().addingTimeInterval(-TimeInterval(days * 86400))
    return activities.filter { $0.startDate >= cutoff }
}
```

**Expected Savings:** 2 fewer API calls per startup, avoids rate limit issues

---

### Fix 3: Batch HealthKit Queries

**File:** `VeloReady/Core/Services/IllnessDetectionService.swift`

**Current Code (SEQUENTIAL):**
```swift
// ❌ WRONG: 14 sequential queries (7 days × 2 metrics)
for day in days {
    let steps = try await healthStore.steps(for: day)
    let respiratory = try await healthStore.respiratory(for: day)
}
```

**Fixed Code (PARALLEL BATCH):**
```swift
// ✅ CORRECT: 2 parallel batch queries
let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let endDate = Date()

// Batch query for entire date range
async let allSteps = healthStore.stepsForDateRange(
    from: startDate,
    to: endDate,
    interval: .day
)

async let allRespiratory = healthStore.respiratoryForDateRange(
    from: startDate, 
    to: endDate,
    interval: .day
)

let (steps, respiratory) = try await (allSteps, allRespiratory)

// steps and respiratory now contain arrays indexed by day
```

**HealthKit Helper:**
```swift
extension HealthKitManager {
    func stepsForDateRange(
        from start: Date,
        to end: Date,
        interval: DateComponents
    ) async throws -> [Date: Double] {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        
        let query = HKStatisticsCollectionQuery(
            quantityType: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: interval
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { query, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var data: [Date: Double] = [:]
                results?.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        data[stats.startDate] = sum.doubleValue(for: .count())
                    }
                }
                continuation.resume(returning: data)
            }
            
            healthStore.execute(query)
        }
    }
}
```

**Expected Savings:** 7 seconds (14 sequential queries → 2 parallel queries)

---

### Fix 4: Move CTL/ATL to Background

**File:** `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`

**Current Code (BLOCKING):**
```swift
func loadInitialUI() async {
    // ... show cached data ...
    
    // ❌ WRONG: This blocks for 14+ seconds!
    await backfillCTLATL()
    
    // UI finally shows
}
```

**Fixed Code (BACKGROUND):**
```swift
func loadInitialUI() async {
    // Show cached data immediately
    await loadCachedData()  // <100ms
    
    // Start critical updates
    await calculateTodayScores()  // 2-3s
    
    // Move heavy work to background (non-blocking)
    Task.detached(priority: .background) {
        await self.backfillCTLATL()  // 14s, but doesn't block UI
        await self.updateTrainingLoad()
    }
}
```

**Expected Savings:** 14 seconds (moves to background, doesn't block UI)

---

### Fix 5: Skip Redundant Backfill

**File:** `VeloReady/Core/Services/ServiceContainer.swift`

**Current Code (ALWAYS RUNS):**
```swift
func checkForStaleData() async {
    // Always runs backfill, even if data is fresh
    await backfillCTLATL()
}
```

**Fixed Code (SMART CHECK):**
```swift
func checkForStaleData() async {
    // Check when last backfill ran
    guard shouldRunBackfill() else {
        Logger.debug("⏭️ [Backfill] Skipping - data is fresh")
        return
    }
    
    Logger.info("🔄 [Backfill] Starting - data is stale")
    await backfillCTLATL()
}

private func shouldRunBackfill() -> Bool {
    let lastBackfill = UserDefaults.standard.object(forKey: "lastCTLBackfill") as? Date
    
    guard let lastBackfill = lastBackfill else {
        return true  // Never run before
    }
    
    let hoursSinceBackfill = Date().timeIntervalSince(lastBackfill) / 3600
    return hoursSinceBackfill > 24  // Only run once per day
}

// After successful backfill:
UserDefaults.standard.set(Date(), forKey: "lastCTLBackfill")
```

**Expected Savings:** Skip 14-second backfill on most app launches

---

### Fix 6: Rate Limit Adjustment

**File:** `veloready-website/netlify/lib/auth.ts`

**Current Limits:**
```typescript
free: {
    rateLimitPerHour: 60,  // Too low for app startup!
}
```

**Problem:** App makes ~10-15 requests on startup (scores, activities, wellness, etc.), hitting FREE limit quickly

**Recommended Fix:**
```typescript
export const TIER_LIMITS = {
  free: {
    daysBack: 90,
    maxActivities: 100,
    activitiesPerHour: 60,
    streamsPerHour: 30,
    rateLimitPerHour: 100,  // ← Increase from 60 to 100
  },
  trial: {
    daysBack: 365,
    maxActivities: 500,
    activitiesPerHour: 300,
    streamsPerHour: 100,
    rateLimitPerHour: 300,  // ← Increase from 200 to 300
  },
  pro: {
    daysBack: 365,
    maxActivities: 500,
    activitiesPerHour: 300,
    streamsPerHour: 100,
    rateLimitPerHour: 300,  // ← Increase from 200 to 300
  },
}
```

**Rationale:** 
- Startup burst: ~15 requests
- Normal usage: 2-3 requests/minute
- 100/hour allows healthy startup without blocking legitimate use

---

## 📈 Expected Performance After Fixes

| Issue | Current | After Fix | Savings |
|-------|---------|-----------|---------|
| Token expired → API failures | 8s | 0s | **-8s** |
| 3× parallel activity requests | 3× rate limit | 1× request | **-2 API calls** |
| 14 sequential HealthKit queries | 7s | 1s | **-6s** |
| CTL/ATL blocking startup | 14s | 0s (background) | **-14s** |
| Redundant backfill | 14s | 0s (skip) | **-14s** |
| **TOTAL STARTUP TIME** | **~25s** | **<2s** | **~23s (92% faster)** |

---

## 🎯 Implementation Priority

### Critical (Do First):
1. **Token Refresh** - Fixes cascading failures
2. **Reduce Parallel Requests** - Fixes rate limit issues
3. **Move CTL/ATL to Background** - Unblocks UI

### Important (Do Next):
4. **Batch HealthKit Queries** - Significant time savings
5. **Skip Redundant Backfill** - Most startups don't need it

### Nice to Have:
6. **Rate Limit Adjustment** - Allows more headroom

---

## 🧪 Testing Checklist

### Before Fixes:
- [ ] Measure cold start time: ~25s
- [ ] Count API failures on startup: 3-5
- [ ] Note rate limit errors: Yes

### After Fixes:
- [ ] Measure cold start time: <2s
- [ ] Count API failures: 0
- [ ] Rate limit errors: No
- [ ] All data loads correctly: Yes
- [ ] Background tasks complete: Yes

---

## 🔍 Monitoring Post-Fix

**Add Instrumentation:**
```swift
func measureStartupPerformance() {
    let start = Date()
    
    // Phase 1: Show cached data
    await loadCachedData()
    Logger.info("⏱️ Phase 1 (cached): \(Date().timeIntervalSince(start))s")
    
    // Phase 2: Calculate scores
    await calculateScores()
    Logger.info("⏱️ Phase 2 (scores): \(Date().timeIntervalSince(start))s")
    
    // Phase 3: Background work (don't measure)
    Task.detached {
        await backgroundWork()
        Logger.info("⏱️ Background complete: \(Date().timeIntervalSince(start))s")
    }
}
```

**Expected Logs After Fix:**
```
⏱️ Phase 1 (cached): 0.1s
⏱️ Phase 2 (scores): 1.8s
⏱️ Background complete: 16.2s (doesn't block UI)
```

---

## 📊 Root Cause Summary

The **25-second startup** is caused by a **cascade of failures**:

1. **Token expired** → All API calls fail
2. **Failed API calls** → Trigger expensive HealthKit fallback
3. **Multiple parallel requests** → Hit rate limit
4. **Rate limit exceeded** → More fallback work
5. **Sequential HealthKit queries** → 14 queries × 500ms each
6. **Heavy calculations** → Block UI thread for 14 seconds

**Fix the token refresh first** - it prevents the entire cascade!

---

## ✅ Success Criteria

- [ ] Cold start < 2 seconds to interactive UI
- [ ] Zero API failures on startup
- [ ] Zero rate limit errors
- [ ] Background work doesn't block UI
- [ ] All scores calculate correctly
- [ ] Token always valid before making requests
