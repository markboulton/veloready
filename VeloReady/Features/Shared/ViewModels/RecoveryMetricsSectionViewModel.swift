import SwiftUI
import Combine

/// ViewModel for RecoveryMetricsSection
/// NOW SIMPLIFIED: Uses ScoresCoordinator as single source of truth (Phase 3)
/// OR TodayViewState (Phase 1 V2 Architecture) based on feature flag
///
/// BEFORE (Week 1):
/// - Observed 3 separate services with 6+ @Published properties
/// - 150+ lines of Combine observer setup
/// - Complex loading state management
/// - Manual animation trigger logic
///
/// AFTER (Week 2 - Phase 3):
/// - Observes ScoresCoordinator.state (single source of truth)
/// - ~50 lines of clean observer setup
/// - State management handled by coordinator
/// - Animation logic delegated to ScoresState
///
/// V2 Architecture (Phase 1):
/// - Observes TodayViewState when feature flag enabled
/// - Uses unified state container with cache-first loading
/// - 0ms to cached content goal
///
/// Created: 2025-11-10 (Week 2 Day 1)
/// Part of: Today View Refactoring Plan
@MainActor
@Observable
final class RecoveryMetricsSectionViewModel {
    // MARK: - Published Properties

    private(set) var recoveryScore: RecoveryScore?
    private(set) var sleepScore: SleepScore?
    private(set) var strainScore: StrainScore?
    private(set) var isRecoveryLoading: Bool = false
    private(set) var isSleepLoading: Bool = false
    private(set) var isStrainLoading: Bool = false
    private(set) var allScoresReady: Bool = false
    private(set) var isInitialLoad: Bool = true  // Tracks if this ViewModel has completed first load
    var ringAnimationTrigger = UUID()
    var missingSleepBannerDismissed: Bool {
        didSet {
            UserDefaults.standard.set(missingSleepBannerDismissed, forKey: "missingSleepBannerDismissed")
        }
    }

    // MARK: - Dependencies

    private let coordinator: ScoresCoordinator
    private let todayState = TodayViewState.shared  // V2 Architecture
    private var cancellables = Set<AnyCancellable>()
    private var hasCompletedFirstLoad = false  // Internal flag to track first load completion
    private var lastPhase: ScoresState.Phase = .initial  // Track last phase for animation triggers (Phase 3)
    
    // MARK: - Initialization

    init(coordinator: ScoresCoordinator? = nil) {
        let useV2 = FeatureFlags.shared.useTodayViewV2
        Logger.info("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT (V2: \(useV2))")

        self.coordinator = coordinator ?? ServiceContainer.shared.scoresCoordinator

        // Load banner dismissed state
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")

        if useV2 {
            // V2 Architecture: Initialize from TodayViewState
            Logger.info("🏗️ [VIEWMODEL] Using TodayViewState (V2)")
            initializeFromTodayState()
        } else {
            // Phase 3 Architecture: Initialize from ScoresCoordinator
            Logger.info("🏗️ [VIEWMODEL] Using ScoresCoordinator (Phase 3)")
            initializeFromCoordinator()
        }

        Logger.info("🏗️ [VIEWMODEL] Setting up observers")
        setupObservers()

        Logger.info("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT complete - recovery: \(recoveryScore?.score ?? -1), sleep: \(sleepScore?.score ?? -1), strain: \(strainScore?.score ?? -1)")
    }

    private func initializeFromTodayState() {
        // Initialize from TodayViewState.shared
        let state = todayState

        // Load score objects from Core Data (should be instant/cached)
        loadScoresFromCoreData()

        // Set loading states based on TodayViewState phase
        let isLoading = state.phase.isLoading
        self.isRecoveryLoading = isLoading
        self.isSleepLoading = isLoading
        self.isStrainLoading = isLoading

        // Set allScoresReady based on whether we have core scores
        let hasScores = recoveryScore != nil || sleepScore != nil || strainScore != nil
        self.allScoresReady = hasScores && !isLoading

        // Set isInitialLoad based on whether data is available
        if case .complete = state.phase, hasScores {
            self.isInitialLoad = false
            self.hasCompletedFirstLoad = true
        }

        Logger.info("🔍 [INIT] V2 State - phase: \(state.phase), isLoading: \(isLoading), allReady: \(allScoresReady)")
        Logger.info("🔍 [INIT] V2 Scores - R: \(recoveryScore?.score ?? -1), S: \(sleepScore?.score ?? -1), St: \(strainScore?.score ?? -1)")
    }

