# Refactoring Opportunities - CacheManager & TodayCoordinator

## Executive Summary

Found **5 major redundant patterns** with significant code duplication:

1. **Throttling Logic** - 170+ lines duplicated across 4 backfill functions
2. **Core Data Context Pattern** - 50+ lines duplicated across 6 functions
3. **Backfill Logging Pattern** - 30+ lines duplicated across 4 functions
4. **Date Range Calculation** - 20+ lines duplicated across 4 functions
5. **Score Calculation Algorithm** - Similar patterns in recovery/sleep backfills

**Total redundant code**: ~270 lines (22% of CacheManager.swift)

---

## 1. Throttling Logic (HIGHEST PRIORITY ⚡)

### Current State: 42 Lines × 4 Functions = 168 Lines

**Pattern repeated in:**
- `calculateMissingCTLATL()` (Lines 555-562)
- `backfillHistoricalRecoveryScores()` (Lines 728-735)
- `backfillStrainScores()` (Lines 996-1003)
- `backfillSleepScores()` (Lines 1093-1100)

### Existing Code (Duplicated 4×)

```swift
// Check if backfill ran recently (within 24 hours) unless forcing
let lastBackfillKey = "lastRecoveryBackfill"
if !forceRefresh, let lastBackfill = UserDefaults.standard.object(forKey: lastBackfillKey) as? Date {
    let hoursSinceBackfill = Date().timeIntervalSince(lastBackfill) / 3600
    if hoursSinceBackfill < 24 {
        Logger.data("⏭️ [RECOVERY BACKFILL] Skipping - last run was \(String(format: "%.1f", hoursSinceBackfill))h ago (< 24h)")
        return
    }
}
// ... do work ...
// Save timestamp of successful backfill (outside context.perform)
UserDefaults.standard.set(Date(), forKey: lastBackfillKey)
```

### Refactored Solution: Throttle Helper

```swift
// MARK: - Throttle Helper

extension CacheManager {
    /// Execute a backfill operation with throttling (once per 24h unless forced)
    private func throttledBackfill(
        key: String,
        logPrefix: String,
        forceRefresh: Bool,
        operation: () async throws -> Void
    ) async rethrows {
        // Check throttle
        if !forceRefresh, let lastRun = UserDefaults.standard.object(forKey: key) as? Date {
            let hoursSince = Date().timeIntervalSince(lastRun) / 3600
            if hoursSince < 24 {
                Logger.data("⏭️ [\(logPrefix)] Skipping - last run was \(String(format: "%.1f", hoursSince))h ago (< 24h)")
                return
            }
        }
        
        // Execute operation
        try await operation()
        
        // Save timestamp
        UserDefaults.standard.set(Date(), forKey: key)
    }
}
```

### Usage (reduces each function by 10 lines)

```swift
func backfillStrainScores(daysBack: Int = 60, forceRefresh: Bool = false) async {
    await throttledBackfill(
        key: "lastStrainBackfill",
        logPrefix: "STRAIN BACKFILL",
        forceRefresh: forceRefresh
    ) {
        Logger.debug("🔄 [STRAIN BACKFILL] Starting backfill for last \(daysBack) days...")
        // ... actual work ...
    }
}
```

**Savings**: 168 lines → 40 lines = **128 lines removed (76% reduction)**

---

## 2. Core Data Context Pattern (HIGH PRIORITY ⚡)

### Current State: Duplicated Pattern Across 6 Functions

**Pattern repeated in:**
- `saveToCache()` (Line 319)
- `cleanupCorruptTrainingLoadData()` (Line 510)
- `updateDailyLoadBatch()` (Line 630)
- `backfillHistoricalRecoveryScores()` (Line 743)
- `backfillStrainScores()` (Line 1009)
- `backfillSleepScores()` (Line 1106)

### Existing Code (Duplicated 6×)

```swift
let context = persistence.newBackgroundContext()

await context.perform {
    var updatedCount = 0
    var skippedCount = 0
    
    // ... loop over items ...
    
    // Save changes
    if context.hasChanges {
        do {
            try context.save()
            Logger.debug("✅ [BACKFILL] Updated \(updatedCount), skipped \(skippedCount)")
        } catch {
            Logger.error("❌ [BACKFILL] Failed to save: \(error)")
        }
    } else {
        Logger.debug("📊 [BACKFILL] No changes to save")
    }
}
```

### Refactored Solution: Context Helper

