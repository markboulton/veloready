# Testing Improvement Plan - VeloReady iOS

## Recent Bugs Analysis

### 1. **Core Data Zero Values Bug** (Oct 29)
- **What**: Recovery scores saved as 0 to Core Data due to incorrect nil handling
- **Root Cause**: `RecoveryScore.RecoveryInputs` constructed with zeros instead of nils during fallback
- **Impact**: Missing recovery stats, incorrect calculations
- **Missing Test**: Core Data persistence validation

### 2. **Historical Data Loss** (Nov 1-4)
- **What**: 7/30/60-day trend charts showing only 1 day after Core Data clear
- **Root Cause**: `refreshRecentDays()` overwrote historical data with empty HealthKit results
- **Impact**: All historical recovery/sleep data lost
- **Missing Test**: Cache refresh logic validation, historical data preservation

### 3. **Recovery Score "Limited Data" Race Condition** (Oct 28)
- **What**: Recovery showed "Limited Data" despite sleep score existing
- **Root Cause**: Parallel execution - recovery calculated before sleep completed
- **Impact**: Incorrect recovery bands, user confusion
- **Missing Test**: Async dependency coordination tests

### 4. **ML Indicator Showing 24 Days** (Nov 4)
- **What**: ML indicator showed 24 days despite 0 training data
- **Root Cause**: `shouldUseML()` checked model existence, not actual data count
- **Impact**: Misleading UI, user expects ML features
- **Missing Test**: ML availability logic tests

### 5. **Alcohol Detection During Illness** (Oct 30)
- **What**: Recovery score penalized for "alcohol" when user was sick
- **Root Cause**: Illness and alcohol have identical HRV/RHR signals
- **Impact**: Incorrect recovery scores during illness
- **Missing Test**: Illness detection integration tests

### 6. **Backend Hardcoded Athlete ID** (Oct 25)
- **What**: All API endpoints used hardcoded `athleteId = 104662`
- **Root Cause**: No authentication validation in development
- **Impact**: CRITICAL security bug, single-user only
- **Missing Test**: Authentication integration tests

## Common Patterns

1. **State Management**: Race conditions in async operations
2. **Data Persistence**: Core Data save/fetch validation gaps
3. **Edge Cases**: Nil handling, empty data, zero values
4. **Integration**: Service dependencies not tested together
5. **Business Logic**: Complex calculations (recovery, illness, alcohol) not validated

---

## Proposed Testing Strategy

### Phase 1: Critical Path Tests (Week 1) - **HIGH PRIORITY**

#### 1.1 Core Data Persistence Tests
**File**: `VeloReadyTests/Unit/CoreDataPersistenceTests.swift`

```swift
@Suite("Core Data Persistence")
struct CoreDataPersistenceTests {
    @Test("Save recovery score with nil values")
    func testSaveRecoveryScoreWithNils()
    
    @Test("Save recovery score with zero values")
    func testSaveRecoveryScoreWithZeros()
    
    @Test("Fetch recovery score preserves nil vs zero")
    func testFetchPreservesNilVsZero()
    
    @Test("Historical data not overwritten by refresh")
    func testHistoricalDataPreservation()
}
```

**Why**: Prevents Core Data zero-value bugs and historical data loss

#### 1.2 Recovery Score Calculation Tests
**File**: `VeloReadyTests/Unit/RecoveryScoreTests.swift`

```swift
@Suite("Recovery Score Calculation")
struct RecoveryScoreTests {
    @Test("Calculate recovery with all inputs")
    func testFullRecoveryCalculation()
    
    @Test("Calculate recovery with missing sleep")
    func testRecoveryWithoutSleep()
    
    @Test("Calculate recovery with missing HRV")
    func testRecoveryWithoutHRV()
    
    @Test("Alcohol detection skipped during illness")
    func testAlcoholDetectionDuringIllness()
    
    @Test("Recovery waits for sleep calculation")
    func testRecoveryWaitsForSleep()
}
```

**Why**: Validates complex business logic, prevents "Limited Data" bugs

#### 1.3 Cache Manager Tests
**File**: `VeloReadyTests/Unit/CacheManagerTests.swift`

```swift
@Suite("Cache Manager")
struct CacheManagerTests {
    @Test("Refresh today only, not historical")
    func testRefreshTodayOnly()
    
    @Test("Save to cache preserves existing data")
    func testSavePreservesExisting()
    
    @Test("Fetch from cache returns correct date range")
    func testFetchDateRange()
    
    @Test("Cache invalidation clears only specified dates")
    func testCacheInvalidation()
}
```

**Why**: Prevents historical data overwrites, validates cache strategy

#### 1.4 ML Model Registry Tests
**File**: `VeloReadyTests/Unit/MLModelRegistryTests.swift`

