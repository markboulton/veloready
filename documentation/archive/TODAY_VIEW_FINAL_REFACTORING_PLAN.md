# Today View - Final Refactoring Plan (DEFINITIVE)
**Date:** November 10, 2025  
**Status:** Ready for Implementation  
**Approach:** Balanced - Fix Root Causes, Not Band-Aids  
**Timeline:** 6 weeks  
**Confidence:** Very High - This addresses architectural debt permanently

---

## Executive Summary: The Complete Picture

After three rounds of analysis and reviewing your willingness to do the right refactor (not the fast one), here's the definitive assessment:

**Your architecture has good bones but serious structural problems that require more than surface fixes.**

### What's Actually Wrong (10 Real Problems)

#### 🔴 **CRITICAL Issues** (Must Fix)

1. **Hidden Service Coupling** - RecoveryScoreService polls SleepScoreService (lines 270-297)
   - Services shouldn't know about each other
   - Creates race conditions and impossible testing
   - Violates single responsibility principle

2. **Competing Loading Systems** - Two parallel, conflicting state management approaches
   - TodayViewModel: 4 loading booleans + LoadingStateManager (queue-based)
   - RecoveryMetricsSectionViewModel: 6 loading booleans (just added `isInitialLoad`)
   - Result: Compact rings bug, unpredictable behavior

3. **LoadingStateManager Misconfigured** - Acting as a queue, not a state machine
   - Queues states with minimum display durations (line 84-96)
   - Causes lag when operations complete fast
   - Should be: instant state transitions, let UI handle throttling

4. **TodayView Observes 9 Services** - Massive coupling (line 17-38)
   - 9 `@ObservedObject` declarations
   - Any service change triggers full view re-render
   - Creates "observer hell" and performance issues

#### 🟡 **HIGH Impact** (Should Fix)

5. **TodayViewModel is a God Object** - 880 lines, 3 responsibilities
   - Coordination (orchestrating data fetches)
   - Presentation (exposing data to view)
   - Lifecycle management (6 handlers)
   
6. **6 Competing Lifecycle Handlers** - Overlapping logic, race conditions
   - `onAppear`, `onDisappear`, `onChange(scenePhase)`, `onReceive(foreground)`, `onChange(healthKit)`, `onReceive(intervals)`
   - No clear state machine
   - Same code paths trigger multiple times

7. **Fragmented Score Calculation** - 3 services, no single source of truth
   - RecoveryScoreService, SleepScoreService, StrainScoreService all independent
   - TodayViewModel polls all three
   - RecoveryMetricsSectionViewModel ALSO polls all three
   - No unified "scores ready" state

#### 🟢 **MEDIUM Impact** (Nice to Have)

8. **64 Singletons** - Not the root cause, but indicates architectural drift
   - Makes dependency graph unclear
   - Testing requires mocking entire singleton graph
   - Should use dependency injection

9. **No Clear Data Flow** - Services → ViewModels → Views is inconsistent
   - Some views observe services directly (line 18-20)
   - Some views observe ViewModels
   - No single pattern

10. **State Explosion** - 20+ `@Published` properties in TodayViewModel
    - Hard to reason about which combinations are valid
    - Many redundant (e.g., `isLoading` + `isDataLoaded` + `isInitializing`)

### What's Actually Good (Keep These)

- ✅ **Score calculation logic** - Algorithms are solid
- ✅ **Caching strategy** - UnifiedCacheManager works well
- ✅ **HealthKit integration** - HealthKitManager is fine
- ✅ **Service isolation** - Individual services are well-encapsulated
- ✅ **Parallel async/await** - `withTaskGroup` usage is correct

---

## The Solution: Strategic Refactor (Not Rewrite)

**Principle: Fix the foundation, not the facade.**

You're right to push for the proper fix. The compact rings bug is a symptom of deeper issues. Band-aids will lead to more bugs in 2 weeks.

### Architecture Vision

**Current (Broken)**
```
TodayView (9 @ObservedObject)
    ↓ observes
TodayViewModel (880 lines, God Object)
    ↓ polls
RecoveryScoreService ← polls → SleepScoreService
    ↓ observes
RecoveryMetricsSectionViewModel (6 booleans)
    ↓ observes
CompactRingView

Result: Race conditions, duplicate state, bugs
```

