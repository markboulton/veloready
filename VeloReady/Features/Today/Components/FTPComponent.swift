import SwiftUI

/// FTP Component (Phase 2 - Component Migration)
///
/// **Component:** Adaptive FTP card showing functional threshold power
///
/// **What it displays:**
/// - Current FTP value in watts
/// - Watts per kilogram (W/kg)
/// - Trend sparkline with RAG coloring
/// - Confidence indicator
///
/// **Data Source:** AdaptiveFTPCardViewModel
///
/// **Feature Flag:** `component_ftp`
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
struct FTPComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "ftp"
    static let displayName = "FTP"
    static let displayOrder = 700 // In performance category
    static let featureFlagKey: String? = "component_ftp"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [FTPComponent] body evaluated")

        // Wrap existing AdaptiveFTPCard
        // Note: onTap closure handled by HapticNavigationLink in TodayView
        return AdaptiveFTPCard(onTap: {})
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// FTP requires activity data from HealthKit
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
        Logger.debug("📦 [FTPComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct FTPComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FTPComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("FTP Component")
    }
}
#endif
