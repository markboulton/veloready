import Foundation

/// Orchestrates multi-layer caching with fallback strategies
///
/// **Purpose:**
/// Coordinates three cache layers (Memory → Disk → CoreData) with intelligent
/// fallback and offline support. Provides the same interface as UnifiedCacheManager.
///
/// **Architecture:**
/// ```
/// CacheOrchestrator
///   ├── MemoryCacheLayer (fastest, volatile)
///   ├── DiskCacheLayer (fast, persistent)
///   └── CoreDataCacheLayer (slowest, queryable)
/// ```
///
/// **Fetch Strategy:**
/// 1. Check memory (instant)
/// 2. Check disk (fast)
/// 3. Check CoreData (slow)
/// 4. Fetch from network
/// 5. Store in all layers for future use
///
/// **Offline Fallback:**
/// - Returns stale cache if network unavailable
/// - Graceful degradation
/// - Background refresh when online
actor CacheOrchestrator {
    
    // MARK: - Singleton
    
    static let shared = CacheOrchestrator()
    
    // MARK: - Cache Layers
    
    private let memoryLayer = MemoryCacheLayer()
    private let diskLayer = DiskCacheLayer()
    private let coreDataLayer = CoreDataCacheLayer()
    
    // MARK: - Initialization
    
    private init() {
        Logger.debug("🗄️ [CacheOrchestrator] Initialized with 3-layer architecture")
    }
    
    // MARK: - Main API (Compatible with UnifiedCacheManager)
    
    /// Get data from cache without fetching
    /// - Parameters:
    ///   - key: Unique cache key
    ///   - ttl: Time-to-live in seconds
    /// - Returns: Cached data if found and valid, nil otherwise
    func get<T: Sendable>(key: String, ttl: TimeInterval) async -> T? {
        // Check memory cache (fastest)
        if let cached: T = await memoryLayer.get(key: key, ttl: ttl) {
            return cached
        }
        
        // Check disk cache (fast)
        if let cached: T = await diskLayer.get(key: key, ttl: ttl) {
            // Restore to memory for next access
            await memoryLayer.set(key: key, value: cached, cachedAt: Date())
            return cached
        }
        
        // Check Core Data (slower)
        if T.self is Codable.Type,
           let cached: T = await coreDataLayer.get(key: key, ttl: ttl) {
            // Restore to memory and disk for faster access
            await memoryLayer.set(key: key, value: cached, cachedAt: Date())
            await diskLayer.set(key: key, value: cached, cachedAt: Date())
            return cached
        }
        
        return nil
    }
    
    /// Set data in cache
    /// - Parameters:
    ///   - key: Unique cache key
    ///   - value: Value to cache
    ///   - cachedAt: Timestamp when value was cached
    func set<T: Sendable>(key: String, value: T, cachedAt: Date) async {
        await storeInAllLayers(key: key, value: value)
    }
    
    /// Fetch data with automatic caching and layer coordination
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
        // 1. Check memory cache (fastest)
        if let cached: T = await memoryLayer.get(key: key, ttl: ttl) {
            return cached
        }
        
        // 2. Check disk cache (fast)
        if let cached: T = await diskLayer.get(key: key, ttl: ttl) {
            // Restore to memory for next access
            await memoryLayer.set(key: key, value: cached, cachedAt: Date())
            return cached
        }
        
        // 3. Check Core Data (slower)
        if T.self is Codable.Type,
           let cached: T = await coreDataLayer.get(key: key, ttl: ttl) {
            // Restore to memory and disk for faster access
            await memoryLayer.set(key: key, value: cached, cachedAt: Date())
            await diskLayer.set(key: key, value: cached, cachedAt: Date())
            return cached
        }
        
        // 4. Fetch from network (use deduplication to prevent duplicate requests)
        Logger.debug("🌐 [CacheOrchestrator MISS] \(key) - fetching...")
        
        do {
            let value = try await memoryLayer.deduplicate(key: key) {
                try await fetchOperation()
            }
            
            // 5. Store in all layers
            await storeInAllLayers(key: key, value: value)
            
            return value
        } catch {
            // 6. Offline fallback - try to return expired cache
            if let stale: T = await getExpiredCache(key: key) {
                Logger.debug("📱 [Offline Fallback] \(key) - returning expired cache")
                return stale
            }
            throw error
        }
    }
    
    /// Fetch with cache-first strategy: return stale cache immediately, refresh in background
    /// This provides instant data display while ensuring freshness over time
    func fetchCacheFirst<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        fetchOperation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check if ANY cache exists (even if stale)
        if let cached: T = await getAnyCache(key: key) {
            let cachedAt = Date() // We don't track exact timestamp in this simplified version
            let age: TimeInterval = 0 // Simplified for now
            
            // If cache is valid, return immediately
            if await memoryLayer.contains(key: key, ttl: ttl) {
                Logger.debug("⚡ [CacheFirst HIT] \(key) (valid)")
                return cached
            }
            
            // Cache is stale - return it AND refresh in background
            Logger.debug("📱 [CacheFirst STALE] \(key) - returning stale, refreshing in background")
            
            // Start background refresh
            Task.detached(priority: .background) {
                let isOnline = await NetworkMonitor.shared.isConnected
                
                if isOnline {
                    await Logger.debug("🔄 [Background Refresh] \(key) - starting...")
                    do {
                        let freshValue = try await fetchOperation()
                        await self.storeInAllLayers(key: key, value: freshValue)
                        await Logger.debug("✅ [Background Refresh] \(key) - complete")
                    } catch {
                        await Logger.warning("⚠️ [Background Refresh] \(key) - failed: \(error.localizedDescription)")
                    }
                } else {
                    await Logger.debug("📱 [Background Refresh] \(key) - skipped (offline)")
                }
            }
            
            return cached
        }
        
        // 2. No cache exists - check if online
        let isOnline = await NetworkMonitor.shared.isConnected
        
        if !isOnline {
            Logger.warning("📱 [CacheFirst MISS] \(key) - offline, no cached data available")
            throw NetworkError.offline
        }
        
        // 3. Online with no cache - use normal fetch
        Logger.debug("🌐 [CacheFirst MISS] \(key) - fetching online...")
        return try await fetch(key: key, ttl: ttl, fetchOperation: fetchOperation)
    }
    
    // MARK: - Cache Management
    
    /// Invalidate specific cache entry across all layers
    func invalidate(key: String) async {
        await memoryLayer.remove(key: key)
        await diskLayer.remove(key: key)
        await coreDataLayer.remove(key: key)
        
        Logger.debug("🗑️ [CacheOrchestrator INVALIDATE] \(key)")
    }
    
    /// Invalidate all entries matching pattern across all layers
    func invalidate(matching pattern: String) async {
        await memoryLayer.removeMatching(pattern: pattern)
        await diskLayer.removeMatching(pattern: pattern)
        await coreDataLayer.removeMatching(pattern: pattern)
        
        Logger.debug("🗑️ [CacheOrchestrator CLEAR] Pattern: \(pattern)")
    }
    
    /// Check if cache is valid (checks all layers)
    func isCacheValid(key: String, ttl: TimeInterval) -> Bool {
        // This is a synchronous method in UnifiedCacheManager, so we'll keep it simple
        // In practice, you'd make this async or check only memory layer
        return false // Simplified for now - would need async version
    }
    
    // MARK: - Statistics
    
    func getStatistics() async -> CacheStatistics {
        let memoryStats = await memoryLayer.getStats()
        
        return CacheStatistics(
            hits: memoryStats.hits,
            misses: memoryStats.misses,
            deduplicatedRequests: 0, // Not tracked in new architecture
            hitRate: memoryStats.hitRate,
            totalRequests: memoryStats.hits + memoryStats.misses
        )
    }
    
    func resetStatistics() async {
        await memoryLayer.resetStats()
    }
    
    // MARK: - Private Helpers
    
    /// Store value in all cache layers
    private func storeInAllLayers<T: Sendable>(key: String, value: T) async {
        let cachedAt = Date()
        
        // Store in memory (always)
        await memoryLayer.set(key: key, value: value, cachedAt: cachedAt)
        
        // Store in disk if value is Encodable
        if value is Encodable {
            await diskLayer.set(key: key, value: value, cachedAt: cachedAt)
        }
        
        // Store in Core Data if value is Codable and matches known types
        if value is Codable {
            await coreDataLayer.set(key: key, value: value, cachedAt: cachedAt)
        }
    }
    
    /// Get expired cache from any layer (for offline fallback)
    private func getExpiredCache<T: Sendable>(key: String) async -> T? {
        // Try memory first (no TTL check)
        if let cached: T = await memoryLayer.get(key: key, ttl: .greatestFiniteMagnitude) {
            return cached
        }
        
        // Try disk
        if let cached: T = await diskLayer.get(key: key, ttl: .greatestFiniteMagnitude) {
            return cached
        }
        
        // Try Core Data
        if T.self is Codable.Type,
           let cached: T = await coreDataLayer.get(key: key, ttl: .greatestFiniteMagnitude) {
            return cached
        }
        
        return nil
    }
    
    /// Get any cache (stale or not) for cache-first strategy
    private func getAnyCache<T: Sendable>(key: String) async -> T? {
        return await getExpiredCache(key: key)
    }
}

// MARK: - Supporting Types
// CacheStatistics is defined in UnifiedCacheManager.swift
// NetworkError is defined in NetworkClient.swift
