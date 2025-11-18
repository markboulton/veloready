import SwiftUI
import Combine

/// ViewModel for RecoveryMetricsSection
/// NOW SIMPLIFIED: Uses ScoresCoordinator as single source of truth
/// 
/// BEFORE (Week 1):
/// - Observed 3 separate services with 6+ @Published properties
/// - 150+ lines of Combine observer setup
/// - Complex loading state management
/// - Manual animation trigger logic
/// 
/// AFTER (Week 2):
/// - Observes ScoresCoordinator.state (single source of truth)
/// - ~50 lines of clean observer setup
/// - State management handled by coordinator
/// - Animation logic delegated to ScoresState
///
/// Created: 2025-11-10 (Week 2 Day 1)
/// Part of: Today View Refactoring Plan
@MainActor
class RecoveryMetricsSectionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var recoveryScore: RecoveryScore?
    @Published private(set) var sleepScore: SleepScore?
    @Published private(set) var strainScore: StrainScore?
    @Published private(set) var isRecoveryLoading: Bool = false
    @Published private(set) var isSleepLoading: Bool = false
    @Published private(set) var isStrainLoading: Bool = false
    @Published private(set) var allScoresReady: Bool = false
    @Published private(set) var isInitialLoad: Bool = true  // Tracks if this ViewModel has completed first load
    @Published var ringAnimationTrigger = UUID()
    @Published var missingSleepBannerDismissed: Bool {
        didSet {
            UserDefaults.standard.set(missingSleepBannerDismissed, forKey: "missingSleepBannerDismissed")
        }
    }
    
    // MARK: - Dependencies (NEW: ScoresCoordinator replaces 3 services)
    
    private let coordinator: ScoresCoordinator
    private var cancellables = Set<AnyCancellable>()
    private var hasCompletedFirstLoad = false  // Internal flag to track first load completion
    private var lastPhase: ScoresState.Phase = .initial  // Track last phase for animation triggers
    
    // MARK: - Initialization
    
    init(coordinator: ScoresCoordinator? = nil) {
        Logger.info("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT (Week 2 - using ScoresCoordinator)")
        self.coordinator = coordinator ?? ServiceContainer.shared.scoresCoordinator
        
        // Load banner dismissed state
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
        
        // CRITICAL: Force synchronous read of coordinator state BEFORE setting up observers
        // This ensures we capture the current state atomically before any async updates
        let currentState = self.coordinator.state

        // Initialize scores from coordinator's current state
        self.recoveryScore = currentState.recovery
        self.sleepScore = currentState.sleep
        self.strainScore = currentState.strain

        // Initialize allScoresReady immediately to prevent flash
        self.allScoresReady = (currentState.phase == .ready || currentState.phase == .refreshing) && currentState.allCoreScoresAvailable

        // Initialize isInitialLoad based on whether we have scores
        if currentState.allCoreScoresAvailable && currentState.phase == .ready {
            self.isInitialLoad = false
            self.hasCompletedFirstLoad = true
        }

        print("🔍 [INIT] Initial state - phase: \(currentState.phase.description), allCoreScoresAvailable: \(currentState.allCoreScoresAvailable), allScoresReady: \(self.allScoresReady)")
        print("🔍 [INIT] Scores - R: \(self.recoveryScore?.score ?? -1), S: \(self.sleepScore?.score ?? -1), St: \(self.strainScore?.score ?? -1)")

        Logger.info("🏗️ [VIEWMODEL] Setting up observer for ScoresCoordinator.state")
        setupObservers()
        // Don't call updateFromState here - we already initialized from current state above
        
        Logger.info("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT complete - recovery: \(recoveryScore?.score ?? -1), sleep: \(sleepScore?.score ?? -1), strain: \(strainScore?.score ?? -1)")
    }
    
    deinit {
        Logger.debug("🗑️ [VIEWMODEL] RecoveryMetricsSectionViewModel DEINIT - was deinitialized")
    }
    
    // MARK: - Setup (NEW: 90% reduction from 150+ lines to ~20 lines)
    
    private func setupObservers() {
        // Observe ScoresCoordinator state (single source of truth)
        coordinator.$state
            .sink { [weak self] newState in
                guard let self = self else { return }
                
                let oldState = ScoresState(
                    recovery: self.recoveryScore,
                    sleep: self.sleepScore,
                    strain: self.strainScore,
                    phase: self.lastPhase  // ✅ FIX: Use actual last phase, not new phase!
                )
                
                Logger.info("🔄 [VIEWMODEL] ScoresCoordinator state changed - OLD phase: \(self.lastPhase.description), NEW phase: \(newState.phase.description)")
                
                // Update scores and loading states
                self.updateFromState(newState)
                
                // Handle animation triggers (logic from ScoresState)
                Logger.info("🎬 [VIEWMODEL] Checking if animation should trigger - oldPhase: \(self.lastPhase.description), newPhase: \(newState.phase.description)")
                if newState.shouldTriggerAnimation(from: oldState) {
                    Logger.info("🎬 [VIEWMODEL] ✅ Animation WILL trigger - updating ringAnimationTrigger UUID")
                    let oldUUID = self.ringAnimationTrigger
                    self.ringAnimationTrigger = UUID()
                    Logger.info("🎬 [VIEWMODEL] ringAnimationTrigger changed: \(oldUUID) → \(self.ringAnimationTrigger)")
                } else {
                    Logger.info("🎬 [VIEWMODEL] ❌ Animation will NOT trigger")
                }
                
                // Update last phase for next comparison
                self.lastPhase = newState.phase
            }
            .store(in: &cancellables)
        
        #if DEBUG
        // Observe sleep simulation toggle to update rings immediately
        ProFeatureConfig.shared.$simulateNoSleepData
            .sink { [weak self] simulate in
                if simulate {
                    self?.sleepScore = nil
                    Logger.debug("🔄 [VIEWMODEL] Sleep simulation ON - cleared sleep score for rings")
                } else {
                    self?.sleepScore = self?.coordinator.state.sleep
                    Logger.debug("🔄 [VIEWMODEL] Sleep simulation OFF - restored sleep score: \(self?.sleepScore?.score ?? -1)")
                }
            }
            .store(in: &cancellables)
        #endif
    }
    
    // MARK: - State Management (NEW: Single method replaces checkAllScoresReady + refreshData)
    
    /// Update ViewModel properties from ScoresCoordinator state
    /// This replaces the old checkAllScoresReady() and refreshData() logic
    private func updateFromState(_ state: ScoresState) {
        // Update scores
        recoveryScore = state.recovery
        sleepScore = state.sleep
        strainScore = state.strain
        
        // Update loading states from phase
        let isLoading = state.isLoading
        isRecoveryLoading = isLoading
        isSleepLoading = isLoading
        isStrainLoading = isLoading
        
        // Update isInitialLoad: stay true until first .ready transition
        // This ensures grey rings + shimmer show on first load, even with cached data
        if state.phase == .ready && !hasCompletedFirstLoad {
            hasCompletedFirstLoad = true
            isInitialLoad = false
            Logger.info("🎯 [VIEWMODEL] First load completed - isInitialLoad now false")
        } else if state.phase == .loading && !hasCompletedFirstLoad {
            isInitialLoad = true  // Ensure we stay in initial load mode during first calculation
            Logger.info("🔄 [VIEWMODEL] First load in progress - isInitialLoad remains true")
        }
        
        // Update allScoresReady based on phase
        allScoresReady = (state.phase == .ready || state.phase == .refreshing) && state.allCoreScoresAvailable
        
        Logger.info("📊 [VIEWMODEL] State updated - phase: \(state.phase.description), isInitialLoad: \(isInitialLoad), hasCompletedFirstLoad: \(hasCompletedFirstLoad), allReady: \(allScoresReady), scores: R=\(recoveryScore?.score ?? -1) S=\(sleepScore?.score ?? -1) St=\(strainScore?.score ?? -1)")
    }
    
    // MARK: - Public Methods
    
    /// Refresh scores (delegates to coordinator)
    func refreshData() {
        Logger.debug("🔄 [VIEWMODEL] refreshData() - delegating to ScoresCoordinator")
        Task {
            await coordinator.refresh()
        }
    }
    
    func reinstateSleepBanner() {
        missingSleepBannerDismissed = false
    }
    
    // MARK: - Recovery Score Helpers
    
    var hasRecoveryScore: Bool {
        recoveryScore != nil
    }
    
    var recoveryTitle: String {
        guard let score = recoveryScore else { return "" }
        // Show actual band description even without sleep data
        // The rebalanced algorithm still provides accurate recovery assessment
        return score.bandDescription
    }
    
    var recoveryScoreValue: Int? {
        recoveryScore?.score
    }
    
    var recoveryBand: RecoveryScore.RecoveryBand? {
        recoveryScore?.band
    }
    
    // MARK: - Sleep Score Helpers
    
    var hasSleepScore: Bool {
        sleepScore != nil
    }
    
    var hasSleepData: Bool {
        guard let score = sleepScore else {
            print("🔍 [hasSleepData] No sleep score - returning false")
            return false
        }
        // If we have a valid sleep score (0-100), we have sleep data
        // This prevents flash when cached scores don't have full inputs populated yet
        if score.score >= 0 && score.score <= 100 {
            print("🔍 [hasSleepData] Valid score \(score.score) - returning true")
            return true
        }
        // Fallback: check if inputs are available (for edge cases)
        let hasInputs = score.inputs.sleepDuration != nil && score.inputs.sleepDuration != 0
        print("🔍 [hasSleepData] Score \(score.score) out of range, checking inputs: \(hasInputs)")
        return hasInputs
    }
    
    var sleepTitle: String {
        if !hasSleepData {
            return missingSleepBannerDismissed ? TodayContent.noDataInfo : TodayContent.noData
        }
        return sleepScore?.bandDescription ?? ""
    }
    
    var sleepScoreValue: Int? {
        hasSleepData ? sleepScore?.score : nil
    }
    
    var sleepBand: SleepScore.SleepBand {
        sleepScore?.band ?? .payAttention
    }
    
    var shouldShowSleepChevron: Bool {
        hasSleepData || !missingSleepBannerDismissed
    }
    
    // MARK: - Load/Strain Score Helpers
    
    var hasStrainScore: Bool {
        strainScore != nil
    }
    
    var strainTitle: String {
        strainScore?.bandDescription ?? ""
    }
    
    var strainScoreValue: Double? {
        strainScore?.score
    }
    
    var strainBand: StrainScore.StrainBand? {
        strainScore?.band
    }
    
    var strainFormattedScore: String {
        strainScore?.formattedScore ?? ""
    }
    
    /// Converts strain score (0-18) to ring percentage (0-100)
    var strainRingScore: Int {
        guard let score = strainScore?.score else { return 0 }
        return Int((Double(score) / 18.0) * 100.0)
    }
}