```swift
@Suite("ML Model Registry")
struct MLModelRegistryTests {
    @Test("shouldUseML returns false with no training data")
    func testMLDisabledWithNoData()
    
    @Test("shouldUseML returns false with insufficient data")
    func testMLDisabledWithInsufficientData()
    
    @Test("shouldUseML returns true with 14+ days")
    func testMLEnabledWith14Days()
    
    @Test("Training data count matches actual records")
    func testTrainingDataCount()
}
```

**Why**: Prevents ML indicator showing incorrect state

---

### Phase 2: Integration Tests (Week 2) - **MEDIUM PRIORITY**

#### 2.1 Service Coordination Tests
**File**: `VeloReadyTests/Integration/ServiceCoordinationTests.swift`

```swift
@Suite("Service Coordination")
struct ServiceCoordinationTests {
    @Test("Recovery waits for sleep completion")
    func testRecoverySleepCoordination()
    
    @Test("Parallel score calculations don't race")
    func testParallelScoreCalculations()
    
    @Test("Cache refresh doesn't block UI")
    func testCacheRefreshAsync()
}
```

**Why**: Prevents race conditions, validates async dependencies

#### 2.2 Authentication Tests
**File**: `VeloReadyTests/Integration/AuthenticationTests.swift`

```swift
@Suite("Authentication")
struct AuthenticationTests {
    @Test("API requests include JWT token")
    func testAPIRequestsIncludeToken()
    
    @Test("Expired token triggers refresh")
    func testTokenRefresh()
    
    @Test("No hardcoded athlete IDs in requests")
    func testNoHardcodedAthleteIDs()
}
```

**Why**: Prevents security bugs, validates multi-user support

#### 2.3 Illness Detection Integration Tests
**File**: `VeloReadyTests/Integration/IllnessDetectionTests.swift`

```swift
@Suite("Illness Detection Integration")
struct IllnessDetectionTests {
    @Test("Illness detected from HRV spike")
    func testIllnessFromHRVSpike()
    
    @Test("Alcohol detection disabled during illness")
    func testAlcoholDisabledDuringIllness()
    
    @Test("AI brief prescribes rest during illness")
    func testAIBriefDuringIllness()
}
```

**Why**: Validates illness detection across services

---

### Phase 3: UI/Snapshot Tests (Week 3) - **LOW PRIORITY**

#### 3.1 Chart Rendering Tests
**File**: `VeloReadyTests/UI/ChartRenderingTests.swift`

```swift
@Suite("Chart Rendering")
struct ChartRenderingTests {
    @Test("7-day chart renders with 1 day of data")
    func testChartWith1Day()
    
    @Test("30-day chart renders with partial data")
    func testChartWithPartialData()
    
    @Test("Chart shows 'No Data' state correctly")
    func testChartNoDataState()
}
```

**Why**: Validates UI behavior with edge cases

---

### Phase 4: Test Infrastructure (Week 1-2) - **PARALLEL WORK**

#### 4.1 Mock Data Helpers
**File**: `VeloReadyTests/Helpers/MockDataFactory.swift`

```swift
struct MockDataFactory {
    static func createRecoveryScore(
        hrv: Double? = nil,
        rhr: Double? = nil,
        sleep: Double? = nil
    ) -> RecoveryScore
    
    static func createDailyScores(
        count: Int,
        startDate: Date
    ) -> [DailyScores]
    
    static func createIllnessIndicator(
        severity: IllnessSeverity
    ) -> IllnessIndicator
}
```

**Why**: Reduces test boilerplate, ensures consistency

#### 4.2 Core Data Test Helpers
**File**: `VeloReadyTests/Helpers/CoreDataTestHelper.swift`

```swift
class CoreDataTestHelper {
    static func createInMemoryContainer() -> NSPersistentContainer
    static func clearAllData()
    static func seedTestData(days: Int)
}
```

**Why**: Simplifies Core Data testing, prevents test pollution

#### 4.3 Async Test Utilities
**File**: `VeloReadyTests/Helpers/AsyncTestUtilities.swift`

```swift
extension XCTestCase {
    func waitForAsync(timeout: TimeInterval = 5.0, _ block: @escaping () async throws -> Void)
    func expectNoRaceCondition(iterations: Int = 100, _ block: @escaping () async throws -> Void)
}
```

**Why**: Makes async testing easier, catches race conditions

---

## Test Execution Strategy

### 1. Quick Test Script Enhancement
**Update**: `/Users/markboulton/Dev/VeloReady/Scripts/quick-test.sh`

```bash
# Current: Only runs TrainingLoadCalculatorTests
-only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests

# Proposed: Run all critical unit tests
-only-testing:VeloReadyTests/Unit/CoreDataPersistenceTests \
-only-testing:VeloReadyTests/Unit/RecoveryScoreTests \
-only-testing:VeloReadyTests/Unit/CacheManagerTests \
-only-testing:VeloReadyTests/Unit/MLModelRegistryTests \
-only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests
```

**Time**: ~60-90 seconds (acceptable)

### 2. Pre-Commit Hook
**File**: `.git/hooks/pre-commit`

