# Today View - Definitive Refactoring Plan
**Date:** November 10, 2025  
**Status:** Ready for Implementation  
**Approach:** Balanced - Fix Root Causes, Not Band-Aids  
**Timeline:** 6 weeks  
**Effort Level:** Medium-Deep (not a rewrite, but substantial fixes)

---

## Executive Summary

After three rounds of analysis and your directive to "do the right thing, not the fast thing," here's the definitive plan.

### The Truth

**Your architecture has good bones but 4 critical structural problems:**

1. **RecoveryScoreService polls SleepScoreService** (hidden coupling)
2. **Two competing loading state systems** (TodayViewModel + RecoveryMetricsSectionViewModel)
3. **TodayView observes 9 services** (observer hell)
4. **TodayViewModel is a God Object** (880 lines, 3 responsibilities)

**These 4 problems cause:**
- ✅ The compact rings bug you just fixed (will reappear)
- ✅ Future bugs as complexity grows
- ✅ Impossible testing
- ✅ Performance issues

### The Solution

**Strategic refactor using Coordinator Pattern + State consolidation.**

**NOT a rewrite.** We're keeping 80% of your code:
- ✅ Keep all score services
- ✅ Keep all calculation logic
- ✅ Keep caching strategy
- ✅ Keep HealthKit integration

**We're fixing 20%:**
- ❌ Remove hidden service dependencies
- ❌ Replace 10+ loading booleans with unified state
- ❌ Extract coordination logic to coordinator
- ❌ Simplify lifecycle management

---

## Current Architecture (What's Broken)

```
TodayView (570 lines)
├─ 9 @ObservedObject declarations
│  ├─ TodayViewModel (880 lines) ← God Object
│  ├─ HealthKitManager.shared
│  ├─ WellnessDetectionService.shared
│  ├─ IllnessDetectionService.shared
│  ├─ LiveActivityService.shared
│  ├─ ProFeatureConfig.shared
│  ├─ StravaAuthService.shared
│  ├─ IntervalsOAuthManager.shared
│  └─ NetworkMonitor.shared
│
├─ 6 lifecycle handlers
│  ├─ onAppear
│  ├─ onDisappear
│  ├─ onChange(scenePhase)
│  ├─ onReceive(foreground)
│  ├─ onChange(healthKit)
│  └─ onReceive(intervals)
│
└─ RecoveryMetricsSection
   └─ RecoveryMetricsSectionViewModel (311 lines)
      ├─ 8 @Published properties
      ├─ observes RecoveryScoreService
      ├─ observes SleepScoreService
      └─ observes StrainScoreService

TodayViewModel orchestrates:
├─ RecoveryScoreService ← POLLS → SleepScoreService ⚠️
├─ SleepScoreService
└─ StrainScoreService

Result: Race conditions, state conflicts, bugs
```

### Specific Problems

#### 1. Hidden Service Coupling (CRITICAL)
**File:** `RecoveryScoreService.swift` lines 270-297

```swift
private func calculateRealRecoveryScore(...) async -> RecoveryScore? {
    // 🚨 POLLS another service!
    if sleepScoreService.currentSleepScore == nil {
        if sleepScoreService.isLoading {
            // Wait up to 5 seconds
            while sleepScoreService.isLoading && attempts < 50 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                attempts += 1
            }
        } else {
            // 🚨 TRIGGERS another service!
            await sleepScoreService.calculateSleepScore()
        }
    }
}
```

**Why this is bad:**
- Services should not know about each other
- Creates hidden dependencies (impossible to test)
- Race conditions (what if both services start simultaneously?)
- Violates single responsibility

#### 2. Competing Loading State Systems (CRITICAL)

**System 1:** TodayViewModel
- `isLoading: Bool`
- `isInitializing: Bool`
- `isDataLoaded: Bool`
- `loadingStateManager: LoadingStateManager` (queue-based, throttled)

**System 2:** RecoveryMetricsSectionViewModel
- `isRecoveryLoading: Bool`
- `isSleepLoading: Bool`
- `isStrainLoading: Bool`
- `allScoresReady: Bool`
- `isInitialLoad: Bool` (just added)
- `ringAnimationTrigger: UUID`

**Result:** The compact rings bug. States conflict. No single source of truth.

#### 3. Observer Hell (HIGH IMPACT)

**File:** `TodayView.swift` lines 17-38

```swift
@ObservedObject private var viewModel = TodayViewModel.shared
@ObservedObject private var healthKitManager = HealthKitManager.shared
@ObservedObject private var wellnessService = WellnessDetectionService.shared
@ObservedObject private var illnessService = IllnessDetectionService.shared
@ObservedObject private var liveActivityService = LiveActivityService.shared
@ObservedObject private var proConfig = ProFeatureConfig.shared
@ObservedObject private var stravaAuth = StravaAuthService.shared
@ObservedObject private var intervalsAuth = IntervalsOAuthManager.shared
@ObservedObject private var networkMonitor = NetworkMonitor.shared
```

**Why this is bad:**
- **ANY** change to **ANY** of these 9 services triggers a view re-render
- Creates performance bottlenecks
- View cares about too many things
- Impossible to reason about what triggers UI updates

#### 4. God Object (HIGH IMPACT)

**TodayViewModel:** 880 lines, 3 responsibilities

1. **Coordination** (lines 182-669)
   - Orchestrating score calculations
   - Fetching activities
   - Managing background tasks

2. **Presentation** (lines 50-180)
   - Exposing data to view
   - Formatting scores
   - Animation triggers

3. **Lifecycle** (lines 82-181)
   - Handling app foreground/background
   - Managing initialization
   - Responding to auth changes

**Should be:** 150 lines, 1 responsibility (presentation only)

---

## New Architecture (What We're Building)

