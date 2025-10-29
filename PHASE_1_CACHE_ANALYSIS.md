# Phase 1: Cache Architecture Analysis & Extraction

## Current State Analysis

### ✅ What's Working Well

1. **Unified Cache Manager** (`UnifiedCacheManager.swift`)
   - ✅ Single source of truth for all caching
   - ✅ Smart features:
     - Request deduplication (prevents duplicate API calls)
     - Memory-efficient NSCache (auto-evicts under pressure)
     - Offline fallback (returns expired data when network fails)
     - TTL-based expiry
   - ✅ Statistics tracking (hits, misses, deduplication)

2. **Standardized Cache Keys** (in `CacheKey` enum)
   - ✅ Consistent format: `source:type:identifier`
   - ✅ Examples:
     - `strava:activities:365`
     - `intervals:activities:90`
     - `healthkit:hrv:2025-10-29`
   - ✅ Date-based keys use ISO8601 for consistency

3. **Proper Integration**
   - ✅ `StravaDataService` uses unified cache (line 32)
   - ✅ `UnifiedActivityService` uses unified cache (line 40, 55)
   - ✅ Both use `CacheKey.stravaActivities(daysBack:)` consistently

### 🐛 Issues Identified

#### Issue 1: Type Safety in Task Casting
**Location**: Lines 68, 104 in `UnifiedCacheManager.swift`

```swift
// Line 68 - Unsafe cast (always fails)
let existingTask = inflightRequests[key] as? Task<T, Error>

// Line 104 - Unsafe cast (always fails)  
inflightRequests[key] = task as? Task<Any, Error>
```

**Problem**: 
- `Task<T, Error>` cannot be cast to `Task<Any, Error>` (or vice versa)
- This means request deduplication **never works**
- Multiple identical requests will all hit the network

**Impact**: 
- 🔴 **HIGH** - Defeats purpose of deduplication
- Wastes bandwidth and API quota
- Slower performance

**Fix**: Use type erasure or protocol-based approach

---

#### Issue 2: NSLock Usage in Async Context
**Location**: Lines 67-69, 103-105, 109-111 in `UnifiedCacheManager.swift`

```swift
inflightLock.lock()
// ... synchronous operations ...
inflightLock.unlock()
```

**Problem**:
- `NSLock` is not actor-safe or async-safe
- Can cause deadlocks in async/await contexts
- Compiler warnings about this

**Impact**:
- 🟡 **MEDIUM** - Potential rare deadlocks
- May cause hangs in production

**Fix**: Use Swift's `actor` for thread-safe state management

---

#### Issue 3: NSCache Conditional Downcast
**Location**: Lines 58, 78, 134, 154 in `UnifiedCacheManager.swift`

```swift
if let cached = memoryCache.object(forKey: key as NSString) as? CachedValue,
```

**Problem**:
- Compiler warning: "conditional downcast from 'CachedValue?' to 'CachedValue' does nothing"
- `NSCache.object(forKey:)` already returns `CachedValue?`
- The `as?` is redundant

**Impact**:
- 🟢 **LOW** - Works but generates warnings
- Code clutter

**Fix**: Remove redundant cast

---

#### Issue 4: Limited Pattern Matching for Invalidation
**Location**: Lines 180-188 in `UnifiedCacheManager.swift`

```swift
nonisolated func invalidate(matching pattern: String) {
    if pattern == "*" {
        memoryCache.removeAllObjects()
    }
}
```

**Problem**:
- Only supports `*` (clear all)
- Can't invalidate by pattern like `strava:*` or `*:activities:*`
- NSCache doesn't support enumeration

**Impact**:
- 🟡 **MEDIUM** - Limited cache management
- Can't selectively clear Strava cache without clearing everything

**Fix**: Track cache keys separately for pattern matching

---

#### Issue 5: Legacy Cache Cleanup is One-Time
**Location**: Lines 191-203 in `UnifiedCacheManager.swift`

```swift
nonisolated func clearLegacyCacheKeys() {
    let legacyKeys = [
        "strava_activities_90d",
        "strava_activities_365d"
    ]
    // ...
}
```

**Problem**:
- Called once on app init
- If user upgrades app while offline, legacy keys might persist
- No persistent tracking of what's been cleaned

**Impact**:
- 🟢 **LOW** - Edge case, but could cause confusion
- User might see stale data from old cache

**Fix**: Store migration version in UserDefaults

---

## Proposed Architecture for VeloReadyCore

### Design Goals

1. **Pure Swift** - No UIKit/SwiftUI dependencies
2. **Actor-based** - Thread-safe by design
3. **Type-safe** - Proper generics, no unsafe casts
4. **Testable** - Easy to write unit tests
5. **Minimal** - Core logic only, no platform dependencies

