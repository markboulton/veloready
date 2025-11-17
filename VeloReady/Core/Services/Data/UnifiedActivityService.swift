import Foundation

/// Unified service for fetching activities from all sources (Intervals.icu, Strava)
/// Provides identical experience regardless of data source
/// Single source of truth for activity fetching throughout the app
@MainActor
class UnifiedActivityService: ObservableObject {
    nonisolated(unsafe) static let shared = UnifiedActivityService()
    
    private let intervalsAPI = IntervalsAPIClient.shared
    private let veloReadyAPI = VeloReadyAPIClient.shared // NEW: Use backend API
    private let intervalsOAuth = IntervalsOAuthManager.shared
    private let stravaAuth = StravaAuthService.shared
    private let proConfig = ProFeatureConfig.shared
    private let cache = CacheOrchestrator.shared // NEW: Multi-layer cache orchestrator
    
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
    /// - Returns: Unified array of Activity regardless of source
    func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90) async throws -> [Activity] {
        return try await fetchRecentActivitiesWithCustomTTL(limit: limit, daysBack: daysBack, ttl: 3600)
    }
    
    /// Fetch recent activities with custom cache TTL
    /// - Parameters:
    ///   - limit: Maximum number of activities to fetch
    ///   - daysBack: Number of days of history to fetch (capped by subscription tier)
    ///   - ttl: Cache time-to-live in seconds (use shorter TTL for recent activities)
    /// - Returns: Unified array of Activity regardless of source
    private func fetchRecentActivitiesWithCustomTTL(limit: Int = 100, daysBack: Int = 90, ttl: TimeInterval) async throws -> [Activity] {
        // Apply subscription-based limits
        let maxDays = proConfig.hasProAccess ? maxDaysForPro : maxDaysForFree
        let actualDays = min(daysBack, maxDays)
        
        Logger.data("📊 [Activities] Fetch request: \(daysBack) days (capped to \(actualDays) for \(proConfig.hasProAccess ? "PRO" : "FREE") tier), TTL: \(Int(ttl))s")
        
        // Try Intervals.icu first if authenticated
        if intervalsOAuth.isAuthenticated {
            let cacheKey = CacheKey.intervalsActivities(daysBack: actualDays)
            
            // Use cache-first: show cached data immediately, refresh in background
            return try await cache.fetchCacheFirst(
                key: cacheKey,
                ttl: ttl
            ) {
                Logger.data("📊 [Activities] Fetching from Intervals.icu (limit: \(limit), days: \(actualDays))")
                let activities = try await self.intervalsAPI.fetchRecentActivities(limit: limit, daysBack: actualDays)
                Logger.data("✅ [Activities] Fetched \(activities.count) activities from Intervals.icu")
                return activities
            }
        }
        
        // Fallback to backend API (which fetches from Strava with caching)
        let cappedLimit = min(limit, 200)
        let cacheKey = CacheKey.stravaActivities(daysBack: actualDays)
        
        // Use cache-first: show cached data immediately, refresh in background
        return try await cache.fetchCacheFirst(
            key: cacheKey,
            ttl: ttl
        ) {
            Logger.data("📊 [Activities] Fetching from VeloReady backend (limit: \(cappedLimit), daysBack: \(actualDays))")
            let stravaActivities = try await self.veloReadyAPI.fetchActivities(daysBack: actualDays, limit: cappedLimit)
            let convertedActivities = ActivityConverter.stravaToActivity(stravaActivities)
            Logger.data("✅ [Activities] Fetched \(convertedActivities.count) activities from backend")
            return convertedActivities
        }
    }
    
    /// Fetch today's activities from all available sources
    /// - Returns: Array of activities from today only
    /// - Note: Uses 5-minute cache (much shorter than standard 1-hour) to catch new activities quickly
    func fetchTodaysActivities() async throws -> [Activity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Fetch recent activities with SHORT cache TTL (5 minutes)
        // This ensures we catch new activities quickly without hammering the API
        let activities = try await fetchRecentActivitiesWithCustomTTL(limit: 50, daysBack: 7, ttl: 300)
        
        Logger.debug("📊 [TodaysActivities] Filtering \(activities.count) activities - showing all dates:")
        for (index, activity) in activities.enumerated() {
            Logger.debug("   Activity \(index + 1): '\(activity.name ?? "Unnamed")' - startDateLocal: '\(activity.startDateLocal)'")
        }
        
        // Filter to today only
        let todaysActivities = activities.filter { activity in
            guard let date = parseDate(from: activity.startDateLocal) else { 
                Logger.warning("⚠️ [TodaysActivities] Failed to parse date: \(activity.startDateLocal)")
                return false 
            }
            let isToday = calendar.isDate(date, inSameDayAs: today)
            if !isToday {
                Logger.debug("🗓️ [TodaysActivities] Activity '\(activity.name ?? "Unnamed")' is not today: \(date) vs \(today)")
            } else {
                Logger.debug("✅ [TodaysActivities] Activity '\(activity.name ?? "Unnamed")' IS today: \(date)")
            }
            return isToday
        }
        
        Logger.debug("📊 [TodaysActivities] Found \(todaysActivities.count) activities for today out of \(activities.count) total")
        if !todaysActivities.isEmpty {
            Logger.debug("📊 [TodaysActivities] Today's activities:")
            for activity in todaysActivities {
                Logger.debug("   - '\(activity.name ?? "Unnamed")' at \(activity.startDateLocal)")
            }
        }
        
        return todaysActivities
    }
    
    /// Fetch activities for adaptive FTP calculation
    /// - Returns: Activities from last 90-120 days (based on tier) with power data
    /// Research shows 90 days is optimal for >90% accuracy (Stryd standard)
    /// Pro users get 120 days (no evidence >120 days improves accuracy)
    func fetchActivitiesForFTP() async throws -> [Activity] {
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
    func fetchActivitiesForTrainingLoad() async throws -> [Activity] {
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
        // Strava's start_date_local should be in local time, but sometimes includes 'Z' suffix
        // which can cause confusion. We need to handle both cases:
        // 1. "2025-11-13T06:24:24Z" - UTC time with Z (convert to local)
        // 2. "2025-11-13T06:24:24" - Local time without Z
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        // If the string has 'Z', it's UTC - parse as UTC
        if dateString.hasSuffix("Z") {
            iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
        } else {
            // No 'Z' suffix means it's already in local time
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Fallback: try both formatters without timezone assumptions
        iso8601Formatter.timeZone = nil
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}
