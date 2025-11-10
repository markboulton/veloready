import Foundation
import Combine

/// Coordinates all score calculations (Recovery, Sleep, Strain)
/// 
/// **Single source of truth for all three scores.**
///
/// Responsibilities:
/// - Orchestrate score calculation order (sleep → recovery, strain in parallel)
/// - Manage loading states through ScoresState
/// - Provide unified ScoresState to consumers
/// - Handle cache loading
/// - Eliminate hidden dependencies between score services
///
/// **Key Design Decisions:**
/// 1. Sleep MUST be calculated first (recovery depends on it)
/// 2. Recovery and strain are calculated sequentially (not parallel) to avoid race conditions
/// 3. All state updates are atomic (no partial states)
/// 4. Comprehensive logging for debugging
/// 5. Error handling with specific error messages
///
/// Created: 2025-11-10
/// Part of: Today View Refactoring Plan - Week 1
@MainActor
class ScoresCoordinator: ObservableObject {
    @Published private(set) var state = ScoresState(phase: .initial)
    
    // Dependencies (injected for testability)
    private let recoveryService: RecoveryScoreService
    private let sleepService: SleepScoreService
    private let strainService: StrainScoreService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with explicit dependencies
    /// - Parameters:
    ///   - recoveryService: Service for recovery score calculation
    ///   - sleepService: Service for sleep score calculation
    ///   - strainService: Service for strain score calculation
    init(
        recoveryService: RecoveryScoreService,
        sleepService: SleepScoreService,
        strainService: StrainScoreService
    ) {
        self.recoveryService = recoveryService
        self.sleepService = sleepService
        self.strainService = strainService
        
        Logger.info("🎯 [ScoresCoordinator] Initialized")
        
        // Load cached scores immediately for instant display
        loadCachedScores()
    }
    
    // MARK: - Public API
    
    /// Calculate all scores (initial load)
    /// Waits for all scores before marking as ready
    ///
    /// **Flow:**
    /// 1. Set phase to .loading
    /// 2. Calculate sleep FIRST (recovery depends on it)
    /// 3. Calculate recovery WITH sleep as input
    /// 4. Calculate strain (independent)
    /// 5. Set phase to .ready (triggers animation)
    ///
    /// - Parameter forceRefresh: If true, bypass daily calculation limits
    func calculateAll(forceRefresh: Bool = false) async {
        let startTime = Date()
        Logger.info("🔄 [ScoresCoordinator] ━━━ Starting calculateAll(forceRefresh: \(forceRefresh)) ━━━")
        
        let oldState = state
        state.phase = .loading
        
        do {
            // STEP 1: Calculate sleep FIRST (recovery needs it)
            Logger.debug("🔄 [ScoresCoordinator] Step 1/3: Calculating sleep...")
            let sleepStartTime = Date()
            await sleepService.calculateSleepScore()
            let sleepDuration = Date().timeIntervalSince(sleepStartTime)
            let sleep = sleepService.currentSleepScore
            state.sleep = sleep
            Logger.debug("✅ [ScoresCoordinator] Sleep calculated in \(String(format: "%.2f", sleepDuration))s - Score: \(sleep?.score ?? -1)")
            
            // STEP 2: Calculate recovery WITH sleep as input (no more polling!)
            Logger.debug("🔄 [ScoresCoordinator] Step 2/3: Calculating recovery with sleep input...")
            let recoveryStartTime = Date()
            let recovery = await recoveryService.calculate(
                sleepScore: sleep,
                forceRefresh: forceRefresh
            )
            let recoveryDuration = Date().timeIntervalSince(recoveryStartTime)
            state.recovery = recovery
            Logger.debug("✅ [ScoresCoordinator] Recovery calculated in \(String(format: "%.2f", recoveryDuration))s - Score: \(recovery.score), Band: \(recovery.band.rawValue)")
            
            // STEP 3: Calculate strain (independent)
            Logger.debug("🔄 [ScoresCoordinator] Step 3/3: Calculating strain...")
            let strainStartTime = Date()
            await strainService.calculateStrainScore()
            let strainDuration = Date().timeIntervalSince(strainStartTime)
            let strain = strainService.currentStrainScore
            state.strain = strain
            Logger.debug("✅ [ScoresCoordinator] Strain calculated in \(String(format: "%.2f", strainDuration))s - Score: \(strain != nil ? String(format: "%.1f", strain!.score) : "-1")")
            
            // STEP 4: Mark as ready (triggers animation if transitioning from loading)
            state.phase = .ready
            let totalDuration = Date().timeIntervalSince(startTime)
            Logger.debug("✅ [ScoresCoordinator] ━━━ All scores ready in \(String(format: "%.2f", totalDuration))s - phase: .ready ━━━")
            
            // Log animation trigger
            if state.shouldTriggerAnimation(from: oldState) {
                Logger.debug("🎬 [ScoresCoordinator] Animation will be triggered (loading → ready transition)")
            }
            
        } catch {
            let errorMessage = "Failed to calculate scores: \(error.localizedDescription)"
            state.phase = .error(errorMessage)
            Logger.error("❌ [ScoresCoordinator] Score calculation failed: \(error.localizedDescription)")
            Logger.error("❌ [ScoresCoordinator] Error details: \(String(describing: error))")
        }
    }
    
