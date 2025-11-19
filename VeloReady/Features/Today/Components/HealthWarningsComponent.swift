import SwiftUI

/// Health Warnings Component (Phase 2 - Component Migration)
///
/// **Component:** Alerts system showing illness, wellness, sleep, and network warnings
///
/// **What it displays:**
/// - Illness indicator (body stress detection - highest priority)
/// - Wellness alert (HRV/RHR/respiratory rate warnings)
/// - Sleep data missing tip (if HealthKit sleep not available)
/// - Network offline indicator (debug/testing)
///
/// **Data Source:** HealthWarningsCardViewModel (observes detection services)
///
/// **Feature Flag:** `component_health_warnings`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, alert accuracy, dismissal rates
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct HealthWarningsComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "health_warnings"
    static let displayName = "Health Warnings"
    static let displayOrder = 100 // In alerts category (after recovery metrics)
    static let featureFlagKey: String? = "component_health_warnings"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [HealthWarningsComponent] body evaluated")

        // Wrap existing HealthWarningsCardV2
        return HealthWarningsCardV2()
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// Health warnings require HealthKit data for illness/wellness detection
    static func shouldRender() -> Bool {
        // First check feature flag (from default implementation)
        if let flagKey = featureFlagKey {
            let isEnabled = FeatureFlags.shared.isEnabled(flagKey)
            Logger.debug("🔌 [Component] \(componentID) feature flag '\(flagKey)': \(isEnabled)")
            if !isEnabled {
                return false
            }
        }

        // Only show when HealthKit is authorized (component needs health data)
        let isAuthorized = HealthKitManager.shared.isAuthorized
        Logger.debug("📦 [HealthWarningsComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct HealthWarningsComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HealthWarningsComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Health Warnings Component")
    }
}
#endif
