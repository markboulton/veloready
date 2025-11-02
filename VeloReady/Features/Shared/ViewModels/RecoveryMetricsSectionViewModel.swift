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
    @Published private(set) var isSleepLoading: Bool = false
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
        self.recoveryScoreService = recoveryScoreService
        self.sleepScoreService = sleepScoreService
        self.strainScoreService = strainScoreService
        
        // Load banner dismissed state
        self.missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
        
        setupObservers()
        refreshData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe recovery score
        recoveryScoreService.$currentRecoveryScore
            .sink { [weak self] score in
                self?.recoveryScore = score
            }
            .store(in: &cancellables)
        
        // Observe sleep score
        sleepScoreService.$currentSleepScore
            .sink { [weak self] score in
                self?.sleepScore = score
            }
            .store(in: &cancellables)
        
        // Observe sleep loading state
        sleepScoreService.$isLoading
            .sink { [weak self] loading in
                self?.isSleepLoading = loading
            }
            .store(in: &cancellables)
        
        // Observe strain score
        strainScoreService.$currentStrainScore
            .sink { [weak self] score in
                self?.strainScore = score
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        recoveryScore = recoveryScoreService.currentRecoveryScore
        sleepScore = sleepScoreService.currentSleepScore
        strainScore = strainScoreService.currentStrainScore
        isSleepLoading = sleepScoreService.isLoading
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
        return score.inputs.sleepDuration == nil ? TodayContent.limitedData : score.bandDescription
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
