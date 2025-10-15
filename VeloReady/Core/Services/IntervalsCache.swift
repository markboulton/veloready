import Foundation

/// Cache manager for Intervals.icu API data to minimize API calls
@MainActor
class IntervalsCache: ObservableObject {
    static let shared = IntervalsCache()
    
    // MARK: - Cache Keys
    private enum CacheKey: String {
        case activities = "intervals_activities"
        case wellness = "intervals_wellness"
        case lastActivityFetch = "last_activity_fetch"
        case lastWellnessFetch = "last_wellness_fetch"
    }
    
    // MARK: - Cache Configuration
    private let cacheExpiryHours: TimeInterval = 4 // Cache expires after 4 hours (more frequent updates)
    private let maxActivities = 50 // Keep last 50 activities (reduced for performance)
    private let maxWellnessRecords = 14 // Keep last 14 days of wellness (reduced for performance)
    
    private init() {}
    
    // MARK: - Activities Cache
    
    /// Get cached activities or fetch from API if needed
    func getCachedActivities(apiClient: IntervalsAPIClient, forceRefresh: Bool = false) async throws -> [IntervalsActivity] {
        let lastFetchKey = CacheKey.lastActivityFetch.rawValue
        
        // Check if we need to fetch new data
        if forceRefresh || shouldRefreshCache(lastFetchKey: lastFetchKey) {
            Logger.debug("🔄 Fetching fresh activities from API...")
            let newActivities = try await fetchAndCacheActivities(apiClient: apiClient)
            return newActivities
        }
        
        // Return cached data
        if let cachedActivities = getCachedActivities() {
            Logger.debug("📱 Using cached activities (\(cachedActivities.count) items)")
            return cachedActivities
        }
        
        // No cache available, fetch fresh
        Logger.debug("🔄 No cache available, fetching fresh activities...")
        return try await fetchAndCacheActivities(apiClient: apiClient)
    }
    
    /// Get cached wellness data or fetch from API if needed
    func getCachedWellness(apiClient: IntervalsAPIClient, forceRefresh: Bool = false) async throws -> [IntervalsWellness] {
        let lastFetchKey = CacheKey.lastWellnessFetch.rawValue
        
        // Check if we need to fetch new data
        if forceRefresh || shouldRefreshCache(lastFetchKey: lastFetchKey) {
            Logger.debug("🔄 Fetching fresh wellness data from API...")
            let newWellness = try await fetchAndCacheWellness(apiClient: apiClient)
            return newWellness
        }
        
        // Return cached data
        if let cachedWellness = getCachedWellness() {
            Logger.debug("📱 Using cached wellness data (\(cachedWellness.count) items)")
            return cachedWellness
        }
        
        // No cache available, fetch fresh
        Logger.debug("🔄 No cache available, fetching fresh wellness data...")
        return try await fetchAndCacheWellness(apiClient: apiClient)
    }
    
    // MARK: - Private Cache Methods
    
    private func shouldRefreshCache(lastFetchKey: String) -> Bool {
        guard let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date else {
            return true // No previous fetch
        }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        let shouldRefresh = timeSinceLastFetch > (cacheExpiryHours * 3600)
        
        if shouldRefresh {
            Logger.debug("⏰ Cache expired (\(String(format: "%.1f", timeSinceLastFetch / 3600))h ago), refreshing...")
        }
        
        return shouldRefresh
    }
    
    private func fetchAndCacheActivities(apiClient: IntervalsAPIClient) async throws -> [IntervalsActivity] {
        // Fetch recent activities (last 30 days)
        let activities = try await apiClient.fetchRecentActivities(limit: maxActivities)
        
        // Merge with existing cache to avoid duplicates
        let mergedActivities = mergeWithCachedActivities(newActivities: activities)
        
        // Save to cache
        saveActivitiesToCache(mergedActivities)
        UserDefaults.standard.set(Date(), forKey: CacheKey.lastActivityFetch.rawValue)
        
        Logger.debug("💾 Cached \(mergedActivities.count) activities")
        return mergedActivities
    }
    
    private func fetchAndCacheWellness(apiClient: IntervalsAPIClient) async throws -> [IntervalsWellness] {
        // Fetch wellness data
        let wellness = try await apiClient.fetchWellnessData()
        
        // Keep only recent records (last 30 days)
        let recentWellness = filterRecentWellness(wellness)
        
        // Save to cache
        saveWellnessToCache(recentWellness)
        UserDefaults.standard.set(Date(), forKey: CacheKey.lastWellnessFetch.rawValue)
        
        Logger.debug("💾 Cached \(recentWellness.count) wellness records")
        return recentWellness
    }
    
