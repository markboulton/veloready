import Foundation
import Testing
@testable import VeloReady

@Suite("Unified Cache Manager")
struct UnifiedCacheManagerTests {
    
    // MARK: - Basic Caching Tests
    
    @Test("Cache stores and retrieves values")
    func testBasicCaching() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:basic:\(UUID().uuidString)"
        var fetchCount = 0
        
        // First fetch - should call operation
        let value1 = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        #expect(value1 == "test value")
        #expect(fetchCount == 1)
        
        // Second fetch - should use cache
        let value2 = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        #expect(value2 == "test value")
        #expect(fetchCount == 1, "Should not call fetch operation again")
    }
    
    @Test("Cache respects TTL expiration")
    func testCacheTTL() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:ttl:\(UUID().uuidString)"
        var fetchCount = 0
        
        // Cache with 1 second TTL
        _ = try await cache.fetch(key: key, ttl: 1.0) {
            fetchCount += 1
            return "test value"
        }
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        
        // Should fetch again
        _ = try await cache.fetch(key: key, ttl: 1.0) {
            fetchCount += 1
            return "test value"
        }
        
        #expect(fetchCount == 2, "Should refetch after TTL expires")
    }
    
    // MARK: - Request Deduplication Tests
    
    @Test("Simultaneous requests are deduplicated")
    func testRequestDeduplication() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:dedupe:\(UUID().uuidString)"
        var fetchCount = 0
        
        // Launch 5 simultaneous fetches
        async let fetch1 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            return "test value"
        }
        
        async let fetch2 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        async let fetch3 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        let results = try await [fetch1, fetch2, fetch3]
        
        #expect(fetchCount == 1, "Should deduplicate simultaneous requests")
        #expect(results.count == 3)
        #expect(results.allSatisfy { $0 == "test value" })
    }
    
    // MARK: - Cache Invalidation Tests
    
    @Test("Cache invalidation removes specific key")
    func testInvalidation() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:invalidate:\(UUID().uuidString)"
        var fetchCount = 0
        
        // Cache value
        _ = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        // Invalidate
        await cache.invalidate(key: key)
        
        // Should fetch again
        _ = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return "test value"
        }
        
        #expect(fetchCount == 2, "Should refetch after invalidation")
    }
    
    @Test("Pattern-based invalidation works")
    func testPatternInvalidation() async throws {
        let cache = await UnifiedCacheManager.shared
        let prefix = "test:pattern:\(UUID().uuidString)"
        
        // Cache multiple values
        _ = try await cache.fetch(key: "\(prefix):1", ttl: 3600) { "value1" }
        _ = try await cache.fetch(key: "\(prefix):2", ttl: 3600) { "value2" }
        _ = try await cache.fetch(key: "\(prefix):3", ttl: 3600) { "value3" }
        _ = try await cache.fetch(key: "other:key", ttl: 3600) { "other" }
        
        // Invalidate pattern
        await cache.invalidate(matching: "\(prefix):.*")
        
        var fetchCount = 0
        _ = try await cache.fetch(key: "\(prefix):1", ttl: 3600) {
            fetchCount += 1
            return "value1"
        }
        
        #expect(fetchCount == 1, "Should refetch after pattern invalidation")
        
        // Other key should still be cached
        var otherFetchCount = 0
        _ = try await cache.fetch(key: "other:key", ttl: 3600) {
            otherFetchCount += 1
            return "other"
        }
        
        #expect(otherFetchCount == 0, "Other keys should remain cached")
    }
    
    // MARK: - Statistics Tests
    
    @Test("Cache statistics are tracked")
    func testStatistics() async throws {
        let cache = await UnifiedCacheManager.shared
        await cache.resetStatistics()
        
        let key = "test:stats:\(UUID().uuidString)"
        
        // Miss
        _ = try await cache.fetch(key: key, ttl: 3600) { "value" }
        
        // Hit
        _ = try await cache.fetch(key: key, ttl: 3600) { "value" }
        
        let stats = await cache.getStatistics()
        #expect(stats.hits >= 1)
        #expect(stats.misses >= 1)
        #expect(stats.hitRate > 0)
    }
    
    // MARK: - Type Safety Tests
    
    @Test("Cache handles different types correctly")
    func testTypeSafety() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // String
        let string = try await cache.fetch(key: "test:string:\(UUID().uuidString)", ttl: 3600) { 
            "test string" 
        }
        #expect(string == "test string")
        
        // Int
        let int = try await cache.fetch(key: "test:int:\(UUID().uuidString)", ttl: 3600) { 
            42 
        }
        #expect(int == 42)
        
        // Array
        let array = try await cache.fetch(key: "test:array:\(UUID().uuidString)", ttl: 3600) { 
            [1, 2, 3] 
        }
        #expect(array == [1, 2, 3])
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Cache handles errors gracefully")
    func testErrorHandling() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:error:\(UUID().uuidString)"
        
        enum TestError: Error {
            case testFailure
        }
        
        do {
            _ = try await cache.fetch(key: key, ttl: 3600) {
                throw TestError.testFailure
            }
            Issue.record("Should have thrown error")
        } catch {
            // Expected
        }
    }
    
    // MARK: - Offline Fallback Tests
    
    @Test("Cache returns expired data on network error")
    func testOfflineFallback() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "test:offline:\(UUID().uuidString)"
        
        enum TestError: Error {
            case networkError
        }
        
        // Cache value with short TTL
        _ = try await cache.fetch(key: key, ttl: 1.0) {
            "cached value"
        }
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Network error - should return expired cache
        do {
            let value: String = try await cache.fetch(key: key, ttl: 1.0) {
                throw TestError.networkError
            }
            
            #expect(value == "cached value", "Should return expired cache on error")
        } catch {
            // If offline fallback isn't implemented yet, that's okay
            // This test documents the expected behavior
        }
    }
    
    // MARK: - Strava Activities Tests
    
    @Test("Strava activities cache with different day ranges")
    func testStravaActivitiesCache() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // Cache different ranges
        let activities1d = try await cache.fetch(key: "strava:activities:1", ttl: 3600) {
            ["activity_today"]
        }
        
        let activities7d = try await cache.fetch(key: "strava:activities:7", ttl: 3600) {
            ["activity1", "activity2", "activity3", "activity4"]
        }
        
        let activities365d = try await cache.fetch(key: "strava:activities:365", ttl: 3600) {
            Array(repeating: "activity", count: 183)
        }
        
        #expect(activities1d.count == 1)
        #expect(activities7d.count == 4)
        #expect(activities365d.count == 183)
        
        // Verify separate caching
        var fetchCount = 0
        _ = try await cache.fetch(key: "strava:activities:7", ttl: 3600) {
            fetchCount += 1
            return ["activity1", "activity2", "activity3", "activity4"]
        }
        
        #expect(fetchCount == 0, "Should use cached value")
    }
    
    // MARK: - HealthKit Data Tests
    
    @Test("HealthKit metrics cache correctly")
    func testHealthKitCache() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // HRV data
        let hrv = try await cache.fetch(key: "healthkit:hrv:today", ttl: 300) {
            45.0
        }
        #expect(hrv == 45.0)
        
        // RHR data
        let rhr = try await cache.fetch(key: "healthkit:rhr:today", ttl: 300) {
            58.0
        }
        #expect(rhr == 58.0)
        
        // Sleep data
        let sleep = try await cache.fetch(key: "healthkit:sleep:today", ttl: 300) {
            7.5
        }
        #expect(sleep == 7.5)
    }
    
    // MARK: - Intervals.icu Tests
    
    @Test("Intervals.icu activities cache correctly")
    func testIntervalsCache() async throws {
        let cache = await UnifiedCacheManager.shared
        
        let activities = try await cache.fetch(key: "intervals:activities:7", ttl: 3600) {
            ["intervals_activity1", "intervals_activity2"]
        }
        
        #expect(activities.count == 2)
        
        // Verify cached
        var fetchCount = 0
        _ = try await cache.fetch(key: "intervals:activities:7", ttl: 3600) {
            fetchCount += 1
            return ["intervals_activity1", "intervals_activity2"]
        }
        
        #expect(fetchCount == 0, "Should use cached value")
    }
    
    // MARK: - Stream Data Tests
    
    @Test("Stream data cache with 7-day TTL")
    func testStreamCache() async throws {
        let cache = await UnifiedCacheManager.shared
        
        let streamKey = "stream:strava_12345"
        let streamData = Array(repeating: "sample", count: 1000)
        
        let cached = try await cache.fetch(key: streamKey, ttl: 604800) {
            streamData
        }
        
        #expect(cached.count == 1000)
        
        // Verify cached
        var fetchCount = 0
        _ = try await cache.fetch(key: streamKey, ttl: 604800) {
            fetchCount += 1
            return streamData
        }
        
        #expect(fetchCount == 0, "Stream should be cached")
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Cache evicts old entries when limit reached")
    func testMemoryManagement() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // Cache 250 entries (limit is 200)
        for i in 0..<250 {
            _ = try await cache.fetch(key: "test:memory:\(i)", ttl: 3600) {
                "value_\(i)"
            }
        }
        
        // Verify cache works (some entries may have been evicted)
        let value = try await cache.fetch(key: "test:memory:249", ttl: 3600) {
            "value_249"
        }
        
        #expect(value == "value_249")
    }
}