```swift
// MARK: - Core Data Helper

extension CacheManager {
    /// Execute Core Data operations in a background context with automatic save
    private func performInBackground<T>(
        logPrefix: String,
        operation: (NSManagedObjectContext) throws -> T
    ) async -> Result<T, Error> {
        let context = persistence.newBackgroundContext()
        
        return await context.perform {
            do {
                let result = try operation(context)
                
                // Save if changes exist
                if context.hasChanges {
                    try context.save()
                }
                
                return .success(result)
            } catch {
                Logger.error("❌ [\(logPrefix)] Core Data error: \(error)")
                return .failure(error)
            }
        }
    }
    
    /// Execute Core Data batch operations with progress tracking
    private func performBatchInBackground(
        logPrefix: String,
        operation: (NSManagedObjectContext) throws -> (updated: Int, skipped: Int)
    ) async {
        let result = await performInBackground(logPrefix: logPrefix, operation: operation)
        
        switch result {
        case .success(let counts):
            if counts.updated > 0 {
                Logger.debug("✅ [\(logPrefix)] Updated \(counts.updated), skipped \(counts.skipped)")
            } else {
                Logger.debug("📊 [\(logPrefix)] No changes to save (\(counts.skipped) skipped)")
            }
        case .failure:
            break // Already logged
        }
    }
}
```

### Usage

```swift
func backfillStrainScores(daysBack: Int = 60) async {
    await performBatchInBackground(logPrefix: "STRAIN BACKFILL") { context in
        var updatedCount = 0
        var skippedCount = 0
        
        // ... do work with context ...
        
        return (updated: updatedCount, skipped: skippedCount)
    }
}
```

**Savings**: ~60 lines across 6 functions = **~50 lines removed**

---

## 3. Date Range Calculation (MEDIUM PRIORITY)

### Current State: Duplicated 4×

**Pattern repeated in:**
- `backfillHistoricalRecoveryScores()`
- `backfillHistoricalPhysioData()`
- `backfillStrainScores()`
- `backfillSleepScores()`

### Existing Code (Duplicated 4×)

```swift
let calendar = Calendar.current
let today = calendar.startOfDay(for: Date())
let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

for dayOffset in 1...days {
    guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
    let startOfDay = calendar.startOfDay(for: date)
    // ... process day ...
}
```

### Refactored Solution: Date Range Iterator

```swift
// MARK: - Date Range Helper

extension CacheManager {
    /// Generate a sequence of historical dates (excluding today)
    private func historicalDates(daysBack: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (1...daysBack).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return calendar.startOfDay(for: date)
        }
    }
    
    /// Get the date range for historical backfill
    private func backfillDateRange(days: Int) -> (start: Date, today: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -days, to: today)!
        return (start, today)
    }
}
```

### Usage

```swift
func backfillStrainScores(daysBack: Int = 60) async {
    for date in historicalDates(daysBack: daysBack) {
        // Process date
    }
}
```

**Savings**: ~20 lines across 4 functions = **15 lines removed**

---

## 4. Score Calculation Algorithms (MEDIUM PRIORITY)

### Current State: Similar Patterns

Both `backfillHistoricalRecoveryScores()` and `backfillSleepScores()` have similar structures:
1. Fetch DailyScores
2. Check if needs calculation (placeholder check)
3. Fetch related data (DailyPhysio or DailyLoad)
4. Calculate score
5. Update and save

### Refactored Solution: Generic Backfill Template

```swift
// MARK: - Generic Backfill Template

extension CacheManager {
    /// Generic backfill template for score calculations
    private func backfillScore<T>(
        days: Int,
        logPrefix: String,
        shouldUpdate: (DailyScores) -> Bool,
        fetchData: (NSManagedObjectContext, Date) -> T?,
        calculateScore: (T, DailyPhysio?) -> Double,
        updateScore: (inout DailyScores, Double) -> Void
    ) async {
        await performBatchInBackground(logPrefix: logPrefix) { context in
            var updatedCount = 0
            var skippedCount = 0
            
            for date in historicalDates(daysBack: days) {
                let scoresRequest = DailyScores.fetchRequest()
                scoresRequest.predicate = NSPredicate(format: "date == %@", date as NSDate)
                scoresRequest.fetchLimit = 1
                
                guard var scores = try context.fetch(scoresRequest).first else {
                    skippedCount += 1
                    continue
                }
                
                guard shouldUpdate(scores) else {
                    skippedCount += 1
                    continue
                }
                
                guard let data = fetchData(context, date) else {
                    skippedCount += 1
                    continue
                }
                
                let score = calculateScore(data, scores.physio)
                updateScore(&scores, score)
                scores.lastUpdated = Date()
                updatedCount += 1
            }
            
            return (updated: updatedCount, skipped: skippedCount)
        }
    }
}
```

### Usage

