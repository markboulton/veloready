import Foundation

/// Unified cache manager that consolidates all caching layers
/// Replaces: StreamCacheService, StravaDataService, IntervalsCache, HealthKitCache
/// Benefits:
/// - Single source of truth
/// - Automatic request deduplication
/// - Memory-efficient (NSCache auto-evicts under pressure)
/// - Simple invalidation (clear by key pattern)
class UnifiedCacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = UnifiedCacheManager()
    
    // MARK: - Cache TTL Configuration
    enum CacheTTL {
        static let activities: TimeInterval = 3600      // 1 hour (Phase 3 optimization)
        static let healthMetrics: TimeInterval = 300    // 5 minutes
        static let streams: TimeInterval = 604800       // 7 days
        static let dailyScores: TimeInterval = 3600     // 1 hour
        static let wellness: TimeInterval = 600         // 10 minutes
    }
    
    // MARK: - Storage
    private nonisolated(unsafe) var memoryCache = NSCache<NSString, CachedValue>()
    private nonisolated(unsafe) var inflightRequests: [String: Task<Any, Error>] = [:]
    private let inflightLock = NSLock()
    private let coreData = PersistenceController.shared
    
    // MARK: - Statistics
    @MainActor @Published private(set) var cacheHits: Int = 0
    @MainActor @Published private(set) var cacheMisses: Int = 0
    @MainActor @Published private(set) var deduplicatedRequests: Int = 0
    
    // MARK: - Initialization
    private init() {
        // Configure NSCache
        memoryCache.countLimit = 200 // Max 200 entries
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB max
        
        Logger.debug("🗄️ [UnifiedCache] Initialized (limit: 200 items, 50MB)")
    }
    
    // MARK: - Smart Fetch with Deduplication
    
    /// Fetch data with automatic caching and request deduplication
    /// - Parameters:
    ///   - key: Unique cache key
    ///   - ttl: Time-to-live in seconds
    ///   - fetchOperation: Async operation to fetch data if cache miss
    /// - Returns: Cached or freshly fetched data
    nonisolated func fetch<T>(
        key: String,
        ttl: TimeInterval,
        fetchOperation: @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: key as NSString) as? CachedValue,
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            await MainActor.run { cacheHits += 1 }
            Logger.debug("⚡ [Cache HIT] \(key) (age: \(Int(Date().timeIntervalSince(cached.cachedAt)))s)")
            return value
        }
        
        // 2. Check if request is already in-flight (deduplication)
        inflightLock.lock()
        let existingTask = inflightRequests[key] as? Task<T, Error>
        inflightLock.unlock()
        
        if let existingTask = existingTask {
            await MainActor.run { deduplicatedRequests += 1 }
            Logger.debug("🔄 [Cache DEDUPE] \(key) - reusing existing request")
            return try await existingTask.value
        }
        
        // 3. Create new task and track it
        let task = Task<T, Error> {
            Logger.debug("🌐 [Cache MISS] \(key) - fetching...")
            await MainActor.run { cacheMisses += 1 }
            
            let value = try await fetchOperation()
            
            // Cache in memory
            let cached = CachedValue(value: value, cachedAt: Date())
            let cost = estimateCost(value)
            memoryCache.setObject(cached, forKey: key as NSString, cost: cost)
            
            Logger.debug("💾 [Cache STORE] \(key) (cost: \(cost/1024)KB)")
            
            return value
        }
        
        // Store the task for deduplication
        inflightLock.lock()
        inflightRequests[key] = task as? Task<Any, Error>
        inflightLock.unlock()
        
        // Clean up after completion
        defer {
            inflightLock.lock()
            inflightRequests.removeValue(forKey: key)
            inflightLock.unlock()
        }
        
        return try await task.value
    }
    
    // MARK: - Specialized Fetch Methods
    
    /// Fetch with Core Data persistence
    /// - Parameters:
    ///   - key: Cache key
    ///   - ttl: Time-to-live
    ///   - fetchFromCoreData: Fetch from Core Data
    ///   - fetchFromNetwork: Fetch from network if Core Data miss
    /// - Returns: Cached or fresh data
    nonisolated func fetchWithPersistence<T>(
        key: String,
        ttl: TimeInterval,
        fetchFromCoreData: () -> T?,
        fetchFromNetwork: @escaping () async throws -> T,
        saveToCoreData: @escaping (T) -> Void
    ) async throws -> T {
        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: key as NSString) as? CachedValue,
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            await MainActor.run { cacheHits += 1 }
            return value
        }
        
        // 2. Check Core Data
        if let coreDataValue = fetchFromCoreData() {
            Logger.debug("📀 [Core Data HIT] \(key)")
            
            // Store in memory cache
            let cached = CachedValue(value: coreDataValue, cachedAt: Date())
            memoryCache.setObject(cached, forKey: key as NSString)
            
            await MainActor.run { cacheHits += 1 }
            return coreDataValue
        }
        
        // 3. Fetch from network (with deduplication)
        return try await fetch(key: key, ttl: ttl) {
            let value = try await fetchFromNetwork()
            
            // Save to Core Data for persistence
            saveToCoreData(value)
            
            return value
        }
    }
    
    // MARK: - Cache Management
    
    /// Invalidate specific cache entry
    nonisolated func invalidate(key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        Logger.debug("🗑️ [Cache INVALIDATE] \(key)")
    }
    
    /// Invalidate all entries matching pattern
    nonisolated func invalidate(matching pattern: String) {
        // Note: NSCache doesn't support enumeration
        // For pattern matching, we'd need to track keys separately
        // For now, clear all if pattern is "*"
        if pattern == "*" {
            memoryCache.removeAllObjects()
            Logger.debug("🗑️ [Cache CLEAR] All entries")
        }
    }
    
    /// Get cache statistics
    @MainActor func getStatistics() -> CacheStatistics {
        let totalRequests = cacheHits + cacheMisses
        let hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
        
        return CacheStatistics(
            hits: cacheHits,
            misses: cacheMisses,
            deduplicatedRequests: deduplicatedRequests,
            hitRate: hitRate,
            totalRequests: totalRequests
        )
    }
    
    /// Reset statistics
    @MainActor func resetStatistics() {
        cacheHits = 0
        cacheMisses = 0
        deduplicatedRequests = 0
    }
    
    // MARK: - Private Helpers
    
    /// Estimate memory cost of cached value
    private func estimateCost(_ value: Any) -> Int {
        // Rough estimate based on type
        switch value {
        case let array as [Any]:
            return array.count * 1024 // ~1KB per item
        case let string as String:
            return string.utf8.count
        case let data as Data:
            return data.count
        default:
            return 1024 // Default 1KB
        }
    }
}