```
TodayView (300 lines)
├─ 2 @ObservedObject declarations
│  ├─ TodayCoordinator
│  └─ TodayPresentationState
│
└─ 2 lifecycle handlers
   ├─ task { await coordinator.handle(.viewAppeared) }
   └─ onDisappear { await coordinator.handle(.viewDisappeared) }

TodayCoordinator (200 lines)
├─ Lifecycle state machine
├─ Orchestrates data fetching
└─ Manages:
   ├─ ScoresCoordinator
   ├─ ActivitiesCoordinator
   └─ TodayPresentationState

ScoresCoordinator (150 lines)
├─ Single source of truth for scores
├─ Publishes: ScoresState
├─ Manages:
│  ├─ RecoveryScoreService
│  ├─ SleepScoreService
│  └─ StrainScoreService
└─ NO inter-service dependencies

Result: Clear data flow, testable, maintainable
```

### Key Improvements

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| **TodayView @ObservedObject** | 9 | 2 | -78% |
| **TodayViewModel Lines** | 880 | 150 | -83% |
| **RecoveryMetricsSectionViewModel** | 311 lines | DELETE | -100% |
| **Loading Booleans** | 10+ | 0 | -100% |
| **Lifecycle Handlers** | 6 | 2 | -67% |
| **Hidden Dependencies** | 1 (critical) | 0 | -100% |
| **New Files Created** | 0 | 5 | +5 |
| **Total System Complexity** | High | Low | -60% |

---

## Implementation Plan (6 Weeks)

### **Week 1: Create ScoresCoordinator** 🔴 CRITICAL

#### Goals
1. Create unified ScoresState
2. Create ScoresCoordinator
3. Fix RecoveryScoreService hidden dependency
4. Write comprehensive tests

#### Day 1: Create ScoresState

**Create:** `VeloReady/Core/Models/ScoresState.swift`

```swift
import Foundation

/// Unified state for all three scores
/// Replaces 10+ loading booleans across 2 ViewModels
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
    
    init(phase: Phase = .initial) {
        self.phase = phase
    }
    
    // MARK: - Computed Properties (replaces complex logic)
    
    /// All core scores (recovery + strain) available
    var allCoreScoresAvailable: Bool {
        recovery != nil && strain != nil
    }
    
    /// Currently loading or refreshing
    var isLoading: Bool {
        phase == .loading || phase == .refreshing
    }
    
    /// Should show grey rings with shimmer
    var shouldShowGreyRings: Bool {
        phase == .initial || phase == .loading
    }
    
    /// Should show "Calculating" status
    var shouldShowCalculatingStatus: Bool {
        phase == .loading || phase == .refreshing
    }
    
    /// Has any error
    var hasError: Bool {
        if case .error = phase {
            return true
        }
        return false
    }
    
    // MARK: - Animation Logic
    
    /// Should trigger ring animation based on state transition
    func shouldTriggerAnimation(from oldState: ScoresState) -> Bool {
        // Trigger when transitioning from loading to ready (all rings animate together)
        if oldState.phase == .loading && phase == .ready {
            return true
        }
        
        // Trigger when any score changes during refresh (individual ring animates)
        if phase == .refreshing || oldState.phase == .refreshing {
            let recoveryChanged = recovery?.score != oldState.recovery?.score
            let sleepChanged = sleep?.score != oldState.sleep?.score
            let strainChanged = strain?.score != oldState.strain?.score
            
            return recoveryChanged || sleepChanged || strainChanged
        }
        
        return false
    }
}
```

#### Days 2-3: Create ScoresCoordinator

**Create:** `VeloReady/Core/Coordinators/ScoresCoordinator.swift`

```swift
import Foundation
import Combine

/// Coordinates all score calculations
/// Single source of truth for recovery, sleep, and strain scores
/// 
/// Responsibilities:
/// - Orchestrate score calculation order (sleep → recovery, strain in parallel)
/// - Manage loading states
/// - Provide unified ScoresState to consumers
/// - Handle cache loading
@MainActor
class ScoresCoordinator: ObservableObject {
    @Published private(set) var state = ScoresState(phase: .initial)
    
    // Dependencies
    private let recoveryService: RecoveryScoreService
    private let sleepService: SleepScoreService
    private let strainService: StrainScoreService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
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
    
    // MARK: - Public API
    
    /// Calculate all scores (initial load)
    /// Waits for all scores before marking as ready
    func calculateAll(forceRefresh: Bool = false) async {
        Logger.debug("🔄 [ScoresCoordinator] Starting calculateAll(forceRefresh: \(forceRefresh))")
        
        let oldState = state
        state.phase = .loading
        
        do {
            // Step 1: Calculate sleep FIRST (recovery depends on it)
            Logger.debug("🔄 [ScoresCoordinator] Step 1: Calculating sleep...")
            let sleep = await sleepService.calculateSleepScore()
            state.sleep = sleep
            Logger.debug("✅ [ScoresCoordinator] Sleep: \(sleep?.score ?? -1)")
            
            // Step 2: Calculate recovery WITH sleep as input (no more polling!)
            Logger.debug("🔄 [ScoresCoordinator] Step 2: Calculating recovery with sleep input...")
            let recovery = await recoveryService.calculate(
                sleepScore: sleep,
                forceRefresh: forceRefresh
            )
            state.recovery = recovery
            Logger.debug("✅ [ScoresCoordinator] Recovery: \(recovery.score)")
            
            // Step 3: Calculate strain (independent, but we wait for it)
            Logger.debug("🔄 [ScoresCoordinator] Step 3: Calculating strain...")
            let strain = await strainService.calculateStrainScore()
            state.strain = strain
            Logger.debug("✅ [ScoresCoordinator] Strain: \(strain.score)")
            
            // Step 4: Mark as ready (triggers animation)
            state.phase = .ready
            Logger.debug("✅ [ScoresCoordinator] All scores ready - phase: .ready")
            
        } catch {
            state.phase = .error(error.localizedDescription)
            Logger.error("❌ [ScoresCoordinator] Score calculation failed: \(error)")
        }
    }
    
    /// Refresh scores (when app reopened or user pulls to refresh)
    /// Immediately marks as refreshing (keeps existing scores visible)
    func refresh() async {
        Logger.debug("🔄 [ScoresCoordinator] Starting refresh...")
        
        state.phase = .refreshing
        
        // Same calculation logic but different phase (shows "Calculating" without grey rings)
        let sleep = await sleepService.calculateSleepScore()
        state.sleep = sleep
        
        let recovery = await recoveryService.calculate(sleepScore: sleep)
        state.recovery = recovery
        
        let strain = await strainService.calculateStrainScore()
        state.strain = strain
        
        state.phase = .ready
        Logger.debug("✅ [ScoresCoordinator] Scores refreshed")
    }
    
    // MARK: - Private Methods
    
    private func loadCachedScores() {
        // Load from service cache (instant, no async needed)
        state.recovery = recoveryService.currentRecoveryScore
        state.sleep = sleepService.currentSleepScore
        state.strain = strainService.currentStrainScore
        
        // If we have cached scores, mark as ready immediately
        if state.allCoreScoresAvailable {
            state.phase = .ready
            Logger.debug("✅ [ScoresCoordinator] Loaded cached scores - phase: .ready")
        } else {
            Logger.debug("⏳ [ScoresCoordinator] No cached scores - phase: .initial")
        }
    }
}
```

