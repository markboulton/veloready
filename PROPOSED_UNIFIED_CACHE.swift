import Foundation
import CoreData

/// Unified Cache System - Single Storage, Type-Safe Keys
///
/// **Design Principles:**
/// 1. Single storage backend (Core Data)
/// 2. Type-safe cache keys (no string typos)
/// 3. Memory layer for hot data
/// 4. Automatic TTL management
/// 5. Thread-safe (actor-based)
///
/// **Replaces:**
/// - UnifiedCacheManager (memory + disk)
/// - CachePersistenceLayer (Core Data)
/// - Manual synchronization between layers
///
/// **Result:** Simpler, faster, more reliable

// MARK: - Cache Key (Type-Safe)

struct CacheKey: Hashable, CustomStringConvertible {
    let namespace: Namespace
    let identifier: String
    
    enum Namespace: String {
        case strava
        case intervals
        case healthkit
        case score
        case baseline
        case stream
        case illness
    }
    
    var description: String {
        "\(namespace.rawValue):\(identifier)"
    }
    
    // MARK: - Type-Safe Constructors
    
    /// Strava activities cache key
    /// - Parameter days: Number of days to fetch
    /// - Returns: Cache key like "strava:activities:365"
    static func stravaActivities(days: Int) -> CacheKey {
        CacheKey(namespace: .strava, identifier: "activities:\(days)")
    }
    
    /// Recovery score cache key
    /// - Parameter date: Date of the score
    /// - Returns: Cache key like "score:recovery:2025-11-09"
    static func recoveryScore(date: Date) -> CacheKey {
        let dateStr = date.ISO8601Format(.iso8601Date(timeZone: .current))
        return CacheKey(namespace: .score, identifier: "recovery:\(dateStr)")
    }
    
    /// Sleep score cache key
    static func sleepScore(date: Date) -> CacheKey {
        let dateStr = date.ISO8601Format(.iso8601Date(timeZone: .current))
        return CacheKey(namespace: .score, identifier: "sleep:\(dateStr)")
    }
    
    /// Strain score cache key
    static func strainScore(timestamp: TimeInterval) -> CacheKey {
        CacheKey(namespace: .score, identifier: "strain:\(timestamp)")
    }
    
    /// HealthKit steps cache key
    static func healthKitSteps(timestamp: TimeInterval) -> CacheKey {
        CacheKey(namespace: .healthkit, identifier: "steps:\(timestamp)")
    }
    
    /// Activity stream cache key
    static func stream(activityId: String, source: DataSource) -> CacheKey {
        CacheKey(namespace: .stream, identifier: "\(source.rawValue)_\(activityId)")
    }
    
    /// Baseline cache key (HRV/RHR/Sleep 7-day averages)
    static func baseline(type: String, days: Int = 7) -> CacheKey {
        CacheKey(namespace: .baseline, identifier: "\(type):\(days)day")
    }
    
    /// Illness detection cache key
    static func illness(date: Date, version: String = "v3") -> CacheKey {
        let dateStr = date.ISO8601Format(.iso8601Date(timeZone: .current))
        return CacheKey(namespace: .illness, identifier: "detection:\(version):\(dateStr)")
    }
}

enum DataSource: String {
    case strava
    case intervals
    case healthkit
}

// MARK: - Unified Cache

