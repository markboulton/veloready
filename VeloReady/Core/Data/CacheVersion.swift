import Foundation

/// Single source of truth for cache versioning across all cache systems.
/// 
/// **CRITICAL**: When changing cache format, increment THIS version only.
/// All cache layers (memory, disk, Core Data) will sync automatically.
///
/// # Version History
/// - v1: Initial cache system
/// - v2: Legacy cache keys cleared
/// - v3: Disk persistence added
/// - v4: Clear corrupted cache from format changes (Nov 9, 2025)
///
/// # When to Increment
/// - ✅ Changing data model structure (e.g., adding fields to Codable types)
/// - ✅ Changing serialization format (e.g., JSON encoding changes)
/// - ✅ Changing Core Data schema
/// - ✅ After major refactoring that affects cache format
/// - ❌ Changing cache TTLs (no need)
/// - ❌ Adding new cache keys (no need)
///
/// # How It Works
/// 1. Both `UnifiedCacheManager` and `CachePersistenceLayer` reference this constant
/// 2. On app launch, each checks its stored version vs current version
/// 3. If mismatch, automatically clears ALL caches
/// 4. Cannot get out of sync - single source of truth!
enum CacheVersion {
    /// Current cache version - increment when cache format changes
    /// **IMPORTANT**: This is the ONLY place to change the version number
    static let current = 4
    
    /// UserDefaults key for UnifiedCacheManager version
    static let unifiedCacheKey = "UnifiedCacheManager.CacheVersion"
    
    /// UserDefaults key for CachePersistenceLayer version
    static let persistenceKey = "CachePersistenceVersion"
    
    /// Check if version has changed and needs cache clear
    /// - Parameter storageKey: The UserDefaults key to check
    /// - Returns: True if cache should be cleared
    static func needsCacheClear(for storageKey: String) -> Bool {
        let storedVersion: Int
        
        if storageKey == unifiedCacheKey {
            // String-based version for UnifiedCacheManager (legacy)
            let storedString = UserDefaults.standard.string(forKey: storageKey)
            storedVersion = storedString == "v\(current)" ? current : 0
        } else {
            // Integer-based version for CachePersistenceLayer
            storedVersion = UserDefaults.standard.integer(forKey: storageKey)
        }
        
        return storedVersion != current
    }
    
    /// Mark version as current in UserDefaults
    /// - Parameter storageKey: The UserDefaults key to update
    static func markAsCurrent(for storageKey: String) {
        if storageKey == unifiedCacheKey {
            // String-based for UnifiedCacheManager
            UserDefaults.standard.set("v\(current)", forKey: storageKey)
        } else {
            // Integer-based for CachePersistenceLayer
            UserDefaults.standard.set(current, forKey: storageKey)
        }
    }
    
    /// Verify all cache systems are synchronized (for debugging)
    /// - Returns: True if all cache systems have the same version
    static func verifySynchronization() -> Bool {
        let unifiedVersion = UserDefaults.standard.string(forKey: unifiedCacheKey)
        let persistenceVersion = UserDefaults.standard.integer(forKey: persistenceKey)
        
        let unifiedMatches = unifiedVersion == "v\(current)"
        let persistenceMatches = persistenceVersion == current
        
        if !unifiedMatches || !persistenceMatches {
            Logger.warning("⚠️ [CacheVersion] Version mismatch detected!")
            Logger.warning("⚠️ [CacheVersion] Current: \(current), Unified: \(unifiedVersion ?? "none"), Persistence: \(persistenceVersion)")
            return false
        }
        
        return true
    }
}
