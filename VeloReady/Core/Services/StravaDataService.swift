import Foundation
import Combine

/// Shared service for fetching and caching Strava activities
@MainActor
class StravaDataService: ObservableObject {
    static let shared = StravaDataService()
    
    @Published private(set) var activities: [StravaActivity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastFetchDate: Date?
    
    private let stravaAuthService = StravaAuthService.shared
    private let stravaAPIClient = StravaAPIClient.shared
    private let cacheExpiryMinutes = 5 // Cache for 5 minutes
    
    private init() {}
    
    /// Fetch activities if cache is expired or force refresh
    func fetchActivitiesIfNeeded(forceRefresh: Bool = false) async {
        // Check if we need to refresh
        if !forceRefresh, let lastFetch = lastFetchDate {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < TimeInterval(cacheExpiryMinutes * 60) {
                Logger.debug("🟠 [StravaDataService] Using cached data (\(Int(timeSinceLastFetch))s old)")
                return
            }
        }
        
        // Check connection
        guard case .connected(let athleteId) = stravaAuthService.connectionState else {
            Logger.debug("ℹ️ [StravaDataService] Strava not connected")
            activities = []
            return
        }
        
        guard !isLoading else {
            Logger.warning("️ [StravaDataService] Already loading, skipping duplicate request")
            return
        }
        
        isLoading = true
        Logger.debug("🟠 [StravaDataService] Fetching activities (athlete: \(athleteId ?? "unknown"))")
        
        do {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())
            let fetchedActivities = try await stravaAPIClient.fetchActivities(
                page: 1,
                perPage: 50,
                after: thirtyDaysAgo
            )
            
            activities = fetchedActivities
            lastFetchDate = Date()
            
            Logger.debug("✅ [StravaDataService] Loaded \(fetchedActivities.count) activities from Strava")
        } catch {
            Logger.warning("️ [StravaDataService] Fetch failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Clear the cache
    func clearCache() {
        activities = []
        lastFetchDate = nil
        Logger.debug("🗑️ [StravaDataService] Cache cleared")
    }
}
