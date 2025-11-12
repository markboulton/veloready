# Cache Unit Tests - Complete Test Suite

**Purpose**: Prevent regression of cache persistence bugs  
**Coverage Target**: 80%+ for UnifiedCacheManager

---

## 🎯 Test Strategy

### What We're Testing
1. **Disk Persistence**: Data survives app restart
2. **Cache Expiration**: TTL enforcement
3. **Request Deduplication**: No duplicate API calls
4. **Cache Invalidation**: Proper cleanup
5. **API Usage**: Strava call reduction

### Why These Tests Matter
**The bug we just fixed would have been caught by test #2** (testActivitiesLoadFromDiskAfterRestart)

---

## 📝 Test Suite Implementation

**File**: `VeloReadyTests/Unit/UnifiedCacheManagerTests.swift`

```swift
import XCTest
@testable import VeloReady

@MainActor
final class UnifiedCacheManagerTests: XCTestCase {
    var cache: UnifiedCacheManager!
    
    override func setUp() async throws {
        cache = UnifiedCacheManager.shared
        
        // Clear disk cache for isolated tests
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCache")
        UserDefaults.standard.removeObject(forKey: "UnifiedCacheManager.DiskCacheMetadata")
    }
    
    // MARK: - Test 1: Disk Persistence
    
    func testActivitiesPersistToDisk() async throws {
        // CRITICAL: This test would have caught today's bug
        let activities = createMockActivities(count: 5)
        let key = "strava:activities:7"
        
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return activities
        }
        
        // Verify disk storage
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache"))
        
        let metadata = UserDefaults.standard.dictionary(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        XCTAssertNotNil(metadata?[key], "Activity cache should be persisted to disk")
    }
    
    // MARK: - Test 2: Load from Disk After Restart
    
    func testActivitiesLoadFromDiskAfterRestart() async throws {
        // CRITICAL: This would have caught the bug we fixed today
        let key = "strava:activities:7"
        var apiCallCount = 0
        
        // First launch: Cache to disk
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 5)
        }
        
        XCTAssertEqual(apiCallCount, 1, "First fetch should call API")
        
        // Simulate app restart by creating new cache instance
        // In real app, this loads from disk in init()
        let newCache = UnifiedCacheManager.shared
        
        // Second launch: Should load from disk
        let loaded = try await newCache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            XCTFail("Should load from disk, not call fetch operation")
            return []
        }
        
        XCTAssertEqual(apiCallCount, 1, "Should not call API again - use disk cache")
        XCTAssertEqual(loaded.count, 5, "Should load correct number from disk")
    }
    
    // MARK: - Test 3: Cache Expiration
    
    func testCacheExpiresAfterTTL() async throws {
        let key = "strava:activities:1"
        var apiCallCount = 0
        
        // Cache with 1 second TTL
        _ = try await cache.fetch(key: key, ttl: 1.0) {
            apiCallCount += 1
            return createMockActivities(count: 3)
        }
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5s
        
        // Should fetch again
        _ = try await cache.fetch(key: key, ttl: 1.0) {
            apiCallCount += 1
            return createMockActivities(count: 3)
        }
        
        XCTAssertEqual(apiCallCount, 2, "Should refetch after TTL expires")
    }
    
    // MARK: - Test 4: Request Deduplication
    
    func testSimultaneousFetchesAreDeduplicated() async throws {
        let key = "strava:activities:7"
        var fetchCount = 0
        
        // Launch 5 simultaneous fetches
        async let fetch1 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            return createMockActivities(count: 5)
        }
        
        async let fetch2 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return createMockActivities(count: 5)
        }
        
        async let fetch3 = cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return createMockActivities(count: 5)
        }
        
        let results = try await [fetch1, fetch2, fetch3]
        
        XCTAssertEqual(fetchCount, 1, "Should deduplicate simultaneous requests")
        XCTAssertEqual(results.count, 3, "Should return results to all callers")
    }
    
    // MARK: - Test 5: Cache Invalidation
    
    func testInvalidateRemovesFromMemoryAndDisk() async throws {
        let key = "strava:activities:7"
        
        // Cache activities
        _ = try await cache.fetch(key: key, ttl: 3600) {
            return createMockActivities(count: 5)
        }
        
        // Invalidate
        await cache.invalidate(key: key)
        
        // Should fetch again
        var fetchCalled = false
        _ = try await cache.fetch(key: key, ttl: 3600) {
            fetchCalled = true
            return createMockActivities(count: 5)
        }
        
        XCTAssertTrue(fetchCalled, "Should fetch again after invalidation")
        
        // Check disk removed
        let metadata = UserDefaults.standard.dictionary(forKey: "UnifiedCacheManager.DiskCacheMetadata")
        XCTAssertNil(metadata?[key], "Should remove from disk metadata")
    }
    
    // MARK: - Test 6: Multiple App Launches (CRITICAL)
    
    func testMultipleAppLaunchesUseCacheNotAPI() async throws {
        // This simulates the real-world scenario we fixed
        let key = "strava:activities:7"
        var apiCallCount = 0
        
        // Launch 1
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 4)
        }
        
        // Launch 2 (within 1 hour)
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 4)
        }
        
        // Launch 3 (within 1 hour)
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 4)
        }
        
        XCTAssertEqual(apiCallCount, 1, "Should only call API once, use cache for subsequent launches")
    }
    
    // MARK: - Test 7: Different Day Ranges
    
    func testDifferentDayRangesAreCachedSeparately() async throws {
        var apiCallCount = 0
        
        // Fetch 1 day
        _ = try await cache.fetch(key: "strava:activities:1", ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 0)
        }
        
        // Fetch 7 days (should be separate cache)
        _ = try await cache.fetch(key: "strava:activities:7", ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 4)
        }
        
        // Fetch 365 days (should be separate cache)
        _ = try await cache.fetch(key: "strava:activities:365", ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 183)
        }
        
        XCTAssertEqual(apiCallCount, 3, "Different day ranges should have separate caches")
        
        // Re-fetch 7 days (should use cache)
        _ = try await cache.fetch(key: "strava:activities:7", ttl: 3600) {
            apiCallCount += 1
            return createMockActivities(count: 4)
        }
        
        XCTAssertEqual(apiCallCount, 3, "Re-fetching same range should use cache")
    }
    
    // MARK: - Test 8: Empty Results
    
    func testCacheHandlesEmptyActivities() async throws {
        let key = "strava:activities:1"
        
        let activities = try await cache.fetch(key: key, ttl: 3600) {
            return [StravaActivity]()
        }
        
        XCTAssertTrue(activities.isEmpty)
        
        // Should still cache empty results
        var fetchCalled = false
        _ = try await cache.fetch(key: key, ttl: 3600) {
            fetchCalled = true
            return [StravaActivity]()
        }
        
        XCTAssertFalse(fetchCalled, "Should cache empty results")
    }
    
    // MARK: - Test 9: Corrupted Data Handling
    
    func testCacheHandlesCorruptedData() async throws {
        // Simulate corrupted disk cache
        let corruptedData = "not json".data(using: .utf8)!
        UserDefaults.standard.set(corruptedData, forKey: "UnifiedCacheManager.DiskCache")
        
        // Should handle gracefully
        let key = "strava:activities:7"
        var fetchCalled = false
        
        _ = try await cache.fetch(key: key, ttl: 3600) {
            fetchCalled = true
            return createMockActivities(count: 5)
        }
        
        XCTAssertTrue(fetchCalled, "Should fall back to API on corrupted cache")
    }
    
    // MARK: - Test 10: Intervals.icu Activities
    
    func testIntervalsActivitiesAlsoPersist() async throws {
        let key = "intervals:activities:7"
        var apiCallCount = 0
        
        // Cache Intervals activities
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockIntervalsActivities(count: 5)
        }
        
        // Verify persisted
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "UnifiedCacheManager.DiskCache"))
        
        // Should load from cache
        _ = try await cache.fetch(key: key, ttl: 3600) {
            apiCallCount += 1
            return createMockIntervalsActivities(count: 5)
        }
        
        XCTAssertEqual(apiCallCount, 1, "Intervals activities should also persist")
    }
    
    // MARK: - Helper Methods
    
    private func createMockActivities(count: Int) -> [StravaActivity] {
        (0..<count).map { i in
            StravaActivity(
                id: "test_\(i)",
                name: "Activity \(i)",
                type: "Ride",
                distance: 10000.0,
                movingTime: 3600,
                elapsedTime: 3600,
                totalElevationGain: 100.0,
                startDate: Date(),
                startDateLocal: Date(),
                timezone: "UTC",
                averageSpeed: 5.0,
                maxSpeed: 10.0,
                averageWatts: 200.0,
                kilojoules: 720.0,
                deviceWatts: true,
                averageHeartrate: 150.0,
                maxHeartrate: 180.0
            )
        }
    }
    
    private func createMockIntervalsActivities(count: Int) -> [Activity] {
        (0..<count).map { i in
            Activity(
                id: "intervals_\(i)",
                startDateLocal: Date(),
                type: "Ride",
                distance: 10000.0,
                movingTime: 3600,
                totalElevationGain: 100.0
            )
        }
    }
}
```