    /// Refresh scores (when app reopened or user pulls to refresh)
    /// Immediately marks as refreshing (keeps existing scores visible)
    ///
    /// **Flow:**
    /// 1. Set phase to .refreshing (keeps scores visible, shows "Calculating")
    /// 2. Calculate sleep, recovery, strain (same order as calculateAll)
    /// 3. Set phase to .ready
    /// 4. Animation triggers for any changed scores
    ///
    /// **Difference from calculateAll:**
    /// - Uses .refreshing phase (no grey rings, shows "Calculating" text)
    /// - Existing scores remain visible during refresh
    /// - Individual score changes trigger animations
    func refresh() async {
        let startTime = Date()
        Logger.debug("🔄 [ScoresCoordinator] ━━━ Starting refresh() ━━━")
        
        let oldState = state
        state.phase = .refreshing
        
        // Same calculation logic but different phase (shows "Calculating" without grey rings)
        Logger.debug("🔄 [ScoresCoordinator] Step 1/3: Refreshing sleep...")
        await sleepService.calculateSleepScore()
        let sleep = sleepService.currentSleepScore
        state.sleep = sleep
        Logger.debug("✅ [ScoresCoordinator] Sleep refreshed - Score: \(sleep?.score ?? -1)")
        
        Logger.debug("🔄 [ScoresCoordinator] Step 2/3: Refreshing recovery...")
        let recovery = await recoveryService.calculate(sleepScore: sleep)
        state.recovery = recovery
        Logger.debug("✅ [ScoresCoordinator] Recovery refreshed - Score: \(recovery.score)")
        
        Logger.debug("🔄 [ScoresCoordinator] Step 3/3: Refreshing strain...")
        await strainService.calculateStrainScore()
        let strain = strainService.currentStrainScore
        state.strain = strain
        Logger.debug("✅ [ScoresCoordinator] Strain refreshed - Score: \(strain != nil ? String(format: "%.1f", strain!.score) : "-1")")
        
        state.phase = .ready
        let totalDuration = Date().timeIntervalSince(startTime)
        Logger.debug("✅ [ScoresCoordinator] ━━━ Scores refreshed in \(String(format: "%.2f", totalDuration))s ━━━")
        
        // Log animation trigger for changed scores
        if state.shouldTriggerAnimation(from: oldState) {
            Logger.debug("🎬 [ScoresCoordinator] Animation will be triggered (score changed during refresh)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Load cached scores from services (instant, no async needed)
    /// Called during initialization for instant UI display
    /// 
    /// **Important:** Even with cached scores, we stay in .initial phase
    /// until the first calculateAll() is called. This ensures the UI has
    /// a chance to display the loading state (grey rings + shimmer).
    private func loadCachedScores() {
        Logger.debug("📦 [ScoresCoordinator] Loading cached scores...")
        
        // Load from service cache (instant, no async needed)
        state.recovery = recoveryService.currentRecoveryScore
        state.sleep = sleepService.currentSleepScore
        state.strain = strainService.currentStrainScore
        
        // ALWAYS stay in .initial phase on startup (even with cached data)
        // This allows the UI to show the loading state properly
        // The phase will transition to .loading → .ready when calculateAll() is called
        state.phase = .initial
        
        if state.allCoreScoresAvailable {
            Logger.debug("✅ [ScoresCoordinator] Loaded cached scores - phase: .initial (waiting for calculateAll)")
            Logger.debug("   Recovery: \(state.recovery?.score ?? -1) (cached)")
            Logger.debug("   Sleep: \(state.sleep?.score ?? -1) (cached)")
            Logger.debug("   Strain: \(state.strain != nil ? String(format: "%.1f", state.strain!.score) : "-1") (cached)")
        } else {
            Logger.debug("⏳ [ScoresCoordinator] Partial/no cached scores - phase: .initial")
            if state.recovery != nil {
                Logger.debug("   Recovery: \(state.recovery!.score) (cached)")
            }
            if state.sleep != nil {
                Logger.debug("   Sleep: \(state.sleep!.score) (cached)")
            }
            if state.strain != nil {
                Logger.debug("   Strain: \(String(format: "%.1f", state.strain!.score)) (cached)")
            }
        }
    }
}

// MARK: - Service Integration Logging

extension ScoresCoordinator {
    /// Log current state for debugging
    func logCurrentState() {
        Logger.debug("📊 [ScoresCoordinator] Current State:")
        Logger.debug(state.debugDescription)
    }
}

// MARK: - Mock Coordinator for Testing

#if DEBUG
extension ScoresCoordinator {
    /// Create a mock coordinator for testing with mock services
    static func mock(
        recoveryService: RecoveryScoreService? = nil,
        sleepService: SleepScoreService? = nil,
        strainService: StrainScoreService? = nil
    ) -> ScoresCoordinator {
        return ScoresCoordinator(
            recoveryService: recoveryService ?? RecoveryScoreService.shared,
            sleepService: sleepService ?? SleepScoreService.shared,
            strainService: strainService ?? StrainScoreService.shared
        )
    }
}
#endif

