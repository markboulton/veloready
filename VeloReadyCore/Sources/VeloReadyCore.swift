import Foundation

// MARK: - Cache Manager

/// Pure Swift cache manager for business logic testing
/// Actor-based for thread safety, no UIKit/SwiftUI dependencies
public actor CacheManager {
    
    // MARK: - Storage
    private var memoryCache: [String: CachedValue] = [:]
    private var inflightRequests: [String: AnyTaskWrapper] = [:]
    private var trackedKeys: Set<String> = []
    
    // MARK: - Statistics
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var deduplicatedRequests: Int = 0
    
    public init() {}
    
    // MARK: - Public API
    
    /// Fetch data with automatic caching and request deduplication
    public func fetch<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check memory cache (valid data)
        if let cached = memoryCache[key],
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            cacheHits += 1
            return value
        }
        
        // 2. Check if request is already in-flight (deduplication)
        if let existingTask = inflightRequests[key] {
            deduplicatedRequests += 1
            return try await existingTask.getValue(as: T.self)
        }
        
        // 3. Create new task and track it
        cacheMisses += 1
        
        let task = Task<T, Error> {
            do {
                let value = try await operation()
                await self.storeInCache(key: key, value: value)
                return value
            } catch {
                // On error, try to return expired cache as fallback
                if let cached = await self.getExpiredCache(key: key, as: T.self) {
                    return cached
                }
                throw error
            }
        }
        
        inflightRequests[key] = AnyTaskWrapper(task: task)
        
        defer {
            Task {
                await self.removeInflightRequest(key: key)
            }
        }
        
        return try await task.value
    }
    
    /// Invalidate specific cache entry
    public func invalidate(key: String) {
        memoryCache.removeValue(forKey: key)
        trackedKeys.remove(key)
    }
    
    /// Invalidate all entries matching pattern
    public func invalidate(matching pattern: String) {
        if pattern == "*" {
            memoryCache.removeAll()
            trackedKeys.removeAll()
            return
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        let keysToRemove = trackedKeys.filter { key in
            let range = NSRange(key.startIndex..., in: key)
            return regex.firstMatch(in: key, range: range) != nil
        }
        
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
            trackedKeys.remove(key)
        }
    }
    
    /// Get cache statistics
    public func getStatistics() -> CacheStatistics {
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
    
    // MARK: - Internal Helpers
    
    private func storeInCache(key: String, value: Any) {
        let cached = CachedValue(value: value, cachedAt: Date())
        memoryCache[key] = cached
        trackedKeys.insert(key)
        
        // Enforce memory limits
        if memoryCache.count > 200 {
            evictOldestEntries(count: 50)
        }
    }
    
    private func removeInflightRequest(key: String) {
        inflightRequests.removeValue(forKey: key)
    }
    
    private func evictOldestEntries(count: Int) {
        let sorted = memoryCache.sorted { $0.value.cachedAt < $1.value.cachedAt }
        let toRemove = sorted.prefix(count)
        
        for (key, _) in toRemove {
            memoryCache.removeValue(forKey: key)
            trackedKeys.remove(key)
        }
    }
    
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
public struct CachedValue {
    let value: Any
    let cachedAt: Date
    
    func isValid(ttl: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttl
    }
}

/// Cache statistics
public struct CacheStatistics {
    public let hits: Int
    public let misses: Int
    public let deduplicatedRequests: Int
    public let hitRate: Double
    public let totalRequests: Int
    
    public init(hits: Int, misses: Int, deduplicatedRequests: Int, hitRate: Double, totalRequests: Int) {
        self.hits = hits
        self.misses = misses
        self.deduplicatedRequests = deduplicatedRequests
        self.hitRate = hitRate
        self.totalRequests = totalRequests
    }
}

/// Type-erased task wrapper for deduplication
struct AnyTaskWrapper {
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

/// Cache errors
public enum CacheError: Error {
    case typeMismatch
    case networkError
}

// MARK: - Cache Key Generator

/// Standardized cache key generation
public enum CacheKey {
    /// Generate key for Strava activities
    public static func stravaActivities(daysBack: Int) -> String {
        "strava:activities:\(daysBack)"
    }
    
    /// Generate key for Intervals activities
    public static func intervalsActivities(daysBack: Int) -> String {
        "intervals:activities:\(daysBack)"
    }
    
    /// Generate key for activity streams
    public static func activityStreams(activityId: String, source: String) -> String {
        "\(source):streams:\(activityId)"
    }
    
    /// Generate key for HRV data
    public static func hrv(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:hrv:\(dateString)"
    }
    
    /// Generate key for RHR data
    public static func rhr(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:rhr:\(dateString)"
    }
    
    /// Generate key for sleep data
    public static func sleep(date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        return "healthkit:sleep:\(dateString)"
    }
    
    /// Generate key for recovery score
    public static func recoveryScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:recovery:\(dateString)"
    }
    
    /// Generate key for sleep score
    public static func sleepScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:sleep:\(dateString)"
    }
    
    /// Validate cache key format
    public static func validate(_ key: String) -> Bool {
        let pattern = "^[a-z]+:[a-z]+:[a-zA-Z0-9-:]+$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Example Business Logic (placeholder for demo)

/// Training load calculator (placeholder - will be extracted later)
// Placeholder structs removed - see dedicated files:
// - TrainingLoadCalculations.swift
// - Models/ActivityData.swift
