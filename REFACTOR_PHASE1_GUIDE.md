# Phase 1: Cache System Unification - Implementation Guide

**Duration:** 3-4 days  
**Branch:** `refactor/cache-unification`

---

## Overview

Consolidate 5 cache systems into UnifiedCacheManager:
- StreamCacheService (364 lines) → DELETE
- IntervalsCache (243 lines) → DELETE  
- HealthKitCache (79 lines) → DELETE
- StravaAthleteCache → DELETE
- CacheManager (keep Core Data logic only)

**Result:** Single unified caching layer with standardized keys

---

## Step 1: Create CacheKeys Enum (1 hour)

**File:** `VeloReady/Core/Data/CacheKeys.swift`

```swift
import Foundation

enum CacheKeys {
    // Activities
    static func stravaActivities(days: Int) -> String { "strava:activities:\(days)" }
    static func intervalsActivities(days: Int) -> String { "intervals:activities:\(days)" }
    
    // Streams
    static func stream(source: String, activityId: String) -> String { "stream:\(source)_\(activityId)" }
    
    // Scores
    static func recoveryScore(date: Date) -> String {
        "score:recovery:\(date.ISO8601Format())"
    }
    static func sleepScore(date: Date) -> String {
        "score:sleep:\(date.ISO8601Format())"
    }
    
    // Baselines
    static let hrvBaseline = "baseline:hrv:7day"
    static let rhrBaseline = "baseline:rhr:7day"
    static let sleepBaseline = "baseline:sleep:7day"
}
```

---

## Step 2: Migration Pattern

**OLD (StreamCacheService):**
```swift
let cached = StreamCacheService.shared.getCachedStreams(activityId: id)
if let cached = cached {
    return cached
}
let fresh = await fetchStreams(id)
StreamCacheService.shared.cacheStreams(fresh, activityId: id, source: "strava")
return fresh
```

**NEW (UnifiedCacheManager):**
```swift
let key = CacheKeys.stream(source: "strava", activityId: id)
return try await UnifiedCacheManager.shared.fetch(
    key: key,
    ttl: UnifiedCacheManager.CacheTTL.streams,
    fetchOperation: { await self.fetchStreams(id) }
)
```

**Benefits:**
- Automatic deduplication
- Offline fallback
- Core Data persistence
- Consistent logging

---

## Step 3: Find All Usages (30 min)

```bash
cd /Users/markboulton/Dev/veloready

# Generate audit
grep -rn "StreamCacheService.shared" --include="*.swift" VeloReady/ > CACHE_MIGRATION.txt
grep -rn "IntervalsCache.shared" --include="*.swift" VeloReady/ >> CACHE_MIGRATION.txt
grep -rn "HealthKitCache.shared" --include="*.swift" VeloReady/ >> CACHE_MIGRATION.txt

# Review
cat CACHE_MIGRATION.txt
```

---

## Step 4: Migrate Each Service (2-3 hours)

### UnifiedActivityService.swift
- Replace StreamCacheService calls
- Use CacheKeys.stream()
- Use UnifiedCacheManager.fetch()

### IntervalsAPIClient.swift
- Replace IntervalsCache calls
- Use CacheKeys.intervalsActivities()

### HealthKitManager.swift
- Replace HealthKitCache calls
- Use fetchCacheFirst() for HKWorkout (not Codable)

---

## Step 5: Delete Old Files

```bash
git rm VeloReady/Core/Services/StreamCacheService.swift
git rm VeloReady/Core/Services/IntervalsCache.swift
git rm VeloReady/Core/Services/HealthKitCache.swift
git rm VeloReady/Core/Services/StravaAthleteCache.swift

git commit -m "refactor: remove legacy cache systems (~1,455 lines)"
```

---

## Step 6: Test (1 hour)

```bash
# Automated tests
./Scripts/quick-test.sh

# Manual tests
# 1. Clear cache via Debug Settings
# 2. Load activities (should cache)
# 3. Close app
# 4. Reopen (should load from cache)
# 5. Check Cache Stats → Hit rate >80%
```

---

## Success Criteria

- [ ] All old cache services deleted
- [ ] All services using UnifiedCacheManager
- [ ] All tests passing
- [ ] Cache hit rate >80% in manual testing
- [ ] No hard-coded cache keys (all via CacheKeys enum)
