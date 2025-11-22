import Foundation
import Combine

/// Shared service for fetching and caching Strava activities
/// Supports Pro (365 days) and Free (90 days) tiers
@MainActor
class StravaDataService: ObservableObject {
    static let shared = StravaDataService()
    
    @Published private(set) var activities: [StravaActivity] = []
    @Published private(set) var isLoading = false
    private(set) var lastFetchDate: Date?
    
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

    // MARK: - API-Optimized Methods

    /// Fetch ONLY the latest activity (single API call)
    /// Use this for Today view to minimize API usage
    /// - Returns: Latest activity or nil if none
    func fetchLatestActivity() async throws -> StravaActivity? {
        // Check connection
        guard case .connected = stravaAuthService.connectionState else {
            Logger.debug("ℹ️ [Strava] Not connected, skipping latest activity fetch")
            return nil
        }

        let cacheKey = CacheKey.stravaLatestActivity
        let cacheTTL: TimeInterval = 300 // 5 minutes for latest activity

        Logger.info("🟠 [Strava] Fetching latest activity (1 API call)")

        do {
            let activities = try await cache.fetch(key: cacheKey, ttl: cacheTTL) {
                // Single API call: page=1, perPage=1
                let result = try await self.stravaAPIClient.fetchActivities(
                    page: 1,
                    perPage: 1,
                    after: nil
                )
                Logger.info("✅ [Strava] Fetched latest activity from API")
                return result
            }

            return activities.first
        } catch {
            Logger.error("❌ [Strava] Failed to fetch latest activity: \(error)")
            throw error
        }
    }

    /// Incremental sync - only fetch activities since last sync
    /// Use this for background sync to minimize API calls
    /// - Parameter forceRefresh: Force refresh even if recently synced
    func incrementalSync(forceRefresh: Bool = false) async {
        // Check connection
        guard case .connected = stravaAuthService.connectionState else {
            Logger.debug("ℹ️ [Strava] Not connected, skipping incremental sync")
            return
        }

        // Get last sync timestamp
        let lastSyncKey = "strava_last_sync_timestamp"
        let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date

        // Skip if synced recently (within 5 minutes) unless forced
        if !forceRefresh, let lastSync = lastSync {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            if timeSinceLastSync < 300 { // 5 minutes
                Logger.info("⏭️ [Strava] Skipping sync - last sync \(Int(timeSinceLastSync))s ago")
                return
            }
        }

        Logger.info("🔄 [Strava] Starting incremental sync (after: \(lastSync?.description ?? "nil"))")

        do {
            // Single API call with `after` parameter
            let newActivities = try await stravaAPIClient.fetchActivities(
                page: 1,
                perPage: 200, // Max per page, but only NEW activities
                after: lastSync
            )

            Logger.info("✅ [Strava] Incremental sync: \(newActivities.count) new activities")

            if !newActivities.isEmpty {
                // Merge with existing cached activities
                var merged = activities
                for newActivity in newActivities {
                    // Remove any existing activity with same ID (update)
                    merged.removeAll { $0.id == newActivity.id }
                    merged.append(newActivity)
                }

                // Sort by date descending
                merged.sort { $0.start_date > $1.start_date }
                activities = merged

                Logger.info("✅ [Strava] Merged to \(activities.count) total activities")
            }

            // Update last sync timestamp
            UserDefaults.standard.set(Date(), forKey: lastSyncKey)
            lastFetchDate = Date()

        } catch {
            Logger.error("❌ [Strava] Incremental sync failed: \(error)")
        }
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