#### Day 4: Fix RecoveryScoreService

**Update:** `VeloReady/Core/Services/Scoring/RecoveryScoreService.swift`

**Step 1:** Add new method that accepts sleep score as parameter

```swift
// MARK: - NEW API (explicit dependency)

/// Calculate recovery score with explicit sleep dependency
/// - Parameters:
///   - sleepScore: Pre-calculated sleep score (can be nil if no sleep data)
///   - forceRefresh: Force recalculation even if daily limit reached
/// - Returns: Recovery score
func calculate(sleepScore: SleepScore?, forceRefresh: Bool = false) async -> RecoveryScore {
    Logger.debug("🔄 [RecoveryScoreService] calculate(sleepScore: \(sleepScore?.score ?? -1), forceRefresh: \(forceRefresh))")
    
    // Check daily calculation limit
    if !forceRefresh && hasReachedDailyCalculationLimit() {
        if let cached = currentRecoveryScore {
            Logger.debug("⏭️ [RecoveryScoreService] Using cached score (daily limit reached)")
            return cached
        }
    }
    
    // Set loading state
    isLoading = true
    defer { isLoading = false }
    
    // Delegate to calculator (runs on background thread)
    guard let score = await calculator.calculateRecoveryScore(sleepScore: sleepScore) else {
        Logger.error("❌ [RecoveryScoreService] Calculation failed")
        return RecoveryScore.placeholder()
    }
    
    // Update current score
    currentRecoveryScore = score
    
    // Save to cache
    await cacheManager.cacheRecoveryScore(score)
    
    // Update calculation tracking
    recordCalculation()
    
    Logger.debug("✅ [RecoveryScoreService] Recovery score calculated: \(score.score)")
    return score
}
```

**Step 2:** Deprecate old method (keep for backwards compatibility)

```swift
// MARK: - DEPRECATED API (for backwards compatibility)

/// Calculate recovery score (DEPRECATED - uses hidden dependency)
/// Use `calculate(sleepScore:)` instead for explicit dependencies
@available(*, deprecated, message: "Use calculate(sleepScore:forceRefresh:) instead")
func calculateRecoveryScore() async {
    // Keep existing implementation for now
    // This will be removed in Phase 3
    _ = await calculateRealRecoveryScore()
}
```

**Step 3:** Update calculateRealRecoveryScore to remove polling

```swift
private func calculateRealRecoveryScore(forceRefresh: Bool = false) async -> RecoveryScore? {
    // REMOVED: Lines 270-297 (polling logic)
    // Sleep score is now passed as parameter to calculate()
    
    // This method is only used by deprecated calculateRecoveryScore()
    // Will be removed in Phase 3
    
    return await calculator.calculateRecoveryScore(sleepScore: sleepScoreService.currentSleepScore)
}
```

#### Day 5: Write Tests

**Create:** `VeloReadyTests/Unit/ScoresCoordinatorTests.swift`

