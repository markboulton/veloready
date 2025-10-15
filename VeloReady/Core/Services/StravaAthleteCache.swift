import Foundation

/// Simple cache for Strava athlete data to avoid repeated API calls
/// Caches for 1 hour to balance freshness with performance
@MainActor
class StravaAthleteCache {
    static let shared = StravaAthleteCache()
    
    private var cachedAthlete: StravaAthlete?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    /// Get cached athlete data or fetch if expired
    func getAthlete() async throws -> StravaAthlete {
        // Check if cache is valid
        if let cached = cachedAthlete,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            Logger.debug("📦 Using cached Strava athlete data (age: \(Int(Date().timeIntervalSince(timestamp)))s)")
            return cached
        }
        
        // Fetch fresh data
        Logger.debug("🌐 Fetching fresh Strava athlete data...")
        let athlete = try await StravaAPIClient.shared.fetchAthlete()
        
        // Cache it
        cachedAthlete = athlete
        cacheTimestamp = Date()
        
        return athlete
    }
    
    /// Clear cache (call when user logs out or changes accounts)
    func clearCache() {
        cachedAthlete = nil
        cacheTimestamp = nil
        Logger.debug("🗑️ Strava athlete cache cleared")
    }
    
    /// Get cached FTP without making API call (nil if not cached or expired)
    var cachedFTP: Double? {
        guard let cached = cachedAthlete,
              let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheDuration,
              let ftp = cached.ftp,
              ftp > 0 else {
            return nil
        }
        return Double(ftp)
    }
}
