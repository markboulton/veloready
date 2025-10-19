# 🗄️ Comprehensive Cache Strategy Proposal

## 📊 Current State Analysis

### Existing Cache Systems

| Cache Type | Location | TTL | Status |
|------------|----------|-----|--------|
| **Core Data** | `CacheManager` | 1h-24h | ✅ Working |
| **Strava Activities** | `StravaDataService` | 5 min | ✅ Working |
| **Strava Athlete** | `StravaAthleteCache` | 1 hour | ✅ Working |
| **Intervals Activities** | `IntervalsCache` | Various | ✅ Working |
| **HealthKit Workouts** | `HealthKitCache` | 1 hour | ✅ Working |
| **AI Briefs** | `AIBriefClient` | 24 hours | ✅ Working |
| **Ride Summaries** | `RideSummaryClient` | 7 days | ✅ Working |
| **Training Load** | None | ❌ | ⚠️ **MISSING** |
| **Strava Streams** | None | ❌ | ⚠️ **MISSING** |

---

## 🚨 Critical Gaps Identified

### 1. **Training Load Chart** (Your Issue)
**Problem:**
- Re-fetches 22 activities every time
- No persistence across app restarts
- `@State` variables don't survive force quit

**Impact:**
- 2-3s load time every open
- Unnecessary API calls
- Battery drain

---

### 2. **Strava Stream Data** (Bigger Issue)
**Problem:**
- **NO CACHING AT ALL**
- Fetches full stream data (1000s of samples) on every ride open
- Most expensive API call in the app

**Current Behavior:**
```swift
// RideDetailViewModel.swift - Line 31
let streamData = try await apiClient.fetchActivityStreams(activityId: activity.id)
// ❌ No cache check!
// ❌ Fetches 3000+ samples every time
// ❌ Even for rides viewed yesterday
```

**Impact:**
- 3-5s load time per ride
- Huge data transfer (100KB-1MB per ride)
- API rate limit risk
- Battery drain

---

## 🎯 Unified Cache Strategy

### Cache Tiers

```
┌─────────────────────────────────────────────────┐
│  Tier 1: In-Memory (Instant)                    │
│  - Current session data                          │
│  - TTL: Until app restart                        │
│  - Examples: @State, @Published                  │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Tier 2: UserDefaults (Fast)                    │
│  - Small metadata, timestamps                    │
│  - TTL: 1 hour - 7 days                         │
│  - Examples: Last fetch times, simple flags      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Tier 3: Core Data (Persistent)                 │
│  - Large datasets, structured data               │
│  - TTL: 7-30 days                               │
│  - Examples: Activities, stream data, scores     │
└─────────────────────────────────────────────────┘
```

---

## 📋 Proposed Implementation Plan

### **Phase 1: Strava Stream Cache (HIGH PRIORITY)** 🔥

**Why First:** Biggest performance win, most expensive API call

#### Implementation:

```swift
// New Entity: StreamDataCache.swift
@objc(StreamDataCache)
public class StreamDataCache: NSManagedObject {
    @NSManaged public var activityId: String
    @NSManaged public var source: String  // "strava" or "intervals"
    @NSManaged public var samples: Data   // Encoded [WorkoutSample]
    @NSManaged public var sampleCount: Int32
    @NSManaged public var cachedAt: Date
    @NSManaged public var expiresAt: Date
}

// Service: StreamCacheService.swift
@MainActor
class StreamCacheService {
    static let shared = StreamCacheService()
    
    private let cacheDuration: TimeInterval = 7 * 24 * 3600  // 7 days
    
    func getCachedStreams(activityId: String) -> [WorkoutSample]? {
        let request = StreamDataCache.fetchRequest()
        request.predicate = NSPredicate(format: "activityId == %@ AND expiresAt > %@", 
                                       activityId, Date() as NSDate)
        request.fetchLimit = 1
        
        guard let cached = try? PersistenceController.shared.fetch(request).first,
              let data = cached.samples,
              let samples = try? JSONDecoder().decode([WorkoutSample].self, from: data) else {
            return nil
        }
        
        Logger.data("✅ Stream cache HIT: \(activityId) (\(samples.count) samples)")
        return samples
    }
    
    func cacheStreams(_ samples: [WorkoutSample], activityId: String, source: String) {
        guard let data = try? JSONEncoder().encode(samples) else { return }
        
        let context = PersistenceController.shared.newBackgroundContext()
        context.perform {
            let cache = StreamDataCache(context: context)
            cache.activityId = activityId
            cache.source = source
            cache.samples = data
            cache.sampleCount = Int32(samples.count)
            cache.cachedAt = Date()
            cache.expiresAt = Date().addingTimeInterval(self.cacheDuration)
            
            PersistenceController.shared.save(context: context)
            Logger.data("💾 Cached \(samples.count) stream samples for \(activityId)")
        }
    }
}
```

