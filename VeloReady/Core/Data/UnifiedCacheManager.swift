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
    private func storeInCache(key: String, value: Any) {
        let cached = CachedValue(value: value, cachedAt: Date())
        memoryCache[key] = cached
        trackedKeys.insert(key)
        
        let cost = estimateCost(value)
        Logger.debug("💾 [Cache STORE] \(key) (cost: \(cost/1024)KB)")
        
        // Persist to disk for long-lived data
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
    
    /// Get expired cache for offline fallback
    private func getExpiredCache<T>(key: String, as type: T.Type) -> T? {
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
            if let data = value as? Data {
                diskData = data
            } else if let dict = value as? [String: Any] {
                // Handle dictionaries (including NSDictionary)
                diskData = try? encodeDictionary(dict, using: encoder)
            } else if let array = value as? [Any] {
                // Handle arrays (including NSArray)
                diskData = try? encodeArray(array, using: encoder)
            } else if let encodable = value as? Encodable {
                // Try to encode any Codable type
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
        // Convert NSNumber/NSCFBoolean to Swift types first
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
        
        // Try common primitive types first for efficiency
        if let string = value as? String {
            return try encoder.encode(string)
        } else if let int = value as? Int {
            return try encoder.encode(int)
        } else if let double = value as? Double {
            return try encoder.encode(double)
        } else if let bool = value as? Bool {
            return try encoder.encode(bool)
        }
        
        // For complex types, use JSONSerialization as a bridge
        // This works because Encodable can be converted to JSON
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
            try container.encode(dict.mapValues { AnyCodable($0 as! Encodable) })
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0 as! Encodable) })
        }
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
