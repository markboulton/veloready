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
            saveToDisk(key: key, value: value, cachedAt: cached.cachedAt)
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
    private func saveToDisk(key: String, value: Any, cachedAt: Date) {
        do {
            let encoder = JSONEncoder()
            var diskData: Data?
            
            // Encode based on value type
            // CRITICAL: Check for Objective-C types FIRST before Encodable check
            if let data = value as? Data {
                diskData = data
            } else if let number = value as? NSNumber {
                // Handle NSNumber/NSCFBoolean (convert to Swift types)
                if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                    diskData = try? encoder.encode(number.boolValue)
                } else if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    diskData = try? encoder.encode(number.intValue)
                } else {
                    diskData = try? encoder.encode(number.doubleValue)
                }
            } else if let nsDict = value as? NSDictionary {
                // Handle NSDictionary (convert to Swift dict)
                if let swiftDict = nsDict as? [String: Any] {
                    diskData = try? encodeDictionary(swiftDict, using: encoder)
                }
            } else if let nsArray = value as? NSArray {
                // Handle NSArray (convert to Swift array)
                if let swiftArray = nsArray as? [Any] {
                    diskData = try? encodeArray(swiftArray, using: encoder)
                }
            } else if let dict = value as? [String: Any] {
                // Handle Swift dictionaries
                diskData = try? encodeDictionary(dict, using: encoder)
            } else if let array = value as? [Any] {
                // Handle Swift arrays
                diskData = try? encodeArray(array, using: encoder)
            } else if let encodable = value as? Encodable {
                // Try to encode any Codable type (Swift types only reach here)
                diskData = try? encodeAny(encodable, using: encoder)
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
            let encoded = try encoder.encode(diskCache)
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
        // a generic method with a runtime type. For now, we'll try common types.
        
        // Try as array of IntervalsActivity (most common)
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: [IntervalsActivity].self) {
            return (result.value, result.cachedAt)
        }
        
        // Try as single IntervalsActivity
        if let result = await CachePersistenceLayer.shared.loadFromCoreData(key: key, as: IntervalsActivity.self) {
            return (result.value, result.cachedAt)
        }
        
        // Try as Double (for scores)
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
        
        // Add more common types as needed...
        
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
    
    /// Helper to encode any Encodable type using type erasure
    private func encodeAny(_ value: Encodable, using encoder: JSONEncoder) throws -> Data? {
        // CRITICAL: Check for Objective-C types FIRST, before checking Encodable
        // NSDictionary/NSArray claim to be Encodable but fail at runtime
        
        // Handle NSDictionary
        if let dict = value as? NSDictionary {
            if let swiftDict = dict as? [String: Any] {
                return try? encodeDictionary(swiftDict, using: encoder)
            }
            return nil
        }
        
        // Handle NSArray
        if let array = value as? NSArray {
            if let swiftArray = array as? [Any] {
                return try? encodeArray(swiftArray, using: encoder)
            }
            return nil
        }
        
        // Convert NSNumber/NSCFBoolean to Swift types
        if let number = value as? NSNumber {
            // Check if it's a boolean (CFBoolean)
            if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                return try encoder.encode(number.boolValue)
            } else if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                return try encoder.encode(number.intValue)
            } else {
                return try encoder.encode(number.doubleValue)
            }
        }
        
        // Try common Swift primitive types
        if let string = value as? String {
            return try encoder.encode(string)
        } else if let int = value as? Int {
            return try encoder.encode(int)
        } else if let double = value as? Double {
            return try encoder.encode(double)
        } else if let bool = value as? Bool {
            return try encoder.encode(bool)
        }
        
        // For complex Swift types, use JSONSerialization as a bridge
        do {
            // Encode to JSON data
            let jsonData = try JSONSerialization.data(
                withJSONObject: try JSONSerialization.jsonObject(
                    with: try encoder.encode(AnyCodable(value)),
                    options: []
                ),
                options: []
            )
            return jsonData
        } catch {
            // If that fails, try direct encoding with a type-erased wrapper
            return try? encoder.encode(AnyCodable(value))
        }
    }
    
    /// Helper to encode dictionaries
    private func encodeDictionary(_ dict: [String: Any], using encoder: JSONEncoder) throws -> Data? {
        // Convert all values to safe Swift types
        var safeDict: [String: Any] = [:]
        
        for (key, value) in dict {
            // Handle NSDictionary/NSArray FIRST (they claim to be Encodable but aren't really)
            if let nsDict = value as? NSDictionary {
                if let swiftDict = nsDict as? [String: Any] {
                    if let encoded = try? encodeDictionary(swiftDict, using: encoder),
                       let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: encoded) {
                        safeDict[key] = decoded
                    }
                }
                continue
            }
            
            if let nsArray = value as? NSArray {
                if let swiftArray = nsArray as? [Any] {
                    if let encoded = try? encodeArray(swiftArray, using: encoder),
                       let decoded = try? JSONDecoder().decode([AnyCodable].self, from: encoded) {
                        safeDict[key] = decoded
                    }
                }
                continue
            }
            
            // Convert NSNumber/NSCFBoolean to Swift types
            if let number = value as? NSNumber {
                if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                    safeDict[key] = number.boolValue
                } else if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    safeDict[key] = number.intValue
                } else {
                    safeDict[key] = number.doubleValue
                }
            } else if let nestedDict = value as? [String: Any] {
                // Recursively handle nested dictionaries
                if let encoded = try? encodeDictionary(nestedDict, using: encoder),
                   let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: encoded) {
                    safeDict[key] = decoded
                }
            } else if let nestedArray = value as? [Any] {
                // Handle nested arrays
                if let encoded = try? encodeArray(nestedArray, using: encoder),
                   let decoded = try? JSONDecoder().decode([AnyCodable].self, from: encoded) {
                    safeDict[key] = decoded
                }
            } else if let encodable = value as? Encodable {
                safeDict[key] = encodable
            } else {
                // Skip non-encodable values
                continue
            }
        }
        
        // Wrap in AnyCodable for type erasure
        let wrappedDict = safeDict.mapValues { value -> AnyCodable in
            if let encodable = value as? Encodable {
                return AnyCodable(encodable)
            } else {
                return AnyCodable(String(describing: value))
            }
        }
        
        return try encoder.encode(wrappedDict)
    }
    
    /// Helper to encode arrays of Encodable types
    private func encodeArray(_ array: [Any], using encoder: JSONEncoder) throws -> Data? {
        // Try common array types first
        if let stringArray = array as? [String] {
            return try encoder.encode(stringArray)
        } else if let intArray = array as? [Int] {
            return try encoder.encode(intArray)
        } else if let boolArray = array as? [Bool] {
            return try encoder.encode(boolArray)
        } else if let doubleArray = array as? [Double] {
            return try encoder.encode(doubleArray)
        }
        
        // For arrays of complex Codable types, convert to safe types first
        var safeArray: [Any] = []
        for item in array {
            // Handle NSDictionary/NSArray FIRST (they claim to be Encodable but aren't really)
            if let nsDict = item as? NSDictionary {
                if let swiftDict = nsDict as? [String: Any],
                   let encoded = try? encodeDictionary(swiftDict, using: encoder),
                   let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: encoded) {
                    safeArray.append(decoded)
                }
                continue
            }
            
            if let nsArray = item as? NSArray {
                if let swiftArray = nsArray as? [Any],
                   let encoded = try? encodeArray(swiftArray, using: encoder),
                   let decoded = try? JSONDecoder().decode([AnyCodable].self, from: encoded) {
                    safeArray.append(decoded)
                }
                continue
            }
            
            // Convert NSNumber/NSCFBoolean to Swift types
            if let number = item as? NSNumber {
                // Check if it's a boolean (CFBoolean)
                if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                    safeArray.append(number.boolValue)
                } else if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    safeArray.append(number.intValue)
                } else {
                    safeArray.append(number.doubleValue)
                }
            } else if let encodable = item as? Encodable {
                safeArray.append(encodable)
            } else {
                return nil // Unsupported type
            }
        }
        
        // Now wrap in AnyCodable
        let wrappedArray = safeArray.map { item -> AnyCodable in
            if let encodable = item as? Encodable {
                return AnyCodable(encodable)
            } else {
                // This shouldn't happen, but provide a fallback
                return AnyCodable(String(describing: item))
            }
        }
        return try encoder.encode(wrappedArray)
    }
}

