import Foundation
import VeloReadyCore

@main
struct VeloReadyCoreTests {
    static func main() async {
        print("🧪 VeloReady Core Tests")
        print("=" + String(repeating: "=", count: 50))
        
        var passed = 0
        var failed = 0
        
        // Test 1: Cache Key Consistency
        if await testCacheKeyConsistency() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 2: Cache Key Format Validation
        if await testCacheKeyFormat() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 3: Basic Cache Operations
        if await testBasicCacheOperations() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 4: Offline Fallback
        if await testOfflineFallback() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 5: Request Deduplication
        if await testRequestDeduplication() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 6: TTL Expiry
        if await testTTLExpiry() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 7: Pattern Invalidation
        if await testPatternInvalidation() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Summary
        print("")
        print("=" + String(repeating: "=", count: 50))
        print("✅ Tests passed: \(passed)")
        if failed > 0 {
            print("❌ Tests failed: \(failed)")
        }
        print("=" + String(repeating: "=", count: 50))
        
        if failed > 0 {
            exit(1)
        }
    }
    
    // MARK: - Test Cases
    
    static func testCacheKeyConsistency() async -> Bool {
        print("\n🧪 Test 1: Cache Key Consistency")
        print("   Testing that cache keys are generated consistently...")
        
        let key1 = CacheKey.stravaActivities(daysBack: 365)
        let key2 = CacheKey.stravaActivities(daysBack: 365)
        let key3 = CacheKey.stravaActivities(daysBack: 90)
        
        guard key1 == key2 else {
            print("   ❌ FAIL: Same parameters produced different keys")
            print("      key1: \(key1)")
            print("      key2: \(key2)")
            return false
        }
        
        guard key1 != key3 else {
            print("   ❌ FAIL: Different parameters produced same key")
            return false
        }
        
        guard key1 == "strava:activities:365" else {
            print("   ❌ FAIL: Unexpected key format: \(key1)")
            return false
        }
        
        print("   ✅ PASS: Cache keys are consistent")
        return true
    }
    
    static func testCacheKeyFormat() async -> Bool {
        print("\n🧪 Test 2: Cache Key Format Validation")
        print("   Testing that all cache keys follow standard format...")
        
        let keys = [
            CacheKey.stravaActivities(daysBack: 90),
            CacheKey.intervalsActivities(daysBack: 120),
            CacheKey.hrv(date: Date()),
            CacheKey.rhr(date: Date()),
            CacheKey.sleep(date: Date()),
            CacheKey.recoveryScore(date: Date()),
            CacheKey.sleepScore(date: Date())
        ]
        
        for key in keys {
            guard CacheKey.validate(key) else {
                print("   ❌ FAIL: Invalid key format: \(key)")
                return false
            }
        }
        
        print("   ✅ PASS: All keys valid (\(keys.count) keys tested)")
        return true
    }
    
    static func testBasicCacheOperations() async -> Bool {
        print("\n🧪 Test 3: Basic Cache Operations")
        print("   Testing cache store and retrieve...")
        
        let cache = CacheManager()
        let key = "test:basic:1"
        let testData = "Hello, Cache!"
        
        do {
            // Store data
            let result1 = try await cache.fetch(key: key, ttl: 60) {
                return testData
            }
            
            guard result1 == testData else {
                print("   ❌ FAIL: Stored data doesn't match")
                return false
            }
            
            // Retrieve from cache (should hit)
            actor FetchCounter {
                var count = 1
                func increment() { count += 1 }
                func get() -> Int { count }
            }
            let counter = FetchCounter()
            
            let result2 = try await cache.fetch(key: key, ttl: 60) {
                await counter.increment()
                return "Should not execute"
            }
            
            let fetchCount = await counter.get()
            
            guard result2 == testData else {
                print("   ❌ FAIL: Cached data doesn't match")
                return false
            }
            
            guard fetchCount == 1 else {
                print("   ❌ FAIL: Cache miss when should hit (fetchCount: \(fetchCount))")
                return false
            }
            
            let stats = await cache.getStatistics()
            guard stats.hits >= 1 else {
                print("   ❌ FAIL: Cache hits not recorded")
                return false
            }
            
            print("   ✅ PASS: Basic cache operations work (hit rate: \(Int(stats.hitRate * 100))%)")
            return true
            
        } catch {
            print("   ❌ FAIL: \(error)")
            return false
        }
    }
    
    static func testOfflineFallback() async -> Bool {
        print("\n🧪 Test 4: Offline Fallback")
        print("   Testing expired cache returns when network fails...")
        
        let cache = CacheManager()
        let key = "test:offline:1"
        let testData = ["important": "data"]
        
        do {
            // Store data with 1 second TTL
            _ = try await cache.fetch(key: key, ttl: 1) {
                return testData
            }
            
            // Wait for expiry
            try await Task.sleep(for: .seconds(2))
            
            // Simulate network failure - should return expired cache
            let result: [String: String] = try await cache.fetch(key: key, ttl: 1) {
                throw CacheError.networkError
            }
            
            guard result["important"] == "data" else {
                print("   ❌ FAIL: Offline fallback didn't return expired cache")
                return false
            }
            
            print("   ✅ PASS: Offline fallback returned expired cache")
            return true
            
        } catch {
            print("   ❌ FAIL: Should have returned expired cache, threw: \(error)")
            return false
        }
    }
    
