# Phase 4: MVVM Architecture Implementation Plan

**Goal:** Separate view logic from UI by implementing proper MVVM architecture patterns across VeloReady.

**Status:** 🟡 IN PROGRESS

---

## 📋 Current State Assessment

### What We Have (Post-Phase 3)
✅ 16 atomic card components with clean UI
✅ Design token system fully integrated
✅ Content abstraction complete
✅ Services and calculators in place

### What Needs Improvement
❌ Business logic mixed with UI in views
❌ Data fetching scattered across components
❌ State management could be cleaner
❌ Testing is difficult due to tight coupling
❌ Some card components have internal logic that should be extracted

---

## 🎯 MVVM Principles

### Model
- Pure data structures
- No business logic
- Codable for persistence
- **Status:** ✅ Already good (TrendsViewModel data types, etc.)

### View
- SwiftUI views
- Only UI/layout code
- Observes ViewModel
- No business logic
- **Status:** 🟡 Mixed - some views have logic

### ViewModel
- ObservableObject
- @Published properties for state
- Business logic and data transformation
- Fetches data from services
- Prepares data for view consumption
- **Status:** ❌ Needs creation for most views

---

## 📊 Priority Matrix

### High Priority (Start Here)
1. **Card ViewModels** - Cards with internal logic need extraction
2. **Today Section ViewModels** - Complex sections need separation
3. **Detail View ViewModels** - Recovery/Sleep detail views have logic

### Medium Priority
4. **Settings ViewModels** - Settings logic should be extracted
5. **Onboarding ViewModels** - Flow logic should be separate

### Low Priority (Phase 5)
6. **Simple Cards** - Cards that are already mostly UI
7. **Utility Views** - Views with minimal logic

---

## 🔨 Implementation Strategy

### Phase 4A: Card ViewModels (Week 1)
**Goal:** Extract logic from card components that have business rules

**Cards Needing ViewModels:**
1. ✅ **StepsCardV2** - Has goal calculation logic
2. ✅ **CaloriesCardV2** - Has goal calculation logic
3. ✅ **DebtMetricCardV2** - Has severity calculation
4. ✅ **HealthWarningsCardV2** - Has alert filtering logic
5. ✅ **LatestActivityCardV2** - Has async data loading (map, location)

**Cards NOT Needing ViewModels (Pure UI):**
- Most trend cards (HRV, Recovery, etc.) - just display data passed in
- Simple metric displays

**Approach:**
```swift
// Before: Logic in View
struct StepsCardV2: View {
    @EnvironmentObject private var liveActivityService: LiveActivityService
    
    var body: some View {
        // Logic mixed with UI
        let steps = liveActivityService.currentSteps
        let goal = liveActivityService.stepGoal
        let percentage = min((Double(steps) / Double(goal)) * 100, 100)
    }
}

// After: Logic in ViewModel
class StepsCardViewModel: ObservableObject {
    @Published var steps: Int = 0
    @Published var goal: Int = 10000
    @Published var percentage: Double = 0
    @Published var isLoading: Bool = true
    
    private let liveActivityService: LiveActivityService
    
    func refresh() {
        steps = liveActivityService.currentSteps
        goal = liveActivityService.stepGoal
        percentage = calculatePercentage()
    }
    
    private func calculatePercentage() -> Double {
        min((Double(steps) / Double(goal)) * 100, 100)
    }
}

struct StepsCardV2: View {
    @StateObject private var viewModel = StepsCardViewModel()
    
    var body: some View {
        // Pure UI only
    }
}
```

**Checklist:**
- [ ] Create ViewModels directory: `Features/Shared/ViewModels/`
- [ ] Implement StepsCardViewModel
- [ ] Implement CaloriesCardViewModel
- [ ] Implement DebtMetricCardViewModel
- [ ] Implement HealthWarningsCardViewModel
- [ ] Implement LatestActivityCardViewModel
- [ ] Update card views to use ViewModels
- [ ] Build & verify
- [ ] Commit

**Success Criteria:**
- ✅ All business logic extracted from views
- ✅ Views only contain layout/UI code
- ✅ State management through @Published properties
- ✅ Build succeeds
- ✅ No regressions