```bash
#!/bin/bash
./Scripts/quick-test.sh
if [ $? -ne 0 ]; then
    echo "❌ Tests failed - commit blocked"
    exit 1
fi
```

**Why**: Prevents broken code from being committed

### 3. CI/CD Pipeline
**File**: `.github/workflows/ios-tests.yml`

```yaml
- name: Run Unit Tests
  run: xcodebuild test -scheme VeloReady -only-testing:VeloReadyTests/Unit

- name: Run Integration Tests
  run: xcodebuild test -scheme VeloReady -only-testing:VeloReadyTests/Integration

- name: Run UI Tests
  run: xcodebuild test -scheme VeloReady -only-testing:VeloReadyTests/UI
```

**Why**: Full test coverage on every push

---

## Development Hygiene Improvements

### 1. Code Review Checklist
**File**: `PULL_REQUEST_TEMPLATE.md`

```markdown
## Testing Checklist
- [ ] Unit tests added for new business logic
- [ ] Integration tests added for service interactions
- [ ] Edge cases tested (nil, zero, empty)
- [ ] Race conditions considered for async code
- [ ] Core Data persistence validated
- [ ] `./Scripts/quick-test.sh` passes locally
```

### 2. Logging Standards
**Pattern**: Structured logging for debugging

```swift
// ❌ WRONG: Generic logging
Logger.debug("Calculating recovery")

// ✅ CORRECT: Structured logging
Logger.debug("🔄 [RECOVERY] Starting calculation - HRV: \(hrv ?? 0), Sleep: \(sleep ?? 0)")
Logger.debug("✅ [RECOVERY] Completed - Score: \(score), Band: \(band)")
```

**Why**: Makes debugging easier, catches issues faster

### 3. Assertion Usage
**Pattern**: Validate assumptions in code

```swift
// ❌ WRONG: Silent failures
guard let hrv = inputs.hrv else { return 0 }

// ✅ CORRECT: Explicit validation
guard let hrv = inputs.hrv else {
    assertionFailure("HRV should not be nil at this point")
    Logger.error("❌ [RECOVERY] Missing HRV input")
    return 0
}
```

**Why**: Catches bugs during development, not production

---

## Success Metrics

### Week 1-2 (Phase 1 + Infrastructure)
- ✅ 20+ critical unit tests added
- ✅ Core Data persistence validated
- ✅ Recovery calculation edge cases covered
- ✅ Quick test script runs 5 test suites in <90s

### Week 3 (Phase 2)
- ✅ 10+ integration tests added
- ✅ Service coordination validated
- ✅ Authentication tests prevent hardcoded IDs
- ✅ Illness detection integration tested

### Week 4 (Phase 3)
- ✅ UI/snapshot tests added
- ✅ Chart rendering edge cases covered
- ✅ Pre-commit hook enabled
- ✅ CI/CD pipeline running full test suite

### Ongoing
- ✅ No Core Data bugs in production
- ✅ No race condition bugs in production
- ✅ Test coverage >70% for business logic
- ✅ All PRs include tests

---

## Effort Estimate

| Phase | Tests | Time | Priority |
|-------|-------|------|----------|
| Phase 1: Critical Unit Tests | 20 tests | 8-12 hours | HIGH |
| Phase 2: Integration Tests | 10 tests | 6-8 hours | MEDIUM |
| Phase 3: UI Tests | 5 tests | 4-6 hours | LOW |
| Phase 4: Infrastructure | Helpers | 4-6 hours | HIGH |
| **Total** | **35+ tests** | **22-32 hours** | **~1 week** |

---

## Implementation Order

### Day 1-2: Foundation
1. Create test helpers (MockDataFactory, CoreDataTestHelper)
2. Add CoreDataPersistenceTests (5 tests)
3. Add CacheManagerTests (4 tests)

### Day 3-4: Business Logic
4. Add RecoveryScoreTests (5 tests)
5. Add MLModelRegistryTests (4 tests)
6. Update quick-test.sh to run all unit tests

### Day 5: Integration
7. Add ServiceCoordinationTests (3 tests)
8. Add AuthenticationTests (3 tests)
9. Add IllnessDetectionTests (3 tests)

### Day 6-7: Polish
10. Add UI/Chart tests (5 tests)
11. Set up pre-commit hook
12. Document testing guidelines

---

## Long-Term Benefits

1. **Faster Development**: Catch bugs in seconds, not days
2. **Confidence**: Refactor without fear of breaking things
3. **Documentation**: Tests serve as living documentation
4. **Onboarding**: New developers understand system through tests
5. **Quality**: Fewer production bugs, better user experience

---

## Next Steps

1. **Review this plan** - Adjust priorities/scope as needed
2. **Create test files** - Start with Phase 1 (critical tests)
3. **Write first test** - CoreDataPersistenceTests.testSaveRecoveryScoreWithNils
4. **Run quick-test.sh** - Validate test runs in CI
5. **Iterate** - Add tests incrementally, don't block features
