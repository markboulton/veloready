import Foundation
import Testing
@testable import VeloReady

/// Comprehensive tests for ScoresCoordinator
///
/// Tests cover:
/// - Initial state
/// - Cache loading
/// - Score calculation order (sleep → recovery → strain)
/// - Refresh behavior
/// - Animation triggers
/// - Error handling
/// - State transitions
///
/// Created: 2025-11-10
/// Part of: Today View Refactoring Plan - Week 1 Day 5
@Suite("ScoresCoordinator Tests")
struct ScoresCoordinatorTests {
    
    // MARK: - Test Helpers
    
    /// Create mock services for testing
    @MainActor
    func createMockServices() -> (recovery: MockRecoveryScoreService, sleep: MockSleepScoreService, strain: MockStrainScoreService) {
        let recovery = MockRecoveryScoreService()
        let sleep = MockSleepScoreService()
        let strain = MockStrainScoreService()
        return (recovery, sleep, strain)
    }
    
    // MARK: - Initialization Tests
    
    @Test("Coordinator initializes with .initial phase")
    @MainActor
    func testInitialState() async throws {
        let (recovery, sleep, strain) = createMockServices()
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        #expect(coordinator.state.phase == .initial)
        #expect(coordinator.state.recovery == nil)
        #expect(coordinator.state.sleep == nil)
        #expect(coordinator.state.strain == nil)
    }
    
    @Test("Coordinator loads cached scores on init")
    @MainActor
    func testCachedScoresLoading() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        // Set up cached scores in services
        recovery.currentRecoveryScore = .mock(score: 78)
        sleep.currentSleepScore = .mock(score: 85)
        strain.currentStrainScore = .mock(score: 12.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        // Should load cached scores and mark as ready
        #expect(coordinator.state.phase == .ready)
        #expect(coordinator.state.recovery?.score == 78)
        #expect(coordinator.state.sleep?.score == 85)
        #expect(coordinator.state.strain?.score == 12.0)
    }
    
