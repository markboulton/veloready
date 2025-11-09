import SwiftUI
import Combine

/// ViewModel for RecoveryMetricsSection
/// Handles three score services, missing sleep banner state, and load score conversion
@MainActor
class RecoveryMetricsSectionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var recoveryScore: RecoveryScore?
    @Published private(set) var sleepScore: SleepScore?
    @Published private(set) var strainScore: StrainScore?
    @Published private(set) var isRecoveryLoading: Bool = false
    @Published private(set) var isSleepLoading: Bool = false
    @Published private(set) var isStrainLoading: Bool = false
    @Published private(set) var allScoresReady: Bool = false // True when all scores are loaded
    @Published var ringAnimationTrigger = UUID() // Triggers ring re-animation when scores change
    @Published var missingSleepBannerDismissed: Bool {
        didSet {
            UserDefaults.standard.set(missingSleepBannerDismissed, forKey: "missingSleepBannerDismissed")
        }
    }
    
    // MARK: - Dependencies
    
    private let recoveryScoreService: RecoveryScoreService
    private let sleepScoreService: SleepScoreService
    private let strainScoreService: StrainScoreService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        recoveryScoreService: RecoveryScoreService = .shared,
        sleepScoreService: SleepScoreService = .shared,
        strainScoreService: StrainScoreService = .shared
    ) {
        Logger.debug("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT starting")
        self.recoveryScoreService = recoveryScoreService
        self.sleepScoreService = sleepScoreService
        self.strainScoreService = strainScoreService
        
        // Load banner dismissed state
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
        
        Logger.debug("🏗️ [VIEWMODEL] Setting up observers for score services")
        setupObservers()
        refreshData()
        Logger.debug("🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT complete - recovery: \(recoveryScore?.score ?? -1), sleep: \(sleepScore?.score ?? -1), strain: \(strainScore?.score ?? -1)")
    }
    
    deinit {
        Logger.debug("🗑️ [VIEWMODEL] RecoveryMetricsSectionViewModel DEINIT - was deinitialized")
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe recovery score
        recoveryScoreService.$currentRecoveryScore
            .sink { [weak self] score in
                Logger.debug("🔄 [VIEWMODEL] Recovery score changed via Combine: \(score?.score ?? -1)")
                self?.recoveryScore = score
                Logger.debug("🔄 [VIEWMODEL] ViewModel recoveryScore now: \(self?.recoveryScore?.score ?? -1)")
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        // Observe recovery loading state
        recoveryScoreService.$isLoading
            .sink { [weak self] loading in
                Logger.debug("🔄 [VIEWMODEL] Recovery loading state changed: \(loading)")
                self?.isRecoveryLoading = loading
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        // Observe sleep score
        sleepScoreService.$currentSleepScore
            .sink { [weak self] score in
                Logger.debug("🔄 [VIEWMODEL] Sleep score changed via Combine: \(score?.score ?? -1)")
                self?.sleepScore = score
                Logger.debug("🔄 [VIEWMODEL] ViewModel sleepScore now: \(self?.sleepScore?.score ?? -1)")
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        // Observe sleep loading state
        sleepScoreService.$isLoading
            .sink { [weak self] loading in
                Logger.debug("🔄 [VIEWMODEL] Sleep loading state changed: \(loading)")
                self?.isSleepLoading = loading
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        // Observe strain score
        strainScoreService.$currentStrainScore
            .receive(on: DispatchQueue.main)  // CRITICAL: Ensure main thread for UI updates
            .sink { [weak self] score in
                print("💪 [VIEWMODEL] Strain score Combine fired: \(score?.score ?? -1)")
                Logger.debug("🔄 [VIEWMODEL] Strain score changed via Combine: \(score?.score ?? -1)")
                let oldScore = self?.strainScore?.score
                self?.strainScore = score
                print("💪 [VIEWMODEL] ViewModel strainScore now: \(self?.strainScore?.score ?? -1)")
                Logger.debug("🔄 [VIEWMODEL] ViewModel strainScore now: \(self?.strainScore?.score ?? -1)")
                
                // Trigger ring animation if score changed (handles cached → real transition)
                if let old = oldScore, let new = score?.score, old != new {
                    print("💪 [VIEWMODEL] Strain score changed from \(old) → \(new), triggering animation")
                    Logger.debug("🎬 [VIEWMODEL] Strain score changed from \(old) → \(new), triggering ring animation")
                    self?.ringAnimationTrigger = UUID()
                }
                
                // CRITICAL: Force allScoresReady = true if we have ANY score
                // This fixes intermittent bug where view renders before checkAllScoresReady() runs
                if score != nil || self?.recoveryScore != nil || self?.sleepScore != nil {
                    print("💪 [VIEWMODEL] FORCING allScoresReady = true (have at least one score)")
                    self?.allScoresReady = true
                }
                
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        // Observe strain loading state
        strainScoreService.$isLoading
            .sink { [weak self] loading in
                Logger.debug("🔄 [VIEWMODEL] Strain loading state changed: \(loading)")
                self?.isStrainLoading = loading
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        
        #if DEBUG
        // Observe sleep simulation toggle to update rings immediately
        ProFeatureConfig.shared.$simulateNoSleepData
            .sink { [weak self] simulate in
                if simulate {
                    // Clear sleep score when simulation is ON
                    self?.sleepScore = nil
                    Logger.debug("🔄 [VIEWMODEL] Sleep simulation ON - cleared sleep score for rings")
                } else {
                    // Restore from service when simulation is OFF
                    self?.sleepScore = self?.sleepScoreService.currentSleepScore
                    Logger.debug("🔄 [VIEWMODEL] Sleep simulation OFF - restored sleep score: \(self?.sleepScore?.score ?? -1)")
                }
                self?.checkAllScoresReady()
            }
            .store(in: &cancellables)
        #endif
    }
    
    /// Check if all scores are ready to display
    /// Shows cached scores immediately on navigation return, only waits for initial load
    /// This prevents rings from disappearing when navigating back to Today page
    private func checkAllScoresReady() {
        // All loading must be complete before showing scores
        let allLoadingComplete = !isRecoveryLoading && !isSleepLoading && !isStrainLoading
        
        // At least one score must exist (could be that sleep has no data, which is OK)
        let hasAnyScore = recoveryScore != nil || sleepScore != nil || strainScore != nil
        
        let wasReady = allScoresReady
        
        print("💪 [VIEWMODEL] checkAllScoresReady - hasAnyScore: \(hasAnyScore), recovery: \(recoveryScore != nil), sleep: \(sleepScore != nil), strain: \(strainScore != nil)")
        print("💪 [VIEWMODEL] checkAllScoresReady - allLoadingComplete: \(allLoadingComplete), wasReady: \(wasReady)")
        
        // FIX: Show scores if we have ANY score, even if still loading
        // This prevents rings from disappearing when navigating back after toggling debug settings
        // Only show loading rings if we have NO scores at all AND still loading
        if hasAnyScore {
            allScoresReady = true
        } else {
            allScoresReady = allLoadingComplete && hasAnyScore
        }
        
        print("💪 [VIEWMODEL] checkAllScoresReady - allScoresReady NOW: \(allScoresReady)")
        
        if !wasReady && allScoresReady {
            print("💪 [VIEWMODEL] ✅ All scores ready!")
            Logger.debug("✅ [VIEWMODEL] All scores ready - recovery: \(recoveryScore?.score ?? -1), sleep: \(sleepScore?.score ?? -1), strain: \(strainScore?.score ?? -1)")
        } else if !allLoadingComplete {
            Logger.debug("⏳ [VIEWMODEL] Still loading - recovery: \(isRecoveryLoading), sleep: \(isSleepLoading), strain: \(isStrainLoading)")
        }
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        Logger.debug("🔄 [VIEWMODEL] refreshData() called")
        Logger.debug("🔄 [VIEWMODEL] Service scores - recovery: \(recoveryScoreService.currentRecoveryScore?.score ?? -1), sleep: \(sleepScoreService.currentSleepScore?.score ?? -1), strain: \(strainScoreService.currentStrainScore?.score ?? -1)")
        recoveryScore = recoveryScoreService.currentRecoveryScore
        sleepScore = sleepScoreService.currentSleepScore
        strainScore = strainScoreService.currentStrainScore
        isRecoveryLoading = recoveryScoreService.isLoading
        isSleepLoading = sleepScoreService.isLoading
        isStrainLoading = strainScoreService.isLoading
        checkAllScoresReady()
        Logger.debug("🔄 [VIEWMODEL] After refresh - recovery: \(recoveryScore?.score ?? -1), sleep: \(sleepScore?.score ?? -1), strain: \(strainScore?.score ?? -1), loading states: R=\(isRecoveryLoading), S=\(isSleepLoading), St=\(isStrainLoading)")
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
        guard let score = sleepScore else { return false }
        return score.inputs.sleepDuration != nil && score.inputs.sleepDuration != 0
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