```swift
import XCTest
@testable import VeloReady

@MainActor
class ScoresCoordinatorTests: XCTestCase {
    var mockRecovery: MockRecoveryScoreService!
    var mockSleep: MockSleepScoreService!
    var mockStrain: MockStrainScoreService!
    var coordinator: ScoresCoordinator!
    
    override func setUp() async throws {
        mockRecovery = MockRecoveryScoreService()
        mockSleep = MockSleepScoreService()
        mockStrain = MockStrainScoreService()
        
        coordinator = ScoresCoordinator(
            recoveryService: mockRecovery,
            sleepService: mockSleep,
            strainService: mockStrain
        )
    }
    
    func testInitialState() async {
        XCTAssertEqual(coordinator.state.phase, .initial)
        XCTAssertNil(coordinator.state.recovery)
        XCTAssertNil(coordinator.state.sleep)
        XCTAssertNil(coordinator.state.strain)
    }
    
    func testCalculateAll() async {
        // Given
        mockSleep.mockScore = SleepScore.mock(score: 85)
        mockRecovery.mockScore = RecoveryScore.mock(score: 78)
        mockStrain.mockScore = StrainScore.mock(score: 120)
        
        // When
        await coordinator.calculateAll()
        
        // Then
        XCTAssertEqual(coordinator.state.phase, .ready)
        XCTAssertEqual(coordinator.state.recovery?.score, 78)
        XCTAssertEqual(coordinator.state.sleep?.score, 85)
        XCTAssertEqual(coordinator.state.strain?.score, 120)
        
        // Verify sleep was calculated first
        XCTAssertTrue(mockSleep.calculateCalled)
        XCTAssertTrue(mockRecovery.calculateCalled)
        XCTAssertTrue(mockStrain.calculateCalled)
    }
    
    func testRefresh() async {
        // Given - initial state with cached scores
        coordinator.state.recovery = RecoveryScore.mock(score: 70)
        coordinator.state.sleep = SleepScore.mock(score: 80)
        coordinator.state.strain = StrainScore.mock(score: 100)
        coordinator.state.phase = .ready
        
        // When
        mockRecovery.mockScore = RecoveryScore.mock(score: 75)
        await coordinator.refresh()
        
        // Then
        XCTAssertEqual(coordinator.state.phase, .ready)
        XCTAssertEqual(coordinator.state.recovery?.score, 75)
    }
    
    func testAnimationTrigger() {
        // Given
        var oldState = ScoresState(phase: .loading)
        var newState = ScoresState(phase: .ready)
        newState.recovery = RecoveryScore.mock(score: 78)
        
        // When
        let shouldAnimate = newState.shouldTriggerAnimation(from: oldState)
        
        // Then
        XCTAssertTrue(shouldAnimate)
    }
    
    func testNoAnimationWhenScoreUnchanged() {
        // Given
        var oldState = ScoresState(phase: .refreshing)
        oldState.recovery = RecoveryScore.mock(score: 78)
        
        var newState = ScoresState(phase: .ready)
        newState.recovery = RecoveryScore.mock(score: 78) // Same score
        
        // When
        let shouldAnimate = newState.shouldTriggerAnimation(from: oldState)
        
        // Then
        XCTAssertFalse(shouldAnimate)
    }
}

// MARK: - Mocks

class MockRecoveryScoreService: RecoveryScoreService {
    var mockScore: RecoveryScore?
    var calculateCalled = false
    
    override func calculate(sleepScore: SleepScore?, forceRefresh: Bool = false) async -> RecoveryScore {
        calculateCalled = true
        return mockScore ?? RecoveryScore.mock(score: 70)
    }
}

class MockSleepScoreService: SleepScoreService {
    var mockScore: SleepScore?
    var calculateCalled = false
    
    override func calculateSleepScore() async -> SleepScore? {
        calculateCalled = true
        return mockScore
    }
}

class MockStrainScoreService: StrainScoreService {
    var mockScore: StrainScore?
    var calculateCalled = false
    
    override func calculateStrainScore() async -> StrainScore {
        calculateCalled = true
        return mockScore ?? StrainScore.mock(score: 100)
    }
}
```

**Week 1 Deliverables:**
- ✅ ScoresState.swift created
- ✅ ScoresCoordinator.swift created
- ✅ RecoveryScoreService.calculate(sleepScore:) added
- ✅ Tests written and passing
- ✅ No more hidden service dependencies

---

### **Week 2: Integrate ScoresCoordinator** 🔴 CRITICAL

#### Goals
1. Replace RecoveryMetricsSectionViewModel with ScoresCoordinator
2. Update RecoveryMetricsSection to use ScoresState
3. Fix compact rings bug permanently
4. Delete 311 lines of duplicate code

#### Day 1: Simplify RecoveryMetricsSectionViewModel

**Current:** 311 lines, 8 `@Published` properties, complex logic

**New:** 80 lines, 2 `@Published` properties, simple logic

**Update:** `VeloReady/Features/Shared/ViewModels/RecoveryMetricsSectionViewModel.swift`

```swift
import Foundation
import Combine

/// Simplified ViewModel for RecoveryMetricsSection
/// Now delegates to ScoresCoordinator for state management
@MainActor
class RecoveryMetricsSectionViewModel: ObservableObject {
    // REMOVED: All these properties
    // @Published private(set) var recoveryScore: RecoveryScore?
    // @Published private(set) var sleepScore: SleepScore?
    // @Published private(set) var strainScore: StrainScore?
    // @Published private(set) var isRecoveryLoading: Bool = false
    // @Published private(set) var isSleepLoading: Bool = false
    // @Published private(set) var isStrainLoading: Bool = false
    // @Published private(set) var allScoresReady: Bool = false
    // @Published var isInitialLoad: Bool = true
    
    // NEW: Single source of truth
    private let scoresCoordinator: ScoresCoordinator
    
    // UI-specific state
    @Published var ringAnimationTrigger = UUID()
    @Published var missingSleepBannerDismissed: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    init(scoresCoordinator: ScoresCoordinator) {
        self.scoresCoordinator = scoresCoordinator
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe ScoresState changes
        scoresCoordinator.$state
            .sink { [weak self] newState in
                guard let self = self else { return }
                
                // Trigger animation when state changes warrant it
                if newState.shouldTriggerAnimation(from: self.previousState) {
                    self.ringAnimationTrigger = UUID()
                    Logger.debug("🎬 [RecoveryMetrics] Triggering ring animation")
                }
                
                self.previousState = newState
            }
            .store(in: &cancellables)
    }
    
    private var previousState = ScoresState(phase: .initial)
    
    // MARK: - Computed Properties (simple pass-through)
    
    var scoresState: ScoresState {
        scoresCoordinator.state
    }
    
    var recoveryScore: RecoveryScore? {
        scoresState.recovery
    }
    
    var sleepScore: SleepScore? {
        scoresState.sleep
    }
    
    var strainScore: StrainScore? {
        scoresState.strain
    }
    
    var recoveryScoreValue: Int? {
        recoveryScore?.score
    }
    
    var recoveryTitle: String {
        recoveryScore?.band.emoji ?? ""
    }
    
    var recoveryBand: RecoveryScore.RecoveryBand? {
        recoveryScore?.band
    }
    
    // Similar for sleep and strain...
    
    // MARK: - Actions
    
    func dismissMissingSleepBanner() {
        missingSleepBannerDismissed = true
        UserDefaults.standard.set(true, forKey: "missingSleepBannerDismissed")
    }
}
```

