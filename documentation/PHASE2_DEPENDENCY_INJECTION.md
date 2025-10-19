# Phase 2: Dependency Injection

## 🎯 Goal
Make TodayView testable and portable by injecting dependencies instead of accessing singletons directly.

## 📊 Current State
- TodayView directly accesses `.shared` singletons
- Hard to test in isolation
- Hard to configure per app
- Tightly coupled to specific implementations

## 🔧 Changes Needed

### 1. TodayViewModel - Accept Dependencies
**Current**:
```swift
@StateObject private var viewModel = TodayViewModel()
@StateObject private var healthKitManager = HealthKitManager.shared
@StateObject private var wellnessService = WellnessDetectionService.shared
```

**Target**:
```swift
@StateObject private var viewModel: TodayViewModel
@StateObject private var coordinator: TodayCoordinator

init(
    viewModel: TodayViewModel = TodayViewModel(),
    coordinator: TodayCoordinator = TodayCoordinator()
) {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self._coordinator = StateObject(wrappedValue: coordinator)
}
```

### 2. TodayViewModel - Inject Services
**Current**:
```swift
class TodayViewModel: ObservableObject {
    // Directly accesses singletons
    private let healthKitManager = HealthKitManager.shared
    let recoveryScoreService = RecoveryScoreService.shared
}
```

**Target**:
```swift
class TodayViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager
    let recoveryScoreService: RecoveryScoreService
    let sleepScoreService: SleepScoreService
    let strainScoreService: StrainScoreService
    
    init(
        healthKitManager: HealthKitManager = .shared,
        recoveryScoreService: RecoveryScoreService = .shared,
        sleepScoreService: SleepScoreService = .shared,
        strainScoreService: StrainScoreService = .shared
    ) {
        self.healthKitManager = healthKitManager
        self.recoveryScoreService = recoveryScoreService
        self.sleepScoreService = sleepScoreService
        self.strainScoreService = strainScoreService
    }
}
```

## ✅ Benefits
- Easy to mock for testing
- Can swap implementations per app
- Clear dependency graph
- Preview-friendly
- Testable in isolation

## 📝 Implementation Steps
1. Update TodayViewModel to accept injected dependencies
2. Update TodayView to use injected ViewModel
3. Test build
4. Commit Phase 2
5. Move to Phase 3

## ⏱️ Estimated Time
3-4 hours