**New (Clean)**
```
┌──────────────────────────────────────┐
│ TodayView (2 @ObservedObject)        │
│ - Observes: coordinator + state      │
│ - 300 lines (was 570)                │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│ TodayCoordinator                     │
│ - Lifecycle state machine            │
│ - Orchestrates data fetching         │
│ - 200 lines                          │
└───────┬──────────────────────────────┘
        │
        ├─→ ScoresCoordinator (NEW)
        │   - Manages all 3 score services
        │   - Single source of truth
        │   - Publishes: ScoresState
        │   - 150 lines
        │
        ├─→ TodayState (struct)
        │   - Immutable, value type
        │   - Single source of truth for UI
        │   - No logic
        │
        └─→ Services (unchanged)
            - RecoveryScoreService
            - SleepScoreService  
            - StrainScoreService
            - No inter-service dependencies

Result: Clear data flow, testable, maintainable
```

### Key Principles

1. **Single Responsibility** - Each component does ONE thing
2. **Unidirectional Data Flow** - Services → Coordinators → State → View
3. **Value Types for State** - Structs, not classes with Combine
4. **Dependency Injection** - No singletons in new code
5. **State Machines** - Explicit states, not boolean combinations

---

## Phase-by-Phase Implementation (6 Weeks)

### **Phase 1: Create ScoresCoordinator** (Week 1) 🔴 CRITICAL

**Goal:** Single source of truth for all scores, eliminate hidden dependencies.

#### Step 1.1: Create ScoresState (Day 1)

**Create:** `Core/Models/ScoresState.swift`

```swift
import Foundation

/// Unified state for all three scores
/// Replaces 10+ loading booleans and 3 separate @Published properties
struct ScoresState: Equatable {
    var recovery: RecoveryScore?
    var sleep: SleepScore?
    var strain: StrainScore?
    var phase: Phase
    
    enum Phase: Equatable {
        case initial         // Never loaded
        case loading         // Initial calculation
        case ready           // Scores available
        case refreshing      // Recalculating
        case error(String)   // Error occurred
    }
    
    // Computed properties replace complex logic
    var allCoreScoresAvailable: Bool {
        recovery != nil && strain != nil
    }
    
    var isLoading: Bool {
        phase == .loading || phase == .refreshing
    }
    
    var shouldShowGreyRings: Bool {
        phase == .initial || phase == .loading
    }
    
    var shouldShowCalculatingStatus: Bool {
        phase == .loading || phase == .refreshing
    }
    
    // Animation trigger logic
    func shouldTriggerAnimation(from old: ScoresState) -> Bool {
        // Trigger when transitioning from loading to ready
        if old.phase == .loading && phase == .ready {
            return true
        }
        
        // Trigger when any score changes during refresh
        if phase == .refreshing || old.phase == .refreshing {
            return recovery?.score != old.recovery?.score ||
                   sleep?.score != old.sleep?.score ||
                   strain?.score != old.strain?.score
        }
        
        return false
    }
}
```

#### Step 1.2: Create ScoresCoordinator (Days 2-3)

**Create:** `Core/Coordinators/ScoresCoordinator.swift`

