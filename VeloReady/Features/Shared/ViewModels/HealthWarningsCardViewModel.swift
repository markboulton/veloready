import SwiftUI
import Combine

/// ViewModel for HealthWarningsCardV2
/// Handles illness and wellness alert logic, filtering, and state
@MainActor
class HealthWarningsCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var illnessIndicator: IllnessIndicator?
    @Published private(set) var wellnessAlert: WellnessAlert?
    @Published var showingIllnessDetail: Bool = false
    @Published var showingWellnessDetail: Bool = false
    
    // MARK: - Dependencies
    
    private let illnessService: IllnessDetectionService
    private let wellnessService: WellnessDetectionService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        illnessService: IllnessDetectionService = .shared,
        wellnessService: WellnessDetectionService = .shared
    ) {
        self.illnessService = illnessService
        self.wellnessService = wellnessService
        
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
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        illnessIndicator = illnessService.currentIndicator
        wellnessAlert = wellnessService.currentAlert
    }
    
    func showIllnessDetail() {
        HapticFeedback.light()
        showingIllnessDetail = true
    }
    
    func showWellnessDetail() {
        HapticFeedback.light()
        showingWellnessDetail = true
    }
    
    // MARK: - Computed Properties
    
    var hasWarnings: Bool {
        hasIllnessWarning || hasWellnessAlert
    }
    
    var hasIllnessWarning: Bool {
        illnessIndicator?.isSignificant ?? false
    }
    
    var hasWellnessAlert: Bool {
        wellnessAlert != nil
    }
    
    var hasBothWarnings: Bool {
        hasIllnessWarning && hasWellnessAlert
    }
    
    var title: String {
        hasIllnessWarning ? "Body Stress Detected" : "Health Alerts"
    }
    
    var severityBadge: CardHeader.Badge? {
        if let indicator = illnessIndicator, indicator.isSignificant {
            let style: VRBadge.Style = indicator.severity == .high ? .error : 
                                        indicator.severity == .moderate ? .warning : .info
            return .init(text: indicator.severity.rawValue.uppercased(), style: style)
        } else if let alert = wellnessAlert {
            return .init(text: alert.severity.rawValue.uppercased(), style: .warning)
        }
        return nil
    }
    
    var warningIcon: String {
        if let indicator = illnessIndicator, indicator.isSignificant {
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
