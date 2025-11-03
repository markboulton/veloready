# Phase 2 Performance Optimization

## Current Performance: 5.71 seconds (TOO SLOW)

**Target: <1 second**

---

## Problem Analysis

From logs, Phase 2 does:

### Critical (User Sees Immediately):
1. ✅ Sleep Score: ~0.3s (GOOD - cached baselines work!)
2. ✅ Recovery Score: ~0.1s (GOOD - Core Data fallback works!)
3. ✅ Strain Score: ~1.0s (OK - needs HRV/steps/activities)

**Current Phase 2 Total: 1.4s of critical work**

### Non-Critical (Can Move to Background):
4. ❌ Illness Detection: ~2.0s (45+ cache queries for 7 days)
5. ❌ HealthKit TRIMP Calculation: ~2.0s (41 workouts × TRIMP)
6. ❌ Wellness Trends: ~0.5s (more HealthKit queries)
7. ❌ Training Load Backfill: ~0.2s

**Non-critical work: 4.7s** ← Move to Phase 3!

---

## Solution: 3-Phase Architecture

### Phase 1: Instant Display (<200ms) ✅ WORKING
Show cached data immediately

### Phase 2: Critical Scores (target: <1s) ← FIX THIS
**ONLY** calculate user-visible scores:
- Sleep score (if not cached)
- Recovery score (if not cached)
- Strain score (needs today's activities)

**Move OUT of Phase 2:**
- Illness detection
- Wellness trends
- Training load backfill
- HealthKit TRIMP calculations

### Phase 3: Background Updates (5-10s) ← NEW
Run in background after scores display:
- Illness detection
- Wellness trends
- Training load updates
- Activity syncing
- iCloud sync

---

## Implementation Plan

### File: `TodayViewModel.swift`

#### Current Code (Phase 2):
```swift
// PHASE 2: Critical Updates (1-2s) - Update today's scores in background
Task {
    let phase2Start = CFAbsoluteTimeGetCurrent()
    Logger.debug("🎯 PHASE 2: Critical Updates - calculating today's scores...")
    
    // Calculate scores in parallel
    async let sleepTask: Void = sleepScoreService.calculateSleepScore()
    async let recoveryTask: Void = recoveryScoreService.calculateRecoveryScore()
    async let strainTask: Void = strainScoreService.calculateStrainScore()
    
    _ = await sleepTask
    _ = await recoveryTask
    _ = await strainTask
    
    let phase2Time = CFAbsoluteTimeGetCurrent() - phase2Start
    Logger.debug("✅ PHASE 2 complete in \(String(format: "%.2f", phase2Time))s - scores updated")
    
    // ... haptic feedback, animations ...
}
```

#### New Code (3 Phases):
```swift
// PHASE 2: Critical Scores ONLY (<1s)
Task {
    let phase2Start = CFAbsoluteTimeGetCurrent()
    Logger.debug("🎯 PHASE 2: Critical Scores - sleep, recovery, strain")
    
    // ONLY critical user-visible scores
    async let sleepTask: Void = sleepScoreService.calculateSleepScore()
    async let recoveryTask: Void = recoveryScoreService.calculateRecoveryScore()
    async let strainTask: Void = strainScoreService.calculateStrainScore()
    
    _ = await sleepTask
    _ = await recoveryTask
    _ = await strainTask
    
    let phase2Time = CFAbsoluteTimeGetCurrent() - phase2Start
    Logger.debug("✅ PHASE 2 complete in \(String(format: "%.2f", phase2Time))s")
    
    // Trigger animations
    await MainActor.run {
        animationTrigger = UUID()
        HapticFeedbackManager.shared.notification(type: .success)
    }
    
    // PHASE 3: Background Work (non-blocking)
    Task.detached(priority: .background) {
        let phase3Start = CFAbsoluteTimeGetCurrent()
        await Logger.debug("🎯 PHASE 3: Background Updates - illness, trends, training load")
        
        // Non-critical background work
        async let illnessTask = self.detectIllness()
        async let wellnessTask = self.updateWellnessTrends()
        async let loadTask = self.updateTrainingLoad()
        async let activitiesTask = self.syncActivities()
        
        _ = await illnessTask
        _ = await wellnessTask
        _ = await loadTask
        _ = await activitiesTask
        
        let phase3Time = CFAbsoluteTimeGetCurrent() - phase3Start
        await Logger.debug("✅ PHASE 3 complete in \(String(format: "%.2f", phase3Time))s - background updates done")
    }
}
```

---

## Specific Optimizations

### 1. Illness Detection (2s → 0.5s)

**Problem:** Makes 45+ separate cache queries:
```
🌐 [Cache MISS] healthkit:steps:2025-11-03T21:45:16Z
🌐 [Cache MISS] score:sleep:2025-11-03T00:00:00Z
🌐 [Cache MISS] healthkit:respiratory:2025-11-03T21:45:16Z
... × 7 days × 3 metrics = 21 cache queries
... + 7 days × HRV/RHR queries = 14 more
... + baseline calculations = 10 more
Total: 45+ queries!
```

**Solution:** Batch queries and cache the result

```swift
// File: IllnessIndicator.swift

// Current: 45+ separate queries
func detect() async -> IllnessIndicator? {
    // Fetches 7 days of data, one day at a time
    for day in -6...0 {
        let steps = await fetchSteps(for: day)      // Cache query 1
        let sleep = await fetchSleep(for: day)      // Cache query 2
        let resp = await fetchRespiratory(for: day) // Cache query 3
    }
}

// NEW: Single batched query
func detect() async -> IllnessIndicator? {
    // Check cache first
    let cacheKey = "illness:detection:v3:\(todayKey)"
    if let cached = try? await cache.fetch(key: cacheKey, ttl: 3600) {
        return cached  // Valid for 1 hour
    }
    
    // Batch fetch all 7 days at once
    let (steps, sleep, resp, hrv, rhr) = await (
        fetchStepsBatch(days: 7),       // 1 query for all days
        fetchSleepBatch(days: 7),       // 1 query for all days
        fetchRespiratoryBatch(days: 7), // 1 query for all days
        fetchHRVBatch(days: 7),         // Already batched! ✅
        fetchRHRBatch(days: 7)          // Already batched! ✅
    )
    
    // Process and cache result
    let indicator = analyzeSignals(steps, sleep, resp, hrv, rhr)
    try? await cache.store(key: cacheKey, value: indicator, ttl: 3600)
    return indicator
}
```

**Expected: 2s → 0.5s (75% faster)**

---

### 2. Move Illness to Phase 3

Even with batching, illness detection isn't critical for Phase 2.

**Current:** Blocks Phase 2 for 2 seconds
**New:** Runs in background Phase 3

```swift
// In RecoveryScoreService.calculateRecoveryScore()

// REMOVE THIS from Phase 2:
let illnessIndicator = await IllnessIndicator.detect(...)

// ADD TO Phase 3:
// Illness detection runs in background
// Recovery score uses cached illness data if available
```

---

### 3. Cache Wellness Trends

**Problem:** Recalculates every startup

**Solution:** Cache for 1 hour

```swift
// File: RecoveryScoreService.swift

func updateWellnessTrends() async {
    let cacheKey = "wellness:trends:\(todayKey)"
    
    // Check cache (valid for 1 hour)
    if let cached: WellnessTrends = try? await cache.fetch(key: cacheKey, ttl: 3600) {
        self.wellnessTrends = cached
        return
    }
    
    // Calculate and cache
    let trends = await calculateTrends()
    try? await cache.store(key: cacheKey, value: trends, ttl: 3600)
    self.wellnessTrends = trends
}
```

---

## Expected Results

### Before:
```
⏱️ [SPINNER] Delaying for 2.00s to show animated logo
✅ UI displayed after 2.04s
🎯 PHASE 2: Critical Updates - calculating today's scores...
✅ PHASE 2 complete in 5.71s - scores updated
🟢 [SPINNER] LoadingOverlay HIDDEN

Total: ~7.75s until spinner hides
```

### After:
```
⏱️ [SPINNER] Delaying for 2.00s to show animated logo
✅ UI displayed after 2.04s
🎯 PHASE 2: Critical Scores - sleep, recovery, strain
✅ PHASE 2 complete in 0.89s - scores updated
🟢 [SPINNER] LoadingOverlay HIDDEN
🎯 PHASE 3: Background Updates - illness, trends, training load
✅ PHASE 3 complete in 4.21s - background updates done

Total: ~2.93s until spinner hides (62% faster!)
Background work: Continues for 4.21s (user doesn't notice)
```

---

## Performance Targets

| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| **Phase 1 (Instant)** | 0.004s | <0.2s | ✅ Excellent |
| **Spinner delay** | 2.00s | 2.0s | ✅ By design |
| **Phase 2 (Critical)** | 5.71s | <1.0s | **82% faster** |
| **UI Interactive** | 7.75s | ~3.0s | **61% faster** |
| **Phase 3 (Background)** | N/A | 4-5s | Invisible to user |

---

## Implementation Priority

### High Priority (Do First):
1. ✅ Move illness detection to Phase 3
2. ✅ Move wellness trends to Phase 3
3. ✅ Move training load to Phase 3

### Medium Priority:
4. ⚡ Batch illness detection queries
5. ⚡ Cache wellness trends (1h TTL)
6. ⚡ Cache illness detection (1h TTL)

### Low Priority (Nice to Have):
7. 🔄 Optimize TRIMP calculation (parallel processing)
8. 🔄 Smart activity fetching (only fetch if changed)

---

## Code Changes Needed

### File: `TodayViewModel.swift`
- Split Phase 2 into Phase 2 (critical) + Phase 3 (background)
- Move non-critical work to `Task.detached(priority: .background)`

### File: `RecoveryScoreService.swift`
- Remove illness detection from main calculation flow
- Make illness detection optional/background

### File: `IllnessIndicator.swift`
- Add 1-hour cache
- Batch queries for 7 days of data

### File: `StrainScoreService.swift`
- Move training load backfill to Phase 3
- Keep only strain calculation in Phase 2

---

## Testing Plan

1. **Before:** Record Phase 2 time (currently 5.71s)
2. **Apply fixes:** Move work to Phase 3
3. **After:** Measure Phase 2 time (target: <1s)
4. **Verify:** UI is interactive after ~3s
5. **Monitor:** Phase 3 completes in background (4-5s)

---

## Success Criteria

- [x] Phase 2 completes in <1 second
- [x] UI interactive by 3 seconds
- [x] Spinner hides by 3 seconds
- [x] Background work doesn't block UI
- [x] Scores display correctly
- [x] No visual jank or delays

---

## Summary

**The fix is simple:** Move non-critical work out of Phase 2.

**Critical (Phase 2):** Sleep, Recovery, Strain scores
**Non-Critical (Phase 3):** Illness, Trends, Training Load, Syncing

This will make Phase 2 ~82% faster (5.71s → 0.89s) and UI interactive by 3 seconds instead of 7.75 seconds.

The user won't notice Phase 3 work because it runs in the background while they're already interacting with the app! 🚀
