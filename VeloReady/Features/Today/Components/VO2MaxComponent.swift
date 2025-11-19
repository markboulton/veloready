import SwiftUI

/// VO2Max Component (Phase 2 - Component Migration)
///
/// **Component:** Adaptive VO₂ Max card showing aerobic capacity
///
/// **What it displays:**
/// - Current VO₂ Max value (ml/kg/min)
/// - Fitness level classification
/// - Trend sparkline with RAG coloring
/// - Confidence indicator
///
/// **Data Source:** AdaptiveVO2MaxCardViewModel
///
/// **Feature Flag:** `component_vo2max`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, calculation accuracy, navigation functionality
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct VO2MaxComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "vo2max"
    static let displayName = "VO2Max"
    static let displayOrder = 800 // In performance category (after FTP)
    static let featureFlagKey: String? = "component_vo2max"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [VO2MaxComponent] body evaluated")

        // Wrap existing AdaptiveVO2MaxCard
        // Note: onTap closure handled by HapticNavigationLink in TodayView
        return AdaptiveVO2MaxCard(onTap: {})
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// VO2Max requires activity data from HealthKit
    static func shouldRender() -> Bool {
        // First check feature flag (from default implementation)
        if let flagKey = featureFlagKey {
            let isEnabled = FeatureFlags.shared.isEnabled(flagKey)
            Logger.debug("🔌 [Component] \(componentID) feature flag '\(flagKey)': \(isEnabled)")
            if !isEnabled {
                return false
            }
        }

        // Only show when HealthKit is authorized (component needs activity data)
        let isAuthorized = HealthKitManager.shared.isAuthorized
        Logger.debug("📦 [VO2MaxComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct VO2MaxComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VO2MaxComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("VO2Max Component")
    }
}
#endif