#### Days 2-3: Update RecoveryMetricsSection View

**Update:** `VeloReady/Features/Today/Views/Dashboard/Sections/RecoveryMetricsSection.swift`

**Key changes:**
1. Use `viewModel.scoresState` instead of individual booleans
2. Simplify loading logic
3. Fix compact rings behavior

```swift
struct RecoveryMetricsSection: View {
    @StateObject private var viewModel: RecoveryMetricsSectionViewModel
    let isHealthKitAuthorized: Bool
    
    init(scoresCoordinator: ScoresCoordinator, isHealthKitAuthorized: Bool) {
        self._viewModel = StateObject(wrappedValue: RecoveryMetricsSectionViewModel(scoresCoordinator: scoresCoordinator))
        self.isHealthKitAuthorized = isHealthKitAuthorized
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Show grey loading rings ONLY during initial load
            if viewModel.scoresState.shouldShowGreyRings {
                loadingRingsView()
            } else {
                // Show actual rings (with "Calculating" text if refreshing)
                scoresView()
            }
            
            // Missing sleep banner
            if shouldShowMissingSleepBanner {
                missingSleepBanner
            }
        }
    }
    
    @ViewBuilder
    private func scoresView() -> some View {
        HStack(spacing: Spacing.xxl) {
            // Recovery Ring
            if let recovery = viewModel.recoveryScore {
                recoveryRingView(recovery: recovery)
            } else {
                placeholderRingView(title: TodayContent.Scores.recoveryScore)
            }
            
            // Sleep Ring
            if let sleep = viewModel.sleepScore {
                sleepRingView(sleep: sleep)
            } else {
                placeholderRingView(title: TodayContent.Scores.sleepScore)
            }
            
            // Strain Ring
            if let strain = viewModel.strainScore {
                strainRingView(strain: strain)
            } else {
                placeholderRingView(title: TodayContent.Scores.loadScore)
            }
        }
    }
    
    private func recoveryRingView(recovery: RecoveryScore) -> some View {
        HapticNavigationLink(destination: RecoveryDetailView(recoveryScore: recovery)) {
            VStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xs) {
                    Text(TodayContent.Scores.recoveryScore)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: Icons.System.chevronRight)
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
                
                CompactRingView(
                    score: recovery.score,
                    title: viewModel.recoveryTitle,
                    band: recovery.band,
                    animationDelay: 0.0,
                    action: {},
                    centerText: nil,
                    animationTrigger: viewModel.ringAnimationTrigger,
                    isLoading: false, // Never show grey ring here
                    isRefreshing: viewModel.scoresState.phase == .refreshing // Show "Calculating" text
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Similar for sleep and strain...
    
    @ViewBuilder
    private func loadingRingsView() -> some View {
        HStack(spacing: Spacing.xxl) {
            // Grey rings with shimmer
            ForEach(0..<3) { _ in
                VStack(spacing: Spacing.lg) {
                    Text("Calculating")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.text.tertiary)
                    
                    CompactRingView(
                        score: nil,
                        title: "",
                        band: .optimal,
                        animationDelay: 0.0,
                        action: {},
                        centerText: nil,
                        animationTrigger: viewModel.ringAnimationTrigger,
                        isLoading: true, // Show grey ring with shimmer
                        isRefreshing: false
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var shouldShowMissingSleepBanner: Bool {
        guard isHealthKitAuthorized else { return false }
        guard !viewModel.missingSleepBannerDismissed else { return false }
        guard viewModel.scoresState.phase == .ready else { return false }
        
        // Show if sleep score is nil and recovery is "Limited Data"
        return viewModel.sleepScore == nil && 
               viewModel.recoveryScore?.band == .limitedData
    }
}
```

#### Day 4: Update TodayViewModel to Use ScoresCoordinator

**Update:** `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`

```swift
@MainActor
class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()
    
    // NEW: Single coordinator for scores
    private let scoresCoordinator: ScoresCoordinator
    
    // Expose scores state
    var scoresState: ScoresState {
        scoresCoordinator.state
    }
    
    // REMOVED: Direct references to score services
    // let recoveryScoreService: RecoveryScoreService
    // let sleepScoreService: SleepScoreService
    // let strainScoreService: StrainScoreService
    
    private init(container: ServiceContainer = .shared) {
        // Initialize scores coordinator
        self.scoresCoordinator = ScoresCoordinator(
            recoveryService: container.recoveryScoreService,
            sleepService: container.sleepScoreService,
            strainService: container.strainScoreService
        )
        
        // ... rest of init
    }
    
    func refreshData(forceRecoveryRecalculation: Bool = false) async {
        // ... existing activity fetching logic ...
        
        // REPLACED: Complex score calculation logic with 3 parallel tasks
        // await withTaskGroup(of: Void.self) { group in
        //     group.addTask { await self.sleepScoreService.calculateSleepScore() }
        //     group.addTask { await self.recoveryScoreService.calculateRecoveryScore() }
        //     group.addTask { await self.strainScoreService.calculateStrainScore() }
        // }
        
        // NEW: Single coordinator call
        await scoresCoordinator.calculateAll(forceRefresh: forceRecoveryRecalculation)
        
        // ... rest of refresh logic ...
    }
}
```

#### Day 5: Integration Testing

- Test initial load (grey rings → all animate together)
- Test refresh (no grey rings, "Calculating" text, individual animations)
- Test app backgrounding/foregrounding
- Test error states
- Verify no regressions