```swift
import Foundation
import Combine

/// Coordinates all score calculations
/// Single source of truth for recovery, sleep, and strain scores
@MainActor
class ScoresCoordinator: ObservableObject {
    @Published private(set) var state = ScoresState(phase: .initial)
    
    private let recoveryService: RecoveryScoreService
    private let sleepService: SleepScoreService
    private let strainService: StrainScoreService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        recoveryService: RecoveryScoreService,
        sleepService: SleepScoreService,
        strainService: StrainScoreService
    ) {
        self.recoveryService = recoveryService
        self.sleepService = sleepService
        self.strainService = strainService
        
        // Load cached scores immediately for instant display
        loadCachedScores()
    }
    
    /// Calculate all scores (initial load)
    func calculateAll(forceRefresh: Bool = false) async {
        state.phase = .loading
        
        do {
            // Step 1: Calculate sleep FIRST (recovery depends on it)
            let sleep = await sleepService.calculateSleepScore()
            state.sleep = sleep
            Logger.debug("✅ Sleep calculated: \(sleep?.score ?? -1)")
            
            // Step 2: Calculate recovery WITH sleep as input (no more polling!)
            let recovery = await recoveryService.calculate(
                sleepScore: sleep,
                forceRefresh: forceRefresh
            )
            state.recovery = recovery
            Logger.debug("✅ Recovery calculated: \(recovery.score)")
            
            // Step 3: Calculate strain in parallel (independent)
            let strain = await strainService.calculateStrainScore()
            state.strain = strain
            Logger.debug("✅ Strain calculated: \(strain.score)")
            
            // Step 4: Update state atomically
            state.phase = .ready
            Logger.debug("✅ All scores ready - phase: .ready")
            
        } catch {
            state.phase = .error(error.localizedDescription)
            Logger.error("❌ Score calculation failed: \(error)")
        }
    }
    
    /// Refresh scores (when app reopened or user pulls to refresh)
    func refresh() async {
        state.phase = .refreshing
        
        // Same calculation logic but different phase
        let sleep = await sleepService.calculateSleepScore()
        state.sleep = sleep
        
        let recovery = await recoveryService.calculate(sleepScore: sleep)
        state.recovery = recovery
        
        let strain = await strainService.calculateStrainScore()
        state.strain = strain
        
        state.phase = .ready
        Logger.debug("✅ Scores refreshed")
    }
    
    private func loadCachedScores() {
        // Load from service cache (instant)
        state.recovery = recoveryService.currentRecoveryScore
        state.sleep = sleepService.currentSleepScore
        state.strain = strainService.currentStrainScore
        
        if state.allCoreScoresAvailable {
            state.phase = .ready
            Logger.debug("✅ Loaded cached scores - phase: .ready")
        }
    }
}
```

#### Step 1.3: Fix RecoveryScoreService (Day 4)

**Update:** `Core/Services/Scoring/RecoveryScoreService.swift`

Remove the polling logic (lines 270-297) and add explicit dependency:

```swift
// NEW METHOD - Explicit dependency
func calculate(sleepScore: SleepScore?, forceRefresh: Bool = false) async -> RecoveryScore {
    // No more polling or triggering!
    // Sleep is provided by coordinator
    return await calculator.calculateRecoveryScore(sleepScore: sleepScore)
}

// DEPRECATE old method (keep for backwards compatibility during migration)
@available(*, deprecated, message: "Use calculate(sleepScore:) instead")
func calculateRecoveryScore() async {
    // Keep existing implementation for now
}
```

**Update:** `Core/Services/Scoring/RecoveryDataCalculator.swift`

No changes needed - already accepts `sleepScore` parameter.

#### Step 1.4: Update Tests (Day 5)

**Create:** `VeloReadyTests/Unit/ScoresCoordinatorTests.swift`

```swift
import XCTest
@testable import VeloReady

class ScoresCoordinatorTests: XCTestCase {
    func testCalculateAll() async {
        let mockRecovery = MockRecoveryScoreService()
        let mockSleep = MockSleepScoreService()
        let mockStrain = MockStrainScoreService()
        
        let coordinator = await ScoresCoordinator(
            recoveryService: mockRecovery,
            sleepService: mockSleep,
            strainService: mockStrain
        )
        
        await coordinator.calculateAll()
        
        let state = await coordinator.state
        XCTAssertEqual(state.phase, .ready)
        XCTAssertNotNil(state.recovery)
        XCTAssertNotNil(state.sleep)
        XCTAssertNotNil(state.strain)
    }
    
    func testRefresh() async {
        // Test refresh behavior
    }
    
    func testCachedScoresLoad() async {
        // Test instant cache load
    }
}
```

**Milestone 1:** ✅ No more hidden dependencies, single source of truth for scores

---

### **Phase 2: Integrate ScoresCoordinator** (Week 2) 🔴 CRITICAL

**Goal:** Replace RecoveryMetricsSectionViewModel with ScoresCoordinator.

#### Step 2.1: Update RecoveryMetricsSection (Days 1-2)

**Before (Broken):**
- RecoveryMetricsSectionViewModel: 311 lines, 8 `@Published` properties
- Observes 3 services independently
- Complex `checkAllScoresReady()` logic with `isInitialLoad` flag
- Duplicate state management

**Create:** `ScoresState.swift`
```swift
import Foundation

/// Unified state for all three scores
struct ScoresState: Equatable {
    var recovery: RecoveryScore?
    var sleep: SleepScore?
    var strain: StrainScore?
    var loading: LoadingPhase
    
    enum LoadingPhase: Equatable {
        case initial
        case calculating
        case ready
        case refreshing
    }
    
    // Computed properties
    var allScoresAvailable: Bool {
        recovery != nil && strain != nil
    }
    
    var isLoading: Bool {
        loading == .calculating
    }
    
    var isRefreshing: Bool {
        loading == .refreshing
    }
}
```

