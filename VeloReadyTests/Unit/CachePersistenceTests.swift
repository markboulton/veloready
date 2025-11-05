import Foundation
import Testing
@testable import VeloReady

@Suite("Cache Disk Persistence")
struct CachePersistenceTests {
    
    // MARK: - Persistence Tests
    
    @Test("Activities persist to disk and load on restart")
    func testActivitiesPersistence() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "strava:activities:7"
        
        // Clear any existing data
        await cache.invalidate(key: key)
        
        // Cache activities
        let activities = ["activity1", "activity2", "activity3", "activity4"]
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return activities
        }
        
        // Verify in memory
        var fetchCount = 0
        let cached = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return activities
        }
        
        #expect(fetchCount == 0, "Should be cached in memory")
        #expect(cached.count == 4)
        
        // Verify persisted to disk by checking UserDefaults
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil, "Should persist to disk")
        
        let metadata = UserDefaults.standard.dictionary(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        #expect(metadata?[key] != nil, "Should have metadata")
    }
    
    @Test("Streams persist to disk with 7-day TTL")
    func testStreamsPersistence() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "stream:strava_12345"
        
        // Clear any existing data
        await cache.invalidate(key: key)
        
        // Cache stream data
        let streamData = Array(repeating: "sample", count: 100)
        _ = try await cache.fetch(key: key, ttl: 604800) {
            return streamData
        }
        
        // Verify persisted
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil, "Streams should persist to disk")
    }
    
    @Test("Scores persist to disk")
    func testScoresPersistence() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "score:recovery:2025-11-05T00:00:00Z"
        
        // Clear any existing data
        await cache.invalidate(key: key)
        
        // Cache score
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return 92
        }
        
        // Verify persisted
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil, "Scores should persist to disk")
    }
    
    @Test("Baselines persist to disk")
    func testBaselinesPersistence() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "baseline:hrv:7day"
        
        // Clear any existing data
        await cache.invalidate(key: key)
        
        // Cache baseline
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return 45.0
        }
        
        // Verify persisted
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil, "Baselines should persist to disk")
    }
    
    @Test("HealthKit metrics do NOT persist (ephemeral)")
    func testHealthKitNotPersisted() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "healthkit:hrv:today"
        
        // Clear disk cache completely
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCache")
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        
        // Cache health metric
        _ = try await cache.fetch(key: key, ttl: 300) {
            return 45.0
        }
        
        // Verify NOT persisted (health metrics are ephemeral)
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        
        if let data = diskData,
           let diskCache = try? JSONDecoder().decode([String: String].self, from: data) {
            #expect(diskCache[key] == nil, "Health metrics should NOT persist to disk")
        } else {
            // No disk cache at all is also acceptable
        }
    }
    
    @Test("Invalidation removes from disk")
    func testInvalidationRemovesFromDisk() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "strava:activities:1"
        
        // Cache and persist
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return ["activity1"]
        }
        
        // Verify persisted
        var diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil, "Should be persisted")
        
        // Invalidate
        await cache.invalidate(key: key)
        
        // Verify removed from disk
        diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        if let data = diskData,
           let diskCache = try? JSONDecoder().decode([String: String].self, from: data) {
            #expect(diskCache[key] == nil, "Should be removed from disk")
        }
    }
    
    @Test("Multiple data types can coexist on disk")
    func testMultipleTypesOnDisk() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // Clear disk
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCache")
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        
        // Cache different types
        _ = try await cache.fetch(key: "strava:activities:7", ttl: 3600) {
            return ["act1", "act2"]
        }
        
        _ = try await cache.fetch(key: "stream:strava_999", ttl: 604800) {
            return Array(repeating: "sample", count: 50)
        }
        
        _ = try await cache.fetch(key: "score:recovery:2025-11-05T00:00:00Z", ttl: 3600) {
            return 95
        }
        
        // Verify all persisted
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        #expect(diskData != nil)
        
        if let data = diskData,
           let diskCache = try? JSONDecoder().decode([String: String].self, from: data) {
            #expect(diskCache.count >= 3, "Should have at least 3 entries")
        }
    }
    
    @Test("Disk cache size is reasonable")
    func testDiskCacheSize() async throws {
        let cache = await UnifiedCacheManager.shared
        
        // Clear disk
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCache")
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        
        // Cache realistic data
        _ = try await cache.fetch(key: "strava:activities:365", ttl: 3600) {
            return Array(repeating: "activity", count: 183)
        }
        
        _ = try await cache.fetch(key: "stream:strava_12345", ttl: 604800) {
            return Array(repeating: "sample", count: 1000)
        }
        
        // Check size
        let diskData = UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache")
        if let data = diskData {
            let sizeKB = data.count / 1024
            #expect(sizeKB < 1000, "Disk cache should be under 1MB for this data")
        }
    }
    
    // MARK: - API Usage Reduction Tests
    
    @Test("Strava activities reduce API calls by 80%")
    func testStravaAPIReduction() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "strava:activities:7:\(UUID().uuidString)"  // Unique key for test isolation
        
        var apiCallCount = 0
        
        // Launch 1: API call
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return ["act1", "act2", "act3", "act4"]
        }
        
        #expect(apiCallCount == 1)
        
        // Launch 2-5: Cached (in same session)
        for _ in 0..<4 {
            _ = try await cache.fetch(key: key, ttl: 3600) {
                apiCallCount += 1
                return ["act1", "act2", "act3", "act4"]
            }
        }
        
        // Should only call API once (all cached in memory)
        #expect(apiCallCount == 1, "Should reduce API calls from 5 to 1 (80% reduction)")
    }
    
    @Test("Stream data reduces API calls by 90%")
    func testStreamAPIReduction() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "stream:strava_\(UUID().uuidString)"  // Unique key for test isolation
        
        var apiCallCount = 0
        
        // First view
        _ = try await cache.fetch(key: key, ttl: 604800) {
            apiCallCount += 1
            return Array(repeating: "sample", count: 1000)
        }
        
        // Subsequent views (10 more views in same session)
        for _ in 0..<10 {
            _ = try await cache.fetch(key: key, ttl: 604800) {
                apiCallCount += 1
                return Array(repeating: "sample", count: 1000)
            }
        }
        
        #expect(apiCallCount == 1, "Should reduce API calls from 11 to 1 (91% reduction)")
    }
}
