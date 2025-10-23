# Phase 4 Implementation Guide: View Architecture & MVVM

**Goal:** Slim views, fat view models - testable business logic  
**Timeline:** Week 7-8 (2 weeks)  
**Status:** Ready to implement  
**Prerequisites:** Phase 1, 2, 3 complete

---

## Executive Summary

Currently VeloReady has **god views** with business logic embedded directly in SwiftUI views. `TodayView.swift` is 814 lines with data fetching, calculations, and UI all mixed together. This makes testing impossible and maintenance difficult.

### Current Issues
- ❌ **TodayView: 814 lines** - God view with everything
- ❌ **Business logic in views** - Can't test without SwiftUI
- ❌ **Tight coupling** - Views depend on 5+ services directly
- ❌ **State management chaos** - @State, @StateObject, @ObservedObject mixed
- ❌ **No dependency injection** - Hard-coded singletons everywhere

### Phase 4 Goals
✅ **80% smaller views** - TodayView: 814 → ~160 lines  
✅ **100% testable logic** - All business logic in view models  
✅ **Dependency injection** - Mock services for testing  
✅ **Clear state management** - Single source of truth  
✅ **MVVM pattern** - Clean separation of concerns  

---

## Step 1: View Model Protocol

### File: `Core/Architecture/ViewModelProtocol.swift`
```swift
import Foundation
import Combine

/// Base protocol for all view models
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    
    func send(_ action: Action)
}

/// Loading states for async operations
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
```

---

## Step 2: TodayViewModel Refactor

### Current State (814 lines - BEFORE)
```swift
// TodayView.swift - BEFORE
struct TodayView: View {
    // 50+ @State variables
    @State private var recoveryScore: Int? = nil
    @State private var sleepScore: Int? = nil
    @State private var activities: [Activity] = []
    @State private var isLoading = false
    // ... 40 more state variables
    
    // Direct service dependencies
    private let healthKit = HealthKitManager.shared
    private let strava = StravaAPIClient()
    private let intervals = IntervalsAPIClient.shared
    // ... 5 more services
    
    var body: some View {
        ScrollView {
            // 700+ lines of view code mixed with:
            // - Data fetching
            // - Business logic
            // - Error handling
            // - State management
            // - UI rendering
        }
        .onAppear {
            // 150 lines of data loading
            Task {
                // Fetch recovery
                if let hrv = try? await healthKit.fetchHRV() {
                    // Calculate score inline
                    recoveryScore = Int((hrv / 100.0) * 100)
                }
                // ... fetch 10 more things
            }
        }
    }
}
```

### New Architecture (AFTER)

#### **ViewModels/TodayViewModel.swift** (~200 lines)
```swift
import Foundation
import Combine

@MainActor
class TodayViewModel: ObservableObject {
    
    // MARK: - State
    
    struct State {
        var recovery: LoadingState<RecoveryScore> = .idle
        var sleep: LoadingState<SleepScore> = .idle
        var strain: LoadingState<StrainScore> = .idle
        var activities: LoadingState<[Activity]> = .idle
        var wellness: LoadingState<WellnessScore> = .idle
        
        var isLoading: Bool {
            recovery.isLoading || sleep.isLoading || strain.isLoading
        }
        
        var hasError: Bool {
            recovery.error != nil || sleep.error != nil || strain.error != nil
        }
    }
    
    @Published private(set) var state = State()
    
    // MARK: - Dependencies (Injected)
    
    private let healthRepository: HealthRepository
    private let activityRepository: ActivityRepository
    private let wellnessRepository: WellnessRepository
    
    init(
        healthRepository: HealthRepository = .shared,
        activityRepository: ActivityRepository = .shared,
        wellnessRepository: WellnessRepository = .shared
    ) {
        self.healthRepository = healthRepository
        self.activityRepository = activityRepository
        self.wellnessRepository = wellnessRepository
    }
    
    // MARK: - Actions
    
    enum Action {
        case loadInitialData
        case refresh
        case loadRecovery
        case loadSleep
        case loadStrain
        case loadActivities
    }
    
    func send(_ action: Action) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .refresh:
            refresh()
        case .loadRecovery:
            Task { await loadRecovery() }
        case .loadSleep:
            Task { await loadSleep() }
        case .loadStrain:
            Task { await loadStrain() }
        case .loadActivities:
            Task { await loadActivities() }
        }
    }
    
    // MARK: - Business Logic (Pure, Testable)
    
    private func loadInitialData() {
        // Load all data in parallel
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadRecovery() }
                group.addTask { await self.loadSleep() }
                group.addTask { await self.loadStrain() }
                group.addTask { await self.loadActivities() }
            }
        }
    }
    
    private func loadRecovery() async {
        state.recovery = .loading
        
        do {
            let score = try await healthRepository.fetchRecoveryScore()
            state.recovery = .loaded(score)
        } catch {
            state.recovery = .failed(error)
            Logger.error("Failed to load recovery: \(error)")
        }
    }
    
    private func loadSleep() async {
        state.sleep = .loading
        
        do {
            let score = try await healthRepository.fetchSleepScore()
            state.sleep = .loaded(score)
        } catch {
            state.sleep = .failed(error)
            Logger.error("Failed to load sleep: \(error)")
        }
    }
    
    private func loadStrain() async {
        state.strain = .loading
        
        do {
            let score = try await activityRepository.fetchStrainScore()
            state.strain = .loaded(score)
        } catch {
            state.strain = .failed(error)
            Logger.error("Failed to load strain: \(error)")
        }
    }
    
    private func loadActivities() async {
        state.activities = .loading
        
        do {
            let activities = try await activityRepository.fetchRecentActivities()
            state.activities = .loaded(activities)
        } catch {
            state.activities = .failed(error)
            Logger.error("Failed to load activities: \(error)")
        }
    }
    
    private func refresh() {
        // Clear cache and reload
        healthRepository.clearCache()
        activityRepository.clearCache()
        loadInitialData()
    }
}
```

