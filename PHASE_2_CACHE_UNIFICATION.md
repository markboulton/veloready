# Phase 2: Cache Unification - In Progress

**Date:** October 18, 2025  
**Status:** Foundation Complete, Migration In Progress  
**Goal:** Consolidate 5 cache layers → 1, add request deduplication, reduce memory by 77%

---

## 🎯 The Problem

### **Current State: 5 Overlapping Cache Layers**

```
1. StreamCacheService (iOS)
   - Location: UserDefaults + File system
   - TTL: 7 days
   - Size: 3.5MB limit (UserDefaults), unlimited (files)
   - Purpose: Activity streams caching

2. StravaDataService (iOS)  
   - Location: Memory (@Published)
   - TTL: 5 minutes
   - Size: 50 activities (~500KB)
   - Purpose: Recent Strava activities

3. IntervalsCache (iOS)
   - Location: Memory
   - TTL: 10 minutes  
   - Size: Wellness data (~100KB)
   - Purpose: Intervals.icu caching

4. HealthKitCache (iOS)
   - Location: Memory
   - TTL: 5-10 minutes
   - Size: Single values (~1KB)
   - Purpose: HRV/RHR/Sleep caching

5. Core Data (iOS)
   - Location: SQLite
   - TTL: Variable (1h-24h)
   - Size: 90 days (~50MB)
   - Purpose: Persistent storage
```

### **Problems:**

```swift
// ❌ Problem 1: Cache Stampede
Task { await recoveryService.calculateRecoveryScore() }  // Fetches HRV
Task { await sleepService.calculateSleepScore() }        // Fetches HRV AGAIN!
Task { await strainService.calculateStrainScore() }      // Fetches activities

// ❌ Problem 2: No Deduplication
// 3 concurrent calls = 3 identical network requests

// ❌ Problem 3: Unclear Invalidation
CacheManager.shared.refreshToday()           // Who clears what?
StravaDataService.shared.clearCache()        // Inconsistent
StreamCacheService.shared.clearAllCaches()   // No coordination

// ❌ Problem 4: Memory Bloat
// TodayViewModel alone: ~13MB
// × 5 tabs = 65MB memory usage!
```

---

## ✅ The Solution: UnifiedCacheManager

### **Single Source of Truth**

```swift
@MainActor
class UnifiedCacheManager {
    static let shared = UnifiedCacheManager()
    
    /// Smart fetch with automatic caching and deduplication
    func fetch<T>(
        key: String,
        ttl: TimeInterval,
        fetchOperation: @escaping () async throws -> T
    ) async throws -> T {
        // 1. Check memory cache → HIT (instant)
        // 2. Check if request in-flight → DEDUPE (reuse)
        // 3. Execute fetch → MISS (network)
        // 4. Cache result → Store
    }
}
```

### **Key Features:**

#### **1. Automatic Request Deduplication**
```swift
// ✅ Multiple concurrent calls = 1 network request
Task { let hrv = try await cache.fetch(key: "hrv", ttl: 300) { ... } }
Task { let hrv = try await cache.fetch(key: "hrv", ttl: 300) { ... } }
Task { let hrv = try await cache.fetch(key: "hrv", ttl: 300) { ... } }

// Result: Only 1 fetch operation executes
// Other 2 tasks wait and reuse the same result
```

#### **2. Memory-Efficient Storage**
```swift
// NSCache automatically evicts under memory pressure
private var memoryCache = NSCache<NSString, CachedValue>()
memoryCache.countLimit = 200           // Max 200 entries
memoryCache.totalCostLimit = 50_000_000 // 50MB max

// Before: Unbounded memory (65MB+)
// After: Capped at 50MB with auto-eviction
```

#### **3. Standardized Cache Keys**
```swift
enum CacheKey {
    static func stravaActivities(daysBack: Int) -> String {
        "strava:activities:\(daysBack)"
    }
    
    static func hrv(date: Date) -> String {
        "healthkit:hrv:\(dateString)"
    }
    
    // Consistent, predictable, no collisions
}
```