/// Actor-based cache with memory + Core Data layers
actor UnifiedCache {
    
    // MARK: - Singleton
    static let shared = UnifiedCache()
    
    // MARK: - Storage
    
    /// Memory cache - hot data, fast access
    private var memoryCache: [CacheKey: CachedItem] = [:]
    
    /// Core Data persistence
    private let persistence = PersistenceController.shared
    
    /// Maximum memory cache size (number of items)
    private let maxMemoryItems = 100
    
    // MARK: - Cache Item
    
    private struct CachedItem {
        let data: Data
        let cachedAt: Date
        let ttl: TimeInterval
        
        var isValid: Bool {
            Date().timeIntervalSince(cachedAt) < ttl
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        Logger.debug("💾 UnifiedCache initialized")
        
        // Check cache version
        Task {
            await checkCacheVersion()
        }
    }
    
    private func checkCacheVersion() async {
        if CacheVersion.needsCacheClear(for: CacheVersion.unifiedCacheKey) {
            Logger.warning("🗑️ Cache version changed - clearing all caches")
            await clear()
            CacheVersion.markAsCurrent(for: CacheVersion.unifiedCacheKey)
        }
    }
    
    // MARK: - Public API
    
    /// Get value from cache
    /// - Parameter key: Type-safe cache key
    /// - Returns: Cached value or nil if not found/expired
    func get<T: Codable>(_ key: CacheKey) async -> T? {
        // 1. Check memory cache first (fast)
        if let item = memoryCache[key], item.isValid {
            if let value = try? JSONDecoder().decode(T.self, from: item.data) {
                Logger.debug("⚡ [Cache HIT] \(key) (memory)")
                return value
            }
        }
        
        // 2. Check Core Data (slower, but persistent)
        if let coreDataItem = await loadFromCoreData(key: key) {
            let item = CachedItem(
                data: coreDataItem.data,
                cachedAt: coreDataItem.cachedAt,
                ttl: coreDataItem.ttl
            )
            
            if item.isValid {
                if let value = try? JSONDecoder().decode(T.self, from: item.data) {
                    // Promote to memory cache
                    memoryCache[key] = item
                    Logger.debug("⚡ [Cache HIT] \(key) (Core Data)")
                    return value
                }
            } else {
                // Expired - delete from Core Data
                await deleteFromCoreData(key: key)
            }
        }
        
        Logger.debug("❌ [Cache MISS] \(key)")
        return nil
    }
    
    /// Set value in cache
    /// - Parameters:
    ///   - key: Type-safe cache key
    ///   - value: Value to cache (must be Codable)
    ///   - ttl: Time-to-live in seconds
    func set<T: Codable>(_ key: CacheKey, value: T, ttl: TimeInterval) async {
        guard let data = try? JSONEncoder().encode(value) else {
            Logger.error("Failed to encode value for key: \(key)")
            return
        }
        
        let item = CachedItem(data: data, cachedAt: Date(), ttl: ttl)
        
        // 1. Store in memory
        memoryCache[key] = item
        evictOldestIfNeeded()
        
        // 2. Store in Core Data (persistent)
        await saveToCoreData(key: key, data: data, ttl: ttl)
        
        Logger.debug("💾 [Cache SET] \(key) (ttl: \(Int(ttl))s)")
    }
    
    /// Invalidate a specific cache entry
    func invalidate(_ key: CacheKey) async {
        memoryCache.removeValue(forKey: key)
        await deleteFromCoreData(key: key)
        Logger.debug("🗑️ [Cache INVALIDATE] \(key)")
    }
    
    /// Invalidate all entries in a namespace
    /// Example: invalidate(.strava) clears all Strava cache
    func invalidateNamespace(_ namespace: CacheKey.Namespace) async {
        // Clear from memory
        let keysToRemove = memoryCache.keys.filter { $0.namespace == namespace }
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
        }
        
        // Clear from Core Data
        await deleteFromCoreData(namespace: namespace)
        
        Logger.debug("🗑️ [Cache INVALIDATE] Namespace: \(namespace.rawValue)")
    }
    
    /// Clear all cache entries
    func clear() async {
        memoryCache.removeAll()
        await clearCoreData()
        Logger.debug("🗑️ [Cache CLEAR] All caches cleared")
    }
    
    // MARK: - Memory Management
    
    private func evictOldestIfNeeded() {
        guard memoryCache.count > maxMemoryItems else { return }
        
        // Find oldest item
        let sorted = memoryCache.sorted { $0.value.cachedAt < $1.value.cachedAt }
        if let oldest = sorted.first {
            memoryCache.removeValue(forKey: oldest.key)
            Logger.debug("🗑️ [Cache EVICT] \(oldest.key) (memory full)")
        }
    }
    
    // MARK: - Core Data Operations
    
    private func loadFromCoreData(key: CacheKey) async -> (data: Data, cachedAt: Date, ttl: TimeInterval)? {
        return await withCheckedContinuation { continuation in
            persistence.container.performBackgroundTask { context in
                let request = CacheEntry.fetchRequest()
                request.predicate = NSPredicate(format: "key == %@", key.description)
                request.fetchLimit = 1
                
                guard let entry = try? context.fetch(request).first,
                      let data = entry.data else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: (
                    data: data,
                    cachedAt: entry.cachedAt ?? Date.distantPast,
                    ttl: entry.ttl
                ))
            }
        }
    }
    
    private func saveToCoreData(key: CacheKey, data: Data, ttl: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            persistence.container.performBackgroundTask { context in
                // Delete old entry if exists
                let deleteRequest = CacheEntry.fetchRequest()
                deleteRequest.predicate = NSPredicate(format: "key == %@", key.description)
                if let oldEntry = try? context.fetch(deleteRequest).first {
                    context.delete(oldEntry)
                }
                
                // Create new entry
                let entry = CacheEntry(context: context)
                entry.key = key.description
                entry.data = data
                entry.cachedAt = Date()
                entry.ttl = ttl
                
                try? context.save()
                continuation.resume()
            }
        }
    }
    
    private func deleteFromCoreData(key: CacheKey) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            persistence.container.performBackgroundTask { context in
                let request = CacheEntry.fetchRequest()
                request.predicate = NSPredicate(format: "key == %@", key.description)
                
                if let entries = try? context.fetch(request) {
                    for entry in entries {
                        context.delete(entry)
                    }
                    try? context.save()
                }
                continuation.resume()
            }
        }
    }
    
    private func deleteFromCoreData(namespace: CacheKey.Namespace) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            persistence.container.performBackgroundTask { context in
                let request = CacheEntry.fetchRequest()
                request.predicate = NSPredicate(format: "key BEGINSWITH %@", "\(namespace.rawValue):")
                
                if let entries = try? context.fetch(request) {
                    for entry in entries {
                        context.delete(entry)
                    }
                    try? context.save()
                }
                continuation.resume()
            }
        }
    }
    
    private func clearCoreData() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            persistence.container.performBackgroundTask { context in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CacheEntry")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                try? context.execute(deleteRequest)
                try? context.save()
                continuation.resume()
            }
        }
    }
}

