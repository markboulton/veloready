# Comprehensive Fix Plan - Performance + Critical Bugs

## Executive Summary

**Phase 2 Time:** 8.17s (Target: <5s)
**Critical Bugs:** 4 bugs blocking functionality
**Performance Optimizations:** 3 optimizations for ~5s savings

---

## Critical Bugs (Must Fix First)

### 1. ❌ Token Expired During Phase 2 → Activity Fetch Fails
**Impact:** HIGH - Blocks all backend API calls

**Problem:**
```
⚠️ [Supabase] Saved session expired - attempting refresh...
✅ PHASE 2 complete in 8.17s
...later...
✅ [Supabase] Token refreshed successfully
```

Token refresh happens in `Task {}` (fire-and-forget) while Phase 2 starts immediately. By the time strain calculation tries to fetch activities (~t=3s), token is still refreshing or has failed.

**Root Cause:**
- `SupabaseClient.init()` starts async token refresh in `Task {}` (line 45)
- Phase 2 doesn't wait for refresh to complete
- API calls fail with `notAuthenticated` or `serverError`

**Solution:**
```swift
// Option A: Wait for token refresh before Phase 2
if SupabaseClient.shared.isRefreshing {
    await SupabaseClient.shared.waitForRefresh()
}

// Option B: Retry API calls after token refresh
VeloReadyAPIClient.fetchActivities() {
    if error == .notAuthenticated && SupabaseClient.shared.isRefreshing {
        await waitForRefresh()
        retry()
    }
}

// Option C: Make token refresh blocking
// Load session → if expired, await refresh() → then continue
```

**Recommended:** Option C - Make refresh blocking in `TodayViewModel.loadInitialUI()`

---

### 2. ❌ Cardio TRIMP is 0 in Strain Score
**Impact:** HIGH - Strain score inaccurate

**Problem:**
```
⚠️ Failed to fetch unified activities: serverError
🔍 Total TRIMP from 0 workouts: 0.0
🔍 Total TRIMP from 0 unified activities: 0.0
Cardio TRIMP: 0.0
```

**Cause:** Cascading from Bug #1. Activity fetch fails due to expired token, so no activities = no TRIMP.

**Solution:** Fix Bug #1 first, then verify TRIMP calculation works.

---

### 3. ❌ AI Brief Error: "Recovery score not available"
**Impact:** MEDIUM - User sees error instead of daily brief

**Problem:**
```
❌ AI brief error: networkError("Recovery score not available")
```

But recovery score IS available (74). The AI brief fetch fails due to expired token.

**Cause:** Same as Bug #1 - token expired during API call.

**Solution:** Fix Bug #1.

---

### 4. ❌ Spinner Hides Too Early
**Impact:** LOW - UI shows scores before they're ready

**Problem:**
```
✅ UI displayed after 2.03s
...
✅ PHASE 2 complete in 8.17s
```

Spinner hides after 2s logo animation, but scores don't update until 8s later. User sees stale/cached scores for 6 seconds.

**Solution:**
```swift
// Don't hide spinner until Phase 2 completes
// Wait for BOTH logo animation (2s) AND Phase 2 (8s)
await Task.sleep(nanoseconds: 2_000_000_000) // Logo
// ❌ DON'T hide spinner here
await waitForPhase2ToComplete()
// ✅ NOW hide spinner
```

---

## Performance Optimizations

### Opt 1: Cache Baselines (HRV/RHR/Sleep) for 1 Hour
**Savings:** ~1 second

**Problem:**
```
🔄 Calculating fresh baselines...  (first time)
🔄 Calculating fresh baselines...  (second time - duplicate!)
```

Baselines are calculated TWICE in Phase 2 and change slowly over 7 days.

