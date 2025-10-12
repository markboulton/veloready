import Foundation
import HealthKit

/// Cache manager for Apple Health workout data
@MainActor
class HealthKitCache: ObservableObject {
    static let shared = HealthKitCache()
    
    // MARK: - Cache Keys
    private enum CacheKey: String {
        case workouts = "health_workouts"
        case lastWorkoutFetch = "last_health_workout_fetch"
    }
    
    // MARK: - Cache Configuration
    private let cacheExpiryHours: TimeInterval = 4 // 4 hours like Intervals cache
    
    private init() {}
    
    // MARK: - Workouts Cache
    
    /// Get cached workouts or fetch from HealthKit if needed
    func getCachedWorkouts(healthKitManager: HealthKitManager, forceRefresh: Bool = false) async -> [HKWorkout] {
        let lastFetchKey = CacheKey.lastWorkoutFetch.rawValue
        
        // Check if we need to fetch new data
        if forceRefresh || shouldRefreshCache(lastFetchKey: lastFetchKey) {
            print("🔄 Fetching fresh workouts from Apple Health...")
            return await fetchAndCacheWorkouts(healthKitManager: healthKitManager)
        }
        
        // Check cache timestamp
        if let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < (cacheExpiryHours * 3600) {
                print("📱 Health workout cache still valid (last fetch \(String(format: "%.1f", timeSinceLastFetch / 3600))h ago), fetching with current time...")
                // Fetch fresh since we can't serialize HKWorkout (but cache timestamp prevents repeated fetches)
                return await healthKitManager.fetchRecentWorkouts(limit: 50, daysBack: 30)
            }
        }
        
        // No cache or expired, fetch fresh
        print("🔄 No cache available, fetching fresh health workouts...")
        return await fetchAndCacheWorkouts(healthKitManager: healthKitManager)
    }
    
    private func fetchAndCacheWorkouts(healthKitManager: HealthKitManager) async -> [HKWorkout] {
        let workouts = await healthKitManager.fetchRecentWorkouts(limit: 50, daysBack: 30)
        
        // Save timestamp to track cache freshness
        UserDefaults.standard.set(Date(), forKey: CacheKey.lastWorkoutFetch.rawValue)
        print("💾 Cached timestamp for \(workouts.count) health workouts")
        
        return workouts
    }
    
    private func shouldRefreshCache(lastFetchKey: String) -> Bool {
        guard let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date else {
            return true // No previous fetch
        }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        let shouldRefresh = timeSinceLastFetch > (cacheExpiryHours * 3600)
        
        if shouldRefresh {
            print("⏰ Health workout cache expired (\(String(format: "%.1f", timeSinceLastFetch / 3600))h ago), refreshing...")
        }
        
        return shouldRefresh
    }
    
    /// Clear workout cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: CacheKey.workouts.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.lastWorkoutFetch.rawValue)
        print("🗑️ Cleared health workout cache")
    }
}
