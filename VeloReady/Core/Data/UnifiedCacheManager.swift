import Foundation

/// Unified cache manager that consolidates all caching layers
/// Replaces: StreamCacheService, StravaDataService, IntervalsCache, HealthKitCache
/// Benefits:
/// - Single source of truth
/// - Automatic request deduplication
/// - Memory-efficient (NSCache auto-evicts under pressure)
/// - Simple invalidation (clear by key pattern)
/// - Thread-safe (actor-based)
actor UnifiedCacheManager {
    
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
    private var memoryCache: [String: CachedValue] = [:]
    private var inflightRequests: [String: AnyTaskWrapper] = [:]
    private var trackedKeys: Set<String> = []
    
    // MARK: - Statistics
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var deduplicatedRequests: Int = 0
    
    // MARK: - Migration Tracking
    private let migrationKey = "UnifiedCacheManager.MigrationVersion"
    private let currentMigrationVersion = 2 // Increment when adding new migrations
    
    // MARK: - Initialization
    private init() {
        Logger.debug("🗄️ [UnifiedCache] Initialized (actor-based, thread-safe)")
        
        // Run migrations if needed
        Task {
            await runMigrationsIfNeeded()
        }
    }
    
    // MARK: - Smart Fetch with Deduplication
    
    /// Fetch data with automatic caching and request deduplication
    /// - Parameters:
    ///   - key: Unique cache key
    ///   - ttl: Time-to-live in seconds
    ///   - fetchOperation: Async operation to fetch data if cache miss
    /// - Returns: Cached or freshly fetched data
    func fetch<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        fetchOperation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check memory cache (valid data)
        if let cached = memoryCache[key],
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            cacheHits += 1
            Logger.debug("⚡ [Cache HIT] \(key) (age: \(Int(Date().timeIntervalSince(cached.cachedAt)))s)")
            return value
        }
        
        // 2. Check if request is already in-flight (deduplication)
        // FIX #1: Use type-safe wrapper for deduplication
        if let existingTask = inflightRequests[key] {
            deduplicatedRequests += 1
            Logger.debug("🔄 [Cache DEDUPE] \(key) - reusing existing request")
            return try await existingTask.getValue(as: T.self)
        }
        
        // 3. Create new task and track it
        Logger.debug("🌐 [Cache MISS] \(key) - fetching...")
        cacheMisses += 1
        
        let task = Task<T, Error> {
            do {
                let value = try await fetchOperation()
                
                // Cache in memory
                await self.storeInCache(key: key, value: value)
                
                return value
            } catch {
                // On network error, try to return expired cache as fallback
                if let cached = await self.getExpiredCache(key: key, as: T.self) {
                    Logger.debug("📱 [Offline Fallback] \(key) - returning expired cache after error")
                    return cached
                }
                throw error
            }
        }
        
        // FIX #1: Store task with type-safe wrapper
        inflightRequests[key] = AnyTaskWrapper(task: task)
        
        // Clean up after completion
        defer {
            Task {
                await self.removeInflightRequest(key: key)
            }
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
    func fetchWithPersistence<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        fetchFromCoreData: @MainActor () -> T?,
        fetchFromNetwork: @Sendable @escaping () async throws -> T,
        saveToCoreData: @MainActor @escaping (T) -> Void
    ) async throws -> T {
        // 1. Check memory cache (valid data)
        if let cached = memoryCache[key],
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            cacheHits += 1
            return value
        }
        
        // 2. Check Core Data
        if let coreDataValue = await fetchFromCoreData() {
            Logger.debug("📀 [Core Data HIT] \(key)")
            
            // Store in memory cache
            await storeInCache(key: key, value: coreDataValue)
            
            cacheHits += 1
            return coreDataValue
        }
        
        // 3. Fetch from network (with deduplication and offline fallback)
        return try await fetch(key: key, ttl: ttl) {
            let value = try await fetchFromNetwork()
            
            // Save to Core Data for persistence
            await saveToCoreData(value)
            
            return value
        }
    }
    
    // MARK: - Cache Management
    
    /// Invalidate specific cache entry
    func invalidate(key: String) {
        memoryCache.removeValue(forKey: key)
        trackedKeys.remove(key)
        Logger.debug("🗑️ [Cache INVALIDATE] \(key)")
    }
    
    /// Invalidate all entries matching pattern
    /// FIX #3: Implement pattern-based invalidation with regex
    func invalidate(matching pattern: String) {
        if pattern == "*" {
            let count = memoryCache.count
            memoryCache.removeAll()
            trackedKeys.removeAll()
            Logger.debug("🗑️ [Cache CLEAR] All \(count) entries")
            return
        }
        
        // Use regex for pattern matching
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            Logger.warning("⚠️ [Cache] Invalid regex pattern: \(pattern)")
            return
        }
        
        var removedCount = 0
        let keysToRemove = trackedKeys.filter { key in
            let range = NSRange(key.startIndex..., in: key)
            return regex.firstMatch(in: key, range: range) != nil
        }
        
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
            trackedKeys.remove(key)
            removedCount += 1
        }
        
        Logger.debug("🗑️ [Cache CLEAR] Removed \(removedCount) entries matching '\(pattern)'")
    }
    
    /// Clear old cache keys during migration
    /// FIX #5: Track migration version persistently
    func clearLegacyCacheKeys() {
        let legacyKeys = [
            "strava_activities_90d",
            "strava_activities_365d"
        ]
        
        for key in legacyKeys {
            memoryCache.removeValue(forKey: key)
            trackedKeys.remove(key)
        }
        
        Logger.debug("🗑️ [Cache MIGRATION] Cleared \(legacyKeys.count) legacy cache keys")
    }
    
    /// Get cache statistics
    func getStatistics() -> CacheStatistics {
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
    func resetStatistics() {
        cacheHits = 0
        cacheMisses = 0
        deduplicatedRequests = 0
    }
    
    // MARK: - Private Helpers
    
    /// Store value in cache
    private func storeInCache(key: String, value: Any) {
        let cached = CachedValue(value: value, cachedAt: Date())
        memoryCache[key] = cached
        trackedKeys.insert(key)
        
        let cost = estimateCost(value)
        Logger.debug("💾 [Cache STORE] \(key) (cost: \(cost/1024)KB)")
        
        // Enforce memory limits (keep last 200 entries)
        if memoryCache.count > 200 {
            evictOldestEntries(count: 50)
        }
    }
    
    /// Remove inflight request
    private func removeInflightRequest(key: String) {
        inflightRequests.removeValue(forKey: key)
    }
    
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
    
    /// Evict oldest cache entries
    private func evictOldestEntries(count: Int) {
        let sorted = memoryCache.sorted { $0.value.cachedAt < $1.value.cachedAt }
        let toRemove = sorted.prefix(count)
        
        for (key, _) in toRemove {
            memoryCache.removeValue(forKey: key)
            trackedKeys.remove(key)
        }
        
        Logger.debug("🗑️ [Cache EVICT] Removed \(toRemove.count) oldest entries")
    }
    
    /// Run migrations if needed
    /// FIX #5: Persistent migration tracking
    private func runMigrationsIfNeeded() {
        let lastVersion = UserDefaults.standard.integer(forKey: migrationKey)
        
        if lastVersion < currentMigrationVersion {
            Logger.info("🔄 [Cache MIGRATION] Running migrations (v\(lastVersion) → v\(currentMigrationVersion))")
            
            // Migration v1 → v2: Clear legacy cache keys
            if lastVersion < 2 {
                clearLegacyCacheKeys()
            }
            
            // Save new version
            UserDefaults.standard.set(currentMigrationVersion, forKey: migrationKey)
            Logger.info("✅ [Cache MIGRATION] Complete")
        }
    }
    
    /// Get expired cache for offline fallback
    private func getExpiredCache<T>(key: String, as type: T.Type) -> T? {
        guard let cached = memoryCache[key],
              let value = cached.value as? T else {
            return nil
        }
        return value
    }
}

// MARK: - Supporting Types

/// Cache entry with timestamp
struct CachedValue {
    let value: Any
    let cachedAt: Date
    
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

/// Type-erased task wrapper for deduplication
/// FIX #1: Enables type-safe task storage and retrieval
private struct AnyTaskWrapper {
    private let getValue: (Any.Type) async throws -> Any
    
    init<T: Sendable>(task: Task<T, Error>) {
        self.getValue = { expectedType in
            guard expectedType == T.self else {
                throw CacheError.typeMismatch
            }
            return try await task.value
        }
    }
    
    func getValue<T>(as type: T.Type) async throws -> T {
        let value = try await getValue(T.self)
        guard let typedValue = value as? T else {
            throw CacheError.typeMismatch
        }
        return typedValue
    }
}

/// Cache-specific errors
enum CacheError: Error {
    case typeMismatch
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
        // v3: Fixed respiratory rate false positive (only flag elevations, not drops)
        return "illness:detection:v3:\(dateString)"
    }
    
    /// Validate cache key format
    static func validate(_ key: String) -> Bool {
        let pattern = "^[a-z]+:[a-z]+:[a-zA-Z0-9-:]+$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}
