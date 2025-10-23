# Phase 2: Service Consolidation & Clean Architecture

**Status:** ✅ COMPLETE  
**Started:** October 23, 2025  
**Completed:** October 23, 2025  
**Goal:** Consolidate health metric services and standardize caching

---

## Key Discovery

✅ **Calculators already exist as pure static methods!**

The calculation logic is already separated from I/O in the model files:
- `RecoveryScoreCalculator.calculate()` in `RecoveryScore.swift`
- `SleepScoreCalculator.calculate()` in `SleepScore.swift`
- `StrainScoreCalculator.calculate()` in `StrainScore.swift`

**This means we can skip Step 1 (Extract Calculators) and focus on service consolidation!**

---

## Current Architecture Analysis

### Existing Services (Needs Consolidation)

**1. RecoveryScoreService.swift** (~827 lines)
- ✅ Already uses `RecoveryScoreCalculator.calculate()`
- 🔴 Manual caching with `UserDefaults` (duplicates UnifiedCacheManager)
- 🔴 Manual `lastCalculationDate` tracking
- 🔴 Dependencies: HealthKitManager, SleepScoreService, BaselineCalculator, IntervalsCache
- 🟡 Some complexity in data fetching (parallel async let)

**2. SleepScoreService.swift** (~522 lines)
- ✅ Already uses `SleepScoreCalculator.calculate()`
- 🔴 Manual caching with `UserDefaults`
- 🔴 Dependencies: HealthKitManager, BaselineCalculator
- 🟡 Validates sleep data freshness

**3. StrainScoreService.swift** (~554 lines)
- ✅ Already uses `StrainScoreCalculator.calculate()`
- 🔴 Manual caching with `UserDefaults`
- 🔴 Dependencies: HealthKitManager, UnifiedActivityService, IntervalsCache

### Code Duplication Identified

**Manual Caching Pattern (repeated 3x):**
```swift
// Save to cache
private let cachedScoreKey = "cached[Type]Score"
private let cachedScoreDateKey = "cached[Type]ScoreDate"

private func loadCachedScore() {
    guard let cachedData = userDefaults.data(forKey: cachedScoreKey),
          let cachedDate = userDefaults.object(forKey: cachedScoreDateKey) as? Date else { return }
    // Decode and check if today...
}

private func saveScoreToCache(_ score: Score) {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(score)
        userDefaults.set(data, forKey: cachedScoreKey)
        userDefaults.set(Date(), forKey: cachedScoreDateKey)
    } catch { ... }
}
```

**Estimated duplicate code:** ~200 lines across 3 services

---

## Revised Implementation Plan

### ✅ Step 1: Audit Current State (COMPLETE)
- [x] Calculators already exist as pure static methods
- [x] Services use calculators correctly
- [x] Identified ~200 lines of duplicate caching code
- [x] All services follow similar pattern: fetch → calculate → cache

### 🚧 Step 2: Standardize Caching (IN PROGRESS)
**Goal:** Replace manual `UserDefaults` caching with `UnifiedCacheManager`

**Changes needed per service:**
1. Remove manual cache keys (`cachedScoreKey`, `cachedScoreDateKey`)
2. Replace `loadCachedScore()` with `UnifiedCacheManager.fetch()`
3. Remove `saveScoreToCache()` (UnifiedCacheManager handles it)
4. Remove duplicate encode/decode logic

**Benefits:**
- ~60 lines removed per service (180 total)
- Consistent TTL behavior
- Memory management handled by UnifiedCacheManager
- Cache invalidation becomes trivial

### ⏭️ Step 3: Optional - Create HealthMetricsService Wrapper
**Decision:** SKIP for now

**Reasoning:**
- Services already work well independently
- Each has unique concerns (Recovery needs Sleep, Strain needs Activities)
- Creating a wrapper adds complexity without clear benefit
- ViewModels can continue calling services directly

### ⏭️ Step 4: Cleanup & Testing
- [ ] Build succeeds
- [ ] Test on device
- [ ] Verify cache behavior
- [ ] Update documentation

---

## Files to Modify

### Phase 2A: Standardize Caching
- [x] `RecoveryScoreService.swift` - Replace manual caching ✅
- [x] `SleepScoreService.swift` - Replace manual caching ✅
- [x] `StrainScoreService.swift` - Replace manual caching ✅

### No Changes Needed
- ✅ `RecoveryScore.swift` - Calculator already pure
- ✅ `SleepScore.swift` - Calculator already pure
- ✅ `StrainScore.swift` - Calculator already pure
- ✅ ViewModels - Continue using services as-is

---

## Success Metrics

- [x] ~180 lines of duplicate code removed ✅
- [x] All services use UnifiedCacheManager ✅
- [x] No manual `UserDefaults` cache management ✅
- [x] Build succeeds ✅
- [ ] All tests pass (manual testing required)
- [ ] Cache hits verified in logs (device testing required)

---

---

## Implementation Summary

### Work Completed

**1. Migrated RecoveryScoreService** ✅
- Removed manual UserDefaults caching (~66 lines)
- Replaced with UnifiedCacheManager.fetch()
- Uses CacheKey.recoveryScore() for consistency

**2. Migrated SleepScoreService** ✅
- Removed manual UserDefaults caching (~54 lines)
- Replaced with UnifiedCacheManager.fetch()
- Uses CacheKey.sleepScore() for consistency

**3. Migrated StrainScoreService** ✅
- Removed manual UserDefaults caching (~56 lines)
- Replaced with UnifiedCacheManager.fetch()
- Uses day-specific cache keys

**4. Fixed Actor Isolation Issues** ✅
- Problem: UnifiedCacheManager was @MainActor but called from background Tasks
- Solution: Made cache methods nonisolated with proper synchronization
- Added NSLock for thread-safe dictionary access
- Kept @Published stats MainActor-isolated

### Code Metrics

- **Total lines removed:** ~176 lines of duplicate cache code
- **Builds:** ✅ All succeeded
- **Runtime errors:** ✅ Fixed (UTF-8 marshal error resolved)

### Key Improvements

1. **Consistency:** All services use same caching mechanism
2. **Thread-Safety:** Proper synchronization with NSLock
3. **Simplicity:** No manual encode/decode/expiry logic
4. **Memory Management:** NSCache handles eviction automatically
5. **Deduplication:** Built-in request deduplication

---

## Next Steps

✅ **Phase 2 Complete** - Ready for device testing

**Testing Checklist:**
- [ ] Verify cache hits in logs
- [ ] Test recovery score calculation
- [ ] Test sleep score calculation
- [ ] Test strain score calculation
- [ ] Verify widget updates work correctly
- [ ] Check memory usage under load
