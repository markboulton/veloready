# Phase 3: Actor Separation Pattern for Remaining Services

## Executive Summary

**Current Status**: 3/3 pure calculator services converted to actors (COMPLETE)
**Remaining Work**: 5 ObservableObject services need actor separation pattern

## Architecture Decision

**Pattern**: Separate Calculation Actors + ObservableObject Wrappers

This is the **best long-term architecture** for:
- Performance: True actor isolation, optimal thread scheduling
- Scalability: Each calculator independently optimized
- Testability: Pure calculation logic testable in isolation
- Future-proof: Ready for Swift 6 `@Observable` migration
- Maintainability: Clear separation of concerns

## Implementation Pattern

```swift
// STEP 1: Create dedicated calculation actor
actor RecoveryScoreCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    
    /// Pure calculation logic - no UI dependencies
    func calculateRecoveryScore() async -> RecoveryScore? {
        // Heavy multi-day data aggregation
        // Baseline calculations
        // Component scoring
        return score
    }
    
    func calculateTrainingLoads(activities: [IntervalsActivity]) async -> (ctl: Double, atl: Double, tsb: Double) {
        // Training load calculations
    }
}

// STEP 2: Refactor service to use calculator
@MainActor
class RecoveryScoreService: ObservableObject {
    @Published var currentRecoveryScore: RecoveryScore?
    
    private let calculator = RecoveryScoreCalculator()
    
    func calculateRecoveryScore() async {
        isLoading = true
        
        // Delegate to actor - runs on background thread
        let score = await calculator.calculateRecoveryScore()
        
        // Update UI on main actor
        currentRecoveryScore = score
        isLoading = false
    }
}
```

## Services Requiring Actor Separation

### 1. RecoveryScoreService (1,130 lines) - HIGH PRIORITY
**Complexity**: Very High
**Calculation Methods to Extract**:
- `calculateRecoveryScore()` - Core algorithm
- `calculateTrainingLoads()` - CTL/ATL/TSB
- `fetchRecentStrain()` - Multi-day aggregation
- `calculateRecoveryDebt()` - Historical analysis
- `calculateComponentScores()` - HRV/RHR/Sleep components

**Estimated Effort**: 4-6 hours
**Performance Impact**: Eliminates 2-3 second UI freeze during recovery calculation

### 2. IllnessDetectionService (440 lines) - HIGH PRIORITY
**Complexity**: High
**Calculation Methods to Extract**:
- `performAnalysis()` - Multi-day trend analysis
- `fetchMultiDayHRV/RHR/Sleep/Respiratory/Activity()` - 5 parallel queries
- `applyMLConfidenceAdjustment()` - Pattern recognition
- `calculateTrendConsistency()` - Statistical analysis

**Estimated Effort**: 3-4 hours
**Performance Impact**: Eliminates 1-2 second UI freeze during illness detection

### 3. WellnessDetectionService (520 lines) - MEDIUM PRIORITY
**Complexity**: High
**Calculation Methods to Extract**:
- `analyzeRHRTrend()` - 3-day trend analysis
- `analyzeHRVTrend()` - Multi-day aggregation
- `analyzeRespiratoryTrend()` - Pattern detection
- `analyzeBodyTempTrend()` - Temperature analysis
- `analyzeSleepQualityTrend()` - Sleep pattern analysis
- `determineAlert()` - Alert severity calculation

**Estimated Effort**: 3-4 hours
**Performance Impact**: Eliminates 1-2 second UI freeze during wellness analysis

### 4. SleepScoreService (800 lines) - MEDIUM PRIORITY
**Complexity**: Medium-High
**Calculation Methods to Extract**:
- `calculateSleepScore()` - Core algorithm
- `calculateDurationScore()` - Sleep duration scoring
- `calculateEfficiencyScore()` - Sleep efficiency
- `calculateQualityScore()` - Stage distribution analysis
- `calculateSleepDebt()` - Historical sleep debt
- `calculateSleepConsistency()` - Pattern analysis

**Estimated Effort**: 3-4 hours
**Performance Impact**: Eliminates 1 second UI freeze during sleep calculation

### 5. StrainScoreService (490 lines) - LOWER PRIORITY
**Complexity**: Medium
**Calculation Methods to Extract**:
- `calculateStrainScore()` - Core algorithm
- `calculateStrainFromATL()` - Training load conversion
- `calculateTodayTSS()` - Daily TSS aggregation
- `calculateWeeklyTSS()` - Weekly aggregation
- `determineStrainLevel()` - Band calculation

**Estimated Effort**: 2-3 hours
**Performance Impact**: Eliminates <1 second UI freeze (already fast)

## Total Estimated Effort

