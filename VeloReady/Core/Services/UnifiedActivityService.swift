import Foundation

/// Unified service for fetching activities from all sources (Intervals.icu, Strava)
/// Provides identical experience regardless of data source
/// Single source of truth for activity fetching throughout the app
@MainActor
class UnifiedActivityService: ObservableObject {
    static let shared = UnifiedActivityService()
    
    private let intervalsAPI = IntervalsAPIClient.shared
    private let veloReadyAPI = VeloReadyAPIClient.shared // NEW: Use backend API
    private let intervalsOAuth = IntervalsOAuthManager.shared
    private let stravaAuth = StravaAuthService.shared
    private let proConfig = ProFeatureConfig.shared
    
    // Data fetch limits based on subscription tier
    // Research-backed windows for >90% accuracy:
    // - Free: 90 days (Stryd industry standard)
    // - Pro: 120 days (extended window, no evidence >120 improves accuracy)
    // Source: https://help.stryd.com/en/articles/6879345-critical-power-definition
    private var maxDaysForFree: Int { 90 }
    private var maxDaysForPro: Int { 120 }
    
    /// Fetch recent activities from available sources
    /// Automatically uses Intervals.icu if authenticated, falls back to Strava
    /// - Parameters:
    ///   - limit: Maximum number of activities to fetch
    ///   - daysBack: Number of days of history to fetch (capped by subscription tier)
    /// - Returns: Unified array of IntervalsActivity regardless of source
    func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90) async throws -> [IntervalsActivity] {
        // Apply subscription-based limits
        let maxDays = proConfig.hasProAccess ? maxDaysForPro : maxDaysForFree
        let actualDays = min(daysBack, maxDays)
        
        Logger.data("📊 [Activities] Fetch request: \(daysBack) days (capped to \(actualDays) for \(proConfig.hasProAccess ? "PRO" : "FREE") tier)")
        
        // Try Intervals.icu first if authenticated
        if intervalsOAuth.isAuthenticated {
            Logger.data("📊 [Activities] Fetching from Intervals.icu (limit: \(limit), days: \(actualDays))")
            do {
                let activities = try await intervalsAPI.fetchRecentActivities(limit: limit, daysBack: actualDays)
                Logger.data("✅ [Activities] Fetched \(activities.count) activities from Intervals.icu")
                return activities
            } catch {
                Logger.warning("⚠️ [Activities] Failed to fetch from Intervals.icu, falling back to Strava: \(error)")
            }
        }
        
        // Fallback to backend API (which fetches from Strava with caching)
        let cappedLimit = min(limit, 200)
        Logger.data("📊 [Activities] Fetching from VeloReady backend (limit: \(cappedLimit), daysBack: \(actualDays))")
        let stravaActivities = try await veloReadyAPI.fetchActivities(daysBack: actualDays, limit: cappedLimit)
        let convertedActivities = ActivityConverter.stravaToIntervals(stravaActivities)
        
        Logger.data("✅ [Activities] Fetched \(convertedActivities.count) activities from backend (cached for 5min)")
        return convertedActivities
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
    /// - Returns: Activities from last 90-120 days (based on tier) with power data
    /// Research shows 90 days is optimal for >90% accuracy (Stryd standard)
    /// Pro users get 120 days (no evidence >120 days improves accuracy)
    func fetchActivitiesForFTP() async throws -> [IntervalsActivity] {
        // Request max days for user's tier (will be capped automatically)
        let requestedDays = proConfig.hasProAccess ? 120 : 90
        Logger.data("📊 [FTP] Fetching activities for FTP computation (\(requestedDays) days, research-backed window)")
        
        let activities = try await fetchRecentActivities(limit: 500, daysBack: requestedDays)
        
        // Filter to activities with power data
        let powerActivities = activities.filter { activity in
            activity.averagePower != nil || activity.normalizedPower != nil
        }
        
        Logger.data("✅ [FTP] Found \(powerActivities.count) activities with power data")
        return powerActivities
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
        // Try ISO8601 first (handles 'Z' suffix)
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        iso8601Formatter.timeZone = TimeZone.current
        
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Fallback to manual parsing without 'Z'
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
}
