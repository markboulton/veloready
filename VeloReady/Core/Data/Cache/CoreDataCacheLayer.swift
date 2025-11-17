import Foundation

/// CoreData-based cache layer wrapping existing CachePersistenceLayer
///
/// **Purpose:**
/// Persistent, queryable cache using SQLite. Ideal for structured data that needs
/// to survive app updates and be searchable.
///
/// **Features:**
/// - Wraps existing CachePersistenceLayer
/// - Provides consistent CacheLayer interface
/// - Type-safe queries
/// - Automatic schema migrations
///
/// **Use Cases:**
/// - Score models (RecoveryScore, SleepScore, StrainScore)
/// - Activity arrays
/// - Athlete data
/// - Any Codable type that needs persistence
///
/// **Performance:**
/// - Read: ~10-20ms (SQLite query)
/// - Write: ~20-30ms (SQLite insert/update)
/// - Slower than memory/disk but more reliable
actor CoreDataCacheLayer: CacheLayer {
    
    // MARK: - Dependencies
    
    private let persistenceLayer = CachePersistenceLayer.shared
    
    // MARK: - CacheLayer Protocol
    
    func get<T: Sendable>(key: String, ttl: TimeInterval) async -> T? {
        // Only proceed if T is Codable
        guard T.self is any Codable.Type else {
            return nil
        }
        
        // Try to load from Core Data using type pattern matching
        if let result = await loadFromCoreData(key: key, as: T.self) {
            let age = Date().timeIntervalSince(result.cachedAt)
            
            if age < ttl {
                Logger.debug("💾 [CoreDataCache HIT] \(key) (age: \(Int(age))s)")
                return result.value as? T
            } else {
                Logger.debug("💾 [CoreDataCache EXPIRED] \(key) (age: \(Int(age))s > \(Int(ttl))s)")
                return nil
            }
        }
        
        // Don't log individual layer misses - CacheOrchestrator logs final result
        return nil
    }
    
    func set<T: Sendable>(key: String, value: T, cachedAt: Date) async {
        // Only proceed if value is Codable
        guard let codableValue = value as? Codable else {
            Logger.warning("⚠️ [CoreDataCache] Value for \(key) is not Codable")
            return
        }
        
        // Determine TTL based on key pattern (reuse logic from UnifiedCacheManager)
        let ttl = determineTTL(for: key)
        
        // Save to Core Data
        await persistenceLayer.saveToCoreData(
            key: key,
            value: codableValue,
            cachedAt: cachedAt,
            ttl: ttl
        )
        
        Logger.debug("💾 [CoreDataCache SET] \(key)")
    }
    
    func remove(key: String) async {
        // Core Data layer doesn't support individual key removal yet
        // This would require updating CachePersistenceLayer
        Logger.debug("⚠️ [CoreDataCache] Remove not implemented for \(key)")
    }
    
    func removeMatching(pattern: String) async {
        // Core Data layer doesn't support pattern-based removal yet
        // This would require updating CachePersistenceLayer
        Logger.debug("⚠️ [CoreDataCache] RemoveMatching not implemented for \(pattern)")
    }
    
    func contains(key: String, ttl: TimeInterval) async -> Bool {
        guard let result = await loadFromCoreData(key: key, as: Any.self) else {
            return false
        }
        
        let age = Date().timeIntervalSince(result.cachedAt)
        return age < ttl
    }
    
    // MARK: - Private Helpers
    
    /// Type-erased Core Data loading (adapted from UnifiedCacheManager)
    private func loadFromCoreData<T>(key: String, as type: T.Type) async -> (value: Any, cachedAt: Date)? {
        // Score models (use key patterns for type detection)
        if key.hasPrefix("score:sleep:") || key.hasPrefix("sleep_score:") {
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: SleepScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        if key.hasPrefix("score:recovery:") || key.hasPrefix("recovery_score:") {
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: RecoveryScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        if key.hasPrefix("strain:") {
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: StrainScore.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Athlete data
        if key == "strava_athlete" {
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: StravaAthlete.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Activity arrays
        if key.contains(":activities:") {
            // Try as array of StravaActivity for Strava keys
            if key.hasPrefix("strava:activities:") {
                if let result = await persistenceLayer.loadFromCoreData(key: key, as: [StravaActivity].self) {
                    return (result.value, result.cachedAt)
                }
            }
            
            // Try as array of Activity (most common)
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: [Activity].self) {
                return (result.value, result.cachedAt)
            }
        }
        
        // Try as single Activity
        if let result = await persistenceLayer.loadFromCoreData(key: key, as: Activity.self) {
            return (result.value, result.cachedAt)
        }
        
        // HealthKit metrics (these are typically Double values)
        if key.hasPrefix("healthkit:") {
            // Try Double first (most HealthKit metrics are Double)
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: Double.self) {
                return (result.value, result.cachedAt)
            }
            // Try Int for step counts
            if let result = await persistenceLayer.loadFromCoreData(key: key, as: Int.self) {
                return (result.value, result.cachedAt)
            }
        }
        
        return nil
    }
    
    /// Determine TTL based on cache key pattern (adapted from UnifiedCacheManager)
    private func determineTTL(for key: String) -> TimeInterval {
        if key.contains(":activities:") {
            return 3600 // 1 hour
        } else if key.contains(":streams:") {
            return 604800 // 7 days
        } else if key.hasPrefix("healthkit:") {
            return 300 // 5 minutes
        } else if key.hasPrefix("score:") {
            return 172800 // 48 hours
        } else if key.contains(":wellness:") {
            return 600 // 10 minutes
        } else {
            return 3600 // Default: 1 hour
        }
    }
}