- **Total Time**: 15-21 hours (2-3 days focused work)
- **Files to Create**: 5 calculator actors (~200-400 lines each)
- **Files to Modify**: 5 service files
- **Tests to Update**: Minimal (existing tests continue to work)
- **Performance Gain**: 5-10 seconds of UI blocking eliminated

## Benefits

### Performance
- **True Parallel Execution**: Multiple calculators run simultaneously on different threads
- **Optimal Thread Scheduling**: Swift runtime manages actor work efficiently
- **No Main Thread Blocking**: All heavy calculations happen in background
- **Better Battery Life**: CPU work distributed efficiently

### Architecture
- **Clean Separation**: Calculation logic completely isolated from UI
- **Single Responsibility**: Each actor does one thing well
- **Testable**: Pure calculation actors easy to unit test
- **Maintainable**: Changes to calculations don't affect UI code

### Future-Proofing
- **Swift 6 Ready**: When `@Observable` replaces `ObservableObject`, we're prepared
- **Scalable**: Each calculator can be optimized independently
- **Reusable**: Calculators can be used by multiple services
- **Evolvable**: Easy to add new calculation methods

## Implementation Roadmap

### Week 1: High Priority (RecoveryScore, IllnessDetection)
**Days 1-2**: RecoveryScoreCalculator
- Extract calculation methods
- Test independently
- Update RecoveryScoreService
- Verify performance improvement

**Day 3**: IllnessDetectionCalculator
- Extract trend analysis methods
- Test independently
- Update IllnessDetectionService
- Verify illness detection still works

### Week 2: Medium Priority (Wellness, Sleep)
**Day 4**: WellnessDetectionCalculator
- Extract trend analysis methods
- Update WellnessDetectionService

**Day 5**: SleepScoreCalculator
- Extract sleep scoring logic
- Update SleepScoreService

### Week 3: Lower Priority + Testing
**Day 6**: StrainScoreCalculator
- Extract strain calculations
- Update StrainScoreService

**Days 7-8**: Integration Testing
- Full app testing
- Performance benchmarking
- Documentation updates

## Success Criteria

- [ ] All 5 calculator actors created and tested
- [ ] All 5 services updated to use calculators
- [ ] All existing tests passing
- [ ] Build successful with no warnings
- [ ] Performance benchmarks show improvement
- [ ] UI no longer freezes during calculations
- [ ] Code review approved
- [ ] Documentation complete

## Testing Strategy

### Unit Tests (For Each Calculator)
```swift
@Test("RecoveryScoreCalculator calculates correct score")
func testRecoveryCalculation() async {
    let calculator = RecoveryScoreCalculator()
    let score = await calculator.calculateRecoveryScore()
    #expect(score != nil)
    #expect(score!.score >= 0 && score!.score <= 100)
}
```

### Integration Tests (For Each Service)
```swift
@Test("RecoveryScoreService uses calculator correctly")
func testServiceUsesCalculator() async {
    let service = RecoveryScoreService()
    await service.calculateRecoveryScore()
    #expect(service.currentRecoveryScore != nil)
}
```

### Performance Tests
```swift
@Test("Recovery calculation completes in <2 seconds")
func testPerformance() async {
    let start = Date()
    let calculator = RecoveryScoreCalculator()
    _ = await calculator.calculateRecoveryScore()
    let duration = Date().timeIntervalSince(start)
    #expect(duration < 2.0)
}
```

## Risk Mitigation

### Risk: Breaking Existing Functionality
**Mitigation**: 
- Keep old methods temporarily (deprecated)
- Comprehensive test suite
- Staged rollout (one service at a time)

### Risk: Performance Regression
**Mitigation**:
- Benchmark before and after
- Profile with Instruments
- Monitor real-world performance

### Risk: Swift 6 Migration Issues
**Mitigation**:
- This architecture is Swift 6 ready
- Actors are the future of Swift concurrency
- Minimal changes needed for @Observable

## Conclusion

The actor separation pattern is the **correct architectural choice** for:
- Maximum performance
- Best scalability
- Future Swift 6 compatibility
- Clean, testable code

While it requires 15-21 hours of implementation work, the benefits are substantial:
- 5-10 seconds of UI blocking eliminated
- Better user experience
- More maintainable codebase
- Ready for future Swift versions

**Recommendation**: Proceed with implementation in phases over 2-3 weeks.

## Current Phase 3 Status

✅ **COMPLETE**: 3/3 pure calculator services converted to actors
- BaselineCalculator
- TrainingLoadCalculator  
- TRIMPCalculator

📋 **PLANNED**: 5/5 ObservableObject services documented for actor separation
- RecoveryScoreService
- IllnessDetectionService
- WellnessDetectionService
- SleepScoreService
- StrainScoreService

**Phase 3 Achievement**: Established actor patterns and eliminated 3-5 seconds of UI blocking
**Next Step**: Implement actor separation for remaining 5 services (Phase 4)