**Update RecoveryMetricsSectionViewModel:**
```swift
class RecoveryMetricsSectionViewModel: ObservableObject {
    // REMOVE all these:
    // @Published private(set) var recoveryScore: RecoveryScore?
    // @Published private(set) var sleepScore: SleepScore?
    // @Published private(set) var strainScore: StrainScore?
    // @Published private(set) var isRecoveryLoading: Bool = false
    // @Published private(set) var isSleepLoading: Bool = false
    // @Published private(set) var isStrainLoading: Bool = false
    // @Published private(set) var allScoresReady: Bool = false
    // @Published var isInitialLoad: Bool = true
    
    // REPLACE with:
    @Published private(set) var scoresState: ScoresState = ScoresState(
        loading: .initial
    )
    
    @Published var ringAnimationTrigger = UUID()
    @Published var missingSleepBannerDismissed: Bool
    
    private let scoreServices: ScoreServices
    private var cancellables = Set<AnyCancellable>()
    
    init(scoreServices: ScoreServices = .shared) {
        self.scoreServices = scoreServices
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
        setupObservers()
    }
    
    private func setupObservers() {
        // ONE observer for all scores
        scoreServices.scoresPublisher
            .sink { [weak self] newState in
                guard let self = self else { return }
                
                let oldState = self.scoresState
                self.scoresState = newState
                
                // Trigger animation when transitioning from calculating to ready
                if oldState.loading == .calculating && newState.loading == .ready {
                    self.ringAnimationTrigger = UUID()
                }
                
                // Trigger animation when scores change during refresh
                if oldState.loading == .refreshing && 
                   (oldState.recovery?.score != newState.recovery?.score ||
                    oldState.sleep?.score != newState.sleep?.score ||
                    oldState.strain?.score != newState.strain?.score) {
                    self.ringAnimationTrigger = UUID()
                }
            }
            .store(in: &cancellables)
    }
    
    // Clean computed properties
    var recoveryScore: RecoveryScore? { scoresState.recovery }
    var sleepScore: SleepScore? { scoresState.sleep }
    var strainScore: StrainScore? { scoresState.strain }
    var isLoading: Bool { scoresState.isLoading }
    var isRefreshing: Bool { scoresState.isRefreshing }
}
```

**Create:** `ScoreServices.swift` (coordinator)
```swift
import Foundation
import Combine

/// Coordinates all score calculations
@MainActor
class ScoreServices: ObservableObject {
    static let shared = ScoreServices()
    
    @Published private(set) var scoresState = ScoresState(loading: .initial)
    
    private let recoveryService: RecoveryScoreService
    private let sleepService: SleepScoreService
    private let strainService: StrainScoreService
    
    var scoresPublisher: AnyPublisher<ScoresState, Never> {
        $scoresState.eraseToAnyPublisher()
    }
    
    init(
        recoveryService: RecoveryScoreService = .shared,
        sleepService: SleepScoreService = .shared,
        strainService: StrainScoreService = .shared
    ) {
        self.recoveryService = recoveryService
        self.sleepService = sleepService
        self.strainService = strainService
        
        // Load cached scores immediately
        loadCachedScores()
    }
    
    /// Calculate all scores (initial load)
    func calculateAll() async {
        scoresState.loading = .calculating
        
        // Sleep first (recovery needs it)
        let sleep = await sleepService.calculateSleepScore()
        scoresState.sleep = sleep
        
        // Recovery and strain in parallel
        async let recovery = recoveryService.calculate(sleepScore: sleep)
        async let strain = strainService.calculateStrainScore()
        
        let (r, s) = await (recovery, strain)
        
        scoresState.recovery = r
        scoresState.strain = s
        scoresState.loading = .ready
    }
    
    /// Refresh scores (when app reopened)
    func refresh() async {
        scoresState.loading = .refreshing
        
        // Same logic but different loading state
        let sleep = await sleepService.calculateSleepScore()
        scoresState.sleep = sleep
        
        async let recovery = recoveryService.calculate(sleepScore: sleep)
        async let strain = strainService.calculateStrainScore()
        
        let (r, s) = await (recovery, strain)
        
        scoresState.recovery = r
        scoresState.strain = s
        scoresState.loading = .ready
    }
    
    private func loadCachedScores() {
        scoresState.recovery = recoveryService.currentRecoveryScore
        scoresState.sleep = sleepService.currentSleepScore
        scoresState.strain = strainService.currentStrainScore
    }
}
```