**Solution:**
```swift
// VeloReady/Core/Services/BaselineCalculator.swift
class BaselineCalculator {
    private var cachedBaselines: (Double, Double, Double, Double)?
    private var cacheTimestamp: Date?
    private let cacheExpiry: TimeInterval = 3600 // 1 hour
    
    func calculateAllBaselines() async -> (Double, Double, Double, Double) {
        if let cached = cachedBaselines,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpiry {
            Logger.debug("⚡ [Baselines] Using cached values (age: \(Int(Date().timeIntervalSince(timestamp)/60))m)")
            return cached
        }
        
        // Calculate fresh
        let baselines = await calculateFresh()
        cachedBaselines = baselines
        cacheTimestamp = Date()
        return baselines
    }
}
```

---

### Opt 2: Cache TRIMP Per Workout
**Savings:** ~3 seconds on subsequent launches

**Problem:**
```
💓 TRIMP Result: 9.9 (Workout on 2025-10-28)
💓 TRIMP Result: 2.8 (Workout on 2025-10-28)
... × 40 workouts = ~3 seconds
```

TRIMP is recalculated for the same 40 workouts on every launch.

**Solution:**
```swift
// VeloReady/Core/Services/TrainingLoadCalculator.swift
class TrainingLoadCalculator {
    // Cache TRIMP per workout ID
    private var trimpCache: [String: Double] = [:]
    
    func calculateTRIMP(for workout: HKWorkout) async -> Double {
        let workoutId = workout.uuid.uuidString
        
        // Check cache
        if let cached = trimpCache[workoutId] {
            Logger.debug("⚡ [TRIMP] Using cached value for workout \(workoutId)")
            return cached
        }
        
        // Calculate fresh
        let trimp = await calculateFreshTRIMP(workout)
        trimpCache[workoutId] = trimp
        return trimp
    }
}
```