#### **4. Built-in Statistics**
```swift
let stats = UnifiedCacheManager.shared.getStatistics()

print(stats.description)
// Cache Statistics:
// - Hits: 842
// - Misses: 158  
// - Deduplicated: 94
// - Hit Rate: 84.2%
// - Total Requests: 1000
```

---

## 🔄 Migration Pattern

### **Before (Old Way):**

```swift
class MyService {
    @Published var data: [Item] = []
    private var lastFetchDate: Date?
    private let cacheExpiryMinutes = 5
    
    func fetchData() async {
        // Manual cache check
        if let lastFetch = lastFetchDate {
            let age = Date().timeIntervalSince(lastFetch)
            if age < TimeInterval(cacheExpiryMinutes * 60) {
                return // Use cached data
            }
        }
        
        // Fetch from network
        data = try await networkCall()
        lastFetchDate = Date()
    }
}
```

### **After (Unified Cache):**

```swift
class MyService {
    private let cache = UnifiedCacheManager.shared
    
    func fetchData() async throws -> [Item] {
        return try await cache.fetch(
            key: CacheKey.myData,
            ttl: UnifiedCacheManager.CacheTTL.activities
        ) {
            try await networkCall()
        }
    }
}
```

**Benefits:**
- ✅ 10 lines → 4 lines
- ✅ No manual cache checking
- ✅ Automatic deduplication
- ✅ Memory management handled
- ✅ Statistics tracked automatically

---

## 📊 Example: UnifiedActivityService Migration

### **Before:**
```swift
func fetchRecentActivities() async throws -> [IntervalsActivity] {
    // No caching
    // No deduplication
    // Direct API call every time
    let activities = try await intervalsAPI.fetchRecentActivities()
    return activities
}
```

### **After:**
```swift
func fetchRecentActivities() async throws -> [IntervalsActivity] {
    let cacheKey = CacheKey.intervalsActivities(daysBack: actualDays)
    
    return try await cache.fetch(
        key: cacheKey,
        ttl: UnifiedCacheManager.CacheTTL.activities
    ) {
        let activities = try await self.intervalsAPI.fetchRecentActivities()
        return activities
    }
}
```

### **Impact:**
```
Scenario: 3 screens load simultaneously, all need activities

Before:
- Screen 1 → API call → 500ms
- Screen 2 → API call → 500ms  
- Screen 3 → API call → 500ms
Total: 3 API calls, 1500ms

After (first load):
- Screen 1 → API call → 500ms
- Screen 2 → DEDUPE (waits for Screen 1) → 500ms
- Screen 3 → DEDUPE (waits for Screen 1) → 500ms
Total: 1 API call, 500ms

After (subsequent loads):
- Screen 1 → Cache HIT → 0ms
- Screen 2 → Cache HIT → 0ms
- Screen 3 → Cache HIT → 0ms
Total: 0 API calls, instant
```

---

## 🎯 Services to Migrate

### **✅ Completed:**
1. UnifiedActivityService - Activities fetching with deduplication

### **⏳ In Progress:**
2. RecoveryScoreService - HRV/RHR/Sleep fetching
3. SleepScoreService - Sleep data caching
4. StrainScoreService - Activity-based strain
5. HealthKitManager - Direct HealthKit calls
6. RideDetailViewModel - Stream fetching

### **📋 To Do:**
7. StreamCacheService - Deprecate (functionality in UnifiedCache)
8. StravaDataService - Deprecate (redundant with backend caching)
9. IntervalsCache - Deprecate (redundant with UnifiedCache)
10. HealthKitCache - Deprecate (integrate with UnifiedCache)

---

## 💾 Cache TTL Strategy

```swift
enum CacheTTL {
    static let activities: TimeInterval = 300       // 5 minutes
    static let healthMetrics: TimeInterval = 300    // 5 minutes  
    static let streams: TimeInterval = 604800       // 7 days
    static let dailyScores: TimeInterval = 3600     // 1 hour
    static let wellness: TimeInterval = 600         // 10 minutes
}
```

**Rationale:**
- **Activities (5 min):** Balance freshness with API limits
- **Health metrics (5 min):** HealthKit data doesn't change frequently
- **Streams (7 days):** Large data, rarely changes
- **Daily scores (1 hour):** Recompute periodically
- **Wellness (10 min):** Moderate freshness needs