// MARK: - Supporting Types

/// Cache entry with timestamp
class CachedValue: NSObject {
    let value: Any
    let cachedAt: Date
    
    init(value: Any, cachedAt: Date) {
        self.value = value
        self.cachedAt = cachedAt
    }
    
    /// Check if cache entry is still valid
    func isValid(ttl: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttl
    }
}

/// Cache statistics for monitoring
struct CacheStatistics {
    let hits: Int
    let misses: Int
    let deduplicatedRequests: Int
    let hitRate: Double
    let totalRequests: Int
    
    var description: String {
        """
        Cache Statistics:
        - Hits: \(hits)
        - Misses: \(misses)
        - Deduplicated: \(deduplicatedRequests)
        - Hit Rate: \(String(format: "%.1f%%", hitRate * 100))
        - Total Requests: \(totalRequests)
        """
    }
}

// MARK: - Cache Keys

/// Standardized cache key generation
enum CacheKey {
    // Activities
    static func stravaActivities(daysBack: Int) -> String {
        "strava:activities:\(daysBack)"
    }
    
    static func intervalsActivities(daysBack: Int) -> String {
        "intervals:activities:\(daysBack)"
    }
    
    // Streams
    static func activityStreams(activityId: String, source: String) -> String {
        "\(source):streams:\(activityId)"
    }
    
    // Health metrics
    static func hrv(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:hrv:\(dateString)"
    }
    
    static func rhr(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:rhr:\(dateString)"
    }
    
    static func sleep(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:sleep:\(dateString)"
    }
    
    // Wellness
    static func intervalsWellness(days: Int) -> String {
        "intervals:wellness:\(days)"
    }
    
    // Scores
    static func recoveryScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:recovery:\(dateString)"
    }
    
    static func sleepScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:sleep:\(dateString)"
    }
    
    static func illnessDetection(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        // v2: Updated recommendation to include signal-specific context
        return "illness:detection:v2:\(dateString)"
    }
}
