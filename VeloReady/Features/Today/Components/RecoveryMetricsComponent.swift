import SwiftUI

/// Recovery Metrics Component (Phase 2 - Component Migration)
///
/// **Component:** First migrated component - wraps RecoveryMetricsSection (3 rings)
///
/// **What it displays:**
/// - Recovery score ring (0-100)
/// - Sleep score ring (0-100)
/// - Load/Strain score ring (0-10+)
///
/// **Data Source:** TodayViewState.shared
///
/// **Feature Flag:** `component_recovery_metrics`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, load time, UI parity
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct RecoveryMetricsComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "recovery_metrics"
    static let displayName = "Recovery Metrics"
    static let displayOrder = 0 // First component (top of Today view)
    static let featureFlagKey: String? = "component_recovery_metrics"

    // MARK: - State

    @ObservedObject private var todayState = TodayViewState.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [RecoveryMetricsComponent] body evaluated")

        // Wrap existing RecoveryMetricsSection with state from TodayViewState
        return RecoveryMetricsSection(
            isHealthKitAuthorized: healthKitManager.isAuthorized,
            animationTrigger: todayState.animationTrigger,
            hideBottomDivider: false
        )
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit authorization check is complete
    /// This prevents flashing empty state rings during initial authorization check
    static func shouldRender() -> Bool {
        // First check feature flag (from default implementation)
        if let flagKey = featureFlagKey {
            let isEnabled = FeatureFlags.shared.isEnabled(flagKey)
            Logger.debug("🔌 [Component] \(componentID) feature flag '\(flagKey)': \(isEnabled)")
            if !isEnabled {
                return false
            }
        }

        // Only show component after HealthKit authorization check completes
        // This prevents UI flashing during app startup
        let hasCompletedCheck = HealthKitManager.shared.authorizationCoordinator.hasCompletedInitialCheck
        Logger.debug("📦 [RecoveryMetricsComponent] shouldRender - hasCompletedCheck: \(hasCompletedCheck)")
        return hasCompletedCheck
    }
}

// MARK: - Preview

#if DEBUG
struct RecoveryMetricsComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecoveryMetricsComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Recovery Metrics Component")
    }
}
#endif
