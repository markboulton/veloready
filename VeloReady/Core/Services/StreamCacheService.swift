import Foundation

/// Service for caching Strava/Intervals stream data to avoid repeated API calls
/// Uses UserDefaults for immediate implementation - can be migrated to Core Data later for better performance
@MainActor
class StreamCacheService {
    static let shared = StreamCacheService()
    
    // MARK: - Properties
    
    private let cacheValidityDuration: TimeInterval = 7 * 24 * 3600  // 7 days
    private let maxCacheSize: Int = 100  // Limit to 100 most recent rides
    
    // Cache metadata stored in UserDefaults
    private let cacheMetadataKey = "stream_cache_metadata"
    
    // Cache hit/miss tracking for monitoring
    private var cacheHits = 0
    private var cacheMisses = 0
    
    // MARK: - Initialization
    
    private init() {
        // Cleanup expired caches on init
        Task {
            cleanupExpiredCaches()
        }
    }
    
    // MARK: - Public API
    
    /// Get cached stream data for an activity
    /// - Parameter activityId: The activity ID (e.g., "strava_12345")
    /// - Returns: Cached samples if available and not expired, nil otherwise
    func getCachedStreams(activityId: String) -> [WorkoutSample]? {
        let cacheKey = "stream_\(activityId)"
        
        // Check if cache exists and is not expired
        let metadata = getCacheMetadata()
        guard let cacheInfo = metadata[activityId],
              cacheInfo.expiresAt > Date() else {
            cacheMisses += 1
            return nil
        }
        
        // Try to load from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let samples = try? JSONDecoder().decode([WorkoutSample].self, from: data) else {
            cacheMisses += 1
            return nil
        }
        
        cacheHits += 1
        Logger.data("⚡ Stream cache HIT: \(activityId) (\(samples.count) samples, age: \(Int(Date().timeIntervalSince(cacheInfo.cachedAt)/60))m)")
        return samples
    }
    
    /// Cache stream data for an activity
    /// - Parameters:
    ///   - samples: The workout samples to cache
    ///   - activityId: The activity ID
    ///   - source: The source of the data ("strava" or "intervals")
    func cacheStreams(_ samples: [WorkoutSample], activityId: String, source: String) {
        guard !samples.isEmpty else { return }
        
        let cacheKey = "stream_\(activityId)"
        
        // Encode samples to Data
        guard let data = try? JSONEncoder().encode(samples) else {
            Logger.warning("⚠️ Failed to encode stream samples for caching")
            return
        }
        
        // Store in UserDefaults
        UserDefaults.standard.set(data, forKey: cacheKey)
        
        // Update metadata
        var metadata = getCacheMetadata()
        metadata[activityId] = StreamCacheMetadata(
            activityId: activityId,
            source: source,
            sampleCount: samples.count,
            cachedAt: Date(),
            expiresAt: Date().addingTimeInterval(cacheValidityDuration)
        )
        
        // Enforce cache size limit
        if metadata.count > maxCacheSize {
            pruneOldestCaches(metadata: &metadata)
        }
        
        saveCacheMetadata(metadata)
        
        Logger.data("💾 Cached \(samples.count) stream samples for \(activityId) (source: \(source))")
    }
    
    /// Invalidate cache for a specific activity
    /// - Parameter activityId: The activity ID to invalidate
    func invalidateCache(activityId: String) {
        let cacheKey = "stream_\(activityId)"
        UserDefaults.standard.removeObject(forKey: cacheKey)
        
        var metadata = getCacheMetadata()
        metadata.removeValue(forKey: activityId)
        saveCacheMetadata(metadata)
        
        Logger.data("🗑️ Invalidated stream cache for \(activityId)")
    }
    
    /// Clear all cached stream data
    func clearAllCaches() {
        let metadata = getCacheMetadata()
        
        for activityId in metadata.keys {
            let cacheKey = "stream_\(activityId)"
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
        
        UserDefaults.standard.removeObject(forKey: cacheMetadataKey)
        
        Logger.data("🗑️ Cleared all stream caches (\(metadata.count) activities)")
    }
    
    /// Get cache statistics for monitoring
    func getCacheStats() -> StreamCacheStats {
        let metadata = getCacheMetadata()
        let totalEntries = metadata.count
        let totalSamples = metadata.values.reduce(0) { $0 + $1.sampleCount }
        let totalHits = cacheHits
        let totalMisses = cacheMisses
        let totalRequests = totalHits + totalMisses
        let hitRate = totalRequests > 0 ? Double(totalHits) / Double(totalRequests) : 0
        
        return StreamCacheStats(
            totalEntries: totalEntries,
            totalSamples: totalSamples,
            cacheHits: totalHits,
            cacheMisses: totalMisses,
            hitRate: hitRate
        )
    }
    
    /// Log cache statistics
    func logCacheStats() {
        let stats = getCacheStats()
        Logger.data("📊 Stream Cache Stats:")
        Logger.data("   Entries: \(stats.totalEntries)")
        Logger.data("   Total Samples: \(stats.totalSamples)")
        Logger.data("   Hits: \(stats.cacheHits), Misses: \(stats.cacheMisses)")
        Logger.data("   Hit Rate: \(Int(stats.hitRate * 100))%")
    }
    
    // MARK: - Private Methods
    
    private func getCacheMetadata() -> [String: StreamCacheMetadata] {
        guard let data = UserDefaults.standard.data(forKey: cacheMetadataKey) else {
            return [:]
        }
        guard let metadata = try? JSONDecoder().decode([String: StreamCacheMetadata].self, from: data) else {
            return [:]
        }
        return metadata
    }
    
    private func saveCacheMetadata(_ metadata: [String: StreamCacheMetadata]) {
        guard let data = try? JSONEncoder().encode(metadata) else { return }
        UserDefaults.standard.set(data, forKey: cacheMetadataKey)
    }
    
    private func cleanupExpiredCaches() {
        var metadata = getCacheMetadata()
        let now = Date()
        var removedCount = 0
        
        for (activityId, cacheInfo) in metadata {
            if cacheInfo.expiresAt < now {
                let cacheKey = "stream_\(activityId)"
                UserDefaults.standard.removeObject(forKey: cacheKey)
                metadata.removeValue(forKey: activityId)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            saveCacheMetadata(metadata)
            Logger.data("🧹 Cleaned up \(removedCount) expired stream caches")
        }
    }
    
    private func pruneOldestCaches(metadata: inout [String: StreamCacheMetadata]) {
        // Sort by cachedAt date and remove oldest entries
        let sorted = metadata.sorted { $0.value.cachedAt < $1.value.cachedAt }
        let toRemove = sorted.prefix(sorted.count - maxCacheSize)
        
        for (activityId, _) in toRemove {
            let cacheKey = "stream_\(activityId)"
            UserDefaults.standard.removeObject(forKey: cacheKey)
            metadata.removeValue(forKey: activityId)
        }
        
        Logger.data("🧹 Pruned \(toRemove.count) oldest stream caches (limit: \(maxCacheSize))")
    }
}

// MARK: - Supporting Types

private struct StreamCacheMetadata: Codable {
    let activityId: String
    let source: String
    let sampleCount: Int
    let cachedAt: Date
    let expiresAt: Date
}

struct StreamCacheStats {
    let totalEntries: Int
    let totalSamples: Int
    let cacheHits: Int
    let cacheMisses: Int
    let hitRate: Double
}