#### Update RideDetailViewModel:

```swift
func loadActivityData(activity: IntervalsActivity, ...) async {
    isLoading = true
    
    // 1. Check cache first
    if let cachedSamples = StreamCacheService.shared.getCachedStreams(activityId: activity.id) {
        Logger.data("⚡ Using cached stream data (\(cachedSamples.count) samples)")
        samples = cachedSamples
        enrichedActivity = enrichActivityWithStreamData(activity: activity, samples: cachedSamples, ...)
        isLoading = false
        return
    }
    
    // 2. Fetch from API if cache miss
    Logger.data("📡 Cache miss - fetching from API")
    let streamData = try await apiClient.fetchActivityStreams(activityId: activity.id)
    
    // 3. Cache for next time
    StreamCacheService.shared.cacheStreams(streamData, activityId: activity.id, source: "strava")
    
    samples = streamData
    enrichedActivity = enrichActivityWithStreamData(...)
    isLoading = false
}
```

**Expected Impact:**
- **First open:** 3-5s (API fetch + cache)
- **Subsequent opens:** <500ms (cache hit)
- **Reduction:** ~90% of stream API calls
- **Data saved:** ~100KB-1MB per cached ride

---

### **Phase 2: Training Load Cache (MEDIUM PRIORITY)** ⚡

#### Implementation:

```swift
// Add to TrainingLoadChart.swift
@AppStorage("trainingLoadLastFetch") private var lastFetchTimestamp: Double = 0
@AppStorage("trainingLoadActivityCount") private var cachedActivityCount: Int = 0

private let cacheValidityDuration: TimeInterval = 3600  // 1 hour

private func loadHistoricalActivities(rideDate: Date) async {
    // 1. Check cache age
    let lastFetch = Date(timeIntervalSince1970: lastFetchTimestamp)
    let cacheAge = Date().timeIntervalSince(lastFetch)
    
    if cacheAge < cacheValidityDuration && !historicalActivities.isEmpty {
        Logger.data("⚡ Using cached training load data (age: \(Int(cacheAge/60))m, \(historicalActivities.count) activities)")
        return
    }
    
    // 2. Check if UnifiedActivityService has cached data
    let cachedActivities = try? await UnifiedActivityService.shared.getCachedActivities()
    if let cached = cachedActivities, !cached.isEmpty, cacheAge < cacheValidityDuration {
        Logger.data("⚡ Using UnifiedActivityService cache (\(cached.count) activities)")
        historicalActivities = cached
        return
    }
    
    // 3. Fetch fresh data
    Logger.data("📡 Cache expired or empty - fetching fresh data")
    let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 200, daysBack: daysBack)
    
    // 4. Update cache metadata
    lastFetchTimestamp = Date().timeIntervalSince1970
    cachedActivityCount = activities.count
    
    // ... rest of processing
}
```

**Expected Impact:**
- **First open:** 2-3s (API fetch)
- **Within 1 hour:** <1s (cache hit)
- **After force quit:** <1s (cache persists)
- **Reduction:** ~80% of training load fetches

---

### **Phase 3: Unified Cache Manager (LONG TERM)** 🏗️

Create a single cache coordinator:

```swift
@MainActor
class UnifiedCacheManager {
    static let shared = UnifiedCacheManager()
    
    // Cache policies
    enum CachePolicy {
        case streamData      // 7 days
        case activities      // 1 hour
        case trainingLoad    // 1 hour
        case rideSummary     // 7 days
        case athlete         // 1 hour
        case aiBrief         // 24 hours
    }
    
    func get<T: Codable>(_ key: String, policy: CachePolicy) -> T? {
        // Unified cache lookup across all tiers
    }
    
    func set<T: Codable>(_ value: T, key: String, policy: CachePolicy) {
        // Unified cache storage with automatic tier selection
    }
    
    func invalidate(policy: CachePolicy) {
        // Invalidate all caches of a specific type
    }
    
    func pruneExpired() {
        // Clean up expired caches across all tiers
    }
}
```