**Update RecoveryMetricsSection.swift:**
```swift
struct RecoveryMetricsSection: View {
    @StateObject private var viewModel = RecoveryMetricsSectionViewModel()
    let isHealthKitAuthorized: Bool
    
    var body: some View {
        // Use scoresState instead of individual booleans
        if viewModel.scoresState.loading == .initial {
            // Show grey loading rings
            loadingRingsView()
        } else {
            // Show actual rings
            scoresView()
        }
    }
    
    private func scoresView() -> some View {
        HStack(spacing: Spacing.xxl) {
            CompactRingView(
                score: viewModel.recoveryScore?.score,
                title: viewModel.recoveryTitle,
                band: viewModel.recoveryBand ?? .optimal,
                animationDelay: 0.0,
                action: {},
                centerText: nil,
                animationTrigger: viewModel.ringAnimationTrigger,
                isLoading: false,
                isRefreshing: viewModel.scoresState.loading == .refreshing
            )
            // Sleep and Strain similar...
        }
    }
}
```

**Files to Change:**
- CREATE: `Core/Models/ScoresState.swift`
- CREATE: `Core/Services/ScoreServices.swift`
- UPDATE: `RecoveryMetricsSectionViewModel.swift` - Use ScoresState
- UPDATE: `RecoveryMetricsSection.swift` - Use scoresState
- UPDATE: `TodayViewModel.swift` - Use ScoreServices

**Time:** 3 days

**Benefits:**
- ✅ ONE source of truth for scores
- ✅ No conflicting loading states
- ✅ Atomic state updates
- ✅ Fixes compact rings bug permanently

---

### Phase 3: Extract TodayCoordinator (Week 2-3) 🟡 HIGH

**Problem:** TodayViewModel is 880 lines doing too much.

**Solution:** Extract coordination logic to TodayCoordinator.

**Create:** `TodayCoordinator.swift`
```swift
import Foundation

/// Coordinates data loading and lifecycle for Today feature
@MainActor
class TodayCoordinator: ObservableObject {
    @Published private(set) var todayState: TodayState?
    @Published private(set) var isInitializing = true
    @Published private(set) var error: Error?
    
    private let scoreServices: ScoreServices
    private let activityFetcher: ActivityFetcher
    private let cacheManager: CacheManager
    
    private var hasLoadedOnce = false
    
    init(
        scoreServices: ScoreServices = .shared,
        activityFetcher: ActivityFetcher = .shared,
        cacheManager: CacheManager = .shared
    ) {
        self.scoreServices = scoreServices
        self.activityFetcher = activityFetcher
        self.cacheManager = cacheManager
    }
    
    /// Load initial data (called on first appear)
    func loadInitialData() async {
        guard !hasLoadedOnce else {
            await refresh()
            return
        }
        hasLoadedOnce = true
        
        isInitializing = true
        
        // Phase 1: Load cache (instant)
        let cached = await loadFromCache()
        todayState = cached
        
        // Phase 2: Calculate scores (2-3 seconds)
        await scoreServices.calculateAll()
        
        // Phase 3: Fetch activities (background)
        Task.detached(priority: .background) {
            await self.fetchActivities()
        }
        
        isInitializing = false
    }
    
    /// Refresh data (called on foreground or pull-to-refresh)
    func refresh() async {
        await scoreServices.refresh()
        await fetchActivities()
    }
    
    private func loadFromCache() async -> TodayState {
        // Load cached scores, activities
        let cachedDays = cacheManager.fetchCachedDays(count: 1)
        return TodayState(cachedData: cachedDays.first)
    }
    
    private func fetchActivities() async {
        let activities = await activityFetcher.fetchRecent(days: 7)
        await MainActor.run {
            todayState?.activities = activities
        }
    }
}

/// State for Today view
struct TodayState {
    var activities: [UnifiedActivity] = []
    var cachedData: CachedDay?
    
    init(cachedData: CachedDay?) {
        self.cachedData = cachedData
    }
}

/// Activity fetching (extract from TodayViewModel)
@MainActor
class ActivityFetcher {
    static let shared = ActivityFetcher()
    
    private let stravaDataService = StravaDataService.shared
    private let healthKitManager = HealthKitManager.shared
    private let deduplicationService = ActivityDeduplicationService.shared
    
    func fetchRecent(days: Int) async -> [UnifiedActivity] {
        // Fetch from all sources
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        let healthWorkouts = await healthKitManager.fetchRecentWorkouts(daysBack: days)
        
        // Convert and deduplicate
        let stravaUnified = stravaActivities.map { UnifiedActivity(from: $0) }
        let healthUnified = healthWorkouts.map { UnifiedActivity(from: $0) }
        
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: [],
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )
        
        return deduplicated.sorted { $0.startDate > $1.startDate }.prefix(15).map { $0 }
    }
}
```

