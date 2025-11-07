import SwiftUI
import Combine

/// ViewModel for HealthWarningsCardV2
/// Handles illness and wellness alert logic, filtering, and state
@MainActor
class HealthWarningsCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var illnessIndicator: IllnessIndicator?
    @Published private(set) var wellnessAlert: WellnessAlert?
    @Published private(set) var hasSleepData: Bool = true
    @Published private(set) var isNetworkOffline: Bool = false
    @Published var showingIllnessDetail: Bool = false
    @Published var showingWellnessDetail: Bool = false
    @Published private(set) var sleepDataWarningDismissed: Bool = false
    
    // MARK: - Dependencies
    
    private let illnessService: IllnessDetectionService
    private let wellnessService: WellnessDetectionService
    private let sleepScoreService: SleepScoreService
    private let proConfig = ProFeatureConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        illnessService: IllnessDetectionService = .shared,
        wellnessService: WellnessDetectionService = .shared,
        sleepScoreService: SleepScoreService = .shared
    ) {
        self.illnessService = illnessService
        self.wellnessService = wellnessService
        self.sleepScoreService = sleepScoreService
        
        // Check if warning should reappear (every 7 days)
        self.sleepDataWarningDismissed = checkSleepWarningDismissalStatus()
        
        setupObservers()
        refreshData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe illness indicators
        illnessService.$currentIndicator
            .sink { [weak self] indicator in
                self?.illnessIndicator = indicator
            }
            .store(in: &cancellables)
        
        // Observe wellness alerts
        wellnessService.$currentAlert
            .sink { [weak self] alert in
                self?.wellnessAlert = alert
            }
            .store(in: &cancellables)
        
        // Observe sleep score to track if data is available
        sleepScoreService.$currentSleepScore
            .sink { [weak self] sleepScore in
                #if DEBUG
                // Check if we're simulating no sleep data
                if ProFeatureConfig.shared.simulateNoSleepData {
                    self?.hasSleepData = false
                    return
                }
                #endif
                
                // Check if sleep score exists and has actual sleep data
                if let score = sleepScore {
                    self?.hasSleepData = score.inputs.sleepDuration != nil
                } else {
                    self?.hasSleepData = false
                }
            }
            .store(in: &cancellables)
        
        #if DEBUG
        // Observe simulateNoSleepData flag
        proConfig.$simulateNoSleepData
            .dropFirst()
            .sink { [weak self] simulate in
                if simulate {
                    self?.hasSleepData = false
                } else {
                    // Refresh from actual sleep score
                    if let score = self?.sleepScoreService.currentSleepScore {
                        self?.hasSleepData = score.inputs.sleepDuration != nil
                    } else {
                        self?.hasSleepData = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe simulateNoNetwork flag
        proConfig.$simulateNoNetwork
            .sink { [weak self] simulate in
                self?.isNetworkOffline = simulate
            }
            .store(in: &cancellables)
        #endif
        
        #if DEBUG
        // Observe testing feature flags and trigger analysis when they change
        proConfig.$showWellnessWarningForTesting
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.wellnessService.analyzeHealthTrends()
                }
            }
            .store(in: &cancellables)
        
        proConfig.$showIllnessIndicatorForTesting
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.illnessService.analyzeHealthTrends(forceRefresh: true)
                }
            }
            .store(in: &cancellables)
        
        // Observe notification to refresh health warnings (e.g., from debug toggles)
        NotificationCenter.default.publisher(for: .refreshHealthWarnings)
            .sink { [weak self] _ in
                // Re-check dismissal status from UserDefaults
                self?.sleepDataWarningDismissed = self?.checkSleepWarningDismissalStatus() ?? false
                self?.refreshData()
                Logger.debug("🔄 [HealthWarnings] Refreshed after notification")
            }
            .store(in: &cancellables)
        #endif
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        illnessIndicator = illnessService.currentIndicator
        wellnessAlert = wellnessService.currentAlert
        
        #if DEBUG
        isNetworkOffline = proConfig.simulateNoNetwork
        
        if proConfig.simulateNoSleepData {
            hasSleepData = false
        } else {
            if let score = sleepScoreService.currentSleepScore {
                hasSleepData = score.inputs.sleepDuration != nil
            } else {
                hasSleepData = false
            }
        }
        #else
        if let score = sleepScoreService.currentSleepScore {
            hasSleepData = score.inputs.sleepDuration != nil
        } else {
            hasSleepData = false
        }
        #endif
    }
    
    func showIllnessDetail() {
        HapticFeedback.light()
        showingIllnessDetail = true
    }
    
    func showWellnessDetail() {
        HapticFeedback.light()
        showingWellnessDetail = true
    }
    
    func dismissSleepDataWarning() {
        HapticFeedback.light()
        sleepDataWarningDismissed = true
        // Store dismissal timestamp instead of boolean
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "sleepDataWarningDismissedAt")
        Logger.debug("🚫 Sleep data warning dismissed - will reappear in 7 days")
    }
    
    /// Check if sleep warning should be shown based on dismissal timer
    /// Returns false if dismissed within last 7 days, true otherwise
    private func checkSleepWarningDismissalStatus() -> Bool {
        let dismissedAt = UserDefaults.standard.double(forKey: "sleepDataWarningDismissedAt")
        
        // If never dismissed, show warning
        guard dismissedAt > 0 else {
            return false
        }
        
        let dismissedDate = Date(timeIntervalSince1970: dismissedAt)
        let daysSinceDismissal = Calendar.current.dateComponents([.day], from: dismissedDate, to: Date()).day ?? 0
        
        // Show warning again after 7 days
        let shouldShow = daysSinceDismissal >= 7
        
        if shouldShow {
            Logger.debug("⏰ Sleep warning timer expired (\(daysSinceDismissal) days) - showing again")
        } else {
            Logger.debug("⏰ Sleep warning dismissed \(daysSinceDismissal) days ago - hiding for \(7 - daysSinceDismissal) more days")
        }
        
        return !shouldShow // Return true if should be dismissed (hidden)
    }
    
    // MARK: - Computed Properties
    
    var hasWarnings: Bool {
        hasIllnessWarning || hasWellnessAlert || !hasSleepData || isNetworkOffline
    }
    
    var hasIllnessWarning: Bool {
        guard let indicator = illnessIndicator else { return false }
        // Only show if significant AND recent (within last 24 hours)
        return indicator.isSignificant && indicator.isRecent
    }
    
    var hasWellnessAlert: Bool {
        wellnessAlert != nil
    }
    
    var hasBothWarnings: Bool {
        hasIllnessWarning && hasWellnessAlert
    }
    
    var warningCount: Int {
        var count = 0
        if hasIllnessWarning { count += 1 }
        if hasWellnessAlert { count += 1 }
        if !hasSleepData { count += 1 }
        if isNetworkOffline { count += 1 }
        return count
    }
    
    var hasSingleWarning: Bool {
        warningCount == 1
    }
    
    var title: String {
        hasIllnessWarning ? "Body Stress Detected" : "Health Alerts"
    }
    
    var severityBadge: CardHeader.Badge? {
        if let indicator = illnessIndicator, indicator.isSignificant && indicator.isRecent {
            let style: VRBadge.Style = indicator.severity == .high ? .error : 
                                        indicator.severity == .moderate ? .warning : .info
            return .init(text: indicator.severity.rawValue.uppercased(), style: style)
        } else if let alert = wellnessAlert {
            return .init(text: alert.severity.rawValue.uppercased(), style: .warning)
        }
        return nil
    }
    
    var warningIcon: String {
        if let indicator = illnessIndicator, indicator.isSignificant && indicator.isRecent {
            return indicator.severity.icon
        } else if let alert = wellnessAlert {
            return alert.severity.icon
        }
        return Icons.Status.warningFill
    }
    
    // MARK: - Illness Helper Methods
    
    func illnessRecommendation() -> String? {
        illnessIndicator?.recommendation
    }
    
    func illnessSignals() -> [IllnessIndicator.Signal] {
        illnessIndicator?.signals ?? []
    }
    
    func topIllnessSignals(limit: Int = 3) -> [IllnessIndicator.Signal] {
        Array(illnessSignals().prefix(limit))
    }
    
    func hasMoreIllnessSignals(than limit: Int = 3) -> Bool {
        illnessSignals().count > limit
    }
    
    func extraIllnessSignalsCount(beyond limit: Int = 3) -> Int {
        max(0, illnessSignals().count - limit)
    }
    
    // MARK: - Wellness Helper Methods
    
    func wellnessTitle() -> String? {
        wellnessAlert?.type.title
    }
    
    func wellnessBannerMessage() -> String? {
        wellnessAlert?.bannerMessage
    }
    
    func wellnessMetrics() -> WellnessAlert.AffectedMetrics? {
        wellnessAlert?.metrics
    }
}
