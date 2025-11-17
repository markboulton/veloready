import Foundation

/// Memory-based cache layer using in-memory dictionary
///
/// **Purpose:**
/// Fastest cache layer for frequently accessed data. Volatile (cleared on app restart).
///
/// **Features:**
/// - Request deduplication (prevents duplicate fetches)
/// - Automatic eviction (LRU, keeps last 200 entries)
/// - Thread-safe (actor-based)
/// - Zero disk I/O
///
/// **Performance:**
/// - Get: O(1) - instant lookup
/// - Set: O(1) - instant storage
/// - Eviction: O(n log n) - sorts by timestamp when limit exceeded
///
/// **Size Limits:**
/// - Max entries: 200
/// - Eviction: Removes oldest 50 when limit exceeded
/// - No byte size limit (relies on system memory pressure)
actor MemoryCacheLayer: CacheLayer {
    
    // MARK: - Storage
    
    private var cache: [String: CachedEntry] = [:]
    private var inflightRequests: [String: AnyTaskWrapper] = [:]
    
    // MARK: - Statistics
    
    private var stats = CacheLayerStats(hits: 0, misses: 0, sets: 0, evictions: 0)
    
    // MARK: - Configuration
    
    private let maxEntries = 200
    private let evictionBatchSize = 50
    
    // MARK: - CacheLayer Protocol
    
    func get<T: Sendable>(key: String, ttl: TimeInterval) async -> T? {
        // Check if cached and valid
        guard let entry = cache[key],
              entry.isValid(ttl: ttl),
              let value = entry.value as? T else {
            updateStats(hit: false)
            return nil
        }
        
        updateStats(hit: true)
        Logger.debug("⚡ [MemoryCache HIT] \(key) (age: \(Int(entry.age))s)")
        return value
    }
    
    func set<T: Sendable>(key: String, value: T, cachedAt: Date) async {
        let entry = CachedEntry(value: value, cachedAt: cachedAt)
        cache[key] = entry
        
        updateStats(set: true)
        
        // Enforce size limits
        if cache.count > maxEntries {
            await evictOldest(count: evictionBatchSize)
        }
        
        Logger.debug("💾 [MemoryCache SET] \(key) (total: \(cache.count))")
    }
    
    func remove(key: String) async {
        cache.removeValue(forKey: key)
        Logger.debug("🗑️ [MemoryCache REMOVE] \(key)")
    }
    
    func removeMatching(pattern: String) async {
        if pattern == "*" {
            let count = cache.count
            cache.removeAll()
            Logger.debug("🗑️ [MemoryCache CLEAR] Removed \(count) entries")
            return
        }
        
        // Regex matching
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            Logger.warning("⚠️ [MemoryCache] Invalid regex pattern: \(pattern)")
            return
        }
        
        var removedCount = 0
        let keysToRemove = cache.keys.filter { key in
            let range = NSRange(key.startIndex..., in: key)
            return regex.firstMatch(in: key, range: range) != nil
        }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            removedCount += 1
        }
        
        Logger.debug("🗑️ [MemoryCache CLEAR] Removed \(removedCount) entries matching '\(pattern)'")
    }
    
    func contains(key: String, ttl: TimeInterval) async -> Bool {
        guard let entry = cache[key] else { return false }
        return entry.isValid(ttl: ttl)
    }
    
    // MARK: - Request Deduplication
    
    /// Deduplicate simultaneous requests for the same key
    /// Prevents multiple concurrent fetches for identical data
    ///
    /// **Usage:**
    /// ```swift
    /// let value = try await deduplicate(key: "user:123") {
    ///     try await fetchExpensiveData()
    /// }
    /// ```
    func deduplicate<T: Sendable>(
        key: String,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // Check if request already in-flight
        if let existingTask = inflightRequests[key] {
            Logger.debug("🔄 [MemoryCache DEDUPE] \(key) - reusing existing request")
            return try await existingTask.getValue(as: T.self)
        }
        
        // Create new task
        let task = Task<T, Error> {
            defer {
                Task {
                    self.removeInflightRequest(key: key)
                }
            }
            return try await operation()
        }
        
        // Store task wrapper
        inflightRequests[key] = AnyTaskWrapper(task: task)
        
        return try await task.value
    }
    
    // MARK: - Statistics
    
    func getStats() -> CacheLayerStats {
        return stats
    }
    
    func resetStats() {
        stats = CacheLayerStats(hits: 0, misses: 0, sets: 0, evictions: 0)
    }
    
    // MARK: - Private Helpers
    
    private func evictOldest(count: Int) async {
        let sorted = cache.sorted { $0.value.cachedAt < $1.value.cachedAt }
        let toRemove = sorted.prefix(count)
        
        for (key, _) in toRemove {
            cache.removeValue(forKey: key)
        }
        
        updateStats(evictions: count)
        Logger.debug("🗑️ [MemoryCache EVICT] Removed \(toRemove.count) oldest entries")
    }
    
    private func removeInflightRequest(key: String) {
        inflightRequests.removeValue(forKey: key)
    }
    
    private func updateStats(hit: Bool? = nil, set: Bool? = nil, evictions: Int? = nil) {
        var newHits = stats.hits
        var newMisses = stats.misses
        var newSets = stats.sets
        var newEvictions = stats.evictions
        
        if let hit = hit {
            if hit {
                newHits += 1
            } else {
                newMisses += 1
            }
        }
        
        if set == true {
            newSets += 1
        }
        
        if let evictions = evictions {
            newEvictions += evictions
        }
        
        stats = CacheLayerStats(hits: newHits, misses: newMisses, sets: newSets, evictions: newEvictions)
    }
}

/// Type-erased task wrapper for request deduplication
private struct AnyTaskWrapper {
    private let getValue: (Any.Type) async throws -> Any
    
    init<T: Sendable>(task: Task<T, Error>) {
        self.getValue = { expectedType in
            guard expectedType == T.self else {
                throw CacheLayerError.typeMismatch
            }
            return try await task.value
        }
    }
    
    func getValue<T>(as type: T.Type) async throws -> T {
        let value = try await getValue(T.self)
        guard let typedValue = value as? T else {
            throw CacheLayerError.typeMismatch
        }
        return typedValue
    }
}

/// Cache layer errors
enum CacheLayerError: Error {
    case typeMismatch
}