---

### Phase 4B: Section ViewModels (Week 2)
**Goal:** Extract logic from Today/Trends page sections

**Sections Needing ViewModels:**
1. **RecoveryMetricsSection** - Has score calculations, animations
2. **ActivitySummarySection** - Has metric aggregations
3. **HealthKitEnablementSection** - Has permission logic

**Approach:**
```swift
// Create dedicated ViewModel for each complex section
class RecoveryMetricsSectionViewModel: ObservableObject {
    @Published var recoveryScore: RecoveryScore?
    @Published var sleepScore: SleepScore?
    @Published var strainScore: StrainScore?
    @Published var isLoading: Bool = true
    
    private let recoveryScoreService: RecoveryScoreService
    private let sleepScoreService: SleepScoreService
    private let strainScoreService: StrainScoreService
    
    func refresh() async {
        // Fetch and update all scores
    }
}
```

**Checklist:**
- [ ] Create RecoveryMetricsSectionViewModel
- [ ] Create ActivitySummarySectionViewModel
- [ ] Create HealthKitEnablementViewModel
- [ ] Update sections to use ViewModels
- [ ] Build & verify
- [ ] Commit

---

### Phase 4C: Detail View ViewModels (Week 3)
**Goal:** Extract logic from detail views

**Views Needing ViewModels:**
1. **RecoveryDetailView** - Has data fetching, chart logic
2. **SleepDetailView** - Has data fetching, hypnogram logic
3. **StrainDetailView** - Has data fetching, chart logic
4. **RideDetailSheet** - Has activity data processing

**Approach:**
```swift
class RecoveryDetailViewModel: ObservableObject {
    @Published var recoveryScore: RecoveryScore
    @Published var weeklyTrendData: [TrendDataPoint] = []
    @Published var hrvLineData: [HRVDataPoint] = []
    @Published var rhrCandlestickData: [CandlestickDataPoint] = []
    @Published var isLoadingTrends: Bool = false
    
    init(recoveryScore: RecoveryScore) {
        self.recoveryScore = recoveryScore
    }
    
    func loadTrendData() async {
        // Fetch historical data
    }
}
```

**Checklist:**
- [ ] Create RecoveryDetailViewModel
- [ ] Create SleepDetailViewModel
- [ ] Create StrainDetailViewModel
- [ ] Create RideDetailViewModel
- [ ] Update detail views to use ViewModels
- [ ] Build & verify
- [ ] Commit

---

### Phase 4D: Testing Infrastructure (Week 4)
**Goal:** Add unit tests now that logic is separated

**Test Coverage:**
1. ViewModel unit tests (no UI dependency)
2. Data transformation tests
3. State management tests
4. Edge case handling

**Approach:**
```swift
final class StepsCardViewModelTests: XCTestCase {
    var sut: StepsCardViewModel!
    var mockService: MockLiveActivityService!
    
    override func setUp() {
        super.setUp()
        mockService = MockLiveActivityService()
        sut = StepsCardViewModel(service: mockService)
    }
    
    func testPercentageCalculation() {
        // Given
        mockService.currentSteps = 5000
        mockService.stepGoal = 10000
        
        // When
        sut.refresh()
        
        // Then
        XCTAssertEqual(sut.percentage, 50.0)
    }
}
```

**Checklist:**
- [ ] Create VeloReadyTests target (if not exists)
- [ ] Write tests for card ViewModels
- [ ] Write tests for section ViewModels
- [ ] Write tests for detail ViewModels
- [ ] Ensure >80% coverage for ViewModels
- [ ] Set up CI to run tests

---

## 🎯 Success Metrics

### Code Quality
- [ ] No business logic in View structs
- [ ] All state managed through ViewModels
- [ ] ViewModels are testable (no SwiftUI dependencies)
- [ ] Clear separation of concerns

### Build Quality
- [ ] 100% build success
- [ ] Zero regressions
- [ ] All features working as before
- [ ] Performance maintained or improved

### Test Coverage
- [ ] >80% coverage for ViewModels
- [ ] Unit tests for all business logic
- [ ] Edge case tests
- [ ] Integration tests for critical flows

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  (Pure UI - Observe ViewModels via @StateObject)   │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ @Published properties
                   ↓