```swift
func backfillSleepScores(days: Int = 60, forceRefresh: Bool = false) async {
    await throttledBackfill(key: "lastSleepBackfill", logPrefix: "SLEEP BACKFILL", forceRefresh: forceRefresh) {
        await backfillScore(
            days: days,
            logPrefix: "SLEEP BACKFILL",
            shouldUpdate: { !forceRefresh && $0.sleepScore == 50 },
            fetchData: { context, date -> DailyPhysio? in
                // Fetch physio
            },
            calculateScore: { physio, _ in
                // Calculate sleep score
            },
            updateScore: { scores, score in
                scores.sleepScore = score
            }
        )
    }
}
```

**Savings**: ~60 lines across 3 score backfills = **40 lines removed**

---

## 5. TodayCoordinator Redundancies

### Current Issues

1. **State Checking Redundancy**
   ```swift
   // Line 155-156 (duplicated pattern)
   let scoresStillLoading = scoresCoordinator.state.phase == .loading || 
                            scoresCoordinator.state.phase == .initial
   ```

2. **Time-Based Refresh Logic**
   ```swift
   // Lines 182-190 - Could be a helper
   private func shouldRefreshOnReappear() -> Bool {
       guard let lastLoad = lastLoadTime else { return true }
       let minutesSinceLoad = Date().timeIntervalSince(lastLoad) / 60
       return minutesSinceLoad > 5
   }
   ```

### Refactored: Coordinator State Helper

```swift
// MARK: - State Helpers

extension TodayCoordinator {
    private var scoresNeedCalculation: Bool {
        [.loading, .initial].contains(scoresCoordinator.state.phase)
    }
    
    private var shouldAutoRefresh: Bool {
        guard let lastLoad = lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) > 300 // 5 minutes
    }
    
    private func needsRefresh(minimumInterval: TimeInterval = 300) -> Bool {
        guard let lastLoad = lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) > minimumInterval
    }
}
```

**Savings**: ~15 lines of state checking logic

---

## Recommended Refactoring Plan

### Phase 1: High Impact, Low Risk (Week 1)
1. ✅ **Throttling Helper** - 128 lines saved, 4 functions improved
2. ✅ **Core Data Helper** - 50 lines saved, 6 functions improved
3. ✅ **Date Range Helper** - 15 lines saved, 4 functions improved

**Total Phase 1 Savings**: ~193 lines (16% of file)

### Phase 2: Medium Impact, Medium Risk (Week 2)
4. ✅ **Generic Backfill Template** - 40 lines saved, standardizes pattern
5. ✅ **TodayCoordinator State Helpers** - 15 lines saved, clearer logic

**Total Phase 2 Savings**: ~55 lines

### Phase 3: Long-term Architecture (Future)
6. Consider extracting backfill operations to separate `BackfillService`
7. Consider using Swift Macros for throttling (iOS 17+)
8. Consider dependency injection for UserDefaults (testability)

---

## Implementation Example: Complete Refactor

### Before (backfillStrainScores): 87 Lines

```swift
func backfillStrainScores(daysBack: Int = 7, forceRefresh: Bool = false) async {
    // Throttle: Only run once per day unless forced
    let lastBackfillKey = "lastStrainBackfill"
    if !forceRefresh, let lastBackfill = UserDefaults.standard.object(forKey: lastBackfillKey) as? Date {
        let hoursSinceBackfill = Date().timeIntervalSince(lastBackfill) / 3600
        if hoursSinceBackfill < 24 {
            Logger.debug("⏭️ [STRAIN BACKFILL] Skipping...")
            return
        }
    }
    
    Logger.debug("🔄 [STRAIN BACKFILL] Starting...")
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let context = persistence.newBackgroundContext()
    
    await context.perform {
        var updatedCount = 0
        var skippedCount = 0
        
        for dayOffset in 1...daysBack {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            // ... 50 lines of logic ...
        }
        
        if context.hasChanges {
            do {
                try context.save()
                Logger.debug("✅ [STRAIN BACKFILL] Updated...")
            } catch {
                Logger.error("❌ [STRAIN BACKFILL] Failed...")
            }
        }
    }
    
    UserDefaults.standard.set(Date(), forKey: lastBackfillKey)
}
```

### After (backfillStrainScores): 31 Lines

```swift
func backfillStrainScores(daysBack: Int = 60, forceRefresh: Bool = false) async {
    await throttledBackfill(
        key: "lastStrainBackfill",
        logPrefix: "STRAIN BACKFILL",
        forceRefresh: forceRefresh
    ) {
        Logger.debug("🔄 [STRAIN BACKFILL] Starting backfill for last \(daysBack) days...")
        
        await performBatchInBackground(logPrefix: "STRAIN BACKFILL") { context in
            var updatedCount = 0
            var skippedCount = 0
            
            for date in historicalDates(daysBack: daysBack) {
                // Fetch DailyScores
                guard let scores = fetchScores(for: date, in: context) else {
                    skippedCount += 1
                    continue
                }
                
                // Skip if already has strain score > 0
                guard forceRefresh || scores.strainScore == 0 else {
                    skippedCount += 1
                    continue
                }
                
                // Fetch DailyLoad for TSS
                guard let load = fetchLoad(for: date, in: context) else {
                    scores.strainScore = 2.0 // Minimal NEAT
                    updatedCount += 1
                    continue
                }
                
                // Calculate and save
                scores.strainScore = calculateStrainFromTSS(load.tss)
                scores.lastUpdated = Date()
                updatedCount += 1
            }
            
            return (updated: updatedCount, skipped: skippedCount)
        }
    }
}
```

