# Cache Persistence Fixes - Implementation Guide

**Priority**: HIGH  
**Estimated Time**: 8 hours total

---

## 📋 Summary of Required Fixes

| Fix | Priority | Time | Impact |
|-----|----------|------|--------|
| 1. Stream Persistence | HIGH | 3h | 90% reduction in stream API calls |
| 2. Baseline Persistence | MEDIUM | 2h | App startup 2-3s faster |
| 3. Unit Tests | CRITICAL | 3h | Prevent regression |

---

## 🎯 Fix 1: Stream Persistence (HIGH PRIORITY)

### Problem
- Streams have 7-day TTL but are memory-only
- Every app restart fetches streams again (500ms API call)
- Wastes bandwidth and API quota

### Solution
Extend disk persistence to include streams.

### Implementation

**File**: `UnifiedCacheManager.swift`

**Step 1: Update persistence check (Line 263)**
```swift
// OLD:
if key.starts(with: "strava:activities:") || key.starts(with: "intervals:activities:") {
    saveToDisk(key: key, value: value, cachedAt: cached.cachedAt)
}

// NEW:
if key.starts(with: "strava:activities:") || 
   key.starts(with: "intervals:activities:") ||
   key.starts(with: "stream:") {
    saveToDisk(key: key, value: value, cachedAt: cached.cachedAt)
}
```

**Step 2: Add stream encoding (Line 383)**
```swift
// In saveToDisk method
if let activities = value as? [StravaActivity] {
    diskData = try encoder.encode(activities)
} else if let activities = value as? [Activity] {
    diskData = try encoder.encode(activities)
} else if let stream = value as? [WorkoutSample] {
    // ADD THIS
    diskData = try encoder.encode(stream)
}
```

**Step 3: Add stream decoding (Line 350)**
```swift
// In loadDiskCache method
if key.starts(with: "strava:activities:") {
    // existing code...
} else if key.starts(with: "intervals:activities:") {
    // existing code...
} else if key.starts(with: "stream:") {
    // ADD THIS
    if let stream = try? decoder.decode([WorkoutSample].self, from: data),
       let cachedAt = metadata[key] {
        let cached = CachedValue(value: stream, cachedAt: Date(timeIntervalSince1970: cachedAt))
        memoryCache[key] = cached
        trackedKeys.insert(key)
        loadedCount += 1
    }
}
```

**Step 4: Verify WorkoutSample is Codable**
```swift
// WorkoutDetailCharts.swift - Should already be Codable
struct WorkoutSample: Codable {
    let time: Date
    let power: Int?
    let heartRate: Int?
    let cadence: Int?
    let speed: Double?
    // ... other fields
}
```

### Testing
```bash
# 1. Open ride with power data
# 2. Check logs for: "💾 [Disk Cache] Saved stream:strava_XXXXX to disk"
# 3. Force quit app
# 4. Reopen same ride
# 5. Check logs for: "💾 [Disk Cache] Loaded 1 entries from disk"
# 6. Verify ride loads instantly (<100ms)
```

### Expected Impact
- **Before**: 500ms to load streams (API call)
- **After**: <50ms to load streams (disk cache)
- **API reduction**: 90% fewer stream fetches

---

## 🎯 Fix 2: Baseline Persistence (MEDIUM PRIORITY)

### Problem
- Baselines recalculated on every app open (2-3s)
- Queries 7-30 days of HealthKit data
- Blocks app startup

### Solution
Cache baselines in UserDefaults with 1-hour TTL.

### Implementation

**File**: `VeloReady/Core/Cache/BaselineCache.swift` (NEW FILE)

```swift
import Foundation

/// Cached baseline values for recovery calculations
struct CachedBaseline: Codable {
    let hrvBaseline: Double
    let rhrBaseline: Double
    let sleepBaseline: Double
    let respiratoryBaseline: Double
    let cachedAt: Date
    let sampleCounts: SampleCounts
    
    struct SampleCounts: Codable {
        let hrvSamples: Int
        let rhrSamples: Int
        let sleepSessions: Int
        let respiratorySamples: Int
    }
    
    /// Check if baseline is still valid
    func isValid(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) < ttl
    }
}

/// Manages baseline caching with disk persistence
@MainActor
class BaselineCache {
    static let shared = BaselineCache()
    
    private let cacheKey = "VeloReady.CachedBaselines"
    private let cacheTTL: TimeInterval = 3600  // 1 hour
    
    private init() {}
    
    /// Load cached baselines if valid
    func loadCached() -> CachedBaseline? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedBaseline.self, from: data),
              cached.isValid(ttl: cacheTTL) else {
            return nil
        }
        
        let age = Int(Date().timeIntervalSince(cached.cachedAt))
        Logger.debug("⚡ [BaselineCache] Loaded from disk (age: \(age)s)")
        Logger.debug("   HRV: \(cached.hrvBaseline)ms, RHR: \(cached.rhrBaseline)bpm")
        
        return cached
    }
    
    /// Save baselines to cache
    func save(_ baseline: CachedBaseline) {
        if let data = try? JSONEncoder().encode(baseline) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            Logger.debug("💾 [BaselineCache] Saved to disk")
            Logger.debug("   HRV: \(baseline.hrvBaseline)ms (\(baseline.sampleCounts.hrvSamples) samples)")
            Logger.debug("   RHR: \(baseline.rhrBaseline)bpm (\(baseline.sampleCounts.rhrSamples) samples)")
        }
    }
    
    /// Clear cached baselines
    func clear() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        Logger.debug("🗑️ [BaselineCache] Cleared")
    }
}
```

