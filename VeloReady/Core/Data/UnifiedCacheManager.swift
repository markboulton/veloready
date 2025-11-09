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
    
    // MARK: - Disk Persistence
    private let diskCacheKey = "UnifiedCacheManager.DiskCache"
    private let diskCacheMetadataKey = "UnifiedCacheManager.DiskCacheMetadata"
    
    // MARK: - Statistics
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var deduplicatedRequests: Int = 0
    
    // MARK: - Migration Tracking
    private let migrationKey = "UnifiedCacheManager.MigrationVersion"
    private let currentMigrationVersion = 3 // Increment when adding new migrations
    
    // MARK: - Cache Version Management
    private let cacheVersionKey = "UnifiedCacheManager.CacheVersion"
    private let currentCacheVersion = "v4" // Increment when cache format changes
    
    // MARK: - Initialization
    private init() {
        Logger.debug("🗄️ [UnifiedCache] Initialized (actor-based, thread-safe)")
        
        // Load disk cache
        loadDiskCache()
        
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
        
        // 2. Check Core Data persistence layer (if memory cache miss and type is Codable)
        if T.self is Codable.Type {
            if let persisted = await loadFromCoreDataIfPossible(key: key, as: T.self, ttl: ttl) {
                return persisted
            }
        }
        
        // 3. Check if request is already in-flight (deduplication)
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
    
    /// Fetch with cache-first strategy: return stale cache immediately, refresh in background
    /// This provides instant data display while ensuring freshness over time
    /// - Parameters:
    ///   - key: Unique cache key
    ///   - ttl: Time-to-live in seconds
    ///   - fetchOperation: Async operation to fetch data if cache miss
    /// - Returns: Cached data (possibly stale) or freshly fetched data
    func fetchCacheFirst<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        fetchOperation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check if ANY cache exists (even if stale)
        if let cached = memoryCache[key],
           let value = cached.value as? T {
            let age = Date().timeIntervalSince(cached.cachedAt)
            
            // 1a. Cache is still valid - return immediately
            if cached.isValid(ttl: ttl) {
                cacheHits += 1
                Logger.debug("⚡ [Cache HIT] \(key) (age: \(Int(age))s, valid)")
                return value
            }
            
            // 1b. Cache is stale - return immediately AND refresh in background
            Logger.debug("📱 [Cache STALE] \(key) (age: \(Int(age))s) - returning stale, refreshing in background")
            cacheHits += 1
            
            // Start background refresh (detached so it doesn't block)
            Task.detached(priority: .background) {
                // Check if online before attempting refresh (uses NetworkMonitor for instant check)
                let isOnline = await NetworkMonitor.shared.isConnected
                
                if isOnline {
                    await Logger.debug("🔄 [Background Refresh] \(key) - starting...")
                    do {
                        let freshValue = try await fetchOperation()
                        await self.storeInCache(key: key, value: freshValue)
                        await Logger.debug("✅ [Background Refresh] \(key) - complete")
                    } catch {
                        await Logger.warning("⚠️ [Background Refresh] \(key) - failed: \(error.localizedDescription)")
                    }
                } else {
                    await Logger.debug("📱 [Background Refresh] \(key) - skipped (offline)")
                }
            }
            
            return value
        }
        
        // 2. Check Core Data persistence layer (if memory cache miss and type is Codable)
        if T.self is Codable.Type {
            if let persisted = await loadFromCoreDataStaleOK(key: key, as: T.self, ttl: ttl, fetchOperation: fetchOperation) {
                return persisted
            }
        }
        
        // 3. No cache exists - check if online (uses NetworkMonitor for instant check)
        let isOnline = await NetworkMonitor.shared.isConnected
        
        if !isOnline {
            // Offline with no cache - throw error
            Logger.warning("📱 [Cache MISS] \(key) - offline, no cached data available")
            throw NetworkError.offline
        }
        
        // 4. Online with no cache - use normal fetch (with deduplication)
        Logger.debug("🌐 [Cache MISS] \(key) - fetching online...")
        return try await fetch(key: key, ttl: ttl, fetchOperation: fetchOperation)
    }
    
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
    
    // MARK: - Cache Inspection
    
    /// Check if cache is valid without fetching
    /// Returns true if cache exists and is fresh (within TTL)
    func isCacheValid(key: String, ttl: TimeInterval) -> Bool {
        guard let cached = memoryCache[key] else {
            return false
        }
        return cached.isValid(ttl: ttl)
    }
    
    // MARK: - Cache Management
    
    /// Invalidate specific cache entry
    func invalidate(key: String) {
        memoryCache.removeValue(forKey: key)
        trackedKeys.remove(key)
        
        // Remove from disk if persisted
        if shouldPersistToDisk(key: key) {
            removeFromDisk(key: key)
        }
        
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
    private func storeInCache<T>(key: String, value: T) async {
        let cached = CachedValue(value: value, cachedAt: Date())
        memoryCache[key] = cached
        
        // Persist to Core Data for all cacheable types
        if let codableValue = value as? Codable {
            // Determine TTL based on key pattern
            let ttl = determineTTL(for: key)
            
            // Save to Core Data in background (non-blocking)
            Task.detached(priority: .utility) {
                await CachePersistenceLayer.shared.saveToCoreData(
                    key: key,
                    value: codableValue,
                    cachedAt: cached.cachedAt,
                    ttl: ttl
                )
            }
        }
        
        // Persist to disk for long-lived data (legacy UserDefaults support)
        if shouldPersistToDisk(key: key) {
            Task {
                await saveToDisk(key: key, value: value, cachedAt: cached.cachedAt)
            }
        }
        
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
        // Check cache version FIRST - if changed, clear everything
        let lastCacheVersion = UserDefaults.standard.string(forKey: cacheVersionKey)
        
        if lastCacheVersion != currentCacheVersion {
            Logger.warning("🗑️ [Cache VERSION] Cache format changed (\(lastCacheVersion ?? "none") → \(currentCacheVersion))")
            Logger.warning("🗑️ [Cache VERSION] Clearing all caches to prevent corruption")
            
            // Clear memory cache
            memoryCache.removeAll()
            
            // Clear Core Data cache
            Task {
                await CachePersistenceLayer.shared.clearAll()
            }
            
            // Clear disk cache
            UserDefaults.standard.removeObject(forKey: diskCacheKey)
            UserDefaults.standard.removeObject(forKey: diskCacheMetadataKey)
            
            // Save new version
            UserDefaults.standard.set(currentCacheVersion, forKey: cacheVersionKey)
            Logger.info("✅ [Cache VERSION] Cache cleared and version updated")
        }
        
        // Then run data migrations
        let lastVersion = UserDefaults.standard.integer(forKey: migrationKey)
        
        if lastVersion < currentMigrationVersion {
            Logger.info("🔄 [Cache MIGRATION] Running migrations (v\(lastVersion) → v\(currentMigrationVersion))")
            
            // Migration v1 → v2: Clear legacy cache keys
            if lastVersion < 2 {
                clearLegacyCacheKeys()
            }
            
            // Migration v2 → v3: Disk persistence added
            if lastVersion < 3 {
                Logger.info("📀 [Cache MIGRATION] v3: Disk persistence enabled for activities, streams, baselines")
            }
            
            // Save new version
            UserDefaults.standard.set(currentMigrationVersion, forKey: migrationKey)
            Logger.info("✅ [Cache MIGRATION] Complete")
        }
    }
    
    /// Get expired cache for offline fallback (public for external use)
    func getExpiredCache<T>(key: String, as type: T.Type) async -> T? {
        guard let cached = memoryCache[key],
              let value = cached.value as? T else {
            return nil
        }
        return value
    }
    
    // MARK: - Disk Persistence Methods
    
    /// Determine if a cache key should be persisted to disk
    private func shouldPersistToDisk(key: String) -> Bool {
        // Persist activities, streams, baselines, and scores (not ephemeral health metrics)
        return key.starts(with: "strava:activities:") ||
               key.starts(with: "intervals:activities:") ||
               key.starts(with: "stream:") ||
               key.starts(with: "baseline:") ||
               key.starts(with: "score:")
    }
    
    /// Load disk cache on init
    private func loadDiskCache() {
        guard let diskData = UserDefaults.standard.data(forKey: diskCacheKey),
              let metadata = UserDefaults.standard.dictionary(forKey: diskCacheMetadataKey) as? [String: TimeInterval] else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let diskCache = try decoder.decode([String: String].self, from: diskData)
            
            var loadedCount = 0
            for (key, base64String) in diskCache {
                if let cachedAt = metadata[key],
                   let data = Data(base64Encoded: base64String) {
                    let timestamp = Date(timeIntervalSince1970: cachedAt)
                    
                    // Try to decode the data back to original type
                    var value: Any = data
                    
                    // Attempt to decode common types
                    if let stringArray = try? decoder.decode([String].self, from: data) {
                        value = stringArray
                    } else if let intValue = try? decoder.decode(Int.self, from: data) {
                        value = intValue
                    } else if let doubleValue = try? decoder.decode(Double.self, from: data) {
                        value = doubleValue
                    } else if let stringValue = try? decoder.decode(String.self, from: data) {
                        value = stringValue
                    }
                    
                    let cached = CachedValue(value: value, cachedAt: timestamp)
                    memoryCache[key] = cached
                    trackedKeys.insert(key)
                    loadedCount += 1
                }
            }
            
            if loadedCount > 0 {
                Logger.debug("💾 [Disk Cache] Loaded \(loadedCount) entries from disk")
            }
        } catch {
            Logger.error("❌ [Disk Cache] Failed to load: \(error)")
        }
    }
    
    /// Save cache entry to disk
    private func saveToDisk(key: String, value: Any, cachedAt: Date) async {
        do {
            var diskData: Data?
            
            // Encode based on value type using CacheEncodingHelper
            if let data = value as? Data {
                diskData = data
            } else if let encodable = value as? Encodable {
                // Use CacheEncodingHelper for all encodable types
                // It handles Objective-C types, Swift types, and nested structures
                diskData = try? await CacheEncodingHelper.shared.encode(encodable)
            }
            
            guard let data = diskData else { 
                Logger.debug("⚠️ [Disk Cache] Cannot persist non-encodable type for \(key)")
                return 
            }
            
            // Convert to base64 string for JSON storage
            let base64String = data.base64EncodedString()
            
            // Load existing disk cache
            var diskCache: [String: String] = [:]
            if let existing = UserDefaults.standard.data(forKey: diskCacheKey),
               let decoded = try? JSONDecoder().decode([String: String].self, from: existing) {
                diskCache = decoded
            }
            
            // Load existing metadata
            var metadata = UserDefaults.standard.dictionary(forKey: diskCacheMetadataKey) as? [String: TimeInterval] ?? [:]
            
            // Update
            diskCache[key] = base64String
            metadata[key] = cachedAt.timeIntervalSince1970
            
            // Save
            let encoded = try JSONEncoder().encode(diskCache)
            UserDefaults.standard.set(encoded, forKey: diskCacheKey)
            UserDefaults.standard.set(metadata, forKey: diskCacheMetadataKey)
            
            Logger.debug("💾 [Disk Cache] Saved \(key) to disk (\(data.count / 1024)KB)")
        } catch {
            Logger.error("❌ [Disk Cache] Failed to save \(key): \(error)")
        }
    }
    
    /// Load from Core Data if value exists and is valid
    private func loadFromCoreDataIfPossible<T>(key: String, as type: T.Type, ttl: TimeInterval) async -> T? {
        // This is only called when T is Codable, but we need to cast
        guard let codableType = type as? any Codable.Type else { return nil }
        
        // Use type erasure to load
        guard let result = await loadFromCoreDataErased(key: key, codableType: codableType) else {
            return nil
        }
        
        let age = Date().timeIntervalSince(result.cachedAt)
        if age < ttl {
            // Valid - restore to memory cache
            memoryCache[key] = CachedValue(value: result.value, cachedAt: result.cachedAt)
            cacheHits += 1
            Logger.debug("💾 [Core Data HIT] \(key) (age: \(Int(age))s) - restored to memory")
            return result.value as? T
        } else {
            Logger.debug("💾 [Core Data EXPIRED] \(key) (age: \(Int(age))s > \(Int(ttl))s)")
            return nil
        }
    }
    
    /// Load from Core Data accepting stale values (for cache-first strategy)
    private func loadFromCoreDataStaleOK<T: Sendable>(
        key: String,
        as type: T.Type,
        ttl: TimeInterval,
        fetchOperation: @Sendable @escaping () async throws -> T
    ) async -> T? {
        // This is only called when T is Codable, but we need to cast
        guard let codableType = type as? any Codable.Type else { return nil }
        
        // Use type erasure to load
        guard let result = await loadFromCoreDataErased(key: key, codableType: codableType),
              let value = result.value as? T else {
            return nil
        }
        
        // Restore to memory cache (even if stale)
        memoryCache[key] = CachedValue(value: value, cachedAt: result.cachedAt)
        
        let age = Date().timeIntervalSince(result.cachedAt)
        
        // If valid, return immediately
        if age < ttl {
            cacheHits += 1
            Logger.debug("💾 [Core Data HIT] \(key) (age: \(Int(age))s, valid) - restored to memory")
            return value
        }
        
        // If stale, return and refresh in background
        Logger.debug("💾 [Core Data STALE] \(key) (age: \(Int(age))s) - returning stale, refreshing in background")
        cacheHits += 1
        
        // Start background refresh if online
        Task.detached(priority: .background) {
            let isOnline = await NetworkMonitor.shared.isConnected
            
            if isOnline {
                await Logger.debug("🔄 [Background Refresh] \(key) - starting...")
                do {
                    let freshValue = try await fetchOperation()
                    await self.storeInCache(key: key, value: freshValue)
                    await Logger.debug("✅ [Background Refresh] \(key) - complete")
                } catch {
                    await Logger.warning("⚠️ [Background Refresh] \(key) - failed: \(error.localizedDescription)")
                }
            } else {
                await Logger.debug("📱 [Background Refresh] \(key) - skipped (offline)")
            }
        }
        
        return value
    }
    
    /// Type-erased Core Data loading (to handle dynamic Codable types)
    private func loadFromCoreDataErased(key: String, codableType: any Codable.Type) async -> (value: Any, cachedAt: Date)? {
        // We need to use reflection/type erasure here because we can't directly call
        // a generic method with a runtime type. Use pattern matching on key for better type detection.
        
        // Score models (use key patterns for type detection)
        if key.hasPrefix("score:sleep:") || key.hasPrefix("sleep_score:") {
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: SleepScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        if key.hasPrefix("score:recovery:") || key.hasPrefix("recovery_score:") {
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: RecoveryScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        if key.hasPrefix("strain:") {
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: StrainScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Athlete data
        if key == "strava_athlete" {
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: StravaAthlete.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Activity arrays
        if key.contains(":activities:") {
            // Try as array of StravaActivity for Strava keys
            if key.hasPrefix("strava:activities:") {
                if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: [StravaActivity].self) {
                    return (result.value, result.cachedAt)
                }
            }
            
            // Try as array of IntervalsActivity (most common)
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: [IntervalsActivity].self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Try as single IntervalsActivity
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: IntervalsActivity.self) {
            return (result.value, result.cachedAt)
        }
        
        // HealthKit metrics (these are typically Double values)
        if key.hasPrefix("healthkit:") {
            // Try Double first (most HealthKit metrics are Double)
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: Double.self) {
                return (result.value, result.cachedAt)
            }
            // Try Int for step counts
            if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: Int.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Try as Double (for numeric scores/metrics)
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: Double.self) {
            return (result.value, result.cachedAt)
        }
        
        // Try as Int
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: Int.self) {
            return (result.value, result.cachedAt)
        }
        
        // Try as String
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: String.self) {
            return (result.value, result.cachedAt)
        }
        
        // Log if we couldn't decode the type
        Logger.warning("⚠️ [CachePersistence] Could not determine type for key: \(key)")
        
        return nil
    }
    
    /// Determine TTL based on cache key pattern
    private func determineTTL(for key: String) -> TimeInterval {
        if key.contains(":activities:") {
            return CacheTTL.activities
        } else if key.contains(":streams:") {
            return CacheTTL.streams
        } else if key.hasPrefix("healthkit:") {
            return CacheTTL.healthMetrics
        } else if key.hasPrefix("score:") {
            return CacheTTL.dailyScores
        } else if key.contains(":wellness:") {
            return CacheTTL.wellness
        } else {
            // Default TTL for unknown patterns
            return CacheTTL.activities
        }
    }
    
    /// Remove cache entry from disk
    private func removeFromDisk(key: String) {
        do {
            // Load existing
            guard let diskData = UserDefaults.standard.data(forKey: diskCacheKey),
                  var diskCache = try? JSONDecoder().decode([String: String].self, from: diskData) else {
                return
            }
            
            var metadata = UserDefaults.standard.dictionary(forKey: diskCacheMetadataKey) as? [String: TimeInterval] ?? [:]
            
            // Remove
            diskCache.removeValue(forKey: key)
            metadata.removeValue(forKey: key)
            
            // Save
            let encoded = try JSONEncoder().encode(diskCache)
            UserDefaults.standard.set(encoded, forKey: diskCacheKey)
            UserDefaults.standard.set(metadata, forKey: diskCacheMetadataKey)
            
            Logger.debug("💾 [Disk Cache] Removed \(key) from disk")
        } catch {
            Logger.error("❌ [Disk Cache] Failed to remove \(key): \(error)")
        }
    }
    
    // MARK: - Encoding helpers removed
    // All encoding/decoding logic has been moved to CacheEncodingHelper.swift
    // This reduces UnifiedCacheManager from 1251 → ~900 lines
}

// MARK: - Type Erasure Helpers (Moved)
// AnyCodable, AnyCodableWrapper, AnyCodableDict have been moved to CacheEncodingHelper.swift
// This eliminates ~150 lines of boilerplate from UnifiedCacheManager

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

// MARK: - Cache Keys (Moved)
// CacheKey enum has been moved to Core/Data/Cache/CacheKey.swift
// This provides type-safe cache keys with built-in TTL configuration