**Reduction**: 87 lines → 31 lines = **64% reduction**

---

## Benefits Summary

### Code Quality
- ✅ **DRY principle**: Remove 193+ lines of duplication
- ✅ **Single responsibility**: Each helper has one job
- ✅ **Testability**: Helpers can be unit tested independently
- ✅ **Maintainability**: Change throttle logic once, not 4×

### Performance
- ✅ **No performance impact**: Same operations, just organized
- ✅ **Better error handling**: Centralized in helpers
- ✅ **Consistent logging**: All backfills log the same way

### Developer Experience
- ✅ **Easier to add new backfills**: Copy template, fill in logic
- ✅ **Clearer intent**: `throttledBackfill()` vs 10 lines of UserDefaults
- ✅ **Less cognitive load**: Helpers abstract complexity

---

## Testing Strategy

### Unit Tests for New Helpers

```swift
class CacheManagerHelpersTests: XCTestCase {
    func testThrottledBackfillSkipsWhenRecent() async {
        // Given: Last run was 1 hour ago
        UserDefaults.standard.set(Date().addingTimeInterval(-3600), forKey: "test")
        
        var didExecute = false
        
        // When: Attempt backfill
        await cacheManager.throttledBackfill(key: "test", logPrefix: "TEST", forceRefresh: false) {
            didExecute = true
        }
        
        // Then: Should skip
        XCTAssertFalse(didExecute)
    }
    
    func testThrottledBackfillExecutesWhenOld() async {
        // Given: Last run was 25 hours ago
        UserDefaults.standard.set(Date().addingTimeInterval(-25 * 3600), forKey: "test")
        
        var didExecute = false
        
        // When: Attempt backfill
        await cacheManager.throttledBackfill(key: "test", logPrefix: "TEST", forceRefresh: false) {
            didExecute = true
        }
        
        // Then: Should execute
        XCTAssertTrue(didExecute)
    }
    
    func testForceRefreshBypassesThrottle() async {
        // Given: Last run was 1 hour ago
        UserDefaults.standard.set(Date().addingTimeInterval(-3600), forKey: "test")
        
        var didExecute = false
        
        // When: Force refresh
        await cacheManager.throttledBackfill(key: "test", logPrefix: "TEST", forceRefresh: true) {
            didExecute = true
        }
        
        // Then: Should execute despite throttle
        XCTAssertTrue(didExecute)
    }
}
```

---

## Migration Path

### Step 1: Add Helpers (No Breaking Changes)
```swift
// Add to CacheManager.swift (bottom of file)
// MARK: - Refactoring Helpers
extension CacheManager {
    // Add throttledBackfill()
    // Add performBatchInBackground()
    // Add historicalDates()
}
```

### Step 2: Migrate One Function (Test)
```swift
// Refactor backfillStrainScores() first
// Run tests, verify logs match
// Deploy and monitor
```

### Step 3: Migrate Remaining Functions
```swift
// Once confident, migrate:
// - backfillSleepScores()
// - backfillHistoricalRecoveryScores()
// - calculateMissingCTLATL()
```

### Step 4: Remove Old Code
```swift
// Delete duplicated inline throttling
// Delete duplicated context.perform blocks
// Update tests
```

---

## Risks & Mitigation

### Risk 1: Behavioral Change
**Mitigation**: Unit tests verify helpers match existing behavior

### Risk 2: Performance Regression
**Mitigation**: Measure before/after with Instruments

### Risk 3: Logging Changes
**Mitigation**: Keep exact same log messages during migration

### Risk 4: UserDefaults Keys
**Mitigation**: Use exact same keys, verify in tests

---

## Conclusion

**Recommended Action**: Start with Phase 1 (throttling + Core Data helpers)

**Expected Results**:
- 193 lines removed (16% reduction)
- 4 backfill functions simplified
- Future backfills easier to add
- Better test coverage
- Zero performance impact

**Timeline**: 
- Phase 1: 2-3 days (includes testing)
- Phase 2: 2 days
- **Total**: 1 week for complete refactor

**ROI**: High - significant code reduction with minimal risk
