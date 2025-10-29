import Foundation

/// Service for caching Strava/Intervals stream data to avoid repeated API calls
/// Uses file-based storage for large activities (>4MB) and UserDefaults for smaller ones
@MainActor
class StreamCacheService {
    static let shared = StreamCacheService()
    
    // MARK: - Properties
    
    private let cacheValidityDuration: TimeInterval = 7 * 24 * 3600  // 7 days
    private let maxCacheSize: Int = 100  // Limit to 100 most recent rides
    private let userDefaultsSizeLimit: Int = 3_500_000  // 3.5MB limit for UserDefaults (iOS limit is 4MB)
    
    // Cache metadata stored in UserDefaults
    private let cacheMetadataKey = "stream_cache_metadata"
    
    // Cache hit/miss tracking for monitoring
    private var cacheHits = 0
    private var cacheMisses = 0
    
    // File-based cache directory
    private var cacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("StreamCache")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Create cache directory if needed
        if let cacheDir = cacheDirectory {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
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
        
        // Try file-based cache first (for large activities)
        if cacheInfo.isFileBased, let samples = loadFromFile(activityId: activityId) {
            cacheHits += 1
            Logger.data("⚡ Stream cache HIT (file): \(activityId) (\(samples.count) samples, age: \(Int(Date().timeIntervalSince(cacheInfo.cachedAt)/60))m)")
            return samples
        }
        
        // Fallback to UserDefaults (for smaller activities)
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
        
        // Determine storage method based on size
        let isFileBased = data.count > userDefaultsSizeLimit
        
        if isFileBased {
            // Store in file system for large activities
            saveToFile(data: data, activityId: activityId)
            Logger.data("💾 Cached \(samples.count) stream samples for \(activityId) (source: \(source), file-based: \(String(format: "%.1f", Double(data.count)/1_000_000))MB)")
        } else {
            // Store in UserDefaults for smaller activities
            UserDefaults.standard.set(data, forKey: cacheKey)
            Logger.data("💾 Cached \(samples.count) stream samples for \(activityId) (source: \(source))")
        }
        
        // Update metadata
        var metadata = getCacheMetadata()
        metadata[activityId] = StreamCacheMetadata(
            activityId: activityId,
            source: source,
            sampleCount: samples.count,
            cachedAt: Date(),
            expiresAt: Date().addingTimeInterval(cacheValidityDuration),
            isFileBased: isFileBased
        )
        
        // Enforce cache size limit
        if metadata.count > maxCacheSize {
            pruneOldestCaches(metadata: &metadata)
        }
        
        saveCacheMetadata(metadata)
    }
    
    /// Invalidate cache for a specific activity
    /// - Parameter activityId: The activity ID to invalidate
    func invalidateCache(activityId: String) {
        let cacheKey = "stream_\(activityId)"
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: cacheKey)
        
        // Remove from file system
        deleteFile(activityId: activityId)
        
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
            deleteFile(activityId: activityId)
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
    
    // MARK: - One-Time Migration
    
    /// Migrate legacy UserDefaults-based streams to file-based storage
    /// This runs once on first launch after update to free up UserDefaults space
    func migrateLegacyStreamsToFileCache() {
        let migrationKey = "stream_cache_migration_v2_complete"
        
        // Skip if already migrated
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            return
        }
        
        Logger.debug("🔄 [StreamCache] Starting one-time migration of legacy streams...")
        
        var migratedCount = 0
        var deletedCount = 0
        var deletedSize: Int64 = 0
        
        // Find all stream_* keys in UserDefaults
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let streamKeys = allKeys.filter { $0.hasPrefix("stream_strava_") || $0.hasPrefix("stream_intervals_") }
        
        for key in streamKeys {
            guard let data = UserDefaults.standard.data(forKey: key) else { continue }
            
            // Extract activity ID from key (e.g., "stream_strava_12345" → "strava_12345")
            let activityId = String(key.dropFirst("stream_".count))
            
            // Migrate to file-based storage if large (>1MB)
            if data.count > 1_000_000 {
                saveToFile(data: data, activityId: activityId)
                deletedSize += Int64(data.count)
                migratedCount += 1
                Logger.debug("   ✓ Migrated \(activityId) (\(String(format: "%.1f", Double(data.count)/1_000_000))MB) to file")
            } else {
                // For smaller streams, just track deletion
                deletedSize += Int64(data.count)
                deletedCount += 1
            }
            
            // Always remove from UserDefaults to free up space
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        UserDefaults.standard.synchronize()
        
        Logger.debug("✅ [StreamCache] Migration complete: \(migratedCount) streams migrated, \(deletedCount) deleted (\(String(format: "%.1f", Double(deletedSize)/1_000_000))MB freed)")
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
                deleteFile(activityId: activityId)
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
            deleteFile(activityId: activityId)
            metadata.removeValue(forKey: activityId)
        }
        
        Logger.data("🧹 Pruned \(toRemove.count) oldest stream caches (limit: \(maxCacheSize))")
    }
    
    // MARK: - File-Based Storage
    
    private func saveToFile(data: Data, activityId: String) {
        guard let cacheDir = cacheDirectory else { return }
        let fileURL = cacheDir.appendingPathComponent("\(activityId).json")
        
        do {
            try data.write(to: fileURL)
        } catch {
            Logger.error("Failed to save stream cache to file: \(error)")
        }
    }
    
    private func loadFromFile(activityId: String) -> [WorkoutSample]? {
        guard let cacheDir = cacheDirectory else { return nil }
        let fileURL = cacheDir.appendingPathComponent("\(activityId).json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([WorkoutSample].self, from: data)
        } catch {
            Logger.error("Failed to load stream cache from file: \(error)")
            return nil
        }
    }
    
    private func deleteFile(activityId: String) {
        guard let cacheDir = cacheDirectory else { return }
        let fileURL = cacheDir.appendingPathComponent("\(activityId).json")
        
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Supporting Types

private struct StreamCacheMetadata: Codable {
    let activityId: String
    let source: String
    let sampleCount: Int
    let cachedAt: Date
    let expiresAt: Date
    let isFileBased: Bool
    
    // For backward compatibility with existing caches
    init(activityId: String, source: String, sampleCount: Int, cachedAt: Date, expiresAt: Date, isFileBased: Bool = false) {
        self.activityId = activityId
        self.source = source
        self.sampleCount = sampleCount
        self.cachedAt = cachedAt
        self.expiresAt = expiresAt
        self.isFileBased = isFileBased
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId = try container.decode(String.self, forKey: .activityId)
        source = try container.decode(String.self, forKey: .source)
        sampleCount = try container.decode(Int.self, forKey: .sampleCount)
        cachedAt = try container.decode(Date.self, forKey: .cachedAt)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        isFileBased = try container.decodeIfPresent(Bool.self, forKey: .isFileBased) ?? false
    }
}

struct StreamCacheStats {
    let totalEntries: Int
    let totalSamples: Int
    let cacheHits: Int
    let cacheMisses: Int
    let hitRate: Double
}