---

## 📊 Expected Performance Improvements

### Before (Current State)

| Action | Time | API Calls | Data Transfer |
|--------|------|-----------|---------------|
| Open ride (1st time) | 3-5s | 2 | ~1MB |
| Open ride (2nd time) | 3-5s | 2 | ~1MB |
| Open ride (after restart) | 3-5s | 2 | ~1MB |
| Training load chart | 2-3s | 1 | ~50KB |
| **Daily total** | ~50s | ~20 | ~10MB |

### After (With Full Cache)

| Action | Time | API Calls | Data Transfer |
|--------|------|-----------|---------------|
| Open ride (1st time) | 3-5s | 2 | ~1MB |
| Open ride (2nd time) | <500ms | 0 | 0 |
| Open ride (after restart) | <500ms | 0 | 0 |
| Training load chart | <1s | 0 | 0 |
| **Daily total** | ~10s | ~4 | ~2MB |

**Improvements:**
- ⚡ **80% faster** for cached operations
- 📉 **80% fewer API calls**
- 💾 **80% less data transfer**
- 🔋 **Significant battery savings**

---

## 🎯 Recommended Next Steps

### **Immediate (This Session)**
1. ✅ Fix UserDefaults excessive saves (DONE)
2. ✅ Fix threading violations (DONE)
3. ⚡ **Implement Strava Stream Cache** (30 min)
   - Biggest performance win
   - Most expensive API call
   - Relatively simple implementation

### **Short Term (Next Session)**
4. ⚡ Implement Training Load Cache (20 min)
5. 🧪 Test both caches thoroughly
6. 📊 Measure performance improvements

### **Medium Term (Future)**
7. 🏗️ Build Unified Cache Manager
8. 🔄 Migrate all caches to unified system
9. 📈 Add cache analytics/monitoring

---

## 🧪 Testing Strategy

### Cache Hit Rate Monitoring

Add to each cache service:

```swift
private var cacheHits = 0
private var cacheMisses = 0

var hitRate: Double {
    let total = cacheHits + cacheMisses
    return total > 0 ? Double(cacheHits) / Double(total) : 0
}

func logCacheStats() {
    Logger.data("📊 Cache Stats: \(cacheHits) hits, \(cacheMisses) misses (\(Int(hitRate * 100))% hit rate)")
}
```

### Test Scenarios

1. **Cold Start** (force quit → relaunch)
   - ✅ Stream cache should persist
   - ✅ Training load cache should persist
   
2. **Warm Cache** (navigate away → back)
   - ✅ Should use in-memory cache
   - ✅ <1s load time
   
3. **Stale Cache** (wait 1 hour)
   - ✅ Should refresh automatically
   - ✅ New data fetched

4. **Cache Invalidation** (logout/login)
   - ✅ All caches cleared
   - ✅ Fresh data fetched

---

## 💾 Storage Impact

### Estimated Cache Sizes

| Cache Type | Per Item | 100 Items | Notes |
|------------|----------|-----------|-------|
| Stream Data | 50-200KB | 5-20MB | Largest |
| Activities | 2-5KB | 200-500KB | Medium |
| Training Load | 1KB | 100KB | Small |
| **Total** | - | **~25MB** | Acceptable |

**Cleanup Strategy:**
- Auto-prune data >30 days old
- Limit to 100 most recent rides
- User can manually clear in Settings

---

## 🚀 Implementation Priority

### **DO NOW** (Highest ROI):
1. ⚡ Strava Stream Cache
2. ⚡ Training Load Cache

### **DO NEXT**:
3. 📊 Cache monitoring/analytics
4. 🧪 Comprehensive testing

### **DO LATER**:
5. 🏗️ Unified Cache Manager
6. 🔄 Cache migration system

---

## ❓ Questions for You

1. **Priority**: Should I implement Strava Stream Cache first (biggest win)?
2. **TTL**: Is 7 days reasonable for stream data? (Rides don't change)
3. **Storage**: Is 25MB cache size acceptable?
4. **Testing**: Want me to add cache hit rate monitoring?

---

**Ready to implement when you are!** 🚀

The Strava Stream Cache alone will give you:
- ⚡ 80-90% faster ride opens
- 📉 Massive reduction in API calls
- 🔋 Better battery life
- 😊 Much better UX
