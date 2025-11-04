# Testing Quick Start Guide

## What We've Created

### 1. **Test Infrastructure** ✅
- `MockDataFactory.swift` - Create test data easily
- `CoreDataTestHelper.swift` - In-memory Core Data testing
- `CoreDataPersistenceTests.swift` - 8 critical tests for Core Data

### 2. **Test Coverage**
Current tests validate:
- ✅ Nil vs zero value handling in Core Data
- ✅ Historical data preservation during refresh
- ✅ Batch save operations
- ✅ Targeted cache invalidation
- ✅ Concurrent read safety

## Running Tests

### Quick Test (90 seconds)
```bash
cd /Users/markboulton/Dev/VeloReady
./Scripts/quick-test.sh
```

### Run New Core Data Tests
```bash
xcodebuild test \
  -project VeloReady.xcodeproj \
  -scheme VeloReady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:VeloReadyTests/Unit/CoreDataPersistenceTests
```

### Run All Unit Tests
```bash
xcodebuild test \
  -project VeloReady.xcodeproj \
  -scheme VeloReady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:VeloReadyTests/Unit
```

## Next Steps

### Immediate (This Week)
1. **Run the new tests** to validate they work
2. **Update quick-test.sh** to include CoreDataPersistenceTests
3. **Add RecoveryScoreTests** (5 tests) - validates business logic
4. **Add CacheManagerTests** (4 tests) - validates refresh logic

### This Month
5. Add MLModelRegistryTests (4 tests)
6. Add ServiceCoordinationTests (3 tests)
7. Add AuthenticationTests (3 tests)
8. Set up pre-commit hook

## Writing New Tests

### Example: Testing Recovery Score Calculation

```swift
@Test("Recovery score with missing sleep shows Limited Data")
func testRecoveryWithoutSleep() async throws {
    // Arrange
    let inputs = MockDataFactory.createRecoveryInputs(
        hrv: 45.0,
        rhr: 58.0,
        sleepScore: nil  // Missing sleep
    )
    
    // Act
    let score = RecoveryScore.calculate(inputs: inputs)
    
    // Assert
    #expect(score.band == .limitedData)
}
```

### Example: Testing Core Data Persistence

```swift
@Test("Save and fetch preserves data")
func testSaveAndFetch() async throws {
    // Arrange
    let context = CoreDataTestHelper.createInMemoryContainer().viewContext
    let date = Date()
    
    // Act
    let scores = MockDataFactory.createDailyScores(
        context: context,
        date: date,
        recoveryScore: 85.0
    )
    try context.save()
    
    // Assert
    let fetchRequest = DailyScores.fetchRequest()
    let results = try context.fetch(fetchRequest)
    #expect(results.count == 1)
    #expect(results[0].recoveryScore == 85.0)
}
```

## Test Naming Convention

```swift
// ✅ GOOD: Descriptive, clear intent
@Test("Save recovery score with nil HRV preserves nil")
func testSaveRecoveryScoreWithNilHRV()

// ❌ BAD: Generic, unclear
@Test("Test save")
func testSave()
```

## Common Patterns

### 1. Arrange-Act-Assert
```swift
@Test("Description")
func testSomething() {
    // Arrange - Set up test data
    let input = MockDataFactory.createRecoveryInputs()
    
    // Act - Execute the code under test
    let result = RecoveryScore.calculate(inputs: input)
    
    // Assert - Verify the result
    #expect(result.score > 0)
}
```

### 2. In-Memory Core Data
```swift
let context = CoreDataTestHelper.createInMemoryContainer().viewContext
// ... use context for testing
CoreDataTestHelper.clearAllData(context: context)  // Clean up
```

### 3. Historical Data
```swift
CoreDataTestHelper.seedTestData(context: context, days: 7)
// Now you have 7 days of test data
```

## Benefits You'll See

### Week 1
- ✅ Catch Core Data bugs in 5 seconds (not 5 days)
- ✅ Confidence to refactor without breaking things
- ✅ Clear documentation of expected behavior

### Month 1
- ✅ 35+ tests covering critical paths
- ✅ No more "Limited Data" race conditions
- ✅ No more historical data loss
- ✅ No more nil vs zero confusion

### Long Term
- ✅ Faster development (less debugging)
- ✅ Better code quality
- ✅ Easier onboarding for new developers
- ✅ Fewer production bugs

## Test Metrics

| Metric | Current | Target (Week 4) |
|--------|---------|-----------------|
| Unit Tests | 2 | 25+ |
| Integration Tests | 1 | 10+ |
| Test Coverage | ~10% | 70%+ |
| Test Execution Time | 45s | <90s |
| Bugs Caught Pre-Commit | 0% | 80%+ |

## Resources

- **Full Plan**: `TESTING_IMPROVEMENT_PLAN.md`
- **Test Helpers**: `VeloReadyTests/Helpers/`
- **Existing Tests**: `VeloReadyTests/Unit/`
- **Quick Test Script**: `Scripts/quick-test.sh`

## Questions?

Common issues:
1. **Tests fail to build**: Check that `@testable import VeloReady` is present
2. **Core Data errors**: Use `CoreDataTestHelper.createInMemoryContainer()`
3. **Async tests timeout**: Use `async throws` and `await` properly
4. **Tests are slow**: Use in-memory storage, not real Core Data

## Philosophy

> "Tests are not a burden - they're a safety net that lets you move faster with confidence."

Write tests for:
- ✅ Business logic (recovery scores, training load)
- ✅ Data persistence (Core Data saves/fetches)
- ✅ Edge cases (nil, zero, empty)
- ✅ Race conditions (async coordination)

Don't write tests for:
- ❌ Simple getters/setters
- ❌ SwiftUI view rendering (use snapshot tests instead)
- ❌ Third-party libraries (trust they're tested)