---

## 📈 Expected Impact

### **Memory Usage:**

| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| **StreamCacheService** | 20MB | 0MB (deprecated) | 100% |
| **StravaDataService** | 500KB | 0MB (deprecated) | 100% |
| **IntervalsCache** | 100KB | 0MB (deprecated) | 100% |
| **HealthKitCache** | 1KB | 0MB (deprecated) | 100% |
| **UnifiedCacheManager** | 0MB | 15MB (managed) | N/A |
| **TodayViewModel** | 13MB | 3MB | 77% |
| **Total (5 tabs)** | 65MB | 15MB | **77%** |

---

### **Request Deduplication:**

```
Scenario: Recovery score calculation
- Needs: HRV, RHR, Sleep, Activities

Before:
1. RecoveryService → Fetch HRV
2. SleepService → Fetch HRV (duplicate!)
3. RecoveryService → Fetch RHR
4. SleepService → Fetch RHR (duplicate!)
5. RecoveryService → Fetch Activities
6. StrainService → Fetch Activities (duplicate!)
Total: 6 fetches (3 duplicates)

After (with deduplication):
1. RecoveryService → Fetch HRV → CacheManager
2. SleepService → Request HRV → DEDUPE (waits for #1)
3. RecoveryService → Fetch RHR → CacheManager
4. SleepService → Request RHR → DEDUPE (waits for #3)
5. RecoveryService → Fetch Activities → CacheManager
6. StrainService → Request Activities → DEDUPE (waits for #5)
Total: 3 fetches (3 deduplicated)

Reduction: 50% fewer network calls
```

---

### **Cache Hit Rates:**

| Data Type | Expected Hit Rate | Reasoning |
|-----------|------------------|-----------|
| **Activities** | 85-90% | Fetched once per app session |
| **Health Metrics** | 95%+ | Rarely changes during day |
| **Streams** | 96%+ | Cached for 7 days |
| **Daily Scores** | 90%+ | Recalculated hourly max |
| **Wellness** | 90%+ | Updated infrequently |

---

## 🔍 Monitoring & Debugging

### **View Cache Statistics:**

```swift
// In Debug menu or console
let stats = UnifiedCacheManager.shared.getStatistics()
print(stats.description)

// Output:
// Cache Statistics:
// - Hits: 842 (84.2%)
// - Misses: 158 (15.8%)
// - Deduplicated: 94 (9.4%)
// - Total Requests: 1000
```

### **Logging:**

```
⚡ [Cache HIT] intervals:activities:30 (age: 245s)
🌐 [Cache MISS] healthkit:hrv:2025-10-18 - fetching...
💾 [Cache STORE] strava:activities:7 (cost: 50KB)
🔄 [Cache DEDUPE] intervals:wellness:30 - reusing existing request
```

---

## 🧪 Testing Strategy

### **Unit Tests:**

```swift
func testCacheHit() async throws {
    let cache = UnifiedCacheManager.shared
    
    // First call - should fetch
    let result1 = try await cache.fetch(key: "test", ttl: 60) {
        return "data"
    }
    
    // Second call - should hit cache
    let result2 = try await cache.fetch(key: "test", ttl: 60) {
        XCTFail("Should not fetch again")
        return "data"
    }
    
    XCTAssertEqual(result1, result2)
    XCTAssertEqual(cache.cacheHits, 1)
    XCTAssertEqual(cache.cacheMisses, 1)
}

func testDeduplication() async throws {
    let cache = UnifiedCacheManager.shared
    var fetchCount = 0
    
    // 3 concurrent calls
    async let call1 = cache.fetch(key: "test", ttl: 60) { fetchCount += 1; return "data" }
    async let call2 = cache.fetch(key: "test", ttl: 60) { fetchCount += 1; return "data" }
    async let call3 = cache.fetch(key: "test", ttl: 60) { fetchCount += 1; return "data" }
    
    let _ = try await (call1, call2, call3)
    
    // Should only fetch once
    XCTAssertEqual(fetchCount, 1)
    XCTAssertEqual(cache.deduplicatedRequests, 2)
}
```

