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
        
        // Test 8: Training Load CTL
        if await testTrainingLoadCTL() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 9: Training Load ATL
        if await testTrainingLoadATL() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 10: Training Load TSB
        if await testTrainingLoadTSB() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 11: Training Load Progressive
        if await testTrainingLoadProgressive() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 12: Training Load Baseline
        if await testTrainingLoadBaseline() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 13: Training Load Edge Cases
        if await testTrainingLoadEdgeCases() {
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
    
    // MARK: - Training Load Tests
    
    static func testTrainingLoadCTL() async -> Bool {
        print("\n🧪 Test 8: Training Load CTL Calculation")
        print("   Testing 42-day exponentially weighted average...")
        
        // Known test data: 42 days with TSS values
        // Simulate realistic training: 3-4 rides per week
        let dailyTSS: [Double] = [
            0, 0, 100, 0, 80, 0, 0,  // Week 1
            0, 0, 90, 0, 0, 120, 0,  // Week 2
            0, 0, 0, 85, 0, 75, 0,   // Week 3
            0, 95, 0, 0, 110, 0, 0,  // Week 4
            0, 0, 105, 0, 90, 0, 0,  // Week 5
            0, 0, 0, 95, 0, 100, 0   // Week 6
        ]
        
        let ctl = TrainingLoadCalculations.calculateCTL(from: dailyTSS)
        
        // CTL should be a smoothed average, typically 20-30 for this pattern
        // (EMA heavily weights recent values, so average is lower than simple mean)
        guard ctl > 15 && ctl < 35 else {
            print("   ❌ FAIL: CTL out of expected range")
            print("      Expected: 15-35, got: \(String(format: "%.1f", ctl))")
            return false
        }
        
        print("   ✅ PASS: CTL calculation works (CTL=\(String(format: "%.1f", ctl)))")
        return true
    }
    
    static func testTrainingLoadATL() async -> Bool {
        print("\n🧪 Test 9: Training Load ATL Calculation")
        print("   Testing 7-day exponentially weighted average...")
        
        // Last 7 days with higher TSS (acute load)
        let dailyTSS: [Double] = [
            0, 0, 100, 0, 80, 0, 0,  // Week 1
            0, 0, 90, 0, 0, 120, 0,  // Week 2
            0, 0, 0, 85, 0, 75, 0,   // Week 3
            0, 95, 0, 0, 110, 0, 0,  // Week 4
            0, 0, 105, 0, 90, 0, 0,  // Week 5
            120, 0, 0, 130, 0, 110, 0  // Week 6 (higher load)
        ]
        
        let atl = TrainingLoadCalculations.calculateATL(from: dailyTSS)
        
        // ATL should be higher due to recent high load
        guard atl > 50 && atl < 90 else {
            print("   ❌ FAIL: ATL out of expected range")
            print("      Expected: 50-90, got: \(String(format: "%.1f", atl))")
            return false
        }
        
        print("   ✅ PASS: ATL calculation works (ATL=\(String(format: "%.1f", atl)))")
        return true
    }
    
    static func testTrainingLoadTSB() async -> Bool {
        print("\n🧪 Test 10: Training Load TSB Calculation")
        print("   Testing Training Stress Balance (form)...")
        
        let ctl = 50.0  // Fitness
        let atl = 45.0  // Fatigue
        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)
        
        // TSB = CTL - ATL = 5 (positive = fresh)
        guard abs(tsb - 5.0) < 0.01 else {
            print("   ❌ FAIL: TSB calculation incorrect")
            print("      Expected: 5.0, got: \(String(format: "%.1f", tsb))")
            return false
        }
        
        // Test negative TSB (fatigued state)
        let fatiguedTSB = TrainingLoadCalculations.calculateTSB(ctl: 50.0, atl: 60.0)
        guard abs(fatiguedTSB + 10.0) < 0.01 else {
            print("   ❌ FAIL: Negative TSB calculation incorrect")
            print("      Expected: -10.0, got: \(String(format: "%.1f", fatiguedTSB))")
            return false
        }
        
        print("   ✅ PASS: TSB calculation works")
        print("      Fresh state (CTL>ATL): TSB=+\(String(format: "%.1f", tsb))")
        print("      Fatigued state (ATL>CTL): TSB=\(String(format: "%.1f", fatiguedTSB))")
        return true
    }
    
    static func testTrainingLoadProgressive() async -> Bool {
        print("\n🧪 Test 11: Training Load Progressive Calculation")
        print("   Testing day-by-day CTL/ATL progression...")
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date(timeIntervalSinceNow: -7 * 24 * 3600))
        let endDate = calendar.startOfDay(for: Date())
        
        // Create test data: 100 TSS on days 1, 3, 5, 7
        var dailyTSS: [Date: Double] = [:]
        for i in 0..<8 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate), i % 2 == 0 {
                dailyTSS[date] = 100.0
            }
        }
        
        let progressiveLoad = TrainingLoadCalculations.calculateProgressiveLoad(
            dailyTSS: dailyTSS,
            startDate: startDate,
            endDate: endDate,
            calendar: calendar
        )
        
        // Should have 8 days of data
        guard progressiveLoad.count == 8 else {
            print("   ❌ FAIL: Expected 8 days, got \(progressiveLoad.count)")
            return false
        }
        
        // Verify data exists for all days
        let sortedDates = progressiveLoad.keys.sorted()
        guard let firstDay = progressiveLoad[sortedDates[0]],
              let lastDay = progressiveLoad[sortedDates[7]] else {
            print("   ❌ FAIL: Missing load data for first or last day")
            return false
        }
        
        // CTL and ATL should be within reasonable ranges
        // With baseline estimation, initial values will be high, then adjust
        // The key test is that the calculation completes and produces reasonable values
        guard firstDay.ctl > 0 && lastDay.ctl > 0 else {
            print("   ❌ FAIL: CTL should be positive")
            return false
        }
        
        guard firstDay.atl > 0 && lastDay.atl > 0 else {
            print("   ❌ FAIL: ATL should be positive")
            return false
        }
        
        // Verify that both values are reasonable (not extreme)
        guard lastDay.ctl < 200 && lastDay.atl < 200 else {
            print("   ❌ FAIL: CTL/ATL values are unreasonably high")
            return false
        }
        
        print("   ✅ PASS: Progressive load calculation works")
        print("      Day 1: CTL=\(String(format: "%.1f", firstDay.ctl)), ATL=\(String(format: "%.1f", firstDay.atl))")
        print("      Day 8: CTL=\(String(format: "%.1f", lastDay.ctl)), ATL=\(String(format: "%.1f", lastDay.atl))")
        return true
    }
    
    static func testTrainingLoadBaseline() async -> Bool {
        print("\n🧪 Test 12: Training Load Baseline Estimation")
        print("   Testing initial CTL/ATL estimation from early training...")
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date(timeIntervalSinceNow: -14 * 24 * 3600))
        
        // Create 2 weeks of consistent training: 100 TSS every other day
        var dailyTSS: [Date: Double] = [:]
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate), i % 2 == 0 {
                dailyTSS[date] = 100.0
            }
        }
        
        let baseline = TrainingLoadCalculations.estimateBaseline(
            dailyTSS: dailyTSS,
            startDate: startDate,
            calendar: calendar
        )
        
        // Average TSS per activity = 100
        // CTL baseline ≈ 100 * 0.7 = 70
        // ATL baseline ≈ 100 * 0.4 = 40
        
        guard abs(baseline.ctl - 70.0) < 5.0 else {
            print("   ❌ FAIL: CTL baseline out of expected range")
            print("      Expected: ~70, got: \(String(format: "%.1f", baseline.ctl))")
            return false
        }
        
        guard abs(baseline.atl - 40.0) < 5.0 else {
            print("   ❌ FAIL: ATL baseline out of expected range")
            print("      Expected: ~40, got: \(String(format: "%.1f", baseline.atl))")
            return false
        }
        
        print("   ✅ PASS: Baseline estimation works")
        print("      CTL baseline: \(String(format: "%.1f", baseline.ctl))")
        print("      ATL baseline: \(String(format: "%.1f", baseline.atl))")
        return true
    }
    
    static func testTrainingLoadEdgeCases() async -> Bool {
        print("\n🧪 Test 13: Training Load Edge Cases")
        print("   Testing edge cases (empty data, single day, zeros)...")
        
        // Test 1: Empty data
        let emptyResult = TrainingLoadCalculations.calculateCTL(from: [])
        guard emptyResult == 0 else {
            print("   ❌ FAIL: Empty data should return 0")
            return false
        }
        
        // Test 2: Single day
        let singleDayResult = TrainingLoadCalculations.calculateCTL(from: [100.0])
        guard singleDayResult == 100.0 else {
            print("   ❌ FAIL: Single day should return that value")
            return false
        }
        
        // Test 3: All zeros
        let allZerosResult = TrainingLoadCalculations.calculateCTL(from: Array(repeating: 0.0, count: 42))
        guard allZerosResult == 0 else {
            print("   ❌ FAIL: All zeros should return 0")
            return false
        }
        
        // Test 4: Negative TSB (fatigue)
        let negativeTSB = TrainingLoadCalculations.calculateTSB(ctl: 40.0, atl: 60.0)
        guard negativeTSB < 0 else {
            print("   ❌ FAIL: High ATL should result in negative TSB")
            return false
        }
        
        // Test 5: Progressive load with no data
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: Date())
        let emptyProgressive = TrainingLoadCalculations.calculateProgressiveLoad(
            dailyTSS: [:],
            startDate: startDate,
            endDate: endDate,
            calendar: calendar
        )
        guard emptyProgressive.count == 1 else {
            print("   ❌ FAIL: Empty progressive should have 1 day (start date)")
            return false
        }
        
        print("   ✅ PASS: All edge cases handled correctly")
        print("      - Empty data: ✓")
        print("      - Single day: ✓")
        print("      - All zeros: ✓")
        print("      - Negative TSB: ✓")
        print("      - Empty progressive: ✓")
        return true
    }
}