#### **Views/TodayView.swift** (~160 lines)
```swift
import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Recovery Section
                recoverySection
                
                // Sleep Section
                sleepSection
                
                // Strain Section
                strainSection
                
                // Activities Section
                activitiesSection
            }
            .padding()
        }
        .navigationTitle(CommonContent.today.title)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onAppear {
            viewModel.send(.loadInitialData)
        }
        .overlay {
            if viewModel.state.isLoading {
                ProgressView()
            }
        }
    }
    
    // MARK: - Sections (Pure UI)
    
    @ViewBuilder
    private var recoverySection: some View {
        switch viewModel.state.recovery {
        case .idle, .loading:
            RecoveryCardSkeleton()
        case .loaded(let score):
            RecoveryCard(score: score)
        case .failed(let error):
            ErrorCard(message: error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private var sleepSection: some View {
        switch viewModel.state.sleep {
        case .idle, .loading:
            SleepCardSkeleton()
        case .loaded(let score):
            SleepCard(score: score)
        case .failed(let error):
            ErrorCard(message: error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private var strainSection: some View {
        switch viewModel.state.strain {
        case .idle, .loading:
            StrainCardSkeleton()
        case .loaded(let score):
            StrainCard(score: score)
        case .failed(let error):
            ErrorCard(message: error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private var activitiesSection: some View {
        switch viewModel.state.activities {
        case .idle, .loading:
            ActivitiesListSkeleton()
        case .loaded(let activities):
            ActivitiesList(activities: activities)
        case .failed(let error):
            ErrorCard(message: error.localizedDescription)
        }
    }
}

#Preview {
    NavigationView {
        TodayView()
    }
}
```

**Result:**
- ✅ TodayView: 814 → 160 lines (-80%)
- ✅ All business logic in view model
- ✅ View is pure UI rendering
- ✅ 100% testable

---

## Step 3: Testing Strategy

### **Tests/ViewModels/TodayViewModelTests.swift**
```swift
import XCTest
@testable import VeloReady

@MainActor
class TodayViewModelTests: XCTestCase {
    
    var viewModel: TodayViewModel!
    var mockHealthRepo: MockHealthRepository!
    var mockActivityRepo: MockActivityRepository!
    
    override func setUp() async throws {
        mockHealthRepo = MockHealthRepository()
        mockActivityRepo = MockActivityRepository()
        
        viewModel = TodayViewModel(
            healthRepository: mockHealthRepo,
            activityRepository: mockActivityRepo,
            wellnessRepository: MockWellnessRepository()
        )
    }
    
    func testLoadRecoverySuccess() async {
        // Given
        let expectedScore = RecoveryScore(value: 92, band: .optimal)
        mockHealthRepo.recoveryScoreToReturn = expectedScore
        
        // When
        viewModel.send(.loadRecovery)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for async
        
        // Then
        XCTAssertEqual(viewModel.state.recovery.value?.value, 92)
        XCTAssertEqual(viewModel.state.recovery.value?.band, .optimal)
    }
    
    func testLoadRecoveryFailure() async {
        // Given
        mockHealthRepo.shouldFail = true
        
        // When
        viewModel.send(.loadRecovery)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.state.recovery.error)
        XCTAssertFalse(viewModel.state.recovery.isLoading)
    }
    
    func testLoadInitialDataLoadsAllSections() async {
        // Given
        mockHealthRepo.recoveryScoreToReturn = RecoveryScore(value: 92, band: .optimal)
        mockHealthRepo.sleepScoreToReturn = SleepScore(value: 88, band: .good)
        mockActivityRepo.strainScoreToReturn = StrainScore(value: 15.5)
        mockActivityRepo.activitiesToReturn = [Activity.mock1, Activity.mock2]
        
        // When
        viewModel.send(.loadInitialData)
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait for parallel tasks
        
        // Then
        XCTAssertNotNil(viewModel.state.recovery.value)
        XCTAssertNotNil(viewModel.state.sleep.value)
        XCTAssertNotNil(viewModel.state.strain.value)
        XCTAssertEqual(viewModel.state.activities.value?.count, 2)
    }
    
    func testRefreshClearsCacheAndReloads() async {
        // Given
        viewModel.send(.loadInitialData)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // When
        viewModel.send(.refresh)
        
        // Then
        XCTAssertTrue(mockHealthRepo.cacheClearedCalled)
        XCTAssertTrue(mockActivityRepo.cacheClearedCalled)
    }
}

// MARK: - Mocks

class MockHealthRepository: HealthRepository {
    var recoveryScoreToReturn: RecoveryScore?
    var sleepScoreToReturn: SleepScore?
    var shouldFail = false
    var cacheClearedCalled = false
    
    func fetchRecoveryScore() async throws -> RecoveryScore {
        if shouldFail { throw NSError(domain: "test", code: -1) }
        return recoveryScoreToReturn ?? RecoveryScore(value: 0, band: .poor)
    }
    
    func fetchSleepScore() async throws -> SleepScore {
        if shouldFail { throw NSError(domain: "test", code: -1) }
        return sleepScoreToReturn ?? SleepScore(value: 0, band: .poor)
    }
    
    func clearCache() {
        cacheClearedCalled = true
    }
}
```