### Extracted Components

```
VeloReadyCore/
├── Sources/
│   ├── CacheManager.swift          # Core cache logic
│   ├── CacheKey.swift              # Key generation
│   ├── CacheTypes.swift            # Supporting types
│   └── CacheStatistics.swift       # Statistics tracking
└── Tests/
    ├── CacheManagerTests.swift     # Core cache tests
    ├── CacheKeyTests.swift         # Key consistency tests
    └── CacheOfflineTests.swift     # Offline fallback tests
```

### New CacheManager (Actor-based)

```swift
public actor CacheManager {
    // Thread-safe by design (actor)
    private var memoryCache: [String: CachedValue] = [:]
    private var inflightRequests: [String: Task<Any, Error>] = [:]
    
    // Statistics
    private var stats = CacheStatistics()
    
    public init() {}
    
    // Generic fetch with type safety
    public func fetch<T: Sendable>(
        key: String,
        ttl: TimeInterval,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        // Check cache
        if let cached = memoryCache[key],
           cached.isValid(ttl: ttl),
           let value = cached.value as? T {
            stats.recordHit()
            return value
        }
        
        // Check inflight (type-safe with AnyTask wrapper)
        if let existingTask = inflightRequests[key] {
            stats.recordDeduplication()
            return try await existingTask.valueAs(T.self)
        }
        
        // Offline fallback (expired cache)
        if let cached = memoryCache[key],
           let value = cached.value as? T {
            return value
        }
        
        // Create new task
        let task = Task {
            let value = try await operation()
            await self.storeInCache(key: key, value: value)
            return value
        }
        
        // Store for deduplication
        inflightRequests[key] = task
        
        defer {
            Task { await self.removeInflight(key: key) }
        }
        
        return try await task.value
    }
    
    // Pattern-based invalidation
    public func invalidate(matching pattern: String) {
        let regex = try? NSRegularExpression(pattern: pattern)
        memoryCache = memoryCache.filter { key, _ in
            guard let regex = regex else { return true }
            let range = NSRange(key.startIndex..., in: key)
            return regex.firstMatch(in: key, range: range) == nil
        }
    }
}
```

### Cache Key Generator (Pure Functions)

```swift
public enum CacheKey {
    public static func stravaActivities(daysBack: Int) -> String {
        "strava:activities:\(daysBack)"
    }
    
    public static func intervalsActivities(daysBack: Int) -> String {
        "intervals:activities:\(daysBack)"
    }
    
    // Validation
    public static func validate(_ key: String) -> Bool {
        let pattern = "^[a-z]+:[a-z]+:[a-zA-Z0-9-:]+$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}
```

## Testing Strategy

### Test 1: Cache Key Consistency
**Catches**: Your Strava cache bug

```swift
func testCacheKeyConsistency() async throws {
    // Test that all services generate the same key
    let key1 = CacheKey.stravaActivities(daysBack: 365)
    let key2 = CacheKey.stravaActivities(daysBack: 365)
    
    #expect(key1 == key2)
    #expect(key1 == "strava:activities:365")
}

func testCacheKeyFormat() async throws {
    let keys = [
        CacheKey.stravaActivities(daysBack: 90),
        CacheKey.intervalsActivities(daysBack: 120),
        CacheKey.hrv(date: Date()),
        CacheKey.recoveryScore(date: Date())
    ]
    
    for key in keys {
        #expect(CacheKey.validate(key))
        print("✅ Valid key: \(key)")
    }
}
```

### Test 2: Offline Fallback
**Catches**: Network failures without offline support

```swift
func testOfflineFallback() async throws {
    let cache = CacheManager()
    
    // Store data
    let data = ["test": "value"]
    let key = "test:data:1"
    let result1 = try await cache.fetch(key: key, ttl: 1) {
        return data
    }
    
    #expect(result1 == data)
    
    // Wait for expiry
    try await Task.sleep(for: .seconds(2))
    
    // Simulate network failure
    do {
        let result2 = try await cache.fetch(key: key, ttl: 1) {
            throw NetworkError.offline
        }
        
        // Should return expired cache
        #expect(result2 == data)
        print("✅ Offline fallback worked")
    } catch {
        #expect(false, "Should have returned expired cache, not thrown")
    }
}
```

### Test 3: Request Deduplication
**Catches**: Multiple simultaneous requests for same data

