import Foundation
import Combine

/// Coordinates activity fetching from multiple sources (Intervals.icu, Strava, Apple Health)
/// 
/// **Responsibilities:**
/// - Fetch activities from all connected sources
/// - Deduplicate activities across sources
/// - Sort and limit activities for display
/// - Manage loading states
/// - Handle errors gracefully
///
/// **Key Design Decisions:**
/// 1. Fetches from all sources in parallel (fast)
/// 2. Deduplicates automatically (prevents showing same workout twice)
/// 3. Sorts by date descending (most recent first)
/// 4. Limits to 15 activities (performance)
/// 5. Gracefully handles auth failures (shows what's available)
///
/// Created: 2025-11-10
/// Part of: Today View Refactoring Plan - Phase 3 (Week 3-4)
@MainActor
class ActivitiesCoordinator: ObservableObject {
    @Published private(set) var activities: [UnifiedActivity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // Dependencies
    private let services: ServiceContainer
    
    // MARK: - Initialization
    
    init(services: ServiceContainer = .shared) {
        self.services = services
        Logger.info("🎯 [ActivitiesCoordinator] Initialized")
    }
    
    // MARK: - Public API
    
    /// Fetch recent activities from all sources
    /// 
    /// **Flow:**
    /// 1. Set isLoading = true
    /// 2. Fetch from Intervals, Strava, HealthKit in parallel
    /// 3. Deduplicate activities
    /// 4. Sort by date descending
    /// 5. Take top 15
    /// 6. Set isLoading = false
    ///
    /// - Parameter days: Number of days of history to fetch
    /// - Returns: Array of fetched activities (top 15)
    func fetchRecent(days: Int) async -> [UnifiedActivity] {
        let startTime = Date()
        Logger.info("🔄 [ActivitiesCoordinator] ━━━ Fetching \(days) days of activities ━━━")
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // Fetch from all sources in parallel
        async let intervalsActivities = fetchIntervalsActivities(days: days)
        async let stravaActivities = fetchStravaActivities(days: days)
        async let healthWorkouts = fetchHealthWorkouts(days: days)
        
        let (intervals, strava, health) = await (intervalsActivities, stravaActivities, healthWorkouts)
        
        Logger.info("✅ [ActivitiesCoordinator] Fetched - Intervals: \(intervals.count), Strava: \(strava.count), Health: \(health.count)")
        
        // Deduplicate activities
        let deduplicated = services.deduplicationService.deduplicateActivities(
            intervalsActivities: intervals,
            stravaActivities: strava,
            appleHealthActivities: health
        )
        
        Logger.info("✅ [ActivitiesCoordinator] Deduplicated: \(deduplicated.count) unique activities")
        
        // Sort by date descending and take top 15
        activities = deduplicated
            .sorted { $0.startDate > $1.startDate }
            .prefix(15)
            .map { $0 }
        
        let duration = Date().timeIntervalSince(startTime)
        Logger.info("✅ [ActivitiesCoordinator] ━━━ Completed in \(String(format: "%.2f", duration))s - \(activities.count) activities ━━━")
        
        return activities
    }
    
    // MARK: - Private Fetching Methods
    
    /// Fetch activities from Intervals.icu
    /// - Parameter days: Number of days of history
    /// - Returns: Array of UnifiedActivity
    private func fetchIntervalsActivities(days: Int) async -> [UnifiedActivity] {
        Logger.info("🔄 [ActivitiesCoordinator] Fetching Intervals.icu activities...")
        
        // Check if authenticated
        guard services.intervalsOAuthManager.isAuthenticated else {
            Logger.info("⏭️ [ActivitiesCoordinator] Intervals.icu not authenticated - skipping")
            return []
        }
        
        do {
            let activities = try await Task { @MainActor in
                try await UnifiedActivityService.shared.fetchRecentActivities(
                    limit: 500,
                    daysBack: days
                )
            }.value
            
            // Filter out Strava duplicates (those with source == "STRAVA")
            let filtered = activities.filter { $0.source?.uppercased() != "STRAVA" }
            
            Logger.info("✅ [ActivitiesCoordinator] Intervals.icu: \(filtered.count) activities (filtered from \(activities.count))")
            
            return filtered.map { UnifiedActivity(from: $0) }
        } catch {
            Logger.warning("⚠️ [ActivitiesCoordinator] Intervals.icu fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch activities from Strava
    /// - Parameter days: Number of days of history
    /// - Returns: Array of UnifiedActivity
    private func fetchStravaActivities(days: Int) async -> [UnifiedActivity] {
        Logger.info("🔄 [ActivitiesCoordinator] Fetching Strava activities...")
        Logger.info("🔄 [ActivitiesCoordinator] Connection state: \(services.stravaAuthService.connectionState)")
        
        // Check if authenticated
        guard case .connected = services.stravaAuthService.connectionState else {
            Logger.info("⏭️ [ActivitiesCoordinator] Strava not authenticated - skipping")
            return []
        }
        
        Logger.info("🔄 [ActivitiesCoordinator] Calling stravaDataService.fetchActivities(daysBack: \(days))")
        
        // Fetch activities using the backend-powered VeloReady API
        // Note: StravaDataService.fetchActivities() uses the local Strava API client,
        // but we should use the VeloReady backend for better caching and rate limiting
        await services.stravaDataService.fetchActivitiesIfNeeded()
        let activities = services.stravaDataService.activities
        
        Logger.info("✅ [ActivitiesCoordinator] Strava: \(activities.count) activities")
        
        return activities.map { UnifiedActivity(from: $0) }
    }
    
    /// Fetch workouts from Apple Health
    /// - Parameter days: Number of days of history
    /// - Returns: Array of UnifiedActivity
    private func fetchHealthWorkouts(days: Int) async -> [UnifiedActivity] {
        Logger.info("🔄 [ActivitiesCoordinator] Fetching Apple Health workouts...")
        
        // Check if authorized
        guard services.healthKitManager.isAuthorized else {
            Logger.info("⏭️ [ActivitiesCoordinator] HealthKit not authorized - skipping")
            return []
        }
        
        let workouts = await services.healthKitManager.fetchRecentWorkouts(daysBack: days)
        
        Logger.info("✅ [ActivitiesCoordinator] Apple Health: \(workouts.count) workouts")
        
        return workouts.map { UnifiedActivity(from: $0) }
    }
    
    // MARK: - Public Helper Methods
    
    /// Clear cached activities
    func clearActivities() {
        activities = []
        Logger.info("🗑️ [ActivitiesCoordinator] Cleared activities cache")
    }
    
    /// Get activity count for a specific source
    func getActivityCount(for source: UnifiedActivity.ActivitySource) -> Int {
        activities.filter { $0.source == source }.count
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension ActivitiesCoordinator {
    /// Log current state for debugging
    func logCurrentState() {
        Logger.debug("📊 [ActivitiesCoordinator] Current State:")
        Logger.debug("  activities: \(activities.count)")
        Logger.debug("  isLoading: \(isLoading)")
        Logger.debug("  error: \(error ?? "nil")")
        
        if !activities.isEmpty {
            Logger.debug("  Activity breakdown:")
            Logger.debug("    Intervals: \(activities.filter { $0.source == .intervalsICU }.count)")
            Logger.debug("    Strava: \(activities.filter { $0.source == .strava }.count)")
            Logger.debug("    Health: \(activities.filter { $0.source == .appleHealth }.count)")
        }
    }
}
#endif

