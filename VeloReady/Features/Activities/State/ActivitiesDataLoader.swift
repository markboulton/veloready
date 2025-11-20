import Foundation

/// Data loader for Activities view with intelligent caching
/// Handles all data fetching for activities list using UnifiedActivityService
@MainActor
final class ActivitiesDataLoader {

    // MARK: - Data Transfer Objects

    struct ActivitiesData {
        let activities: [UnifiedActivity]
        let hasMore: Bool
        let daysLoaded: Int
    }

    // MARK: - Services (Dependency Injection)

    private let unifiedActivityService: UnifiedActivityService
    private let proConfig: ProFeatureConfig

    init(
        unifiedActivityService: UnifiedActivityService = .shared,
        proConfig: ProFeatureConfig = .shared
    ) {
        self.unifiedActivityService = unifiedActivityService
        self.proConfig = proConfig
    }

    // MARK: - Public API

    /// Load initial activities (30 days, ~50 activities)
    /// Optimized for fast initial load
    func loadInitialActivities() async throws -> ActivitiesData {
        Logger.debug("📊 [ActivitiesDataLoader] Loading initial activities (30 days)")

        let activities = try await unifiedActivityService.fetchRecentUnifiedActivities(
            limit: 50,
            daysBack: 30,
            includeHealthKit: true
        )

        Logger.debug("✅ [ActivitiesDataLoader] Loaded \(activities.count) initial activities")

        return ActivitiesData(
            activities: activities,
            hasMore: proConfig.hasProAccess, // Pro users can load more (31-90 days)
            daysLoaded: 30
        )
    }

    /// Load extended activities (31-90 days) for Pro users
    /// Merges with existing activities to avoid duplicates
    func loadExtendedActivities(existingActivities: [UnifiedActivity]) async throws -> ActivitiesData {
        guard proConfig.hasProAccess else {
            Logger.warning("⚠️ [ActivitiesDataLoader] Extended activities require Pro subscription")
            throw ServiceError.proFeatureRequired
        }

        Logger.debug("📊 [ActivitiesDataLoader] Loading extended activities (31-90 days)")

        let newActivities = try await unifiedActivityService.fetchExtendedUnifiedActivities(
            existingActivities: existingActivities,
            limit: 50
        )

        // Merge with existing activities
        let allActivities = existingActivities + newActivities
        let sorted = allActivities.sorted { $0.startDate > $1.startDate }

        Logger.debug("✅ [ActivitiesDataLoader] Loaded \(newActivities.count) extended activities")
        Logger.debug("📊 [ActivitiesDataLoader] Total: \(sorted.count) activities (0-90 days)")

        return ActivitiesData(
            activities: sorted,
            hasMore: false, // No more data to load after 90 days
            daysLoaded: 90
        )
    }

    /// Force refresh activities (ignores cache)
    /// Used after auth changes (e.g., Strava connection)
    func forceRefreshActivities() async throws -> ActivitiesData {
        Logger.debug("🔄 [ActivitiesDataLoader] Force refreshing activities")

        let activities = try await unifiedActivityService.forceRefreshUnifiedActivities(
            limit: 50,
            daysBack: 30
        )

        Logger.debug("✅ [ActivitiesDataLoader] Force refreshed \(activities.count) activities")

        return ActivitiesData(
            activities: activities,
            hasMore: proConfig.hasProAccess,
            daysLoaded: 30
        )
    }

    // MARK: - Filtering & Grouping (View Logic)

    /// Filter activities by type
    func filterActivities(
        _ activities: [UnifiedActivity],
        by selectedTypes: Set<UnifiedActivity.ActivityType>
    ) -> [UnifiedActivity] {
        guard !selectedTypes.isEmpty else {
            return activities
        }

        return activities.filter { selectedTypes.contains($0.type) }
    }

    /// Group activities by month
    func groupActivitiesByMonth(
        _ activities: [UnifiedActivity]
    ) -> [String: [UnifiedActivity]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return Dictionary(grouping: activities) { activity in
            formatter.string(from: activity.startDate)
        }
    }

    /// Sort month keys chronologically (newest first)
    func sortedMonthKeys(
        _ grouped: [String: [UnifiedActivity]]
    ) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return grouped.keys.sorted { month1, month2 in
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                return month1 > month2
            }
            return date1 > date2
        }
    }

    // MARK: - Progressive Loading

    /// Apply progressive loading (batch display)
    /// Returns a subset of activities for initial display
    func applyProgressiveLoading(
        _ activities: [UnifiedActivity],
        batchSize: Int = 10
    ) -> [UnifiedActivity] {
        return Array(activities.prefix(batchSize))
    }

    /// Get next batch of activities
    func getNextBatch(
        from activities: [UnifiedActivity],
        currentCount: Int,
        batchSize: Int = 10
    ) -> [UnifiedActivity] {
        let startIndex = currentCount
        let endIndex = min(startIndex + batchSize, activities.count)

        guard startIndex < activities.count else {
            return []
        }

        return Array(activities[startIndex..<endIndex])
    }
}