    /// Load score objects from coordinator (V2 Architecture)
    /// Force coordinator to refresh to get fresh scores
    private func loadScoresFromCoreData() {
        // V2: Force coordinator to refresh and load latest scores from Core Data
        // This ensures we get the scores that TodayDataLoader just calculated
        Task {
            await coordinator.refresh()
            await MainActor.run {
                let state = coordinator.state
                self.recoveryScore = state.recovery
                self.sleepScore = state.sleep
                self.strainScore = state.strain

                // Update allScoresReady based on loaded scores and current loading state
                let hasScores = state.allCoreScoresAvailable
                let isLoading = todayState.phase.isLoading
                self.allScoresReady = hasScores && !isLoading

                // Handle first load completion
                if hasScores && !self.hasCompletedFirstLoad {
                    self.hasCompletedFirstLoad = true
                    self.isInitialLoad = false
                    self.ringAnimationTrigger = UUID()
                    Logger.info("🎬 [VIEWMODEL] V2 first load complete after score loading - triggering animations")
                }

                Logger.info("📦 [V2] Loaded scores from coordinator - R: \(recoveryScore?.score ?? -1), S: \(sleepScore?.score ?? -1), St: \(strainScore?.score ?? -1), allReady: \(self.allScoresReady)")
            }
        }
    }

    private func initializeFromCoordinator() {
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

        Logger.info("🔍 [INIT] Phase 3 State - phase: \(currentState.phase.description), allCoreScoresAvailable: \(currentState.allCoreScoresAvailable), allScoresReady: \(self.allScoresReady)")
        Logger.info("🔍 [INIT] Phase 3 Scores - R: \(self.recoveryScore?.score ?? -1), S: \(self.sleepScore?.score ?? -1), St: \(self.strainScore?.score ?? -1)")
    }
    
    deinit {
        Logger.debug("🗑️ [VIEWMODEL] RecoveryMetricsSectionViewModel DEINIT - was deinitialized")
    }
    
    // MARK: - Setup

    private func setupObservers() {
        if FeatureFlags.shared.useTodayViewV2 {
            setupV2Observers()
        } else {
            setupPhase3Observers()
        }
    }

    private func setupV2Observers() {
        // Observe TodayViewState for V2 architecture
        Logger.info("🔄 [VIEWMODEL] Setting up V2 observers (TodayViewState)")

        // Observe loading phase - reload scores when data changes
        todayState.$phase
            .sink { [weak self] phase in
                guard let self = self else { return }
                let isLoading = phase.isLoading
                self.isRecoveryLoading = isLoading
                self.isSleepLoading = isLoading
                self.isStrainLoading = isLoading

                // Reload scores from Core Data when phase changes
                if case .complete = phase {
                    self.loadScoresFromCoreData()

                    // Handle initial load completion
                    if !self.hasCompletedFirstLoad {
                        self.hasCompletedFirstLoad = true
                        self.isInitialLoad = false
                        self.ringAnimationTrigger = UUID()
                        Logger.info("🎬 [VIEWMODEL] V2 first load complete - triggering animations")
                    }
                }

                // Update allScoresReady
                let hasScores = self.recoveryScore != nil || self.sleepScore != nil || self.strainScore != nil
                self.allScoresReady = hasScores && !isLoading

                Logger.info("🔄 [VIEWMODEL] V2 phase changed: \(phase), isLoading: \(isLoading), allReady: \(self.allScoresReady)")
            }
            .store(in: &cancellables)

        // Observe lastUpdated to reload scores on refresh
        todayState.$lastUpdated
            .compactMap { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                Logger.info("🔄 [VIEWMODEL] V2 data updated - reloading scores")
                self.loadScoresFromCoreData()
            }
            .store(in: &cancellables)

        // Observe animation trigger from TodayViewState
        todayState.$animationTrigger
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.ringAnimationTrigger = UUID()
                Logger.info("🎬 [VIEWMODEL] V2 animation trigger updated")
            }
            .store(in: &cancellables)

        #if DEBUG
        // Observe sleep simulation toggle
        ProFeatureConfig.shared.$simulateNoSleepData
            .sink { [weak self] simulate in
                guard let self = self else { return }
                if simulate {
                    self.sleepScore = nil
                    Logger.debug("🔄 [VIEWMODEL] V2 Sleep simulation ON - cleared sleep score")
                } else {
                    self.loadScoresFromCoreData()
                    Logger.debug("🔄 [VIEWMODEL] V2 Sleep simulation OFF - reloaded scores")
                }
            }
            .store(in: &cancellables)
        #endif
    }

    private func setupPhase3Observers() {
        // Observe ScoresCoordinator state (Phase 3 architecture)
        Logger.info("🔄 [VIEWMODEL] Setting up Phase 3 observers (ScoresCoordinator)")

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