**Week 2 Deliverables:**
- ✅ RecoveryMetricsSectionViewModel simplified (311 → 80 lines)
- ✅ RecoveryMetricsSection uses ScoresState
- ✅ TodayViewModel uses ScoresCoordinator
- ✅ Compact rings bug fixed permanently
- ✅ All tests passing

---

### **Week 3-4: Create TodayCoordinator** 🟡 HIGH PRIORITY

#### Goals
1. Extract coordination logic from TodayViewModel
2. Create unified lifecycle state machine
3. Reduce TodayViewModel to 150 lines (presentation only)
4. Reduce TodayView to 2 `@ObservedObject` declarations

#### Week 3: TodayCoordinator Implementation

**Create:** `VeloReady/Features/Today/Coordinators/TodayCoordinator.swift`

```swift
import Foundation
import Combine

/// Coordinates Today feature lifecycle and data fetching
/// 
/// Responsibilities:
/// - Manage app lifecycle (foreground/background, appear/disappear)
/// - Orchestrate data fetching (scores, activities, wellness)
/// - Manage loading states
/// - Coordinate background tasks
@MainActor
class TodayCoordinator: ObservableObject {
    @Published private(set) var state: State = .initial
    @Published private(set) var error: TodayError?
    
    // State machine
    enum State {
        case initial            // Never loaded
        case loading            // First load
        case ready              // Loaded and active
        case background         // App in background
        case refreshing         // Pull-to-refresh or foreground
    }
    
    enum TodayError: Error {
        case networkUnavailable
        case authenticationFailed
        case unknown(String)
    }
    
    // Dependencies
    private let scoresCoordinator: ScoresCoordinator
    private let activitiesCoordinator: ActivitiesCoordinator
    private let services: ServiceContainer
    
    // Lifecycle tracking
    private var hasLoadedOnce = false
    private var isViewActive = false
    
    init(
        scoresCoordinator: ScoresCoordinator,
        activitiesCoordinator: ActivitiesCoordinator,
        services: ServiceContainer = .shared
    ) {
        self.scoresCoordinator = scoresCoordinator
        self.activitiesCoordinator = activitiesCoordinator
        self.services = services
    }
    
    // MARK: - Lifecycle Events
    
    /// Handle lifecycle events through state machine
    func handle(_ event: LifecycleEvent) async {
        Logger.debug("🔄 [TodayCoordinator] Handling event: \(event) - current state: \(state)")
        
        switch (event, state) {
        case (.viewAppeared, .initial):
            // First time view appears
            await loadInitial()
            isViewActive = true
            hasLoadedOnce = true
            
        case (.viewAppeared, _):
            // Subsequent appears
            isViewActive = true
            if shouldRefreshOnAppear() {
                await refresh()
            }
            
        case (.viewDisappeared, _):
            isViewActive = false
            state = .background
            
        case (.appForegrounded, _) where isViewActive:
            // App came to foreground while view is active
            await refresh()
            
        case (.healthKitAuthorized, _):
            // HealthKit was just authorized
            await loadInitial()
            
        case (.pullToRefresh, .ready):
            // User triggered pull-to-refresh
            await refresh()
            
        default:
            Logger.debug("⏭️ [TodayCoordinator] Ignoring event: \(event) in state: \(state)")
        }
    }
    
    enum LifecycleEvent {
        case viewAppeared
        case viewDisappeared
        case appForegrounded
        case healthKitAuthorized
        case pullToRefresh
    }
    
    // MARK: - Data Loading
    
    private func loadInitial() async {
        Logger.debug("🔄 [TodayCoordinator] loadInitial()")
        state = .loading
        
        // Phase 1: Load cached data (instant)
        // This happens in ScoresCoordinator init automatically
        
        // Phase 2: Calculate scores (2-3 seconds)
        await scoresCoordinator.calculateAll()
        
        // Phase 3: Fetch activities (background, non-blocking)
        Task.detached(priority: .background) {
            await self.activitiesCoordinator.fetchRecent(days: 90)
        }
        
        state = .ready
        Logger.debug("✅ [TodayCoordinator] Initial load complete")
    }
    
    private func refresh() async {
        Logger.debug("🔄 [TodayCoordinator] refresh()")
        state = .refreshing
        
        // Refresh scores
        await scoresCoordinator.refresh()
        
        // Refresh activities
        await activitiesCoordinator.fetchRecent(days: 90)
        
        state = .ready
        Logger.debug("✅ [TodayCoordinator] Refresh complete")
    }
    
    private func shouldRefreshOnAppear() -> Bool {
        // Don't refresh if we just loaded
        guard hasLoadedOnce else { return false }
        
        // Refresh if last update was > 5 minutes ago
        // (Implementation depends on your requirements)
        return true
    }
}

/// Coordinates activity fetching from multiple sources
@MainActor
class ActivitiesCoordinator: ObservableObject {
    @Published private(set) var activities: [UnifiedActivity] = []
    @Published private(set) var isLoading = false
    
    private let services: ServiceContainer
    
    init(services: ServiceContainer = .shared) {
        self.services = services
    }
    
    func fetchRecent(days: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        Logger.debug("🔄 [ActivitiesCoordinator] Fetching \(days) days of activities...")
        
        // Fetch from all sources in parallel
        async let intervalsActivities = fetchIntervalsActivities(days: days)
        async let stravaActivities = fetchStravaActivities(days: days)
        async let healthWorkouts = fetchHealthWorkouts(days: days)
        
        let (intervals, strava, health) = await (intervalsActivities, stravaActivities, healthWorkouts)
        
        // Deduplicate and merge
        let deduplicated = services.deduplicationService.deduplicateActivities(
            intervalsActivities: intervals,
            stravaActivities: strava,
            appleHealthActivities: health
        )
        
        // Sort and take top 15
        activities = deduplicated.sorted { $0.startDate > $1.startDate }.prefix(15).map { $0 }
        
        Logger.debug("✅ [ActivitiesCoordinator] Found \(activities.count) activities")
    }
    
    private func fetchIntervalsActivities(days: Int) async -> [UnifiedActivity] {
        do {
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(
                limit: 500,
                daysBack: days
            )
            // Filter out Strava duplicates
            let filtered = activities.filter { !$0.external_id.starts(with: "strava-") }
            return filtered.map { UnifiedActivity(from: $0) }
        } catch {
            Logger.warning("⚠️ [ActivitiesCoordinator] Intervals fetch failed: \(error)")
            return []
        }
    }
    
    private func fetchStravaActivities(days: Int) async -> [UnifiedActivity] {
        await services.stravaDataService.fetchActivities(daysBack: days)
        return services.stravaDataService.activities.map { UnifiedActivity(from: $0) }
    }
    
    private func fetchHealthWorkouts(days: Int) async -> [UnifiedActivity] {
        let workouts = await services.healthKitManager.fetchRecentWorkouts(daysBack: days)
        return workouts.map { UnifiedActivity(from: $0) }
    }
}
```

