import Foundation

/// Protocol defining the interface for cache layers
///
/// **Purpose:**
/// Provides a consistent interface for different cache storage mechanisms.
/// Each layer can be independently tested and swapped without affecting orchestration.
///
/// **Layers:**
/// - Memory: Fast, volatile (NSCache)
/// - Disk: Persistent, moderate speed (UserDefaults/FileManager)
/// - CoreData: Persistent, queryable (SQLite)
///
/// **Design Principles:**
/// - Each layer is independent and testable
/// - Layers don't know about each other
/// - Orchestrator coordinates layer usage
/// - Simple interface: get, set, remove
protocol CacheLayer: Actor {
    
    /// Retrieve value from this cache layer
    /// - Parameters:
    ///   - key: Cache key
    ///   - ttl: Time-to-live in seconds
    /// - Returns: Cached value if found and valid, nil otherwise
    func get<T: Sendable>(key: String, ttl: TimeInterval) async -> T?
    
    /// Store value in this cache layer
    /// - Parameters:
    ///   - key: Cache key
    ///   - value: Value to cache
    ///   - cachedAt: Timestamp when value was cached
    func set<T: Sendable>(key: String, value: T, cachedAt: Date) async
    
    /// Remove value from this cache layer
    /// - Parameter key: Cache key
    func remove(key: String) async
    
    /// Remove all entries matching pattern
    /// - Parameter pattern: Regex pattern or "*" for all
    func removeMatching(pattern: String) async
    
    /// Check if this layer contains a valid cached value
    /// - Parameters:
    ///   - key: Cache key
    ///   - ttl: Time-to-live in seconds
    /// - Returns: True if cached value exists and is valid
    func contains(key: String, ttl: TimeInterval) async -> Bool
}

/// Cached value with metadata
struct CachedEntry {
    let value: Any
    let cachedAt: Date
    
    /// Check if entry is still valid based on TTL
    func isValid(ttl: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttl
    }
    
    /// Age in seconds
    var age: TimeInterval {
        return Date().timeIntervalSince(cachedAt)
    }
}

/// Cache layer statistics for monitoring
struct CacheLayerStats {
    let hits: Int
    let misses: Int
    let sets: Int
    let evictions: Int
    
    var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0.0
    }
}
