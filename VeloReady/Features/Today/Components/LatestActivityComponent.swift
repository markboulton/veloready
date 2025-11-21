import SwiftUI

/// Latest Activity Component (Phase 2 - Component Migration)
///
/// **Component:** Latest activity card showing most recent workout from Strava/Intervals
///
/// **What it displays:**
/// - Latest activity card with map (outdoor activities)
/// - Activity metadata (distance, duration, elevation, power)
/// - RPE (Rate of Perceived Exertion) badge and input
/// - Skeleton card while loading or when no activity available
///
/// **Data Source:** TodayViewState.shared.recentActivities (first activity)
///
/// **Feature Flag:** `component_latest_activity`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, map loading performance, navigation accuracy
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct LatestActivityComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "latest_activity"
    static let displayName = "Latest Activity"
    static let displayOrder = 300 // In activities category (after alerts)
    static let featureFlagKey: String? = "component_latest_activity"

    // MARK: - State

    @ObservedObject private var todayState = TodayViewState.shared
    @ObservedObject private var stravaAuth = StravaAuthService.shared
    @ObservedObject private var intervalsAuth = IntervalsOAuthManager.shared

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [LatestActivityComponent] body evaluated")

        return Group {
            if hasConnectedDataSource {
                if let latestActivity = getLatestActivity() {
                    LatestActivityCardV2(activity: latestActivity, showAsLatestActivity: true)
                        .onAppear {
                            Logger.debug("📦 [LatestActivityComponent] Showing activity: \(latestActivity.name)")
                        }
                } else {
                    SkeletonActivityCard()
                        .onAppear {
                            Logger.debug("📦 [LatestActivityComponent] No activity - showing skeleton")
                        }
                }
            } else {
                EmptyView()
                    .onAppear {
                        Logger.debug("📦 [LatestActivityComponent] No connected data source")
                    }
            }
        }
    }

    // MARK: - Helper Methods

    /// Check if user has connected Strava or Intervals.icu
    private var hasConnectedDataSource: Bool {
        stravaAuth.connectionState.isConnected || intervalsAuth.isAuthenticated
    }

    /// Get the latest activity from TodayViewState
    private func getLatestActivity() -> UnifiedActivity? {
        // Use latestActivity property which is specifically populated by TodayDataLoader
        // (TodayViewState.latestActivity is set from TodayDataLoader.ActivitiesData.latest)
        guard let activity = todayState.latestActivity else {
            return nil
        }
        return UnifiedActivity(from: activity)
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when:
    /// 1. HealthKit is authorized (needed for activities)
    /// 2. User has connected Strava or Intervals.icu
    static func shouldRender() -> Bool {
        // First check feature flag (from default implementation)
        if let flagKey = featureFlagKey {
            let isEnabled = FeatureFlags.shared.isEnabled(flagKey)
            Logger.debug("🔌 [Component] \(componentID) feature flag '\(flagKey)': \(isEnabled)")
            if !isEnabled {
                return false
            }
        }

        // Check HealthKit authorization
        let isAuthorized = HealthKitManager.shared.isAuthorized

        // Check if user has connected data source
        let hasDataSource = StravaAuthService.shared.connectionState.isConnected ||
                           IntervalsOAuthManager.shared.isAuthenticated

        let shouldRender = isAuthorized && hasDataSource
        Logger.debug("📦 [LatestActivityComponent] shouldRender - isAuthorized: \(isAuthorized), hasDataSource: \(hasDataSource), result: \(shouldRender)")
        return shouldRender
    }
}

// MARK: - Preview

#if DEBUG
struct LatestActivityComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LatestActivityComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Latest Activity Component")
    }
}
#endif