// MARK: - TTL Constants

extension UnifiedCache {
    enum TTL {
        static let activities: TimeInterval = 3600          // 1 hour
        static let streams: TimeInterval = 604800           // 7 days
        static let scores: TimeInterval = 172800            // 48 hours
        static let baselines: TimeInterval = 3600           // 1 hour
        static let healthMetrics: TimeInterval = 300        // 5 minutes
        static let illness: TimeInterval = 86400            // 24 hours
    }
}

// MARK: - Usage Examples

/*
 
 ## Before (Old System)
 
 ```swift
 // String keys - typo-prone, hard to track
 let key = "strava:activities:365"
 let cached = await UnifiedCacheManager.shared.fetch(
     key: key,
     ttl: 3600,
     fetchOperation: { ... }
 )
 ```
 
 ## After (New System)
 
 ```swift
 // Type-safe keys - no typos, autocomplete works
 let key = CacheKey.stravaActivities(days: 365)
 
 // Try cache first
 if let cached: [StravaActivity] = await UnifiedCache.shared.get(key) {
     return cached
 }
 
 // Cache miss - fetch fresh data
 let fresh = try await fetchFromAPI()
 
 // Store in cache
 await UnifiedCache.shared.set(key, value: fresh, ttl: UnifiedCache.TTL.activities)
 ```
 
 ## Benefits
 
 1. **Type Safety**
    - Old: "strava:activities:365" (string, typo-prone)
    - New: CacheKey.stravaActivities(days: 365) (type-safe, autocomplete)
 
 2. **Single Storage**
    - Old: 3 layers (memory, disk, Core Data) with manual sync
    - New: 1 layer (Core Data) with automatic memory promotion
 
 3. **Simpler API**
    - Old: fetch() with ttl and fetchOperation
    - New: get() / set() - simple and clear
 
 4. **Namespace Invalidation**
    - Old: Manual key matching with strings
    - New: await cache.invalidateNamespace(.strava)
 
 5. **Automatic Version Management**
    - Uses CacheVersion.current
    - Auto-clears on version change
    - No manual coordination needed
 
 */
