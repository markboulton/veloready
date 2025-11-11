# Cache Fix Verification Plan

**Date**: November 5, 2025  
**Issue**: Cache not persisting between app restarts, causing excessive Strava API calls

---

## Root Cause

**Problem**: `UnifiedCacheManager` was memory-only - all cache lost on app restart
- Every launch = cache miss = API calls
- User saw: "Downloading 1 activity", then "Downloading 4 activities"
- Impact: Excessive API usage, risk of rate limiting

**Evidence from Logs**:
```
08:35:22 - Cache stored (valid until 09:35:22)
08:41:37 - Cache MISS (should have been HIT!)
08:41:37 - Downloaded 1 activity from Strava API
08:41:39 - Downloaded 4 activities from Strava API
```

---

## Fix Implemented

### Added Disk Persistence to UnifiedCacheManager

**File**: `VeloReady/Core/Data/UnifiedCacheManager.swift`

**Changes**:
1. **Added disk storage keys** (lines 30-32)
   ```swift
   private let diskCacheKey = "UnifiedCacheManager.DiskCache"
   private let diskCacheMetadataKey = "UnifiedCacheManager.DiskCacheMetadata"
   ```

2. **Load disk cache on init** (line 48)
   ```swift
   loadDiskCache()
   ```

3. **Persist activity cache to disk** (lines 262-265)
   ```swift
   // Persist activity cache to disk (survives app restarts)
   if key.starts(with: "strava:activities:") || key.starts(with: "intervals:activities:") {
       saveToDisk(key: key, value: value, cachedAt: cached.cachedAt)
   }
   ```

4. **Remove from disk on invalidation** (lines 174-177)
   ```swift
   // Remove from disk if activity cache
   if key.starts(with: "strava:activities:") || key.starts(with: "intervals:activities:") {
       removeFromDisk(key: key)
   }
   ```

5. **Disk persistence helpers** (lines 334-440)
   - `loadDiskCache()` - Load on app launch
   - `saveToDisk()` - Save after API fetch
   - `removeFromDisk()` - Remove on invalidation

**What Gets Persisted**:
- ✅ `strava:activities:1` (today)
- ✅ `strava:activities:7` (week)
- ✅ `strava:activities:120` (FTP)
- ✅ `strava:activities:365` (full history)
- ✅ `intervals:activities:*` (Intervals.icu)

**What Stays Memory-Only**:
- ❌ Health metrics (fast to fetch)
- ❌ Scores (recalculated daily)
- ❌ Streams (too large for UserDefaults)

---

## Verification Steps

### Test 1: First Launch (Cold Start)
**Expected**: Cache miss, downloads from API
```
🌐 [Cache MISS] strava:activities:1 - fetching...
✅ [Strava] Fetched 1 activities from API
💾 [Cache STORE] strava:activities:1 (cost: 1KB)
💾 [Disk Cache] Saved strava:activities:1 to disk
```

### Test 2: Second Launch (Warm Start)
**Expected**: Cache hit, NO API calls
```
💾 [Disk Cache] Loaded 3 entries from disk
⚡ [Cache HIT] strava:activities:1 (age: 120s)
⚡ [Cache HIT] strava:activities:7 (age: 120s)
⚡ [Cache HIT] strava:activities:120 (age: 120s)
```

### Test 3: Pull-to-Refresh (Within 1 Hour)
**Expected**: Cache hit, NO API calls
```
⚡ [Cache HIT] strava:activities:1 (age: 300s)
⚡ [Cache HIT] strava:activities:7 (age: 300s)
```

### Test 4: After 1 Hour (Cache Expired)
**Expected**: Cache miss, re-downloads from API
```
🌐 [Cache MISS] strava:activities:1 - fetching...
✅ [Strava] Fetched 1 activities from API
💾 [Disk Cache] Saved strava:activities:1 to disk
```

### Test 5: Kill App, Relaunch Immediately
**Expected**: Cache hit from disk
```
💾 [Disk Cache] Loaded 3 entries from disk
⚡ [Cache HIT] strava:activities:1 (age: 30s)
```

---

## Manual Testing Checklist

- [ ] **Test 1**: Clean install → First launch → Verify cache miss + API calls
- [ ] **Test 2**: Kill app → Relaunch → Verify cache hit + NO API calls
- [ ] **Test 3**: Pull-to-refresh → Verify cache hit + NO API calls
- [ ] **Test 4**: Wait 1 hour → Pull-to-refresh → Verify cache miss + API calls
- [ ] **Test 5**: Check UserDefaults → Verify disk cache exists
- [ ] **Test 6**: Check logs → Count Strava API calls (should be minimal)

---

## Expected Results

### Before Fix:
- **Every launch**: 3-4 Strava API calls
- **Every pull-to-refresh**: 3-4 Strava API calls
- **Daily API calls**: 50-100+ (excessive!)

### After Fix:
- **First launch**: 3-4 Strava API calls (cache miss)
- **Subsequent launches**: 0 API calls (cache hit)
- **Pull-to-refresh**: 0 API calls (within 1 hour)
- **Daily API calls**: 10-20 (reasonable)

**API Usage Reduction**: ~80-90%

---

## Monitoring

### Log Patterns to Watch:

**Good (Cache Working)**:
```
💾 [Disk Cache] Loaded 3 entries from disk
⚡ [Cache HIT] strava:activities:1 (age: 120s)
⚡ [Cache HIT] strava:activities:7 (age: 120s)
```

**Bad (Cache Not Working)**:
```
🌐 [Cache MISS] strava:activities:1 - fetching...
🌐 [Cache MISS] strava:activities:7 - fetching...
✅ [Strava] Fetched 1 activities from API
✅ [Strava] Fetched 4 activities from API
```

### UserDefaults Keys:
- `UnifiedCacheManager.DiskCache` - Encoded activity data
- `UnifiedCacheManager.DiskCacheMetadata` - Cache timestamps

---

## Build Status

✅ **Build Succeeded** (November 5, 2025 08:57 UTC)
- No errors
- 15 warnings (pre-existing, Swift 6 concurrency)
- Ready for testing

---

## Next Steps

1. ✅ Build succeeded
2. ⏳ Deploy to simulator
3. ⏳ Test cache persistence
4. ⏳ Verify API call reduction
5. ⏳ Monitor logs for cache hits

---

## Success Criteria

- ✅ Build succeeds
- ⏳ Cache persists between app restarts
- ⏳ API calls reduced by 80%+
- ⏳ No cache-related errors in logs
- ⏳ App performance unchanged or improved
