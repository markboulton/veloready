import Foundation

/// Unified service for fetching activities from all sources (Intervals.icu, Strava)
/// Provides identical experience regardless of data source
/// Single source of truth for activity fetching throughout the app
@MainActor
class UnifiedActivityService: ObservableObject {
    static let shared = UnifiedActivityService()
    
    private let intervalsAPI = IntervalsAPIClient.shared
    private let stravaAPI = StravaAPIClient.shared
    private let intervalsOAuth = IntervalsOAuthManager.shared
    private let stravaAuth = StravaAuthService.shared
    
    /// Fetch recent activities from available sources
    /// Automatically uses Intervals.icu if authenticated, falls back to Strava
    /// - Parameters:
    ///   - limit: Maximum number of activities to fetch
    ///   - daysBack: Number of days of history to fetch
    /// - Returns: Unified array of IntervalsActivity regardless of source
    func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90) async throws -> [IntervalsActivity] {
        // Try Intervals.icu first if authenticated
        if intervalsOAuth.isAuthenticated {
            Logger.data("📊 Fetching activities from Intervals.icu (limit: \(limit), days: \(daysBack))")
            do {
                let activities = try await intervalsAPI.fetchRecentActivities(limit: limit, daysBack: daysBack)
                Logger.data("✅ Fetched \(activities.count) activities from Intervals.icu")
                return activities
            } catch {
                Logger.warning("⚠️ Failed to fetch from Intervals.icu, falling back to Strava: \(error)")
            }
        }
        
        // Fallback to Strava
        Logger.data("📊 Fetching activities from Strava (limit: \(limit))")
        let stravaActivities = try await stravaAPI.fetchActivities(perPage: limit)
        let convertedActivities = ActivityConverter.stravaToIntervals(stravaActivities)
        
        // Filter by date range
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
        let filteredActivities = convertedActivities.filter { activity in
            guard let date = parseDate(from: activity.startDateLocal) else { return false }
            return date >= cutoffDate
        }
        
        Logger.data("✅ Fetched \(filteredActivities.count) activities from Strava (filtered to \(daysBack) days)")
        return filteredActivities
    }
    
    /// Fetch today's activities from all available sources
    /// - Returns: Array of activities from today only
    func fetchTodaysActivities() async throws -> [IntervalsActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Fetch recent activities (last 7 days to ensure we get today)
        let activities = try await fetchRecentActivities(limit: 50, daysBack: 7)
        
        // Filter to today only
        return activities.filter { activity in
            guard let date = parseDate(from: activity.startDateLocal) else { return false }
            return calendar.isDate(date, inSameDayAs: today)
        }
    }
    
    /// Fetch activities for adaptive FTP calculation
    /// - Returns: Activities from last 120 days with power data
    func fetchActivitiesForFTP() async throws -> [IntervalsActivity] {
        let activities = try await fetchRecentActivities(limit: 300, daysBack: 120)
        
        // Filter to activities with power data
        return activities.filter { activity in
            activity.averagePower != nil || activity.normalizedPower != nil
        }
    }
    
    /// Fetch activities for training load calculation (CTL/ATL)
    /// - Returns: Activities from last 42 days for accurate load calculation
    func fetchActivitiesForTrainingLoad() async throws -> [IntervalsActivity] {
        return try await fetchRecentActivities(limit: 200, daysBack: 42)
    }
    
    /// Check if any data source is available
    var isAnySourceAvailable: Bool {
        return intervalsOAuth.isAuthenticated || stravaAuth.connectionState != .disconnected
    }
    
    /// Get current data source name for UI display
    var currentDataSourceName: String {
        if intervalsOAuth.isAuthenticated {
            return "Intervals.icu"
        } else if stravaAuth.connectionState != .disconnected {
            return "Strava"
        } else {
            return "None"
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
}