    static func testRequestDeduplication() async -> Bool {
        print("\n🧪 Test 5: Request Deduplication")
        print("   Testing multiple simultaneous requests are deduplicated...")
        
        let cache = CacheManager()
        let key = "test:dedup:1"
        
        // Shared counter (needs to be isolated)
        actor CallCounter {
            var count = 0
            func increment() { count += 1 }
            func get() -> Int { count }
        }
        let counter = CallCounter()
        
        do {
            // Launch 10 concurrent requests for same data
            let tasks = (0..<10).map { _ in
                Task {
                    try await cache.fetch(key: key, ttl: 60) {
                        await counter.increment()
                        try await Task.sleep(for: .milliseconds(100))
                        return "data"
                    }
                }
            }
            
            // Wait for all
            for task in tasks {
                _ = try await task.value
            }
            
            let callCount = await counter.get()
            
            // Should only call operation once
            guard callCount == 1 else {
                print("   ❌ FAIL: Operation called \(callCount) times (expected 1)")
                return false
            }
            
            let stats = await cache.getStatistics()
            guard stats.deduplicatedRequests >= 9 else {
                print("   ❌ FAIL: Deduplication count wrong: \(stats.deduplicatedRequests)")
                return false
            }
            
            print("   ✅ PASS: Deduplication prevented \(stats.deduplicatedRequests) unnecessary requests")
            return true
            
        } catch {
            print("   ❌ FAIL: \(error)")
            return false
        }
    }
    
    static func testTTLExpiry() async -> Bool {
        print("\n🧪 Test 6: TTL Expiry")
        print("   Testing cache entries expire correctly...")
        
        let cache = CacheManager()
        let key = "test:ttl:1"
        
        actor FetchCounter {
            var count = 0
            func increment() { count += 1 }
            func get() -> Int { count }
        }
        let counter = FetchCounter()
        
        do {
            // Store with 1 second TTL
            _ = try await cache.fetch(key: key, ttl: 1) {
                await counter.increment()
                return "fresh"
            }
            
            // Immediately fetch again (should hit cache)
            _ = try await cache.fetch(key: key, ttl: 1) {
                await counter.increment()
                return "fresh"
            }
            
            let count1 = await counter.get()
            guard count1 == 1 else {
                print("   ❌ FAIL: Cache miss when should hit")
                return false
            }
            
            // Wait for TTL expiry
            try await Task.sleep(for: .seconds(2))
            
            // Fetch again (should miss cache and re-fetch)
            _ = try await cache.fetch(key: key, ttl: 1) {
                await counter.increment()
                return "new"
            }
            
            let count2 = await counter.get()
            guard count2 == 2 else {
                print("   ❌ FAIL: Cache hit when should miss after expiry")
                return false
            }
            
            print("   ✅ PASS: TTL expiry works correctly")
            return true
            
        } catch {
            print("   ❌ FAIL: \(error)")
            return false
        }
    }
    
    static func testPatternInvalidation() async -> Bool {
        print("\n🧪 Test 7: Pattern Invalidation")
        print("   Testing selective cache clearing by pattern...")
        
        let cache = CacheManager()
        
        actor FetchCounter {
            var count = 0
            func increment() { count += 1 }
            func get() -> Int { count }
            func reset() { count = 0 }
        }
        let counter = FetchCounter()
        
        do {
            // Store various data
            _ = try await cache.fetch(key: "strava:activities:90", ttl: 60) {
                await counter.increment()
                return "strava1"
            }
            _ = try await cache.fetch(key: "strava:activities:365", ttl: 60) {
                await counter.increment()
                return "strava2"
            }
            _ = try await cache.fetch(key: "intervals:activities:120", ttl: 60) {
                await counter.increment()
                return "intervals"
            }
            _ = try await cache.fetch(key: "healthkit:hrv:today", ttl: 60) {
                await counter.increment()
                return "hrv"
            }
            
            let initialCount = await counter.get()
            guard initialCount == 4 else {
                print("   ❌ FAIL: Setup failed, got \(initialCount) fetches")
                return false
            }
            
            // Clear only Strava cache
            await cache.invalidate(matching: "^strava:.*")
            
            // Reset counter to track post-invalidation fetches
            await counter.reset()
            
            // Test 1: Strava should be cleared (causes fetch)
            _ = try await cache.fetch(key: "strava:activities:90", ttl: 60) {
                await counter.increment()
                return "strava1-new"
            }
            
            let stravaFetchCount = await counter.get()
            guard stravaFetchCount == 1 else {
                print("   ❌ FAIL: Strava should have been cleared (expected 1 fetch, got \(stravaFetchCount))")
                return false
            }
            
            // Test 2: Intervals should still be cached (no fetch)
            _ = try await cache.fetch(key: "intervals:activities:120", ttl: 60) {
                await counter.increment()
                return "intervals-new"
            }
            
            let totalPostInvalidation = await counter.get()
            guard totalPostInvalidation == 1 else {
                print("   ❌ FAIL: Intervals should have been cached")
                print("      Expected 1 fetch (Strava only), got \(totalPostInvalidation)")
                return false
            }
            
            // Test 3: HealthKit should also still be cached (no fetch)
            _ = try await cache.fetch(key: "healthkit:hrv:today", ttl: 60) {
                await counter.increment()
                return "hrv-new"
            }
            
            let finalCount = await counter.get()
            guard finalCount == 1 else {
                print("   ❌ FAIL: HealthKit should have been cached")
                print("      Expected 1 fetch total, got \(finalCount)")
                return false
            }
            
            print("   ✅ PASS: Pattern-based invalidation works")
            print("      - Strava cleared: ✓")
            print("      - Intervals cached: ✓")
            print("      - HealthKit cached: ✓")
            return true
            
        } catch {
            print("   ❌ FAIL: \(error)")
            return false
        }
    }
}