#### Week 4: Integrate TodayCoordinator

**Update:** `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`

Massively simplify - delegate everything to coordinators:

```swift
@MainActor
class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()
    
    // Coordinators
    private let coordinator: TodayCoordinator
    private let scoresCoordinator: ScoresCoordinator
    private let activitiesCoordinator: ActivitiesCoordinator
    
    // Expose coordinator state
    var coordinatorState: TodayCoordinator.State {
        coordinator.state
    }
    
    var scoresState: ScoresState {
        scoresCoordinator.state
    }
    
    var activities: [UnifiedActivity] {
        activitiesCoordinator.activities
    }
    
    var isInitializing: Bool {
        coordinatorState == .loading
    }
    
    var isLoading: Bool {
        coordinatorState == .refreshing
    }
    
    // UI-specific state
    @Published var animationTrigger = UUID()
    
    private init(container: ServiceContainer = .shared) {
        // Create coordinators
        self.scoresCoordinator = ScoresCoordinator(
            recoveryService: container.recoveryScoreService,
            sleepService: container.sleepScoreService,
            strainService: container.strainScoreService
        )
        
        self.activitiesCoordinator = ActivitiesCoordinator(services: container)
        
        self.coordinator = TodayCoordinator(
            scoresCoordinator: scoresCoordinator,
            activitiesCoordinator: activitiesCoordinator,
            services: container
        )
    }
    
    // MARK: - Public API (delegates to coordinator)
    
    func loadInitialUI() async {
        await coordinator.handle(.viewAppeared)
        animationTrigger = UUID()
    }
    
    func refreshData() async {
        await coordinator.handle(.pullToRefresh)
        animationTrigger = UUID()
    }
    
    func handleAppForeground() async {
        await coordinator.handle(.appForegrounded)
    }
    
    func handleHealthKitAuth() async {
        await coordinator.handle(.healthKitAuthorized)
    }
}
```

**Result:** TodayViewModel reduced from 880 lines to ~150 lines

**Update:** `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

Simplify lifecycle handling:

```swift
struct TodayView: View {
    @ObservedObject private var viewModel = TodayViewModel.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    
    // REMOVED: 7 other @ObservedObject declarations!
    
    @State private var isViewActive = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            // ... UI code ...
        }
        .task {
            // Single lifecycle handler
            await viewModel.loadInitialUI()
            isViewActive = true
        }
        .onDisappear {
            isViewActive = false
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && isViewActive {
                Task {
                    await viewModel.handleAppForeground()
                }
            }
        }
        .onChange(of: healthKitManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                Task {
                    await viewModel.handleHealthKitAuth()
                }
            }
        }
    }
}
```

**Result:** TodayView lifecycle handling reduced from 6 handlers to 4, much simpler logic

**Week 3-4 Deliverables:**
- ✅ TodayCoordinator created (200 lines)
- ✅ ActivitiesCoordinator created (150 lines)
- ✅ TodayViewModel simplified (880 → 150 lines)
- ✅ TodayView simplified (9 → 2 @ObservedObject)
- ✅ Lifecycle state machine implemented
- ✅ All tests passing

---

### **Week 5: Fix LoadingStateManager** 🟢 MEDIUM PRIORITY

#### Goals
1. Convert LoadingStateManager from queue to true state machine
2. Remove throttling/delay logic (let UI handle it)
3. Instant state transitions

**Problem:** LoadingStateManager acts as a queue with minimum display durations, causing lag.

**Current:**
```swift
// Queues states and throttles transitions
func updateState(_ newState: LoadingState) {
    stateQueue.append(newState)
    processQueueIfNeeded()
}

// Waits for minimum display duration
if remaining > 0 {
    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
}
```

**New:**
```swift
// Instant state transitions
func updateState(_ newState: LoadingState) {
    currentState = newState
    Logger.debug("✅ [LoadingState] Now: \(newState)")
}
```

**Update:** `VeloReady/Core/Services/LoadingStateManager.swift`

```swift
import Foundation
import Combine

/// Manages loading state for the app
/// Simple state machine with instant transitions
@MainActor
class LoadingStateManager: ObservableObject {
    @Published private(set) var currentState: LoadingState = .initial
    
    /// Update to a new loading state (instant)
    func updateState(_ newState: LoadingState) {
        let oldState = currentState
        currentState = newState
        
        Logger.debug("🔄 [LoadingState] \(oldState) → \(newState)")
    }
    
    /// Force state (alias for updateState for backwards compatibility)
    func forceState(_ newState: LoadingState) {
        updateState(newState)
    }
    