---

## 📋 Migration Checklist

### **For Each Service:**

- [ ] Identify all data fetching methods
- [ ] Determine appropriate cache TTL
- [ ] Create standardized cache keys
- [ ] Wrap fetch operations with `cache.fetch()`
- [ ] Remove old caching logic
- [ ] Test cache hits/misses
- [ ] Verify request deduplication
- [ ] Check memory usage

### **Example Migration (Step-by-Step):**

**1. Before:**
```swift
class MyService {
    @Published var data: [Item] = []
    
    func loadData() async {
        data = try await api.fetchData()
    }
}
```

**2. Add cache:**
```swift
class MyService {
    @Published var data: [Item] = []
    private let cache = UnifiedCacheManager.shared
    
    func loadData() async throws {
        data = try await cache.fetch(
            key: "my-data",
            ttl: 300
        ) {
            try await api.fetchData()
        }
    }
}
```

**3. Standardize key:**
```swift
// In CacheKey enum
static func myData() -> String {
    "service:data"
}

// In service
key: CacheKey.myData()
```

**4. Test:**
- Call `loadData()` twice
- Second call should be instant
- Check logs for "Cache HIT"

---

## 🎯 Success Metrics

### **Phase 2 Goals:**

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Memory Reduction** | 77% | Xcode Instruments (Memory Profiler) |
| **Request Deduplication** | >50% | UnifiedCacheManager statistics |
| **Cache Hit Rate** | >85% | UnifiedCacheManager statistics |
| **Code Reduction** | 30% | Lines of cache-related code |

### **Before/After Comparison:**

| Metric | Before | After | Status |
|--------|--------|-------|--------|
| Cache Layers | 5 | 1 | ⏳ In progress |
| Memory Usage | 65MB | TBD | ⏳ To measure |
| Duplicate Requests | ~50% | TBD | ⏳ To measure |
| Cache Hit Rate | ~20% | TBD | ⏳ To measure |

---

## 🚀 Next Steps

### **This Week:**

1. **Migrate RecoveryScoreService** (Day 1)
   - HRV/RHR/Sleep fetching
   - Baseline calculation caching

2. **Migrate SleepScoreService** (Day 1)
   - Sleep data caching
   - Score calculation caching

3. **Migrate StrainScoreService** (Day 2)
   - Activity-based strain
   - TSS calculation caching

4. **Migrate HealthKitManager** (Day 2)
   - Direct HealthKit calls
   - Sample aggregation caching

5. **Test & Measure** (Day 3)
   - Memory profiling
   - Cache statistics analysis
   - Performance benchmarking

---

## 📚 Documentation

### **For Developers:**

**Adding New Cached Data:**

```swift
// 1. Add cache key to CacheKey enum
extension CacheKey {
    static func myNewData(param: String) -> String {
        "my-service:data:\(param)"
    }
}

// 2. Use in service
func fetchMyData() async throws -> MyData {
    return try await cache.fetch(
        key: CacheKey.myNewData(param: "value"),
        ttl: UnifiedCacheManager.CacheTTL.activities
    ) {
        try await api.fetchData()
    }
}
```

**Custom TTL:**

```swift
// In UnifiedCacheManager.CacheTTL
extension UnifiedCacheManager.CacheTTL {
    static let myCustomData: TimeInterval = 1800  // 30 minutes
}

// Use it
ttl: UnifiedCacheManager.CacheTTL.myCustomData
```

---

## ✅ Summary

### **What's Done:**
- ✅ UnifiedCacheManager created
- ✅ Request deduplication implemented
- ✅ Memory management (NSCache)
- ✅ Standardized cache keys
- ✅ Statistics tracking
- ✅ Example migration (UnifiedActivityService)

### **What's Next:**
- ⏳ Migrate 5 remaining services
- ⏳ Deprecate old cache layers
- ⏳ Test & measure impact
- ⏳ Document final results

### **Expected Impact:**
- 77% memory reduction (65MB → 15MB)
- 50% fewer duplicate requests
- 85%+ cache hit rate
- Simpler, more maintainable code

---

**Phase 2 foundation complete. Service migration in progress.** 🚀