**Cache Persistence:** Store in UserDefaults with workout UUID as key
**Cache Invalidation:** Never (TRIMP for a workout doesn't change)
**Memory:** ~40 workouts × 8 bytes = 320 bytes (negligible)

---

### Opt 3: Batch HealthKit HR Queries
**Savings:** ~1 second

**Problem:**
```swift
// Current: Serial queries (one at a time)
for workout in workouts {
    let hr = await healthKit.fetchHeartRate(workout)  // 75ms each
    let trimp = calculate(hr)
}
// Total: 40 × 75ms = 3 seconds
```

**Solution:**
```swift
// Batch query all HR data at once
let allWorkouts = workouts
let startDate = allWorkouts.map { $0.startDate }.min()!
let endDate = allWorkouts.map { $0.endDate }.max()!

// Single query for all HR data in date range
let allHRSamples = await healthKit.fetchHeartRate(
    from: startDate,
    to: endDate
)

// Map HR samples to workouts
for workout in workouts {
    let hrForWorkout = allHRSamples.filter {
        $0.date >= workout.startDate && $0.date <= workout.endDate
    }
    let trimp = calculate(hrForWorkout)
}
// Total: 1 query + processing = ~1-2 seconds
```

**Complexity:** HIGH - Requires significant refactoring of TRIMPCalculator

---

## Implementation Priority

### Phase 1: Critical Bugs (30 min)
1. ✅ Fix token refresh blocking (15 min)
2. ✅ Verify activity fetch works (5 min)
3. ✅ Verify AI brief works (5 min)
4. ✅ Fix spinner timing (5 min)

### Phase 2: Quick Wins (20 min)
5. ✅ Cache baselines for 1 hour (10 min)
6. ✅ Cache TRIMP per workout (10 min)

### Phase 3: Advanced (Optional, 2 hours)
7. ⚠️ Batch HealthKit queries (2 hours) - Complex refactor

---

## Expected Results

### After Phase 1 (Bug Fixes):
- ✅ Activity fetch works
- ✅ Strain score shows correct cardio TRIMP
- ✅ AI brief loads successfully
- ✅ Spinner hides after scores ready
- **Phase 2 Time:** Still ~8s (no performance gain)

### After Phase 2 (Quick Wins):
- ✅ Baselines cached (1s savings)
- ✅ TRIMP cached (3s savings on repeat)
- **Phase 2 Time:** 8s first launch, ~4s subsequent launches

### After Phase 3 (Advanced):
- ✅ Batched HealthKit queries (1s savings)
- **Phase 2 Time:** 7s first launch, ~3s subsequent launches

---

## Testing Checklist

### Bug Fixes:
- [ ] Cold launch with expired token → scores load
- [ ] Cardio TRIMP > 0 when workouts exist
- [ ] AI brief loads without error
- [ ] Spinner hides AFTER scores appear

### Performance:
- [ ] First launch: Baselines calculated, TRIMP calculated
- [ ] Second launch (within 1h): Baselines cached, TRIMP cached
- [ ] Logs show cache hits with age

### Edge Cases:
- [ ] No token → graceful fallback
- [ ] No workouts → strain shows steps only
- [ ] Token expires mid-request → retry works

---

## Files to Modify

### Bug Fixes:
1. `VeloReady/Core/Networking/SupabaseClient.swift` - Make refresh blocking
2. `VeloReady/Features/Today/ViewModels/TodayViewModel.swift` - Wait for refresh
3. `VeloReady/Features/Today/Views/Dashboard/TodayView.swift` - Fix spinner timing

### Performance:
4. `VeloReady/Core/Services/BaselineCalculator.swift` - Add caching
5. `VeloReady/Core/Services/TrainingLoadCalculator.swift` - Add TRIMP caching
6. `VeloReady/Core/Services/TRIMPCalculator.swift` - (Optional) Batch queries

---

## Unit Tests Needed

### Critical Paths:
```swift
// Test token refresh blocking
func testTokenRefreshBlocksPhase2() async {
    // Expire token
    // Start Phase 2
    // Verify: Activity fetch succeeds
}

// Test TRIMP caching
func testTRIMPCaching() async {
    let workout = mockWorkout()
    
    // First call: Calculate
    let trimp1 = await calculator.calculateTRIMP(for: workout)
    
    // Second call: Use cache
    let trimp2 = await calculator.calculateTRIMP(for: workout)
    
    XCTAssertEqual(trimp1, trimp2)
    // Verify only 1 HealthKit query
}

// Test baseline caching
func testBaselineCaching() async {
    // First call: Calculate
    let baselines1 = await calculator.calculateAllBaselines()
    
    // Second call (within 1h): Use cache
    let baselines2 = await calculator.calculateAllBaselines()
    
    XCTAssertEqual(baselines1, baselines2)
    // Verify only 1 HealthKit query
}
```

---

## Rollback Plan

If any fix breaks functionality:
1. Revert commit
2. Test on simulator
3. Fix issue
4. Re-deploy

Each fix is independent and can be rolled back individually.

---

## Success Criteria

### Must Have (Phase 1):
- ✅ No `serverError` in logs
- ✅ Cardio TRIMP > 0 when workouts exist
- ✅ AI brief loads
- ✅ Spinner timing correct

### Should Have (Phase 2):
- ✅ Phase 2 < 5s on subsequent launches
- ✅ Baseline cache hits in logs
- ✅ TRIMP cache hits in logs

### Nice to Have (Phase 3):
- ✅ Phase 2 < 4s on first launch
- ✅ Batched HealthKit queries

---

## Next Steps

1. Start with **Bug #1 (Token Refresh)** - blocks everything else
2. Test on device - verify activity fetch works
3. Move to **Bug #4 (Spinner)** - quick fix
4. Implement **Opt 1 (Baseline Cache)** - easy win
5. Implement **Opt 2 (TRIMP Cache)** - big win
6. Decide if **Opt 3 (Batch Queries)** is worth the complexity

**Estimated Total Time:** 1 hour (Phases 1-2)
**Expected Improvement:** 8s → 4s (50% faster on repeat launches)
