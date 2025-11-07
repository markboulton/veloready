import Foundation
import Combine

/// Shared service for fetching and caching Strava activities
/// Supports Pro (365 days) and Free (90 days) tiers
@MainActor
class StravaDataService: ObservableObject {
    static let shared = StravaDataService()
    
    @Published private(set) var activities: [StravaActivity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastFetchDate: Date?
    
    private let stravaAuthService = StravaAuthService.shared
    private let stravaAPIClient = StravaAPIClient.shared
    private let cache = UnifiedCacheManager.shared
    private let proConfig = ProFeatureConfig.shared
    
    private init() {}
    
    /// Fetch activities for adaptive zones (respects Pro/Free tier)
    /// Pro: 365 days, Free: 90 days
    func fetchActivitiesForZones(forceRefresh: Bool = false) async -> [StravaActivity] {
        // Check connection
        guard case .connected(let athleteId) = stravaAuthService.connectionState else {
            Logger.debug("ℹ️ [Strava] Not connected, skipping fetch")
            return []
        }
        
        // Determine days based on Pro status
        let days = proConfig.hasProAccess ? 365 : 90
        let cacheKey = CacheKey.stravaActivities(daysBack: days)
        let cacheTTL: TimeInterval = 3600 // 1 hour
        
        Logger.info("🟠 [Strava] Fetching activities (\(days) days, Pro: \(proConfig.hasProAccess))")
        
        do {
            let activities = try await cache.fetch(key: cacheKey, ttl: cacheTTL) {
                // Fetch from API
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
                let activities = try await self.fetchAllActivities(after: startDate)
                Logger.info("✅ [Strava] Fetched \(activities.count) activities from API")
                return activities
            }
            
            return activities
        } catch {
            Logger.error("❌ [Strava] Failed to fetch activities: \(error)")
            return []
        }
    }
    
    /// Fetch activities for a specific time range
    /// - Parameters:
    ///   - daysBack: Number of days to fetch (defaults to Pro/Free tier limit)
    ///   - forceRefresh: Force refresh even if cache is valid
    func fetchActivities(daysBack: Int? = nil, forceRefresh: Bool = false) async {
        // Check connection
        guard case .connected(let athleteId) = stravaAuthService.connectionState else {
            Logger.debug("ℹ️ [Strava] Not connected, skipping fetch")
            activities = []
            return
        }
        
        // Determine days: use parameter if provided, otherwise use Pro/Free tier limit
        let days = daysBack ?? (proConfig.hasProAccess ? 365 : 90)
        let cacheKey = CacheKey.stravaActivities(daysBack: days)
        let cacheTTL: TimeInterval = 3600 // 1 hour
        
        Logger.info("🟠 [Strava] Fetching activities (\(days) days, Pro: \(proConfig.hasProAccess))")
        
        do {
            let fetched = try await cache.fetch(key: cacheKey, ttl: cacheTTL) {
                // Fetch from API
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
                let activities = try await self.fetchAllActivities(after: startDate)
                Logger.info("✅ [Strava] Fetched \(activities.count) activities from API")
                return activities
            }
            
            activities = fetched
            lastFetchDate = Date()
        } catch {
            Logger.error("❌ [Strava] Failed to fetch activities: \(error)")
            activities = []
        }
    }
    
    /// Fetch activities if cache is expired or force refresh (legacy method)
    func fetchActivitiesIfNeeded(forceRefresh: Bool = false) async {
        // Use new method with default days
        await fetchActivities(daysBack: nil, forceRefresh: forceRefresh)
    }
    
    /// Fetch all activities with pagination
    private func fetchAllActivities(after startDate: Date?) async throws -> [StravaActivity] {
        var allActivities: [StravaActivity] = []
        var page = 1
        let perPage = 200 // Max allowed by Strava
        
        while true {
            let batch = try await stravaAPIClient.fetchActivities(
                page: page,
                perPage: perPage,
                after: startDate
            )
            
            if batch.isEmpty {
                break
            }
            
            allActivities.append(contentsOf: batch)
            Logger.debug("🟠 [Strava] Fetched page \(page): \(batch.count) activities")
            
            // Stop if we got less than a full page
            if batch.count < perPage {
                break
            }
            
            page += 1
        }
        
        return allActivities
    }
    
    /// Clear the cache
    func clearCache() {
        activities = []
        lastFetchDate = nil
        Logger.debug("🗑️ [StravaDataService] Cache cleared")
    }
}
