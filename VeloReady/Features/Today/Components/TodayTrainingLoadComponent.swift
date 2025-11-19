import SwiftUI

/// Training Load Component (Phase 2 - Component Migration)
///
/// **Component:** Training load graph showing CTL, ATL, TSB with 7-day projection
///
/// **What it displays:**
/// - 14 days historical training load data
/// - CTL (Chronic Training Load / Fitness)
/// - ATL (Acute Training Load / Fatigue)
/// - TSB (Training Stress Balance / Form)
/// - 7-day future projection with decay
///
/// **Data Source:** TrainingLoadGraphCardViewModel
/// - Attempts Intervals.icu/Wahoo data from Core Data first
/// - Falls back to progressive calculation from activities
/// - Smart baseline seeding from most recent data
///
/// **Feature Flag:** `component_training_load`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, calculation performance, data accuracy
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct TodayTrainingLoadComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "training_load"
    static let displayName = "Training Load"
    static let displayOrder = 400 // In performance category
    static let featureFlagKey: String? = "component_training_load"

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [TodayTrainingLoadComponent] body evaluated")

        // Wrap existing TrainingLoadGraphCard
        return TrainingLoadGraphCard()
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// Training load requires activity data from HealthKit
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
        Logger.debug("📦 [TodayTrainingLoadComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct TodayTrainingLoadComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TodayTrainingLoadComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Today Training Load Component")
    }
}
#endif