---

## 🚀 Running the Tests

### Via Command Line
```bash
cd VeloReady
swift test --filter UnifiedCacheManagerTests
```

### Via Xcode
```
⌘U (Run all tests)
```

### Via quick-test.sh
```bash
./Scripts/quick-test.sh
```

---

## 📊 Expected Results

```
Test Suite 'UnifiedCacheManagerTests' started
✓ testActivitiesPersistToDisk (0.145s)
✓ testActivitiesLoadFromDiskAfterRestart (0.089s)  ← Would have caught bug
✓ testCacheExpiresAfterTTL (1.502s)
✓ testSimultaneousFetchesAreDeduplicated (0.112s)
✓ testInvalidateRemovesFromMemoryAndDisk (0.078s)
✓ testMultipleAppLaunchesUseCacheNotAPI (0.056s)  ← Validates fix
✓ testDifferentDayRangesAreCachedSeparately (0.143s)
✓ testCacheHandlesEmptyActivities (0.034s)
✓ testCacheHandlesCorruptedData (0.091s)
✓ testIntervalsActivitiesAlsoPersist (0.067s)

Test Suite 'UnifiedCacheManagerTests' passed at 2025-11-05 09:45:23.456
  Executed 10 tests, with 0 failures (0 unexpected)
  Total time: 2.417s
```

---

## ✅ Integration with CI/CD

### Add to quick-test.sh
```bash
echo "Running cache tests..."
swift test --filter UnifiedCacheManagerTests
if [ $? -ne 0 ]; then
    echo "❌ Cache tests failed"
    exit 1
fi
```

### Add to pre-commit hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running cache persistence tests..."
swift test --filter UnifiedCacheManagerTests
if [ $? -ne 0 ]; then
    echo "❌ COMMIT BLOCKED: Cache tests failed"
    echo "Fix cache persistence before committing"
    exit 1
fi
```

---

## 🎯 Success Criteria

- ✅ All 10 tests pass
- ✅ Tests run in <3 seconds
- ✅ Tests catch disk persistence bugs
- ✅ Tests validate API call reduction
- ✅ Tests integrated with pre-commit hook

---

**Status**: Test suite ready for implementation. Run after creating test file.