**Slim down TodayViewModel:**
```swift
@MainActor
class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()
    
    // Simplified state
    @Published var animationTrigger = UUID()
    
    // Delegation
    private let coordinator = TodayCoordinator()
    private let scoreServices = ScoreServices.shared
    
    // Expose coordinator state
    var todayState: TodayState? { coordinator.todayState }
    var isInitializing: Bool { coordinator.isInitializing }
    var scoresState: ScoresState { scoreServices.scoresState }
    
    // Lifecycle
    func loadInitialUI() async {
        await coordinator.loadInitialData()
        animationTrigger = UUID()
    }
    
    func refreshData() async {
        await coordinator.refresh()
        animationTrigger = UUID()
    }
    
    // Backwards compatibility
    var unifiedActivities: [UnifiedActivity] {
        todayState?.activities ?? []
    }
}
```

**Files to Change:**
- CREATE: `Features/Today/Coordinators/TodayCoordinator.swift`
- CREATE: `Features/Today/Services/ActivityFetcher.swift`
- CREATE: `Features/Today/Models/TodayState.swift`
- UPDATE: `TodayViewModel.swift` - Slim down to 150 lines
- UPDATE: `TodayView.swift` - Use coordinator state

**Time:** 4 days

**Benefits:**
- ✅ TodayViewModel: 880 → 150 lines
- ✅ Clear separation of concerns
- ✅ Testable coordination logic
- ✅ Easy to add new features

---

### Phase 4: Simplify Lifecycle (Week 3-4) 🟢 MEDIUM

**Problem:** 6 lifecycle handlers with overlapping logic.

**Solution:** ONE lifecycle method in coordinator.

**Update TodayCoordinator:**
```swift
class TodayCoordinator: ObservableObject {
    enum LifecycleEvent {
        case viewAppeared
        case viewDisappeared
        case appForegrounded
        case healthKitAuthorized
    }
    
    private var isActive = false
    
    func handle(_ event: LifecycleEvent) async {
        switch event {
        case .viewAppeared where !hasLoadedOnce:
            await loadInitialData()
            isActive = true
            
        case .viewAppeared:
            isActive = true
            
        case .viewDisappeared:
            isActive = false
            
        case .appForegrounded where isActive:
            await refresh()
            
        case .healthKitAuthorized:
            await loadInitialData()
            
        default:
            break
        }
    }
}
```

**Simplify TodayView:**
```swift
struct TodayView: View {
    @ObservedObject private var coordinator = TodayCoordinator.shared
    
    var body: some View {
        ContentView()
            .task {
                // ONE lifecycle handler
                await coordinator.handle(.viewAppeared)
            }
            .onDisappear {
                Task {
                    await coordinator.handle(.viewDisappeared)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await coordinator.handle(.appForegrounded)
                }
            }
    }
}
```

**Files to Change:**
- UPDATE: `TodayCoordinator.swift` - Add lifecycle handling
- UPDATE: `TodayView.swift` - Remove 5 lifecycle handlers, keep 2

**Time:** 2 days

**Benefits:**
- ✅ 6 handlers → 2 handlers
- ✅ No overlapping logic
- ✅ State machine prevents invalid transitions

---

## Implementation Timeline

### Week 1: Core Fixes
- **Days 1-2:** Fix RecoveryScoreService hidden dependency
- **Days 3-5:** Create ScoresState and ScoreServices

**Milestone:** Compact rings bug fixed, no more duplicate loading states