┌─────────────────────────────────────────────────────┐
│                   ViewModels                         │
│  (Business Logic - ObservableObject)                │
│  • Data transformation                               │
│  • State management                                  │
│  • Service coordination                              │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Calls methods
                   ↓
┌─────────────────────────────────────────────────────┐
│                    Services                          │
│  (Data Layer - Existing)                            │
│  • LiveActivityService                               │
│  • HealthKitManager                                  │
│  • RecoveryScoreService                              │
│  • etc.                                              │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Returns Models
                   ↓
┌─────────────────────────────────────────────────────┐
│                     Models                           │
│  (Data Structures - Existing)                       │
│  • RecoveryScore                                     │
│  • TrendDataPoint                                    │
│  • UnifiedActivity                                   │
│  • etc.                                              │
└─────────────────────────────────────────────────────┘
```

---

## ⚠️ Risks & Mitigation

### Risk 1: Breaking Changes
**Mitigation:**
- Implement one ViewModel at a time
- Build & test after each change
- Keep git commits granular
- Easy rollback if issues

### Risk 2: Over-Engineering
**Mitigation:**
- Only create ViewModels where there's actual logic
- Pure display cards don't need ViewModels
- KISS principle - keep it simple

### Risk 3: Performance Regression
**Mitigation:**
- Profile before/after
- Watch for unnecessary re-renders
- Use proper @Published optimization
- Test on real devices

### Risk 4: Testing Complexity
**Mitigation:**
- Start with simple ViewModel tests
- Mock services properly
- Focus on business logic tests
- Don't test SwiftUI rendering

---

## 📝 Documentation Updates

After Phase 4 completion:
- [ ] Update ARCHITECTURE.md with MVVM patterns
- [ ] Create VIEWMODEL_GUIDE.md
- [ ] Update CARD_COMPONENT_GUIDE.md with ViewModel info
- [ ] Add testing examples to docs

---

## 🚀 Next Steps

**Immediate:**
1. Create `Features/Shared/ViewModels/` directory
2. Start with StepsCardViewModel (simplest)
3. Build confidence with small changes
4. Progress to more complex ViewModels

**This Week (Phase 4A):**
- Focus on card ViewModels only
- Build & test after each one
- Commit frequently

**Next Week (Phase 4B-D):**
- Section ViewModels
- Detail ViewModels  
- Testing infrastructure

---

## 💡 Best Practices

### ViewModel Design
```swift
// ✅ Good: Clear, testable, single responsibility
class StepsCardViewModel: ObservableObject {
    @Published private(set) var steps: Int = 0
    @Published private(set) var goal: Int = 10000
    @Published private(set) var percentage: Double = 0
    
    private let service: LiveActivityServiceProtocol
    
    init(service: LiveActivityServiceProtocol = LiveActivityService.shared) {
        self.service = service
    }
    
    func refresh() {
        steps = service.currentSteps
        goal = service.stepGoal
        percentage = calculatePercentage()
    }
}

// ❌ Bad: Too much responsibility, hard to test
class MegaViewModel: ObservableObject {
    // Handles everything from multiple features
}
```

### View Design
```swift
// ✅ Good: Pure UI, observes ViewModel
struct StepsCardV2: View {
    @StateObject private var viewModel = StepsCardViewModel()
    
    var body: some View {
        CardContainer(...) {
            Text("\(viewModel.steps)")
            ProgressRing(percentage: viewModel.percentage)
        }
        .onAppear { viewModel.refresh() }
    }
}

// ❌ Bad: Logic in view
struct StepsCardV2: View {
    var body: some View {
        let steps = calculateSteps() // ❌ Logic here
        let percentage = steps / goal * 100 // ❌ Calculation here
    }
}
```

---

## 🎯 Phase 4 Goals Summary

By end of Phase 4, we will have:
- ✅ Clear separation between UI and business logic
- ✅ Testable ViewModels with unit tests
- ✅ Maintainable codebase
- ✅ Better state management
- ✅ Foundation for future features
- ✅ Documentation for MVVM patterns

**Let's begin with Phase 4A: Card ViewModels!** 🚀