---

## Step 4: Migration Priority

### High Priority Views (Week 7)
1. ✅ **TodayView** (814 lines) → TodayViewModel
2. ✅ **TrendsView** (523 lines) → TrendsViewModel
3. ✅ **ActivitiesView** (412 lines) → ActivitiesViewModel

### Medium Priority Views (Week 8)
4. ✅ **RecoveryDetailView** (345 lines) → RecoveryDetailViewModel
5. ✅ **SleepDetailView** (298 lines) → SleepDetailViewModel
6. ✅ **ProfileView** (267 lines) → ProfileViewModel

### Low Priority (Optional)
- Settings views (simpler, less logic)
- Detail views (mostly read-only)
- Onboarding views (linear flow)

---

## Step 5: View Model Patterns

### Pattern 1: List View Model
```swift
@MainActor
class ActivitiesViewModel: ObservableObject {
    @Published private(set) var activities: [Activity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var filter: Filter = .all
    
    enum Filter {
        case all
        case running
        case cycling
        case strength
    }
    
    func applyFilter(_ filter: Filter) {
        self.filter = filter
        // Filter activities
    }
    
    func deleteActivity(_ activity: Activity) async {
        // Delete logic
    }
}
```

### Pattern 2: Detail View Model
```swift
@MainActor
class RecoveryDetailViewModel: ObservableObject {
    @Published private(set) var score: RecoveryScore?
    @Published private(set) var history: [RecoveryScore] = []
    @Published private(set) var insights: [Insight] = []
    
    let activityId: String
    
    init(activityId: String) {
        self.activityId = activityId
    }
    
    func loadData() async {
        // Load score and history
    }
}
```

### Pattern 3: Form View Model
```swift
@MainActor
class ProfileEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 30
    @Published var weight: Double = 70.0
    @Published private(set) var isSaving = false
    
    var isValid: Bool {
        !name.isEmpty && age > 0 && weight > 0
    }
    
    func save() async throws {
        guard isValid else { return }
        isSaving = true
        defer { isSaving = false }
        
        // Save to repository
        try await profileRepository.updateProfile(
            name: name,
            age: age,
            weight: weight
        )
    }
}
```

---

## Step 6: State Management Rules

### ✅ DO:
- Use `@Published` for all observable state
- Keep state in view model, not view
- Use `LoadingState<T>` for async operations
- Inject dependencies via init
- Make view models `@MainActor` for UI updates

### ❌ DON'T:
- Put business logic in views
- Use `@State` for complex data
- Access services directly from views
- Make view models depend on other view models
- Store UI state in view model (scroll position, etc.)

---

## Success Metrics

### Code Reduction
- [ ] **TodayView:** 814 → ~160 lines (-80%)
- [ ] **TrendsView:** 523 → ~120 lines (-77%)
- [ ] **ActivitiesView:** 412 → ~100 lines (-76%)
- [ ] **Total view code:** -70% reduction

### Quality Improvements
- [ ] **100% testable business logic** (in view models)
- [ ] **Zero services in views** (dependency injection only)
- [ ] **Clear state management** (single source of truth)
- [ ] **80%+ test coverage** on view models

### Developer Experience
- [ ] **Easy to test** - Mock dependencies
- [ ] **Clear separation** - UI vs logic
- [ ] **Reusable view models** - Share across screens
- [ ] **Type-safe** - Compiler catches issues

---

## Timeline

**Week 7:**
- Day 1: Create ViewModelProtocol, LoadingState
- Day 2-3: Refactor TodayView → TodayViewModel
- Day 4: Refactor TrendsView → TrendsViewModel
- Day 5: Write tests for both view models

**Week 8:**
- Day 1-2: Refactor ActivitiesView, RecoveryDetailView
- Day 3: Refactor SleepDetailView, ProfileView
- Day 4: Write tests for all view models
- Day 5: Review, documentation, deploy

---

## Next Phase

After Phase 4 completes, move to **Phase 5: Design System** where we'll:
- Eliminate all hard-coded values
- 100% design token usage
- Sync with Figma design files
- Create design system documentation

**Ready to implement Phase 4?** Start with TodayViewModel refactor!
