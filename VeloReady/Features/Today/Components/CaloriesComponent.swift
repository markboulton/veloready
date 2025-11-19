import SwiftUI

/// Calories Component (Phase 2 - Component Migration)
///
/// **Component:** Daily calorie tracking with active/BMR breakdown visualization
///
/// **What it displays:**
/// - Total calories burned (active + BMR)
/// - Daily goal with progress percentage
/// - Achievement badge (if goal met)
/// - Breakdown chart showing active vs BMR calories (right side)
///
/// **Data Source:** CaloriesCardViewModel (loads from HealthKit)
///
/// **Feature Flag:** `component_calories`
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
struct CaloriesComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "calories"
    static let displayName = "Calories"
    static let displayOrder = 600 // In lifestyle category (after steps)
    static let featureFlagKey: String? = "component_calories"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [CaloriesComponent] body evaluated")

        // Wrap existing CaloriesCardV2
        return CaloriesCardV2()
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// Calories require HealthKit data
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
        Logger.debug("📦 [CaloriesComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct CaloriesComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CaloriesComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Calories Component")
    }
}
#endif
