import SwiftUI

/// Steps Component (Phase 2 - Component Migration)
///
/// **Component:** Daily steps tracking with hourly sparkline visualization
///
/// **What it displays:**
/// - Total steps count with goal progress
/// - Distance walked (if available)
/// - Hourly steps sparkline chart (right side)
///
/// **Data Source:** StepsCardViewModel (loads from HealthKit)
///
/// **Feature Flag:** `component_steps`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, HealthKit read performance, chart rendering accuracy
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct StepsComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "steps"
    static let displayName = "Steps"
    static let displayOrder = 500 // In lifestyle category
    static let featureFlagKey: String? = "component_steps"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [StepsComponent] body evaluated")

        // Wrap existing StepsCardV2
        return StepsCardV2()
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// Steps require HealthKit data
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
        Logger.debug("📦 [StepsComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct StepsComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StepsComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Steps Component")
    }
}
#endif