```swift
func testRequestDeduplication() async throws {
    let cache = CacheManager()
    let key = "test:dedup:1"
    var callCount = 0
    
    // Launch 10 concurrent requests for same data
    let tasks = (0..<10).map { _ in
        Task {
            try await cache.fetch(key: key, ttl: 60) {
                callCount += 1
                try await Task.sleep(for: .milliseconds(100))
                return "data"
            }
        }
    }
    
    // Wait for all
    _ = try await tasks.map { try await $0.value }
    
    // Should only call operation once
    #expect(callCount == 1)
    
    let stats = await cache.getStatistics()
    #expect(stats.deduplicatedRequests == 9)
    print("✅ Deduplication prevented 9 unnecessary requests")
}
```

### Test 4: TTL Expiry
**Catches**: Stale data being served

```swift
func testTTLExpiry() async throws {
    let cache = CacheManager()
    let key = "test:ttl:1"
    
    // Store with 1 second TTL
    let result1 = try await cache.fetch(key: key, ttl: 1) {
        return "fresh"
    }
    #expect(result1 == "fresh")
    
    // Immediately fetch again (should hit cache)
    var fetchCount = 1
    let result2 = try await cache.fetch(key: key, ttl: 1) {
        fetchCount += 1
        return "fresh"
    }
    #expect(result2 == "fresh")
    #expect(fetchCount == 1, "Should hit cache")
    
    // Wait for TTL expiry
    try await Task.sleep(for: .seconds(2))
    
    // Fetch again (should miss cache)
    let result3 = try await cache.fetch(key: key, ttl: 1) {
        fetchCount += 1
        return "new"
    }
    #expect(result3 == "new")
    #expect(fetchCount == 2, "Should miss cache after TTL")
}
```

### Test 5: Pattern Invalidation
**Catches**: Inability to clear specific data sources

```swift
func testPatternInvalidation() async throws {
    let cache = CacheManager()
    
    // Store various data
    _ = try await cache.fetch(key: "strava:activities:90", ttl: 60) { "strava1" }
    _ = try await cache.fetch(key: "strava:activities:365", ttl: 60) { "strava2" }
    _ = try await cache.fetch(key: "intervals:activities:120", ttl: 60) { "intervals" }
    _ = try await cache.fetch(key: "healthkit:hrv:today", ttl: 60) { "hrv" }
    
    // Clear only Strava cache
    await cache.invalidate(matching: "^strava:.*")
    
    // Verify Strava is cleared but others remain
    var fetchCount = 0
    
    _ = try await cache.fetch(key: "strava:activities:90", ttl: 60) {
        fetchCount += 1
        return "strava1-new"
    }
    #expect(fetchCount == 1, "Strava should be cleared")
    
    _ = try await cache.fetch(key: "intervals:activities:120", ttl: 60) {
        fetchCount += 1
        return "intervals-new"
    }
    #expect(fetchCount == 1, "Intervals should still be cached")
}
```

## Migration Steps

### Step 1: Extract Core Logic (1 hour)
1. Create `VeloReadyCore/Sources/CacheManager.swift`
2. Implement actor-based cache with fixes
3. Extract `CacheKey` to separate file
4. Remove UIKit/SwiftUI dependencies

### Step 2: Write Tests (1 hour)
1. Implement all 5 test cases above
2. Run tests locally: `cd VeloReadyCore && swift run VeloReadyCoreTests`
3. Verify all pass

### Step 3: Update Main App (30 minutes)
1. Import `VeloReadyCore` in main app
2. Update `UnifiedCacheManager` to use new `CacheManager` under the hood
3. Keep existing API for backward compatibility
4. Run `quick-test.sh` to verify no regressions

### Step 4: Deploy & Monitor (ongoing)
1. Push changes, verify CI passes
2. Monitor cache hit rates in production
3. Watch for any edge cases

## Expected Outcomes

### Immediate Benefits
- ✅ **Bug Prevention**: Cache key consistency tests prevent your bug
- ✅ **Deduplication Works**: Fixes broken request deduplication
- ✅ **Thread-Safe**: Actor-based design prevents race conditions
- ✅ **Fast CI**: Tests run in <1 minute on macOS

### Long-Term Benefits
- ✅ **Confidence**: Every cache change is tested
- ✅ **Maintainability**: Pure Swift logic is easy to understand
- ✅ **Extensibility**: Easy to add new cache features
- ✅ **Documentation**: Tests serve as living documentation

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Breaking existing cache behavior | Low | Keep `UnifiedCacheManager` wrapper |
| Performance regression | Low | Benchmark before/after |
| Edge cases in production | Medium | Gradual rollout, monitoring |

## Next Steps

Ready to proceed with extraction? Here's the plan:

1. **Now**: Review this analysis
2. **Next 30 min**: Extract `CacheManager` to VeloReadyCore
3. **Next 1 hour**: Write and verify tests
4. **Next 30 min**: Integrate with main app
5. **Then**: Push and verify CI passes

Total time: ~2-3 hours for complete Phase 1.