**File**: Update `BaselineCalculator.swift` or score services

```swift
// In RecoveryScoreService or wherever baselines are calculated

func calculateWithCachedBaselines() async -> RecoveryScore {
    // 1. Try to load cached baselines
    if let cached = BaselineCache.shared.loadCached() {
        Logger.debug("⚡ Using cached baselines (skipping expensive calculation)")
        return await calculateScore(
            hrvBaseline: cached.hrvBaseline,
            rhrBaseline: cached.rhrBaseline,
            sleepBaseline: cached.sleepBaseline
        )
    }
    
    // 2. Calculate fresh baselines (expensive)
    Logger.debug("📊 Calculating fresh baselines (30-day data)...")
    let hrvBaseline = await calculateHRVBaseline()
    let rhrBaseline = await calculateRHRBaseline()
    let sleepBaseline = await calculateSleepBaseline()
    let respiratoryBaseline = await calculateRespiratoryBaseline()
    
    // 3. Cache for next time
    let cached = CachedBaseline(
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        sleepBaseline: sleepBaseline,
        respiratoryBaseline: respiratoryBaseline,
        cachedAt: Date(),
        sampleCounts: CachedBaseline.SampleCounts(
            hrvSamples: 70,  // actual count
            rhrSamples: 7,   // actual count
            sleepSessions: 6, // actual count
            respiratorySamples: 316  // actual count
        )
    )
    BaselineCache.shared.save(cached)
    
    // 4. Calculate score with fresh baselines
    return await calculateScore(
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        sleepBaseline: sleepBaseline
    )
}
```

### Testing
```bash
# 1. Force quit app
# 2. Launch app
# 3. Check logs for: "📊 Calculating fresh baselines (30-day data)..."
# 4. Check logs for: "💾 [BaselineCache] Saved to disk"
# 5. Force quit app
# 6. Launch app again
# 7. Check logs for: "⚡ [BaselineCache] Loaded from disk (age: Xs)"
# 8. Verify app starts 2-3s faster
```

### Expected Impact
- **Before**: 2-3s to calculate baselines on every launch
- **After**: <10ms to load baselines from cache
- **HealthKit queries**: 95% reduction

---

## 🎯 Fix 3: Unit Tests (CRITICAL)

### Implementation

**File**: `VeloReadyTests/Unit/UnifiedCacheManagerTests.swift`

See `CACHE_UNIT_TESTS.md` for complete test suite.

**Integration**: Add to `quick-test.sh`

```bash
#!/bin/bash
# Scripts/quick-test.sh

echo "🧪 Running cache tests..."
swift test --filter UnifiedCacheManagerTests
if [ $? -ne 0 ]; then
    echo "❌ Cache tests failed"
    exit 1
fi
```

---

## 📊 Expected Results After All Fixes

### API Call Reduction

| Scenario | Before | After | Reduction |
|----------|--------|-------|-----------|
| **Activities** | 30/day | 3/day | 90% ✅ |
| **Streams** | 10/day | 1/day | 90% ✅ |
| **Baselines** | N/A (HealthKit) | N/A | N/A |

**Total Strava API Calls/Day/User**: 5 (down from 40)

### Performance Improvements

| Operation | Before | After | Improvement |
|-----------|--------|-------|-------------|
| **App startup** | 5-8s | 2-3s | 40% faster ✅ |
| **Open ride (cached)** | 500ms | <50ms | 90% faster ✅ |
| **Baseline calculation** | 2-3s | <10ms | 99% faster ✅ |

---

## ✅ Implementation Checklist

### Week 1: Tests (3 hours)
- [ ] Create `UnifiedCacheManagerTests.swift`
- [ ] Implement 10 core tests
- [ ] Add to `quick-test.sh`
- [ ] Verify all tests pass
- **Validation**: `swift test --filter UnifiedCacheManagerTests`

### Week 2: Stream Persistence (3 hours)
- [ ] Update `storeInCache()` to persist streams
- [ ] Add stream encoding in `saveToDisk()`
- [ ] Add stream decoding in `loadDiskCache()`
- [ ] Test ride detail loading
- **Validation**: Check logs for disk cache hits

### Week 3: Baseline Persistence (2 hours)
- [ ] Create `BaselineCache.swift`
- [ ] Update score services to use cache
- [ ] Test app startup performance
- [ ] Verify baselines persist across restarts
- **Validation**: App starts 2-3s faster

---

## 🐛 Troubleshooting

### Issue: Streams not persisting
**Check**: WorkoutSample must conform to Codable
**Fix**: Add Codable conformance if missing

### Issue: Baselines still slow
**Check**: BaselineCache.loadCached() being called
**Fix**: Ensure it's called before expensive calculation

### Issue: Tests failing
**Check**: UserDefaults cleared in setUp()
**Fix**: Add cleanup in test setup

---

**Status**: Ready for implementation. Follow checklist above.