    /// Reset to initial state
    func reset() {
        updateState(.initial)
    }
}
```

**Week 5 Deliverables:**
- ✅ LoadingStateManager simplified (113 → 20 lines)
- ✅ No more queuing or throttling
- ✅ Instant state transitions
- ✅ UI handles any animation/throttling if needed

---

### **Week 6: Testing, Documentation, Cleanup** ✅

#### Goals
1. Comprehensive integration testing
2. Update documentation
3. Remove deprecated code
4. Performance testing

#### Day 1-2: Integration Testing

**Test scenarios:**
1. Initial app launch (cold start)
2. App backgrounding/foregrounding
3. Pull-to-refresh
4. HealthKit authorization changes
5. Network connectivity changes
6. Error states
7. Concurrent refreshes
8. Memory pressure

#### Day 3: Documentation

**Create:** `TODAY_VIEW_ARCHITECTURE.md`

Document:
- New architecture diagrams
- Data flow
- State machines
- Testing strategy
- How to add new features

#### Day 4: Cleanup

**Remove deprecated code:**
- `RecoveryScoreService.calculateRecoveryScore()` (deprecated method)
- Old loading state logic from TodayViewModel
- Unused @Published properties

**Verify:**
- No compiler warnings
- No linter errors
- All tests passing

#### Day 5: Performance Testing

**Metrics to measure:**
1. Time to first render (should be <100ms)
2. Time to first score display (should be <2s)
3. Memory usage (should be stable)
4. Animation smoothness (60fps)
5. Background task cancellation (no leaks)

**Week 6 Deliverables:**
- ✅ All integration tests passing
- ✅ Documentation complete
- ✅ No deprecated code
- ✅ Performance validated
- ✅ Ready for production

---

## Final Metrics

### Before vs After

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **TodayView @ObservedObject** | 9 | 2 | **-78%** |
| **TodayView Lines** | 570 | 300 | **-47%** |
| **TodayViewModel Lines** | 880 | 150 | **-83%** |
| **RecoveryMetricsSectionViewModel Lines** | 311 | 80 | **-74%** |
| **LoadingStateManager Lines** | 113 | 20 | **-82%** |
| **Loading Boolean Variables** | 10+ | 0 | **-100%** |
| **Lifecycle Handlers in TodayView** | 6 | 4 | **-33%** |
| **Hidden Service Dependencies** | 1 (critical) | 0 | **-100%** |
| **New Files Created** | 0 | 5 | +5 |
| **Total Code Complexity** | Very High | Low | **-70%** |
| **Test Coverage** | ~30% | ~80% | **+167%** |

### New Files Created

1. `Core/Models/ScoresState.swift` (100 lines)
2. `Core/Coordinators/ScoresCoordinator.swift` (150 lines)
3. `Features/Today/Coordinators/TodayCoordinator.swift` (200 lines)
4. `Features/Today/Coordinators/ActivitiesCoordinator.swift` (150 lines)
5. `VeloReadyTests/Unit/ScoresCoordinatorTests.swift` (200 lines)

**Total new code:** ~800 lines  
**Total deleted code:** ~1,200 lines  
**Net reduction:** -400 lines (-25%)

---

## Risk Assessment

### Low Risk ✅
- Score calculation logic unchanged
- Changes are mostly additive (new files)
- Can migrate incrementally (deprecated methods stay)
- Easy rollback (Git branches)
- Comprehensive tests at each phase

### Medium Risk ⚠️
- Need to update all references to scores
- RecoveryMetricsSectionViewModel API changes
- TodayView needs updates
- Migration: Use feature flags if needed

### High Risk ❌
- None identified

---

## Why This Will Work

### 1. Proven Patterns
- **Coordinator Pattern** - Standard iOS pattern, battle-tested
- **Unidirectional Data Flow** - Easier to reason about
- **Value Types for State** - Eliminates entire class of bugs
- **Dependency Injection** - Makes testing trivial

### 2. Incremental Migration
- Week 1: Create new code (doesn't break anything)
- Week 2: Integrate new code (can rollback)
- Week 3-4: Migrate view layer (visible progress)
- Week 5: Optimize (optional)
- Week 6: Polish (ship it)

### 3. Clear Success Criteria
- ✅ Compact rings bug fixed
- ✅ No regressions in functionality
- ✅ Test coverage > 80%
- ✅ Performance same or better
- ✅ Code is simpler (metrics prove it)

### 4. Addresses Root Causes
- ❌ No more hidden dependencies
- ❌ No more state conflicts
- ❌ No more observer hell
- ❌ No more God objects

---

## What NOT to Do

❌ **Don't use TCA** - Overkill, learning curve, vendor lock-in  
❌ **Don't rewrite score services** - They work fine  
❌ **Don't change 64 singletons** - Not the root problem (yet)  
❌ **Don't refactor UI components** - Not the problem  
❌ **Don't add more loading booleans** - Use ScoresState instead  

---

## Decision Time

**This is the balanced, right approach:**

- ✅ Fixes all 4 critical problems
- ✅ 6 weeks (reasonable timeline)
- ✅ Proven patterns (no experiments)
- ✅ Incremental (low risk)
- ✅ Testable (comprehensive tests)
- ✅ Addresses root causes (not band-aids)

**What do you think?**

1. **Approve** - Let's start Week 1
2. **Modify** - What would you change?
3. **Questions** - What needs clarification?

---

## Appendix: Complete Code Examples

### ScoresState.swift (Complete)

See Week 1, Day 1 above.

### ScoresCoordinator.swift (Complete)

See Week 1, Days 2-3 above.

### TodayCoordinator.swift (Complete)

See Week 3 above.

### RecoveryMetricsSectionViewModel.swift (Complete)

See Week 2, Day 1 above.

---

**Ready to begin? Let me know and we'll start Week 1, Day 1.**