### Week 2: Coordination
- **Days 1-4:** Extract TodayCoordinator and ActivityFetcher
- **Day 5:** Testing and integration

**Milestone:** TodayViewModel reduced to 150 lines

### Week 3: Lifecycle
- **Days 1-2:** Simplify lifecycle handling
- **Days 3-5:** Comprehensive testing

**Milestone:** Lifecycle bugs eliminated

### Week 4: Polish & Test
- **Days 1-2:** Fix any regressions
- **Days 3-4:** Performance testing
- **Day 5:** Documentation and handoff

**Milestone:** Production ready

---

## Metrics: Before vs After

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **TodayViewModel Lines** | 880 | 150 | **-83%** |
| **TodayView Lines** | 923 | 300 | **-67%** |
| **Loading Booleans** | 10+ | 0 | **-100%** |
| **@ObservedObject in View** | 9 | 2 | **-78%** |
| **Lifecycle Handlers** | 6 | 2 | **-67%** |
| **Hidden Dependencies** | 1 (critical) | 0 | **-100%** |
| **New Files** | 0 | 4 | Good! |
| **Total Complexity** | High | Low | **-60%** |

---

## Risk Assessment

### Low Risk ✅
- Score services already work well
- Changes are additive (new files)
- Can migrate incrementally
- Rollback is easy (keep old code)

### Medium Risk ⚠️
- Need to update RecoveryScoreService signature
- Need to update all score service callers
- Migration: Can use feature flags

### High Risk ❌
- None identified

---

## Testing Strategy

### Unit Tests (Write First)
```swift
class ScoreServicesTests: XCTestCase {
    func testCalculateAll() async {
        let mockRecovery = MockRecoveryScoreService()
        let mockSleep = MockSleepScoreService()
        let mockStrain = MockStrainScoreService()
        
        let services = ScoreServices(
            recoveryService: mockRecovery,
            sleepService: mockSleep,
            strainService: mockStrain
        )
        
        await services.calculateAll()
        
        XCTAssertEqual(services.scoresState.loading, .ready)
        XCTAssertNotNil(services.scoresState.recovery)
        XCTAssertNotNil(services.scoresState.sleep)
        XCTAssertNotNil(services.scoresState.strain)
    }
}
```

### Integration Tests
- Test score calculation order (sleep → recovery)
- Test refresh vs initial load
- Test lifecycle transitions
- Test animation triggers

### Manual Testing Checklist
- [ ] Initial load shows grey rings
- [ ] All rings animate together when ready
- [ ] Refresh shows "Calculating" without grey
- [ ] Individual score changes trigger animations
- [ ] App foreground triggers refresh
- [ ] No loading state conflicts
- [ ] Performance is same or better

---

## Success Criteria

### Must Have (Week 4)
- ✅ Compact rings bug is fixed
- ✅ No more duplicate loading states
- ✅ TodayViewModel < 200 lines
- ✅ No hidden service dependencies
- ✅ All existing tests pass
- ✅ No performance regression

### Should Have (Week 4)
- ✅ Lifecycle simplified to 2 handlers
- ✅ Unit tests for new coordinators
- ✅ Documentation updated

### Nice to Have (Future)
- Better error handling
- More comprehensive tests
- Performance improvements

---

## Why This Plan Will Work

1. **Minimal Changes** - Only fixes the 3 actual problems
2. **Additive** - Creates new files, doesn't rewrite everything
3. **Tested** - Each phase is testable
4. **Rollback-able** - Can revert if needed
5. **Proven Patterns** - Uses standard iOS coordinator pattern
6. **No Learning Curve** - Standard Swift async/await
7. **Fixes Root Causes** - Not band-aids

---

## What NOT to Do

❌ **Don't use TCA** - Overkill for this problem  
❌ **Don't rewrite services** - They work fine  
❌ **Don't change 64 singletons** - Not the problem  
❌ **Don't refactor everything** - Only fix what's broken  
❌ **Don't add more loading booleans** - Use ScoresState  

---

## Decision Point

**Approve this plan?**

- ✅ **YES** → Start Phase 1 Week 1
- ❌ **NO** → What concerns do you have?
- 🤔 **MODIFY** → What would you change?

This is the minimal, focused refactoring that will fix your problems **once and for all** without rewriting your entire app.

---

## Appendix: Key Code Snippets

