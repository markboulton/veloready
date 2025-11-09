# Cache Resilience Strategy

## Problem
Cache corruption causes cascading failures:
- Failed cache loads → assumes no data
- Assumes no data → assumes no permissions
- Shows "Enable Health Data" even when permissions are granted

## Solution: Multi-Layer Defense

### 1. Cache Versioning (Prevents corruption)
```swift
// Increment version when cache format changes
let cacheVersion = "v4"

// On app launch, check version
if UserDefaults.standard.string(forKey: "cacheVersion") != cacheVersion {
    // Clear all caches
    await clearAllCaches()
    UserDefaults.standard.set(cacheVersion, forKey: "cacheVersion")
}
```

### 2. Graceful Degradation (Handles failures)
```swift
// Instead of failing silently, log and continue
do {
    let cached = try await cache.load(key)
} catch {
    Logger.warning("Cache load failed, will regenerate: \(error)")
    // Delete corrupted cache entry
    cache.invalidate(key)
    // Continue without cache (will fetch fresh)
}
```

### 3. Cache Health Check (Detects issues early)
```swift
// On app launch, test cache integrity
func validateCacheHealth() async {
    let testKeys = [
        "score:sleep:2025-11-09T00:00:00Z",
        "strava:activities:7"
    ]
    
    var corruptedCount = 0
    for key in testKeys {
        if let _ = try? await cache.load(key) {
            // Success
        } else {
            corruptedCount += 1
        }
    }
    
    if corruptedCount > testKeys.count / 2 {
        // More than 50% corrupted - clear all
        Logger.warning("Cache corruption detected - clearing all caches")
        await clearAllCaches()
    }
}
```

### 4. Separate Permissions Check (Prevents false negatives)
```swift
// NEVER assume permissions based on cache state
// Always check HealthKit directly
let hasPermissions = await healthKitManager.checkAuthorizationStatus()

// Cache failures should NOT affect permission checks
```

## Implementation Priority

1. **Immediate (5 min):** Add cache version check and auto-clear
2. **Short-term (15 min):** Add graceful degradation to cache loads
3. **Medium-term (30 min):** Add cache health check on launch
4. **Long-term (1 hour):** Refactor to separate permissions from cache state

## Benefits

- ✅ **Self-healing:** App recovers automatically from cache corruption
- ✅ **No user action:** No need to delete/reinstall
- ✅ **Clear logging:** Know exactly when and why cache is cleared
- ✅ **Future-proof:** Version bumps handle format changes
- ✅ **Graceful:** Failures don't cascade to permissions

## Trade-offs

- ⚠️ First launch after cache clear will be slower (fresh data fetch)
- ⚠️ Users lose cached data (but it was corrupted anyway)
- ✅ Better than showing "Enable Health Data" incorrectly
- ✅ Better than requiring app deletion
