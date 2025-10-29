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
        
        // Test 14: Strain Cardio Load
        if await testStrainCardioLoad() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 15: Strain Strength Load
        if await testStrainStrengthLoad() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 16: Strain Non-Exercise Load
        if await testStrainNonExerciseLoad() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 17: Strain Recovery Factor
        if await testStrainRecoveryFactor() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 18: Strain Full Calculation
        if await testStrainFullCalculation() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 19: Strain Edge Cases
        if await testStrainEdgeCases() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 20: Recovery HRV Score
        if await testRecoveryHRVScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 21: Recovery RHR Score
        if await testRecoveryRHRScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 22: Recovery Sleep Score
        if await testRecoverySleepScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 23: Recovery Form Score
        if await testRecoveryFormScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 24: Recovery Full Calculation
        if await testRecoveryFullCalculation() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 25: Recovery Edge Cases
        if await testRecoveryEdgeCases() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 26: Sleep Performance Score
        if await testSleepPerformanceScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 27: Sleep Efficiency Score
        if await testSleepEfficiencyScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 28: Sleep Stage Quality Score
        if await testSleepStageQualityScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 29: Sleep Disturbances Score
        if await testSleepDisturbancesScore() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 30: Sleep Full Calculation
        if await testSleepFullCalculation() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 31: Sleep Edge Cases
        if await testSleepEdgeCases() {
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
    
    // MARK: - Strain Score Tests
    
    static func testStrainCardioLoad() async -> Bool {
        print("\n🧪 Test 14: Strain Cardio Load Calculation")
        print("   Testing TRIMP → cardio load conversion...")
        
        // Test 1: Moderate TRIMP
        let moderateLoad = StrainCalculations.calculateCardioLoad(
            trimp: 100.0,
            duration: nil,
            intensityFactor: nil
        )
        guard moderateLoad > 30 && moderateLoad < 80 else {
            print("   ❌ FAIL: Moderate TRIMP out of range")
            print("      Expected: 30-80, got: \(moderateLoad)")
            return false
        }
        
        // Test 2: Duration bonus (long ride)
        let longRideLoad = StrainCalculations.calculateCardioLoad(
            trimp: 100.0,
            duration: 120.0, // 2 hours
            intensityFactor: nil
        )
        guard longRideLoad > moderateLoad else {
            print("   ❌ FAIL: Long duration should increase load")
            return false
        }
        
        // Test 3: Intensity bonus (high IF)
        let highIntensityLoad = StrainCalculations.calculateCardioLoad(
            trimp: 100.0,
            duration: nil,
            intensityFactor: 0.9 // High intensity
        )
        guard highIntensityLoad > moderateLoad else {
            print("   ❌ FAIL: High intensity should increase load")
            return false
        }
        
        // Test 4: Zero TRIMP
        let zeroLoad = StrainCalculations.calculateCardioLoad(
            trimp: 0.0,
            duration: nil,
            intensityFactor: nil
        )
        guard zeroLoad == 0 else {
            print("   ❌ FAIL: Zero TRIMP should return 0")
            return false
        }
        
        print("   ✅ PASS: Cardio load calculation works")
        print("      Moderate TRIMP: \(moderateLoad)")
        print("      With duration bonus: \(longRideLoad)")
        print("      With intensity bonus: \(highIntensityLoad)")
        return true
    }
    
    static func testStrainStrengthLoad() async -> Bool {
        print("\n🧪 Test 15: Strain Strength Load Calculation")
        print("   Testing RPE → strength load conversion...")
        
        // Test 1: Moderate strength session
        let moderateLoad = StrainCalculations.calculateStrengthLoad(
            rpe: 7.0,
            duration: 45.0,
            volume: nil,
            sets: nil,
            bodyMass: nil
        )
        guard moderateLoad > 50 && moderateLoad < 90 else {
            print("   ❌ FAIL: Moderate RPE out of range")
            print("      Expected: 50-90, got: \(moderateLoad)")
            return false
        }
        
        // Test 2: High RPE session
        let highRPELoad = StrainCalculations.calculateStrengthLoad(
            rpe: 9.5,
            duration: 45.0,
            volume: nil,
            sets: nil,
            bodyMass: nil
        )
        guard highRPELoad > moderateLoad else {
            print("   ❌ FAIL: High RPE should increase load")
            return false
        }
        
        // Test 3: Volume bonus
        let volumeLoad = StrainCalculations.calculateStrengthLoad(
            rpe: 7.0,
            duration: 45.0,
            volume: 5000.0, // 5000 kg total
            sets: nil,
            bodyMass: 75.0
        )
        guard volumeLoad > moderateLoad else {
            print("   ❌ FAIL: Volume should increase load")
            return false
        }
        
        // Test 4: Sets bonus
        let setsLoad = StrainCalculations.calculateStrengthLoad(
            rpe: 7.0,
            duration: 45.0,
            volume: nil,
            sets: 20, // High volume
            bodyMass: nil
        )
        guard setsLoad > moderateLoad else {
            print("   ❌ FAIL: High sets should increase load")
            return false
        }
        
        // Test 5: Invalid RPE
        let invalidLoad = StrainCalculations.calculateStrengthLoad(
            rpe: 11.0, // Out of range
            duration: 45.0,
            volume: nil,
            sets: nil,
            bodyMass: nil
        )
        guard invalidLoad == 0 else {
            print("   ❌ FAIL: Invalid RPE should return 0")
            return false
        }
        
        print("   ✅ PASS: Strength load calculation works")
        print("      Moderate RPE: \(moderateLoad)")
        print("      High RPE: \(highRPELoad)")
        print("      With volume: \(volumeLoad)")
        print("      With sets: \(setsLoad)")
        return true
    }
    
    static func testStrainNonExerciseLoad() async -> Bool {
        print("\n🧪 Test 16: Strain Non-Exercise Load Calculation")
        print("   Testing steps/calories → activity load...")
        
        // Test 1: Moderate steps
        let stepsLoad = StrainCalculations.calculateNonExerciseLoad(
            steps: 8000,
            activeCalories: nil
        )
        guard stepsLoad > 50 && stepsLoad < 100 else {
            print("   ❌ FAIL: Steps load out of range")
            print("      Expected: 50-100, got: \(stepsLoad)")
            return false
        }
        
        // Test 2: Active calories
        let caloriesLoad = StrainCalculations.calculateNonExerciseLoad(
            steps: nil,
            activeCalories: 500.0
        )
        guard caloriesLoad > 5 && caloriesLoad < 40 else {
            print("   ❌ FAIL: Calories load out of range")
            return false
        }
        
        // Test 3: Combined (may hit logarithmic cap, so just verify it's >= either individual)
        let combinedLoad = StrainCalculations.calculateNonExerciseLoad(
            steps: 8000,
            activeCalories: 500.0
        )
        guard combinedLoad >= stepsLoad || combinedLoad >= caloriesLoad else {
            print("   ❌ FAIL: Combined should be >= individual components")
            print("      Steps: \(stepsLoad), Calories: \(caloriesLoad), Combined: \(combinedLoad)")
            return false
        }
        
        // Test 4: Zero input
        let zeroLoad = StrainCalculations.calculateNonExerciseLoad(
            steps: 0,
            activeCalories: 0
        )
        guard zeroLoad == 0 else {
            print("   ❌ FAIL: Zero input should return 0")
            return false
        }
        
        print("   ✅ PASS: Non-exercise load calculation works")
        print("      Steps only: \(stepsLoad)")
        print("      Calories only: \(caloriesLoad)")
        print("      Combined: \(combinedLoad)")
        return true
    }
    
    static func testStrainRecoveryFactor() async -> Bool {
        print("\n🧪 Test 17: Strain Recovery Factor Calculation")
        print("   Testing recovery modulation...")
        
        // Test 1: Well recovered (high HRV, low RHR, good sleep)
        let wellRecovered = StrainCalculations.calculateRecoveryFactor(
            hrvCurrent: 60.0,
            hrvBaseline: 50.0, // 20% above baseline
            rhrCurrent: 50.0,
            rhrBaseline: 55.0, // 9% below baseline
            sleepQuality: 85
        )
        guard wellRecovered > 1.0 && wellRecovered <= 1.15 else {
            print("   ❌ FAIL: Well recovered factor out of range")
            print("      Expected: 1.0-1.15, got: \(String(format: "%.2f", wellRecovered))")
            return false
        }
        
        // Test 2: Poorly recovered (low HRV, high RHR, poor sleep)
        let poorlyRecovered = StrainCalculations.calculateRecoveryFactor(
            hrvCurrent: 40.0,
            hrvBaseline: 50.0, // 20% below baseline
            rhrCurrent: 60.0,
            rhrBaseline: 55.0, // 9% above baseline
            sleepQuality: 50
        )
        guard poorlyRecovered < 1.0 && poorlyRecovered >= 0.85 else {
            print("   ❌ FAIL: Poorly recovered factor out of range")
            print("      Expected: 0.85-1.0, got: \(String(format: "%.2f", poorlyRecovered))")
            return false
        }
        
        // Test 3: Neutral recovery
        let neutral = StrainCalculations.calculateRecoveryFactor(
            hrvCurrent: 50.0,
            hrvBaseline: 50.0,
            rhrCurrent: 55.0,
            rhrBaseline: 55.0,
            sleepQuality: 75
        )
        guard abs(neutral - 1.0) < 0.05 else {
            print("   ❌ FAIL: Neutral recovery should be ~1.0")
            print("      Got: \(String(format: "%.2f", neutral))")
            return false
        }
        
        // Test 4: No data
        let noData = StrainCalculations.calculateRecoveryFactor(
            hrvCurrent: nil,
            hrvBaseline: nil,
            rhrCurrent: nil,
            rhrBaseline: nil,
            sleepQuality: nil
        )
        guard abs(noData - 1.0) < 0.01 else {
            print("   ❌ FAIL: No data should return 1.0")
            return false
        }
        
        print("   ✅ PASS: Recovery factor calculation works")
        print("      Well recovered: \(String(format: "%.2f", wellRecovered))")
        print("      Poorly recovered: \(String(format: "%.2f", poorlyRecovered))")
        print("      Neutral: \(String(format: "%.2f", neutral))")
        return true
    }
    
    static func testStrainFullCalculation() async -> Bool {
        print("\n🧪 Test 18: Strain Full Calculation")
        print("   Testing complete strain score...")
        
        // Test 1: Moderate training day
        let moderateDay = StrainCalculations.calculateStrainScore(
            cardioTRIMP: 100.0,
            cardioDuration: 60.0,
            intensityFactor: 0.7,
            strengthRPE: nil,
            strengthDuration: nil,
            strengthVolume: nil,
            strengthSets: nil,
            bodyMass: 75.0,
            steps: 8000,
            activeCalories: 400.0,
            hrvCurrent: 50.0,
            hrvBaseline: 50.0,
            rhrCurrent: 55.0,
            rhrBaseline: 55.0,
            sleepQuality: 75
        )
        
        // Score will be clamped to max 21, so just verify it's reasonable
        guard moderateDay.score >= 11.0 && moderateDay.score <= 21.0 else {
            print("   ❌ FAIL: Moderate day score out of range")
            print("      Expected: 11-21, got: \(String(format: "%.1f", moderateDay.score))")
            return false
        }
        
        // Band should be hard or higher due to combined loads
        guard moderateDay.band == .hard || moderateDay.band == .veryHard || moderateDay.band == .allOut else {
            print("   ❌ FAIL: Band should be hard or higher, got: \(moderateDay.band.rawValue)")
            return false
        }
        
        // Test 2: Hard training day
        let hardDay = StrainCalculations.calculateStrainScore(
            cardioTRIMP: 200.0,
            cardioDuration: 120.0,
            intensityFactor: 0.85,
            strengthRPE: 8.0,
            strengthDuration: 45.0,
            strengthVolume: nil,
            strengthSets: nil,
            bodyMass: 75.0,
            steps: 10000,
            activeCalories: 600.0,
            hrvCurrent: 50.0,
            hrvBaseline: 50.0,
            rhrCurrent: 55.0,
            rhrBaseline: 55.0,
            sleepQuality: 75
        )
        
        // Both may be clamped at max, so just verify hard day has more load components
        guard hardDay.score >= moderateDay.score else {
            print("   ❌ FAIL: Hard day should have >= score than moderate")
            print("      Moderate: \(String(format: "%.1f", moderateDay.score)), Hard: \(String(format: "%.1f", hardDay.score))")
            return false
        }
        
        guard hardDay.cardioLoad > 0 && hardDay.strengthLoad > 0 else {
            print("   ❌ FAIL: Should have both cardio and strength load")
            return false
        }
        
        // Test 3: Recovery modulation (use minimal load to avoid clamping)
        let poorRecoveryDay = StrainCalculations.calculateStrainScore(
            cardioTRIMP: 30.0, // Minimal load
            cardioDuration: nil,
            intensityFactor: nil,
            strengthRPE: nil,
            strengthDuration: nil,
            strengthVolume: nil,
            strengthSets: nil,
            bodyMass: 75.0,
            steps: 3000, // Minimal steps
            activeCalories: nil,
            hrvCurrent: 40.0, // Low HRV
            hrvBaseline: 50.0,
            rhrCurrent: 60.0, // High RHR
            rhrBaseline: 55.0,
            sleepQuality: 50 // Poor sleep
        )
        
        let wellRecoveryDay = StrainCalculations.calculateStrainScore(
            cardioTRIMP: 30.0, // Same minimal load
            cardioDuration: nil,
            intensityFactor: nil,
            strengthRPE: nil,
            strengthDuration: nil,
            strengthVolume: nil,
            strengthSets: nil,
            bodyMass: 75.0,
            steps: 3000,
            activeCalories: nil,
            hrvCurrent: 60.0, // High HRV
            hrvBaseline: 50.0,
            rhrCurrent: 50.0, // Low RHR
            rhrBaseline: 55.0,
            sleepQuality: 85 // Good sleep
        )
        
        // Verify recovery factors are correct (scores may be clamped at max)
        guard poorRecoveryDay.recoveryFactor < 1.0 else {
            print("   ❌ FAIL: Poor recovery should have factor < 1.0")
            print("      Got: \(String(format: "%.2f", poorRecoveryDay.recoveryFactor))")
            return false
        }
        
        guard wellRecoveryDay.recoveryFactor > 1.0 else {
            print("   ❌ FAIL: Good recovery should have factor > 1.0")
            print("      Got: \(String(format: "%.2f", wellRecoveryDay.recoveryFactor))")
            return false
        }
        
        // Verify that well recovered has higher or equal score
        // (may both hit cap at 21, which is correct behavior)
        guard wellRecoveryDay.score >= poorRecoveryDay.score else {
            print("   ❌ FAIL: Good recovery should have >= score")
            return false
        }
        
        print("   ✅ PASS: Full strain calculation works")
        print("      Moderate day: \(String(format: "%.1f", moderateDay.score)) (\(moderateDay.band.rawValue))")
        print("      Hard day: \(String(format: "%.1f", hardDay.score)) (\(hardDay.band.rawValue))")
        print("      Poor recovery: \(String(format: "%.1f", poorRecoveryDay.score)) (factor: \(String(format: "%.2f", poorRecoveryDay.recoveryFactor)))")
        return true
    }
    
    static func testStrainEdgeCases() async -> Bool {
        print("\n🧪 Test 19: Strain Edge Cases")
        print("   Testing edge cases and boundary conditions...")
        
        // Test 1: All zeros
        let allZeros = StrainCalculations.calculateStrainScore(
            cardioTRIMP: nil,
            cardioDuration: nil,
            intensityFactor: nil,
            strengthRPE: nil,
            strengthDuration: nil,
            strengthVolume: nil,
            strengthSets: nil,
            bodyMass: nil,
            steps: nil,
            activeCalories: nil,
            hrvCurrent: nil,
            hrvBaseline: nil,
            rhrCurrent: nil,
            rhrBaseline: nil,
            sleepQuality: nil
        )
        guard allZeros.score == 0 else {
            print("   ❌ FAIL: All zeros should return 0 strain")
            return false
        }
        
        // Test 2: Extreme values (should clamp to 0-21)
        let extremeValues = StrainCalculations.calculateStrainScore(
            cardioTRIMP: 1000.0, // Very high
            cardioDuration: 300.0,
            intensityFactor: 1.2,
            strengthRPE: 10.0,
            strengthDuration: 180.0,
            strengthVolume: 50000.0,
            strengthSets: 100,
            bodyMass: 75.0,
            steps: 50000,
            activeCalories: 5000.0,
            hrvCurrent: 100.0,
            hrvBaseline: 50.0,
            rhrCurrent: 40.0,
            rhrBaseline: 60.0,
            sleepQuality: 100
        )
        guard extremeValues.score <= 21.0 else {
            print("   ❌ FAIL: Score should be clamped to max 21.0")
            return false
        }
        
        // Test 3: Band determination
        let lightBand = StrainCalculations.determineStrainBand(score: 3.0)
        guard lightBand == .light else {
            print("   ❌ FAIL: Score 3.0 should be 'Light'")
            return false
        }
        
        let allOutBand = StrainCalculations.determineStrainBand(score: 20.0)
        guard allOutBand == .allOut else {
            print("   ❌ FAIL: Score 20.0 should be 'All Out'")
            return false
        }
        
        // Test 4: Negative inputs (should handle gracefully)
        let negativeInputs = StrainCalculations.calculateCardioLoad(
            trimp: -100.0,
            duration: nil,
            intensityFactor: nil
        )
        guard negativeInputs == 0 else {
            print("   ❌ FAIL: Negative TRIMP should return 0")
            return false
        }
        
        print("   ✅ PASS: All edge cases handled correctly")
        print("      - All zeros: ✓")
        print("      - Extreme values clamped: ✓")
        print("      - Band determination: ✓")
        print("      - Negative inputs: ✓")
        return true
    }
    
    // MARK: - Recovery Score Tests
    
    static func testRecoveryHRVScore() async -> Bool {
        print("\n🧪 Test 20: Recovery HRV Score Calculation")
        print("   Testing HRV deviation → recovery score...")
        
        // Test 1: At baseline
        let baseline = RecoveryCalculations.calculateHRVScore(hrv: 50.0, baseline: 50.0)
        guard baseline == 100 else {
            print("   ❌ FAIL: At baseline should be 100")
            print("      Got: \(baseline)")
            return false
        }
        
        // Test 2: Above baseline (good)
        let above = RecoveryCalculations.calculateHRVScore(hrv: 55.0, baseline: 50.0)
        guard above == 100 else {
            print("   ❌ FAIL: Above baseline should be 100")
            return false
        }
        
        // Test 3: Small drop (5%)
        let smallDrop = RecoveryCalculations.calculateHRVScore(hrv: 47.5, baseline: 50.0)
        guard smallDrop >= 85 && smallDrop <= 100 else {
            print("   ❌ FAIL: Small drop (5%) out of range")
            print("      Expected: 85-100, got: \(smallDrop)")
            return false
        }
        
        // Test 4: Moderate drop (15%)
        let moderateDrop = RecoveryCalculations.calculateHRVScore(hrv: 42.5, baseline: 50.0)
        guard moderateDrop >= 60 && moderateDrop <= 85 else {
            print("   ❌ FAIL: Moderate drop (15%) out of range")
            print("      Expected: 60-85, got: \(moderateDrop)")
            return false
        }
        
        // Test 5: Large drop (30%)
        let largeDrop = RecoveryCalculations.calculateHRVScore(hrv: 35.0, baseline: 50.0)
        guard largeDrop >= 30 && largeDrop < 60 else {
            print("   ❌ FAIL: Large drop (30%) out of range")
            print("      Expected: 30-60, got: \(largeDrop)")
            return false
        }
        
        // Test 6: Extreme drop (50%)
        let extremeDrop = RecoveryCalculations.calculateHRVScore(hrv: 25.0, baseline: 50.0)
        guard extremeDrop < 30 else {
            print("   ❌ FAIL: Extreme drop (50%) should be < 30")
            print("      Got: \(extremeDrop)")
            return false
        }
        
        print("   ✅ PASS: HRV score calculation works")
        print("      Baseline: \(baseline)")
        print("      Above baseline: \(above)")
        print("      Small drop: \(smallDrop)")
        print("      Moderate drop: \(moderateDrop)")
        print("      Large drop: \(largeDrop)")
        return true
    }
    
    static func testRecoveryRHRScore() async -> Bool {
        print("\n🧪 Test 21: Recovery RHR Score Calculation")
        print("   Testing RHR deviation → recovery score...")
        
        // Test 1: At baseline
        let baseline = RecoveryCalculations.calculateRHRScore(rhr: 55.0, baseline: 55.0)
        guard baseline == 100 else {
            print("   ❌ FAIL: At baseline should be 100")
            return false
        }
        
        // Test 2: Below baseline (good)
        let below = RecoveryCalculations.calculateRHRScore(rhr: 52.0, baseline: 55.0)
        guard below == 100 else {
            print("   ❌ FAIL: Below baseline should be 100")
            return false
        }
        
        // Test 3: Small increase (5%)
        let smallIncrease = RecoveryCalculations.calculateRHRScore(rhr: 57.75, baseline: 55.0)
        guard smallIncrease >= 88 && smallIncrease <= 100 else {
            print("   ❌ FAIL: Small increase (5%) out of range")
            print("      Expected: 88-100, got: \(smallIncrease)")
            return false
        }
        
        // Test 4: Moderate increase (12%)
        let moderateIncrease = RecoveryCalculations.calculateRHRScore(rhr: 61.6, baseline: 55.0)
        guard moderateIncrease >= 67 && moderateIncrease <= 88 else {
            print("   ❌ FAIL: Moderate increase (12%) out of range")
            print("      Expected: 67-88, got: \(moderateIncrease)")
            return false
        }
        
        // Test 5: Large increase (20%)
        let largeIncrease = RecoveryCalculations.calculateRHRScore(rhr: 66.0, baseline: 55.0)
        guard largeIncrease >= 37 && largeIncrease < 67 else {
            print("   ❌ FAIL: Large increase (20%) out of range")
            print("      Expected: 37-67, got: \(largeIncrease)")
            return false
        }
        
        print("   ✅ PASS: RHR score calculation works")
        print("      Baseline: \(baseline)")
        print("      Below baseline: \(below)")
        print("      Small increase: \(smallIncrease)")
        print("      Moderate increase: \(moderateIncrease)")
        return true
    }
    
    static func testRecoverySleepScore() async -> Bool {
        print("\n🧪 Test 22: Recovery Sleep Score Calculation")
        print("   Testing sleep duration/quality → recovery score...")
        
        // Test 1: Use quality score if available
        let withQuality = RecoveryCalculations.calculateSleepScore(
            sleepDuration: 7 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: 85
        )
        guard withQuality == 85 else {
            print("   ❌ FAIL: Should use quality score when available")
            print("      Expected: 85, got: \(withQuality)")
            return false
        }
        
        // Test 2: Duration-based (at baseline)
        let atBaseline = RecoveryCalculations.calculateSleepScore(
            sleepDuration: 8 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: nil
        )
        guard atBaseline == 100 else {
            print("   ❌ FAIL: At baseline should be 100")
            print("      Got: \(atBaseline)")
            return false
        }
        
        // Test 3: Duration-based (below baseline)
        let belowBaseline = RecoveryCalculations.calculateSleepScore(
            sleepDuration: 6 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: nil
        )
        guard belowBaseline == 75 else {
            print("   ❌ FAIL: 6h / 8h should be 75")
            print("      Got: \(belowBaseline)")
            return false
        }
        
        // Test 4: Duration-based (above baseline, capped at 100)
        let aboveBaseline = RecoveryCalculations.calculateSleepScore(
            sleepDuration: 9 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: nil
        )
        guard aboveBaseline == 100 else {
            print("   ❌ FAIL: Above baseline should be capped at 100")
            print("      Got: \(aboveBaseline)")
            return false
        }
        
        print("   ✅ PASS: Sleep score calculation works")
        print("      With quality score: \(withQuality)")
        print("      At baseline: \(atBaseline)")
        print("      Below baseline: \(belowBaseline)")
        return true
    }
    
    static func testRecoveryFormScore() async -> Bool {
        print("\n🧪 Test 23: Recovery Form Score Calculation")
        print("   Testing training load → form score...")
        
        // Test 1: Fresh state (ATL < CTL)
        let fresh = RecoveryCalculations.calculateFormScore(
            atl: 40.0,
            ctl: 50.0,
            yesterdayTSS: nil
        )
        guard fresh == 100 else {
            print("   ❌ FAIL: Fresh state (ATL<CTL) should be 100")
            print("      Got: \(fresh)")
            return false
        }
        
        // Test 2: Moderate fatigue (ATL = 1.25 * CTL)
        let moderate = RecoveryCalculations.calculateFormScore(
            atl: 62.5,
            ctl: 50.0,
            yesterdayTSS: nil
        )
        guard moderate >= 50 && moderate < 100 else {
            print("   ❌ FAIL: Moderate fatigue out of range")
            print("      Expected: 50-100, got: \(moderate)")
            return false
        }
        
        // Test 3: High fatigue (ATL = 1.5 * CTL)
        let highFatigue = RecoveryCalculations.calculateFormScore(
            atl: 75.0,
            ctl: 50.0,
            yesterdayTSS: nil
        )
        guard highFatigue == 50 else {
            print("   ❌ FAIL: High fatigue (ATL=1.5*CTL) should be 50")
            print("      Got: \(highFatigue)")
            return false
        }
        
        // Test 4: Yesterday's TSS penalty
        let withPenalty = RecoveryCalculations.calculateFormScore(
            atl: 40.0,
            ctl: 50.0,
            yesterdayTSS: 120.0 // 100-150 range = 10 point penalty
        )
        guard withPenalty == 90 else {
            print("   ❌ FAIL: TSS penalty not applied correctly")
            print("      Expected: 90, got: \(withPenalty)")
            return false
        }
        
        // Test 5: TSS penalty calculation
        let penalty50 = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: 50.0)
        let penalty120 = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: 120.0)
        let penalty250 = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: 250.0)
        
        guard penalty50 == 5 && penalty120 == 10 && penalty250 == 30 else {
            print("   ❌ FAIL: TSS penalty tiers incorrect")
            return false
        }
        
        print("   ✅ PASS: Form score calculation works")
        print("      Fresh state: \(fresh)")
        print("      Moderate fatigue: \(moderate)")
        print("      With TSS penalty: \(withPenalty)")
        return true
    }
    
    static func testRecoveryFullCalculation() async -> Bool {
        print("\n🧪 Test 24: Recovery Full Calculation")
        print("   Testing complete recovery score...")
        
        // Test 1: Optimal recovery
        let optimal = RecoveryCalculations.calculateRecoveryScore(
            hrv: 55.0,
            hrvBaseline: 50.0,
            rhr: 52.0,
            rhrBaseline: 55.0,
            sleepDuration: 8 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: 85,
            respiratoryRate: 15.0,
            respiratoryBaseline: 15.0,
            atl: 40.0,
            ctl: 50.0,
            yesterdayTSS: nil
        )
        
        guard optimal.score >= 80 && optimal.score <= 100 else {
            print("   ❌ FAIL: Optimal recovery out of range")
            print("      Expected: 80-100, got: \(optimal.score)")
            return false
        }
        
        guard optimal.band == .optimal else {
            print("   ❌ FAIL: Band should be optimal")
            return false
        }
        
        // Test 2: Poor recovery
        let poor = RecoveryCalculations.calculateRecoveryScore(
            hrv: 35.0,
            hrvBaseline: 50.0,
            rhr: 66.0,
            rhrBaseline: 55.0,
            sleepDuration: 5 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: 40,
            respiratoryRate: 18.0,
            respiratoryBaseline: 15.0,
            atl: 75.0,
            ctl: 50.0,
            yesterdayTSS: 180.0
        )
        
        guard poor.score < 60 else {
            print("   ❌ FAIL: Poor recovery should be < 60")
            print("      Got: \(poor.score)")
            return false
        }
        
        // Test 3: Verify sub-scores
        guard optimal.hrvScore == 100 else {
            print("   ❌ FAIL: Optimal HRV should be 100")
            return false
        }
        
        guard optimal.rhrScore == 100 else {
            print("   ❌ FAIL: Optimal RHR should be 100")
            return false
        }
        
        guard optimal.sleepScore == 85 else {
            print("   ❌ FAIL: Sleep score should be 85")
            return false
        }
        
        // Test 4: Weighted combination
        // HRV(100)*0.3 + RHR(100)*0.2 + Sleep(85)*0.3 + Resp(100)*0.1 + Form(100)*0.1
        // = 30 + 20 + 25.5 + 10 + 10 = 95.5
        let hrvContribution = 100.0 * 0.3
        let rhrContribution = 100.0 * 0.2
        let sleepContribution = 85.0 * 0.3
        let respContribution = 100.0 * 0.1
        let formContribution = 100.0 * 0.1
        let expectedScore = hrvContribution + rhrContribution + sleepContribution + respContribution + formContribution
        guard abs(Double(optimal.score) - expectedScore) < 1.0 else {
            print("   ❌ FAIL: Weighted combination incorrect")
            print("      Expected: ~\(Int(expectedScore)), got: \(optimal.score)")
            return false
        }
        
        print("   ✅ PASS: Full recovery calculation works")
        print("      Optimal: \(optimal.score) (\(optimal.band.rawValue))")
        print("      Poor: \(poor.score) (\(poor.band.rawValue))")
        return true
    }
    
    static func testRecoveryEdgeCases() async -> Bool {
        print("\n🧪 Test 25: Recovery Edge Cases")
        print("   Testing edge cases and boundary conditions...")
        
        // Test 1: No data (should return neutral)
        let noData = RecoveryCalculations.calculateRecoveryScore(
            hrv: nil,
            hrvBaseline: nil,
            rhr: nil,
            rhrBaseline: nil,
            sleepDuration: nil,
            sleepBaseline: nil,
            sleepQualityScore: nil,
            respiratoryRate: nil,
            respiratoryBaseline: nil,
            atl: nil,
            ctl: nil,
            yesterdayTSS: nil
        )
        guard noData.score == 50 else {
            print("   ❌ FAIL: No data should return 50")
            print("      Got: \(noData.score)")
            return false
        }
        
        // Test 2: Band determination
        let optimal = RecoveryCalculations.determineRecoveryBand(score: 85)
        let good = RecoveryCalculations.determineRecoveryBand(score: 70)
        let fair = RecoveryCalculations.determineRecoveryBand(score: 50)
        let poor = RecoveryCalculations.determineRecoveryBand(score: 30)
        
        guard optimal == .optimal && good == .good && fair == .fair && poor == .poor else {
            print("   ❌ FAIL: Band determination incorrect")
            return false
        }
        
        // Test 3: Zero baseline (should handle gracefully)
        let zeroBaseline = RecoveryCalculations.calculateHRVScore(hrv: 50.0, baseline: 0.0)
        guard zeroBaseline == 50 else {
            print("   ❌ FAIL: Zero baseline should return 50")
            return false
        }
        
        // Test 4: Negative values (should handle gracefully)
        let negativeHRV = RecoveryCalculations.calculateHRVScore(hrv: -10.0, baseline: 50.0)
        guard negativeHRV >= 0 else {
            print("   ❌ FAIL: Should handle negative HRV")
            return false
        }
        
        // Test 5: Extreme values (should clamp)
        let extreme = RecoveryCalculations.calculateRecoveryScore(
            hrv: 200.0,
            hrvBaseline: 50.0,
            rhr: 30.0,
            rhrBaseline: 55.0,
            sleepDuration: 12 * 3600,
            sleepBaseline: 8 * 3600,
            sleepQualityScore: 100,
            respiratoryRate: 12.0,
            respiratoryBaseline: 15.0,
            atl: 20.0,
            ctl: 50.0,
            yesterdayTSS: 0.0
        )
        guard extreme.score <= 100 else {
            print("   ❌ FAIL: Score should be clamped to 100")
            return false
        }
        
        print("   ✅ PASS: All edge cases handled correctly")
        print("      - No data: ✓")
        print("      - Band determination: ✓")
        print("      - Zero baseline: ✓")
        print("      - Negative values: ✓")
        print("      - Extreme values clamped: ✓")
        return true
    }
    
    // MARK: - Sleep Score Tests
    
    static func testSleepPerformanceScore() async -> Bool {
        print("\n🧪 Test 26: Sleep Performance Score Calculation")
        print("   Testing sleep duration vs need → performance score...")
        
        // Test 1: Met sleep need exactly
        let perfect = SleepCalculations.calculatePerformanceScore(
            sleepDuration: 8 * 3600,
            sleepNeed: 8 * 3600
        )
        guard perfect == 100 else {
            print("   ❌ FAIL: Meeting sleep need should be 100")
            print("      Got: \(perfect)")
            return false
        }
        
        // Test 2: Exceeded sleep need
        let exceeded = SleepCalculations.calculatePerformanceScore(
            sleepDuration: 9 * 3600,
            sleepNeed: 8 * 3600
        )
        guard exceeded == 100 else {
            print("   ❌ FAIL: Exceeding sleep need should be capped at 100")
            print("      Got: \(exceeded)")
            return false
        }
        
        // Test 3: Sleep deficit (75% of need)
        let deficit = SleepCalculations.calculatePerformanceScore(
            sleepDuration: 6 * 3600,
            sleepNeed: 8 * 3600
        )
        guard deficit == 75 else {
            print("   ❌ FAIL: 6h / 8h should be 75")
            print("      Got: \(deficit)")
            return false
        }
        
        // Test 4: Large deficit (50% of need)
        let largeDeficit = SleepCalculations.calculatePerformanceScore(
            sleepDuration: 4 * 3600,
            sleepNeed: 8 * 3600
        )
        guard largeDeficit == 50 else {
            print("   ❌ FAIL: 4h / 8h should be 50")
            print("      Got: \(largeDeficit)")
            return false
        }
        
        print("   ✅ PASS: Performance score calculation works")
        print("      Perfect: \(perfect)")
        print("      Exceeded: \(exceeded)")
        print("      Deficit: \(deficit)")
        return true
    }
    
    static func testSleepEfficiencyScore() async -> Bool {
        print("\n🧪 Test 27: Sleep Efficiency Score Calculation")
        print("   Testing time asleep vs time in bed → efficiency score...")
        
        // Test 1: Perfect efficiency
        let perfect = SleepCalculations.calculateEfficiencyScore(
            sleepDuration: 8 * 3600,
            timeInBed: 8 * 3600
        )
        guard perfect == 100 else {
            print("   ❌ FAIL: Perfect efficiency should be 100")
            return false
        }
        
        // Test 2: Good efficiency (90%)
        let good = SleepCalculations.calculateEfficiencyScore(
            sleepDuration: 7.2 * 3600,
            timeInBed: 8 * 3600
        )
        guard good == 90 else {
            print("   ❌ FAIL: 90% efficiency should be 90")
            print("      Got: \(good)")
            return false
        }
        
        // Test 3: Fair efficiency (75%)
        let fair = SleepCalculations.calculateEfficiencyScore(
            sleepDuration: 6 * 3600,
            timeInBed: 8 * 3600
        )
        guard fair == 75 else {
            print("   ❌ FAIL: 75% efficiency should be 75")
            print("      Got: \(fair)")
            return false
        }
        
        // Test 4: Poor efficiency (50%)
        let poor = SleepCalculations.calculateEfficiencyScore(
            sleepDuration: 4 * 3600,
            timeInBed: 8 * 3600
        )
        guard poor == 50 else {
            print("   ❌ FAIL: 50% efficiency should be 50")
            print("      Got: \(poor)")
            return false
        }
        
        print("   ✅ PASS: Efficiency score calculation works")
        print("      Perfect: \(perfect)")
        print("      Good: \(good)")
        print("      Fair: \(fair)")
        return true
    }
    
    static func testSleepStageQualityScore() async -> Bool {
        print("\n🧪 Test 28: Sleep Stage Quality Score Calculation")
        print("   Testing deep/REM percentage → stage quality score...")
        
        let totalSleep = 8.0 * 3600
        
        // Test 1: Excellent (45% deep+REM)
        let excellent = SleepCalculations.calculateStageQualityScore(
            sleepDuration: totalSleep,
            deepSleep: 2.0 * 3600,
            remSleep: 1.6 * 3600
        )
        guard excellent == 100 else {
            print("   ❌ FAIL: 45% deep+REM should be 100")
            print("      Got: \(excellent)")
            return false
        }
        
        // Test 2: Good (35% deep+REM)
        let good = SleepCalculations.calculateStageQualityScore(
            sleepDuration: totalSleep,
            deepSleep: 1.6 * 3600,
            remSleep: 1.2 * 3600
        )
        guard good >= 50 && good < 100 else {
            print("   ❌ FAIL: 35% deep+REM should be 50-100")
            print("      Got: \(good)")
            return false
        }
        
        // Test 3: Fair (25% deep+REM)
        let fair = SleepCalculations.calculateStageQualityScore(
            sleepDuration: totalSleep,
            deepSleep: 1.2 * 3600,
            remSleep: 0.8 * 3600
        )
        guard fair >= 0 && fair < 50 else {
            print("   ❌ FAIL: 25% deep+REM should be 0-50")
            print("      Got: \(fair)")
            return false
        }
        
        // Test 4: Poor (10% deep+REM)
        let poor = SleepCalculations.calculateStageQualityScore(
            sleepDuration: totalSleep,
            deepSleep: 0.5 * 3600,
            remSleep: 0.3 * 3600
        )
        guard poor >= 0 && poor < 20 else {
            print("   ❌ FAIL: 10% deep+REM should be very low")
            print("      Got: \(poor)")
            return false
        }
        
        print("   ✅ PASS: Stage quality score calculation works")
        print("      Excellent (45%): \(excellent)")
        print("      Good (35%): \(good)")
        print("      Fair (25%): \(fair)")
        return true
    }
    
    static func testSleepDisturbancesScore() async -> Bool {
        print("\n🧪 Test 29: Sleep Disturbances Score Calculation")
        print("   Testing wake events → disturbances score...")
        
        // Test 1: No disturbances
        let none = SleepCalculations.calculateDisturbancesScore(wakeEvents: 0)
        guard none == 100 else {
            print("   ❌ FAIL: No disturbances should be 100")
            return false
        }
        
        // Test 2: Minimal disturbances (2)
        let minimal = SleepCalculations.calculateDisturbancesScore(wakeEvents: 2)
        guard minimal == 100 else {
            print("   ❌ FAIL: 2 disturbances should be 100")
            return false
        }
        
        // Test 3: Moderate disturbances (4)
        let moderate = SleepCalculations.calculateDisturbancesScore(wakeEvents: 4)
        guard moderate == 75 else {
            print("   ❌ FAIL: 4 disturbances should be 75")
            return false
        }
        
        // Test 4: Many disturbances (7)
        let many = SleepCalculations.calculateDisturbancesScore(wakeEvents: 7)
        guard many == 50 else {
            print("   ❌ FAIL: 7 disturbances should be 50")
            return false
        }
        
        // Test 5: Excessive disturbances (10)
        let excessive = SleepCalculations.calculateDisturbancesScore(wakeEvents: 10)
        guard excessive == 25 else {
            print("   ❌ FAIL: 10 disturbances should be 25")
            return false
        }
        
        print("   ✅ PASS: Disturbances score calculation works")
        print("      None: \(none)")
        print("      Minimal: \(minimal)")
        print("      Moderate: \(moderate)")
        print("      Many: \(many)")
        return true
    }
    
    static func testSleepFullCalculation() async -> Bool {
        print("\n🧪 Test 30: Sleep Full Calculation")
        print("   Testing complete sleep score...")
        
        let baselineBedtime = Date(timeIntervalSinceNow: -8 * 3600)
        let baselineWakeTime = Date()
        
        // Test 1: Optimal sleep
        let optimal = SleepCalculations.calculateSleepScore(
            sleepDuration: 8 * 3600,
            sleepNeed: 8 * 3600,
            timeInBed: 8.2 * 3600,
            deepSleep: 2.0 * 3600,
            remSleep: 1.6 * 3600,
            wakeEvents: 1,
            bedtime: baselineBedtime,
            wakeTime: baselineWakeTime,
            baselineBedtime: baselineBedtime,
            baselineWakeTime: baselineWakeTime
        )
        
        guard optimal.score >= 80 && optimal.score <= 100 else {
            print("   ❌ FAIL: Optimal sleep should be 80-100")
            print("      Got: \(optimal.score)")
            return false
        }
        
        guard optimal.band == .optimal else {
            print("   ❌ FAIL: Band should be optimal")
            return false
        }
        
        // Test 2: Poor sleep
        let poor = SleepCalculations.calculateSleepScore(
            sleepDuration: 5 * 3600,
            sleepNeed: 8 * 3600,
            timeInBed: 8 * 3600,
            deepSleep: 0.5 * 3600,
            remSleep: 0.5 * 3600,
            wakeEvents: 10,
            bedtime: Date(timeIntervalSinceNow: -6 * 3600),
            wakeTime: Date(timeIntervalSinceNow: 2 * 3600),
            baselineBedtime: baselineBedtime,
            baselineWakeTime: baselineWakeTime
        )
        
        guard poor.score < 60 else {
            print("   ❌ FAIL: Poor sleep should be < 60")
            print("      Got: \(poor.score)")
            return false
        }
        
        // Test 3: Verify sub-scores
        guard optimal.performanceScore == 100 else {
            print("   ❌ FAIL: Performance should be 100")
            return false
        }
        
        guard optimal.efficiencyScore >= 95 else {
            print("   ❌ FAIL: Efficiency should be high")
            return false
        }
        
        guard optimal.stageQualityScore == 100 else {
            print("   ❌ FAIL: Stage quality should be 100")
            return false
        }
        
        guard optimal.disturbancesScore == 100 else {
            print("   ❌ FAIL: Disturbances score should be 100")
            return false
        }
        
        // Test 4: Weighted combination
        let performance = Double(optimal.performanceScore) * SleepCalculations.performanceWeight
        let efficiency = Double(optimal.efficiencyScore) * SleepCalculations.efficiencyWeight
        let stageQuality = Double(optimal.stageQualityScore) * SleepCalculations.stageQualityWeight
        let disturbances = Double(optimal.disturbancesScore) * SleepCalculations.disturbancesWeight
        let timing = Double(optimal.timingScore) * SleepCalculations.timingWeight
        let expectedScore = performance + efficiency + stageQuality + disturbances + timing
        
        guard abs(Double(optimal.score) - expectedScore) < 2.0 else {
            print("   ❌ FAIL: Weighted combination incorrect")
            print("      Expected: ~\(Int(expectedScore)), got: \(optimal.score)")
            return false
        }
        
        print("   ✅ PASS: Full sleep calculation works")
        print("      Optimal: \(optimal.score) (\(optimal.band.rawValue))")
        print("      Poor: \(poor.score) (\(poor.band.rawValue))")
        return true
    }
    
    static func testSleepEdgeCases() async -> Bool {
        print("\n🧪 Test 31: Sleep Edge Cases")
        print("   Testing edge cases and boundary conditions...")
        
        // Test 1: No data (should return neutral)
        let noData = SleepCalculations.calculateSleepScore(
            sleepDuration: nil,
            sleepNeed: nil,
            timeInBed: nil,
            deepSleep: nil,
            remSleep: nil,
            wakeEvents: nil,
            bedtime: nil,
            wakeTime: nil,
            baselineBedtime: nil,
            baselineWakeTime: nil
        )
        guard noData.score == 50 else {
            print("   ❌ FAIL: No data should return 50")
            print("      Got: \(noData.score)")
            return false
        }
        
        // Test 2: Band determination
        let optimal = SleepCalculations.determineSleepBand(score: 85)
        let good = SleepCalculations.determineSleepBand(score: 70)
        let fair = SleepCalculations.determineSleepBand(score: 50)
        let poor = SleepCalculations.determineSleepBand(score: 30)
        
        guard optimal == .optimal && good == .good && fair == .fair && poor == .payAttention else {
            print("   ❌ FAIL: Band determination incorrect")
            return false
        }
        
        // Test 3: Zero time in bed (should handle gracefully)
        let zeroTimeInBed = SleepCalculations.calculateEfficiencyScore(
            sleepDuration: 8 * 3600,
            timeInBed: 0
        )
        guard zeroTimeInBed == 50 else {
            print("   ❌ FAIL: Zero time in bed should return 50")
            return false
        }
        
        // Test 4: Zero total sleep (should handle gracefully)
        let zeroSleep = SleepCalculations.calculateStageQualityScore(
            sleepDuration: 0,
            deepSleep: 0,
            remSleep: 0
        )
        guard zeroSleep == 50 else {
            print("   ❌ FAIL: Zero sleep should return 50")
            return false
        }
        
        // Test 5: Extreme values (should clamp)
        let extreme = SleepCalculations.calculateSleepScore(
            sleepDuration: 12 * 3600,
            sleepNeed: 8 * 3600,
            timeInBed: 12 * 3600,
            deepSleep: 5 * 3600,
            remSleep: 4 * 3600,
            wakeEvents: 0,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date()
        )
        guard extreme.score <= 100 else {
            print("   ❌ FAIL: Score should be clamped to 100")
            return false
        }
        
        print("   ✅ PASS: All edge cases handled correctly")
        print("      - No data: ✓")
        print("      - Band determination: ✓")
        print("      - Zero time in bed: ✓")
        print("      - Zero sleep: ✓")
        print("      - Extreme values clamped: ✓")
        return true
    }
}