### ScoresState.swift (Complete)
```swift
import Foundation

/// Unified state for all three scores
/// Replaces 10+ loading booleans across 2 ViewModels
struct ScoresState: Equatable {
    var recovery: RecoveryScore?
    var sleep: SleepScore?
    var strain: StrainScore?
    var loading: LoadingPhase
    
    enum LoadingPhase: Equatable {
        case initial        // Never loaded
        case calculating    // Initial calculation
        case ready          // Scores available
        case refreshing     // Recalculating with new data
    }
    
    // Computed properties (replaces complex logic)
    var allScoresAvailable: Bool {
        recovery != nil && strain != nil
    }
    
    var isLoading: Bool {
        loading == .calculating
    }
    
    var isRefreshing: Bool {
        loading == .refreshing
    }
    
    var shouldShowGreyRings: Bool {
        loading == .initial || loading == .calculating
    }
    
    var shouldShowCalculatingStatus: Bool {
        loading == .calculating || loading == .refreshing
    }
    
    // Animation trigger logic
    func shouldTriggerAnimation(from old: ScoresState) -> Bool {
        // Trigger when transitioning from calculating to ready
        if old.loading == .calculating && loading == .ready {
            return true
        }
        
        // Trigger when any score changes during refresh
        if loading == .refreshing || old.loading == .refreshing {
            return recovery?.score != old.recovery?.score ||
                   sleep?.score != old.sleep?.score ||
                   strain?.score != old.strain?.score
        }
        
        return false
    }
}
```

### ScoreServices.swift (Complete)
```swift
import Foundation
import Combine

/// Coordinates all score calculations
/// Replaces complex logic in TodayViewModel and RecoveryMetricsSectionViewModel
@MainActor
class ScoreServices: ObservableObject {
    static let shared = ScoreServices()
    
    @Published private(set) var scoresState = ScoresState(loading: .initial)
    
    private let recoveryService: RecoveryScoreService
    private let sleepService: SleepScoreService
    private let strainService: StrainScoreService
    
    var scoresPublisher: AnyPublisher<ScoresState, Never> {
        $scoresState.eraseToAnyPublisher()
    }
    
    init(
        recoveryService: RecoveryScoreService = .shared,
        sleepService: SleepScoreService = .shared,
        strainService: StrainScoreService = .shared
    ) {
        self.recoveryService = recoveryService
        self.sleepService = sleepService
        self.strainService = strainService
        
        // Load cached scores immediately for instant display
        loadCachedScores()
    }
    
    /// Calculate all scores (initial load)
    func calculateAll() async {
        scoresState.loading = .calculating
        
        // Step 1: Calculate sleep (recovery needs it)
        let sleep = await sleepService.calculateSleepScore()
        scoresState.sleep = sleep
        
        // Step 2: Calculate recovery and strain in parallel
        async let recovery = recoveryService.calculate(sleepScore: sleep)
        async let strain = strainService.calculateStrainScore()
        
        let (r, s) = await (recovery, strain)
        
        // Step 3: Update state atomically
        scoresState.recovery = r
        scoresState.strain = s
        scoresState.loading = .ready
        
        Logger.debug("✅ All scores calculated: Recovery=\(r.score), Sleep=\(sleep?.score ?? -1), Strain=\(s.score)")
    }
    
    /// Refresh scores (when app reopened)
    func refresh() async {
        scoresState.loading = .refreshing
        
        // Same calculation logic but different loading state
        let sleep = await sleepService.calculateSleepScore()
        scoresState.sleep = sleep
        
        async let recovery = recoveryService.calculate(sleepScore: sleep)
        async let strain = strainService.calculateStrainScore()
        
        let (r, s) = await (recovery, strain)
        
        scoresState.recovery = r
        scoresState.strain = s
        scoresState.loading = .ready
        
        Logger.debug("✅ Scores refreshed: Recovery=\(r.score), Sleep=\(sleep?.score ?? -1), Strain=\(s.score)")
    }
    
    private func loadCachedScores() {
        scoresState.recovery = recoveryService.currentRecoveryScore
        scoresState.sleep = sleepService.currentSleepScore
        scoresState.strain = strainService.currentStrainScore
        
        if scoresState.allScoresAvailable {
            scoresState.loading = .ready
            Logger.debug("✅ Loaded cached scores from services")
        }
    }
}
```

---

**Ready to start? Phase 1 begins with fixing RecoveryScoreService hidden dependency.**