// MARK: - Type Erasure Helper

/// Type-erased wrapper for Codable values
/// This allows us to encode/decode any Codable type through the cache
private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as common types
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // Encode based on the actual type
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let encodable = value as? Encodable {
            // For complex types, encode as JSON dictionary
            let encoder = JSONEncoder()
            let data = try encoder.encode(AnyCodableWrapper(encodable))
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            try container.encode(AnyCodableDict(json))
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode value of type \(type(of: value))"
                )
            )
        }
    }
}

/// Wrapper for encoding any Encodable type
private struct AnyCodableWrapper: Encodable {
    let value: Encodable
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

/// Wrapper for JSON dictionaries
private struct AnyCodableDict: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodableDict"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let dict = value as? [String: Any] {
            // Convert values safely, filtering out Objective-C types
            let safeDict = dict.compactMapValues { value -> AnyCodable? in
                return convertToEncodable(value)
            }
            try container.encode(safeDict)
        } else if let array = value as? [Any] {
            // Convert elements safely, filtering out Objective-C types
            let safeArray = array.compactMap { value -> AnyCodable? in
                return convertToEncodable(value)
            }
            try container.encode(safeArray)
        }
    }
    
    /// Safely convert Any value to AnyCodable, handling Objective-C types
    private func convertToEncodable(_ value: Any) -> AnyCodable? {
        // Handle NSDictionary
        if let nsDict = value as? NSDictionary, let swiftDict = nsDict as? [String: Any] {
            return AnyCodable(swiftDict.compactMapValues { convertToEncodable($0) })
        }
        
        // Handle NSArray
        if let nsArray = value as? NSArray, let swiftArray = nsArray as? [Any] {
            return AnyCodable(swiftArray.compactMap { convertToEncodable($0) })
        }
        
        // Handle NSNumber/NSCFBoolean
        if let number = value as? NSNumber {
            if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                return AnyCodable(number.boolValue)
            } else if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                return AnyCodable(number.intValue)
            } else {
                return AnyCodable(number.doubleValue)
            }
        }
        
        // Handle Swift Encodable types
        if let encodable = value as? Encodable {
            // Make sure it's not an ObjC type claiming to be Encodable
            if !(value is NSDictionary) && !(value is NSArray) {
                return AnyCodable(encodable)
            }
        }
        
        // Skip non-encodable values
        return nil
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