    private func mergeWithCachedActivities(newActivities: [IntervalsActivity]) -> [IntervalsActivity] {
        guard let cachedActivities = getCachedActivities() else {
            return newActivities
        }
        
        // Create a set of cached activity IDs for fast lookup
        let cachedIds = Set(cachedActivities.map { $0.id })
        
        // Add only new activities that aren't already cached
        let uniqueNewActivities = newActivities.filter { !cachedIds.contains($0.id) }
        
        // Combine and sort by date (newest first)
        let allActivities = (cachedActivities + uniqueNewActivities)
            .sorted { activity1, activity2 in
                // Parse dates for comparison
                let formatter = ISO8601DateFormatter()
                let date1 = formatter.date(from: activity1.startDateLocal) ?? Date.distantPast
                let date2 = formatter.date(from: activity2.startDateLocal) ?? Date.distantPast
                return date1 > date2
            }
        
        // Keep only the most recent activities
        let trimmedActivities = Array(allActivities.prefix(maxActivities))
        
        Logger.debug("🔄 Merged activities: \(cachedActivities.count) cached + \(uniqueNewActivities.count) new = \(trimmedActivities.count) total")
        return trimmedActivities
    }
    
    private func filterRecentWellness(_ wellness: [IntervalsWellness]) -> [IntervalsWellness] {
        // Since we now fetch only last 30 days from API, keep all records up to our limit
        // This ensures we don't lose data that was specifically requested
        return Array(wellness.prefix(maxWellnessRecords))
    }
    
    // MARK: - UserDefaults Storage
    
    private func saveActivitiesToCache(_ activities: [IntervalsActivity]) {
        do {
            let data = try JSONEncoder().encode(activities)
            UserDefaults.standard.set(data, forKey: CacheKey.activities.rawValue)
        } catch {
            Logger.error("Failed to cache activities: \(error)")
        }
    }
    
    private func getCachedActivities() -> [IntervalsActivity]? {
        guard let data = UserDefaults.standard.data(forKey: CacheKey.activities.rawValue) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([IntervalsActivity].self, from: data)
        } catch {
            Logger.error("Failed to decode cached activities: \(error)")
            return nil
        }
    }
    
    private func saveWellnessToCache(_ wellness: [IntervalsWellness]) {
        do {
            let data = try JSONEncoder().encode(wellness)
            UserDefaults.standard.set(data, forKey: CacheKey.wellness.rawValue)
        } catch {
            Logger.error("Failed to cache wellness data: \(error)")
        }
    }
    
    private func getCachedWellness() -> [IntervalsWellness]? {
        guard let data = UserDefaults.standard.data(forKey: CacheKey.wellness.rawValue) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([IntervalsWellness].self, from: data)
        } catch {
            Logger.error("Failed to decode cached wellness data: \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: CacheKey.activities.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.wellness.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.lastActivityFetch.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.lastWellnessFetch.rawValue)
        Logger.debug("🗑️ Cleared all Intervals.icu cache")
    }
    
    /// Clear all cached data (alias for clearCache)
    func clearAllCache() {
        clearCache()
    }
    
    /// Get cache status for debugging
    func getCacheStatus() -> (activities: Int, wellness: Int, lastActivityFetch: Date?, lastWellnessFetch: Date?) {
        let activities = getCachedActivities()?.count ?? 0
        let wellness = getCachedWellness()?.count ?? 0
        let lastActivityFetch = UserDefaults.standard.object(forKey: CacheKey.lastActivityFetch.rawValue) as? Date
        let lastWellnessFetch = UserDefaults.standard.object(forKey: CacheKey.lastWellnessFetch.rawValue) as? Date
        
        return (activities, wellness, lastActivityFetch, lastWellnessFetch)
    }
    
    /// Check if cache is available and fresh (for fast startup)
    func hasFreshCache() -> Bool {
        let lastFetchKey = CacheKey.lastActivityFetch.rawValue
        
        // Check if we have cached data
        guard getCachedActivities() != nil else {
            return false
        }
        
        // Check if cache is still fresh
        guard let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date else {
            return false
        }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        let isFresh = timeSinceLastFetch < (cacheExpiryHours * 3600)
        
        Logger.debug("📱 Cache status: \(isFresh ? "Fresh" : "Stale") (\(String(format: "%.1f", timeSinceLastFetch / 3600))h ago)")
        return isFresh
    }
}
