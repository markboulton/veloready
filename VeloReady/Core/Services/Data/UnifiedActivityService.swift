import Foundation
import HealthKit

/// Unified service for fetching activities from all sources (Intervals.icu, Strava, HealthKit)
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
    private let cache = CacheOrchestrator.shared // NEW: Multi-layer cache orchestrator
    private let healthKitManager = HealthKitManager.shared
    private let stravaDataService = StravaDataService.shared
    private let deduplicationService = ActivityDeduplicationService.shared

    // Request deduplication: Track in-flight requests to prevent parallel API calls
    private var inflightRequests: [String: Task<[Activity], Error>] = [:]
    private var inflightUnifiedRequests: [String: Task<[UnifiedActivity], Error>] = [:]

    // API usage tracking for monitoring
    private var apiCallCount = 0
    private var lastResetDate = Date()
    private var apiCallsBySource: [String: Int] = [:]
    
    // Data fetch limits based on subscription tier
    // Research-backed windows for >90% accuracy:
    // - Free: 90 days (Stryd industry standard)
    // - Pro: 120 days (extended window, no evidence >120 improves accuracy)
    // Source: https://help.stryd.com/en/articles/6879345-critical-power-definition
    private var maxDaysForFree: Int { 90 }
    private var maxDaysForPro: Int { 120 }

    /// Maximum period to fetch and cache (fetch once, filter locally for shorter periods)
    /// This eliminates multiple API calls for overlapping data
    private var maxPeriodDays: Int {
        proConfig.hasProAccess ? maxDaysForPro : maxDaysForFree
    }
    
    /// Fetch recent activities from available sources
    /// Automatically uses Intervals.icu if authenticated, falls back to Strava
    /// - Parameters:
    ///   - limit: Maximum number of activities to fetch
    ///   - daysBack: Number of days of history to fetch (capped by subscription tier)
    /// - Returns: Unified array of Activity regardless of source
    func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90) async throws -> [Activity] {
        // AGGRESSIVE CACHING: Increased TTL to 24h to drastically reduce API usage
        // Activities don't change retroactively - once cached, they're valid for 24h
        // This is critical for scaling to 300-400 users within 1000 req/day limit
        return try await fetchRecentActivitiesWithCustomTTL(limit: limit, daysBack: daysBack, ttl: 86400)
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

        let source = intervalsOAuth.isAuthenticated ? "intervals" : "strava"

        Logger.data("📊 [API USAGE] Fetch request: \(daysBack) days (capped to \(actualDays) for \(proConfig.hasProAccess ? "PRO" : "FREE") tier), TTL: \(Int(ttl))s, source: \(source)")
        logAPIUsageStats()

        // UNIFIED CACHE STRATEGY: Always fetch/cache maxPeriodDays, filter locally for shorter periods
        // This eliminates multiple API calls for overlapping data (e.g., 7, 42, 90 days)
        let shouldUseUnifiedCache = actualDays < maxPeriodDays

        if shouldUseUnifiedCache {
            Logger.data("🎯 [UNIFIED CACHE] Checking if we have \(maxPeriodDays)-day cache to filter for \(actualDays) days")

            // Try to get the full period from cache
            let fullPeriodActivities = try? await fetchMaxPeriodActivities(limit: limit, ttl: ttl, skipDedupeLog: true)

            if let fullPeriodActivities = fullPeriodActivities {
                // Filter locally to requested period
                let filtered = filterActivities(fullPeriodActivities, daysBack: actualDays)
                Logger.data("✅ [UNIFIED CACHE] Filtered \(filtered.count) activities from cached \(maxPeriodDays)-day dataset (ZERO API calls)")
                return filtered
            } else {
                Logger.data("⚠️ [UNIFIED CACHE] No \(maxPeriodDays)-day cache found, fetching full period")
            }
        }

        // If we're requesting the max period OR unified cache miss, fetch and cache it
        let periodToFetch = shouldUseUnifiedCache ? maxPeriodDays : actualDays
        let activities = try await fetchAndCacheActivities(
            limit: limit,
            daysBack: periodToFetch,
            ttl: ttl,
            source: source
        )

        // If we fetched the full period but need a shorter one, filter locally
        if shouldUseUnifiedCache && periodToFetch == maxPeriodDays {
            let filtered = filterActivities(activities, daysBack: actualDays)
            Logger.data("🎯 [UNIFIED CACHE] Fetched \(activities.count) activities (\(maxPeriodDays) days), filtered to \(filtered.count) (\(actualDays) days)")
            return filtered
        }

        return activities
    }

    /// Fetch the maximum period (90 or 120 days) from cache or API
    /// This is the unified cache that all shorter periods filter from
    private func fetchMaxPeriodActivities(limit: Int, ttl: TimeInterval, skipDedupeLog: Bool = false) async throws -> [Activity] {
        let source = intervalsOAuth.isAuthenticated ? "intervals" : "strava"
        let dedupeKey = "\(source):\(maxPeriodDays)"

        if !skipDedupeLog {
            Logger.data("📊 [API USAGE] Fetch max period: \(maxPeriodDays) days, TTL: \(Int(ttl))s, source: \(source)")
        }

        // Check if there's already an in-flight request for this data
        if let existingTask = inflightRequests[dedupeKey] {
            Logger.data("♻️ [DEDUPE] Reusing in-flight request for \(dedupeKey) - avoiding redundant API call")
            return try await existingTask.value
        }

        // Create a new task for this request
        let task = Task<[Activity], Error> {
            defer {
                // Remove from inflight requests when complete
                Task { @MainActor in
                    self.inflightRequests.removeValue(forKey: dedupeKey)
                }
            }

            return try await self.fetchAndCacheActivities(
                limit: limit,
                daysBack: self.maxPeriodDays,
                ttl: ttl,
                source: source
            )
        }

        // Store the task to prevent duplicate requests
        inflightRequests[dedupeKey] = task

        return try await task.value
    }

    /// Fetch and cache activities from API (with request deduplication)
    private func fetchAndCacheActivities(limit: Int, daysBack: Int, ttl: TimeInterval, source: String) async throws -> [Activity] {
        // Try Intervals.icu first if authenticated
        if intervalsOAuth.isAuthenticated {
            let cacheKey = CacheKey.intervalsActivities(daysBack: daysBack)

            // Use cache-first: show cached data immediately, refresh in background
            return try await cache.fetchCacheFirst(
                key: cacheKey,
                ttl: ttl
            ) {
                Logger.data("📊 [API CALL] Fetching from Intervals.icu (limit: \(limit), days: \(daysBack))")
                await self.trackAPICall(source: "Intervals.icu")
                let activities = try await self.intervalsAPI.fetchRecentActivities(limit: limit, daysBack: daysBack)
                Logger.data("✅ [API CALL] Fetched \(activities.count) activities from Intervals.icu")
                return activities
            }
        }

        // Fallback to backend API (which fetches from Strava with caching)
        let cappedLimit = min(limit, 200)
        let cacheKey = CacheKey.stravaActivities(daysBack: daysBack)

        // Use cache-first: show cached data immediately, refresh in background
        return try await cache.fetchCacheFirst(
            key: cacheKey,
            ttl: ttl
        ) {
            Logger.data("📊 [API CALL] Fetching from VeloReady backend (limit: \(cappedLimit), daysBack: \(daysBack))")
            await self.trackAPICall(source: "Strava (via backend)")
            let stravaActivities = try await self.veloReadyAPI.fetchActivities(daysBack: daysBack, limit: cappedLimit)
            let convertedActivities = ActivityConverter.stravaToActivity(stravaActivities)
            Logger.data("✅ [API CALL] Fetched \(convertedActivities.count) activities from backend")
            return convertedActivities
        }
    }

    /// Filter activities to only include those within the specified number of days
    private func filterActivities(_ activities: [Activity], daysBack: Int) -> [Activity] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()

        return activities.filter { activity in
            guard let activityDate = parseDate(from: activity.startDateLocal) else {
                return false
            }
            return activityDate >= cutoffDate
        }
    }

    /// Track API call for usage monitoring
    private func trackAPICall(source: String) {
        // Reset counter if it's a new day
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            Logger.data("📊 [API USAGE] Daily reset - Previous day total: \(apiCallCount) calls")
            apiCallCount = 0
            apiCallsBySource = [:]
            lastResetDate = Date()
        }

        apiCallCount += 1
        apiCallsBySource[source, default: 0] += 1

        Logger.data("📊 [API USAGE] API call #\(apiCallCount) today to \(source)")
    }

    /// Log current API usage statistics
    private func logAPIUsageStats() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            return // Will be reset on next API call
        }

        if apiCallCount > 0 {
            Logger.data("📊 [API USAGE STATS] Today's calls: \(apiCallCount) | By source: \(apiCallsBySource)")

            // Warn if approaching rate limits
            if apiCallCount > 50 {
                Logger.warning("⚠️ [API USAGE] High API usage detected: \(apiCallCount) calls today. Strava limit is 1000/day per app.")
            }
        }
    }
    
    /// Fetch today's activities from all available sources
    /// - Returns: Array of activities from today only
    /// - Note: Uses 15-minute cache (increased from 5min to reduce API usage)
    func fetchTodaysActivities() async throws -> [Activity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Fetch recent activities with MODERATE cache TTL (1 hour)
        // Increased from 15min to 1h - most users don't add activities every hour
        // Once webhooks are implemented, this can be even more aggressive
        let activities = try await fetchRecentActivitiesWithCustomTTL(limit: 50, daysBack: 7, ttl: 3600)
        
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

// MARK: - UnifiedActivity Fetching (All Sources)

extension UnifiedActivityService {
    /// Fetch recent unified activities from ALL sources (Intervals.icu, Strava, HealthKit)
    /// Returns deduplicated UnifiedActivity objects, prioritizing Intervals > Strava > HealthKit
    /// - Parameters:
    ///   - limit: Maximum number of activities to fetch from each source
    ///   - daysBack: Number of days of history to fetch (capped by subscription tier)
    ///   - includeHealthKit: Whether to include HealthKit workouts (default: true)
    /// - Returns: Deduplicated array of UnifiedActivity objects from all sources
    func fetchRecentUnifiedActivities(
        limit: Int = 50,
        daysBack: Int = 30,
        includeHealthKit: Bool = true
    ) async throws -> [UnifiedActivity] {
        let dedupeKey = "unified:\(daysBack):\(includeHealthKit)"

        // Check for in-flight request
        if let existingTask = inflightUnifiedRequests[dedupeKey] {
            Logger.debug("♻️ [UnifiedActivities] Reusing in-flight request for \(dedupeKey)")
            return try await existingTask.value
        }

        // Create new task
        let task = Task<[UnifiedActivity], Error> {
            defer {
                Task { @MainActor in
                    self.inflightUnifiedRequests.removeValue(forKey: dedupeKey)
                }
            }

            return try await self.fetchUnifiedActivitiesInternal(
                limit: limit,
                daysBack: daysBack,
                includeHealthKit: includeHealthKit
            )
        }

        inflightUnifiedRequests[dedupeKey] = task
        return try await task.value
    }

    /// Internal method to fetch from all sources and deduplicate
    private func fetchUnifiedActivitiesInternal(
        limit: Int,
        daysBack: Int,
        includeHealthKit: Bool
    ) async throws -> [UnifiedActivity] {
        Logger.debug("📊 [UnifiedActivities] Fetching from all sources: limit=\(limit), days=\(daysBack), includeHealthKit=\(includeHealthKit)")

        // STEP 1: Fetch from Intervals.icu (optional - only if authenticated)
        var intervalsUnified: [UnifiedActivity] = []
        var stravaFilteredCount = 0

        do {
            let intervalsActivities = try await fetchRecentActivities(limit: limit, daysBack: daysBack)
            Logger.debug("✅ [UnifiedActivities] Fetched \(intervalsActivities.count) from Intervals.icu")

            // Convert and filter out Strava-sourced activities (we fetch them directly)
            for activity in intervalsActivities {
                if let source = activity.source, source.uppercased() == "STRAVA" {
                    stravaFilteredCount += 1
                    continue
                }
                intervalsUnified.append(UnifiedActivity(from: activity))
            }

            Logger.debug("🔍 [UnifiedActivities] Intervals: \(intervalsActivities.count) → \(intervalsUnified.count) native (filtered \(stravaFilteredCount) Strava)")
        } catch {
            Logger.warning("⚠️ [UnifiedActivities] Intervals.icu not available: \(error.localizedDescription)")
        }

        // STEP 2: Fetch from Strava (via shared service)
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        let stravaUnified = stravaActivities.map { UnifiedActivity(from: $0) }
        Logger.debug("✅ [UnifiedActivities] Fetched \(stravaUnified.count) from Strava")

        // STEP 3: Fetch from HealthKit (optional)
        var healthUnified: [UnifiedActivity] = []
        if includeHealthKit {
            let healthWorkouts = await healthKitManager.fetchRecentWorkouts(limit: limit, daysBack: daysBack)
            healthUnified = healthWorkouts.map { UnifiedActivity(from: $0) }
            Logger.debug("✅ [UnifiedActivities] Fetched \(healthUnified.count) from HealthKit")
        }

        // STEP 4: Deduplicate across all sources
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervalsUnified,
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )

        // STEP 5: Sort by date (newest first)
        let sorted = deduplicated.sorted { $0.startDate > $1.startDate }

        Logger.debug("📊 [UnifiedActivities] Total: \(sorted.count) deduplicated activities")

        return sorted
    }

    /// Fetch extended unified activities (31-90 days) for Pro users
    /// Merges with existing activities to avoid duplicates
    /// - Parameters:
    ///   - existingActivities: Activities already loaded (0-30 days)
    ///   - limit: Maximum number of activities to fetch from each source
    /// - Returns: Array of NEW activities from 31-90 days range
    func fetchExtendedUnifiedActivities(
        existingActivities: [UnifiedActivity],
        limit: Int = 50
    ) async throws -> [UnifiedActivity] {
        guard proConfig.hasProAccess else {
            throw ServiceError.proFeatureRequired
        }

        Logger.debug("📊 [UnifiedActivities] Fetching extended activities (31-90 days)")

        // Fetch full 90-day range
        let allActivities = try await fetchRecentUnifiedActivities(
            limit: limit,
            daysBack: 90,
            includeHealthKit: true
        )

        // Filter to only activities from 31-90 days
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let extendedActivities = allActivities.filter { activity in
            activity.startDate < thirtyDaysAgo
        }

        // Remove any that are already in existingActivities (by ID)
        let existingIDs = Set(existingActivities.map { $0.id })
        let newActivities = extendedActivities.filter { !existingIDs.contains($0.id) }

        Logger.debug("📊 [UnifiedActivities] Extended: \(newActivities.count) new activities (31-90 days)")

        return newActivities
    }

    /// Force refresh unified activities (ignores cache)
    /// Used after auth changes (e.g., Strava connection)
    func forceRefreshUnifiedActivities(
        limit: Int = 50,
        daysBack: Int = 30
    ) async throws -> [UnifiedActivity] {
        Logger.debug("🔄 [UnifiedActivities] Force refresh (ignoring cache)")

        // Clear in-flight requests to force fresh fetch
        inflightUnifiedRequests.removeAll()

        // Fetch fresh data (cache will handle TTL)
        return try await fetchRecentUnifiedActivities(
            limit: limit,
            daysBack: daysBack,
            includeHealthKit: true
        )
    }
}

enum ServiceError: Error {
    case proFeatureRequired
    case noDataAvailable
}