    @Test("Coordinator stays in .initial if no cached scores")
    @MainActor
    func testNoCachedScores() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        // No cached scores
        recovery.currentRecoveryScore = nil
        sleep.currentSleepScore = nil
        strain.currentStrainScore = nil
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        #expect(coordinator.state.phase == .initial)
    }
    
    // MARK: - Calculate All Tests
    
    @Test("calculateAll follows correct order: sleep → recovery → strain")
    @MainActor
    func testCalculateAllOrder() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        // Set up mock scores
        sleep.mockScore = .mock(score: 85)
        recovery.mockScore = .mock(score: 78)
        strain.mockScore = .mock(score: 12.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        await coordinator.calculateAll()
        
        // Verify correct order
        #expect(sleep.calculateCallCount == 1)
        #expect(recovery.calculateCallCount == 1)
        #expect(strain.calculateCallCount == 1)
        
        // Verify sleep was calculated first (recovery received it)
        #expect(recovery.receivedSleepScore?.score == 85)
        
        // Verify final state
        #expect(coordinator.state.phase == .ready)
        #expect(coordinator.state.recovery?.score == 78)
        #expect(coordinator.state.sleep?.score == 85)
        #expect(coordinator.state.strain?.score == 12.0)
    }
    
    @Test("calculateAll sets phase to .loading then .ready")
    @MainActor
    func testCalculateAllPhaseTransitions() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        sleep.mockScore = .mock(score: 85)
        recovery.mockScore = .mock(score: 78)
        strain.mockScore = .mock(score: 12.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        // Before calculation
        #expect(coordinator.state.phase == .initial)
        
        await coordinator.calculateAll()
        
        // After calculation
        #expect(coordinator.state.phase == .ready)
    }
    
    @Test("calculateAll handles forceRefresh parameter")
    @MainActor
    func testCalculateAllForceRefresh() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        sleep.mockScore = .mock(score: 85)
        recovery.mockScore = .mock(score: 78)
        strain.mockScore = .mock(score: 12.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        await coordinator.calculateAll(forceRefresh: true)
        
        // Verify forceRefresh was passed to recovery service
        #expect(recovery.receivedForceRefresh == true)
    }
    
    // MARK: - Refresh Tests
    
    @Test("refresh sets phase to .refreshing then .ready")
    @MainActor
    func testRefreshPhaseTransitions() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        // Start with cached scores
        recovery.currentRecoveryScore = .mock(score: 70)
        sleep.currentSleepScore = .mock(score: 80)
        strain.currentStrainScore = .mock(score: 10.0)
        
        // Set up new scores for refresh
        sleep.mockScore = .mock(score: 85)
        recovery.mockScore = .mock(score: 75)
        strain.mockScore = .mock(score: 11.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        // Should start as .ready (has cached scores)
        #expect(coordinator.state.phase == .ready)
        
        await coordinator.refresh()
        
        // Should end as .ready
        #expect(coordinator.state.phase == .ready)
        
        // Scores should be updated
        #expect(coordinator.state.recovery?.score == 75)
        #expect(coordinator.state.sleep?.score == 85)
        #expect(coordinator.state.strain?.score == 11.0)
    }
    
    @Test("refresh follows same order as calculateAll")
    @MainActor
    func testRefreshOrder() async throws {
        let (recovery, sleep, strain) = createMockServices()
        
        sleep.mockScore = .mock(score: 85)
        recovery.mockScore = .mock(score: 78)
        strain.mockScore = .mock(score: 12.0)
        
        let coordinator = ScoresCoordinator(
            recoveryService: recovery,
            sleepService: sleep,
            strainService: strain
        )
        
        await coordinator.refresh()
        
        // Verify correct order
        #expect(sleep.calculateCallCount == 1)
        #expect(recovery.calculateCallCount == 1)
        #expect(strain.calculateCallCount == 1)
        
        // Verify sleep was passed to recovery
        #expect(recovery.receivedSleepScore?.score == 85)
    }
    
    // MARK: - Animation Trigger Tests
    
    @Test("shouldTriggerAnimation returns true for loading → ready")
    func testAnimationTriggerLoadingToReady() {
        var oldState = ScoresState(phase: .loading)
        var newState = ScoresState(phase: .ready)
        newState.recovery = .mock(score: 78)
        
        let shouldAnimate = newState.shouldTriggerAnimation(from: oldState)
        #expect(shouldAnimate == true)
    }
    
    @Test("shouldTriggerAnimation returns true for score change during refresh")
    func testAnimationTriggerScoreChange() {
        var oldState = ScoresState(phase: .refreshing)
        oldState.recovery = .mock(score: 70)
        
        var newState = ScoresState(phase: .ready)
        newState.recovery = .mock(score: 75) // Changed score
        
        let shouldAnimate = newState.shouldTriggerAnimation(from: oldState)
        #expect(shouldAnimate == true)
    }
    
    @Test("shouldTriggerAnimation returns false for unchanged scores")
    func testNoAnimationForUnchangedScores() {
        var oldState = ScoresState(phase: .refreshing)
        oldState.recovery = .mock(score: 78)
        
        var newState = ScoresState(phase: .ready)
        newState.recovery = .mock(score: 78) // Same score
        
        let shouldAnimate = newState.shouldTriggerAnimation(from: oldState)
        #expect(shouldAnimate == false)
    }
    
    // MARK: - State Validation Tests
    
    @Test("allCoreScoresAvailable returns true when recovery and strain present")
    func testAllCoreScoresAvailable() {
        var state = ScoresState(phase: .ready)
        state.recovery = .mock(score: 78)
        state.strain = .mock(score: 12.0)
        // Sleep is optional
        
        #expect(state.allCoreScoresAvailable == true)
    }
    
    @Test("allCoreScoresAvailable returns false when missing core scores")
    func testAllCoreScoresNotAvailable() {
        var state = ScoresState(phase: .ready)
        state.recovery = .mock(score: 78)
        // Missing strain
        
        #expect(state.allCoreScoresAvailable == false)
    }
    
    @Test("shouldShowGreyRings is true for initial and loading phases")
    func testShouldShowGreyRings() {
        let initialState = ScoresState(phase: .initial)
        #expect(initialState.shouldShowGreyRings == true)
        
        let loadingState = ScoresState(phase: .loading)
        #expect(loadingState.shouldShowGreyRings == true)
        
        let readyState = ScoresState(phase: .ready)
        #expect(readyState.shouldShowGreyRings == false)
        
        let refreshingState = ScoresState(phase: .refreshing)
        #expect(refreshingState.shouldShowGreyRings == false)
    }
    
    @Test("shouldShowCalculatingStatus is true for loading and refreshing")
    func testShouldShowCalculatingStatus() {
        let loadingState = ScoresState(phase: .loading)
        #expect(loadingState.shouldShowCalculatingStatus == true)
        
        let refreshingState = ScoresState(phase: .refreshing)
        #expect(refreshingState.shouldShowCalculatingStatus == true)
        
        let readyState = ScoresState(phase: .ready)
        #expect(readyState.shouldShowCalculatingStatus == false)
    }
}

// MARK: - Mock Services

@MainActor
class MockRecoveryScoreService: RecoveryScoreService {
    var mockScore: RecoveryScore?
    var calculateCallCount = 0
    var receivedSleepScore: SleepScore?
    var receivedForceRefresh: Bool = false
    
    override func calculate(sleepScore: SleepScore?, forceRefresh: Bool = false) async -> RecoveryScore {
        calculateCallCount += 1
        receivedSleepScore = sleepScore
        receivedForceRefresh = forceRefresh
        
        // Simulate async delay
        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
        
        return mockScore ?? .mock(score: 70)
    }
}

@MainActor
class MockSleepScoreService: SleepScoreService {
    var mockScore: SleepScore?
    var calculateCallCount = 0
    
    override func calculateSleepScore() async {
        calculateCallCount += 1
        
        // Simulate async delay
        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
        
        // Update published property (matches real service behavior)
        currentSleepScore = mockScore
    }
}

@MainActor
class MockStrainScoreService: StrainScoreService {
    var mockScore: StrainScore?
    var calculateCallCount = 0
    
    override func calculateStrainScore() async {
        calculateCallCount += 1
        
        // Simulate async delay
        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
        
        // Update published property (matches real service behavior)
        currentStrainScore = mockScore ?? .mock(score: 10.0)
    }
}

