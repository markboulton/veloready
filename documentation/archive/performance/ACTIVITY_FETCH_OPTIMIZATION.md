# Activity Fetch Optimization - Critical Issues

**Date**: November 4, 2025  
**Status**: ⚠️ CRITICAL PERFORMANCE ISSUES IDENTIFIED

---

## 🐛 Issues Identified from Logs

### 1. **Strava Authentication Failing**
```
❌ [Strava] Failed to fetch activities: notAuthenticated
```
- Strava connection shows as "connected" but API calls fail
- Causes "Downloading 0 activities" status to show
- Eventually succeeds after multiple retries

### 2. **365-Day Fetch Happening Every Time**
```
🌐 [Cache MISS] strava:activities:365 - fetching...
✅ [Strava] Fetched 183 activities from API
💾 [Cache STORE] strava:activities:365 (cost: 183KB)
```
- Cache is MISSING every time
- Downloads 183 activities on EVERY app open
- Takes 28+ seconds in background
- Should be cached for 1 hour

### 3. **Incremental Loading Not Working**
```
📊 [INCREMENTAL] Fetching today's activities...
📊 [INCREMENTAL] Fetching this week's activities...
📊 [INCREMENTAL] Fetching full activity history in background...
```
- All 3 calls fetch 365 days (not 1 day, 7 days, 365 days)
- Incremental loading is broken
- Downloads same 183 activities 3 times

### 4. **Status Mismatch**
```
✅ [LoadingState] Now showing: downloadingActivities(count: Optional(183), source: Optional(VeloReady.LoadingState.DataSource.strava))
```
- Status shows "Downloading 183 Strava activities"
- But download happened 20+ seconds earlier
- Status is out of sync with actual work

### 5. **Background Task Running in Foreground**
```
🎯 PHASE 3: Background Updates - activities, trends, training load
⚡ Background refresh completed in 28.89s
```
- 365-day fetch (183 activities) runs in Phase 3
- Blocks "Updated just now" status for 28+ seconds
- Should be truly background (Task.detached)

---

## 📊 Performance Impact

### Current Behavior (BROKEN):
```
0-2s:   [Logo]
2-3s:   "Fetching health data..."
3-4s:   "Calculating scores..."
4-5s:   "Checking for new data..."
5-6s:   "Contacting Strava..."
6-34s:  "Downloading 183 Strava activities..." ← 28 SECONDS!
34s:    "Updated just now"
```

### Expected Behavior (CACHED):
```
0-2s:   [Logo]
2-3s:   "Fetching health data..."
3-4s:   "Calculating scores..."
4-5s:   "Checking for new data..."
5-6s:   "Contacting Strava..."
6-7s:   "Downloading 4 Strava activities..." ← Only new ones!
7-8s:   "Computing power zones..."
8s:     "Updated just now"
```

---

## 🔍 Root Causes

### 1. Cache Not Working
**Problem**: `strava:activities:365` cache key is MISSING every time

**Possible Causes**:
- Cache key format changed
- Cache TTL too short
- Cache being invalidated somewhere
- UnifiedCacheManager not persisting

**Evidence from Logs**:
```
🌐 [Cache MISS] strava:activities:365 - fetching...
```
Every single app open shows cache MISS, never HIT.

### 2. Incremental Loading Broken
**Problem**: `fetchAndUpdateActivities(daysBack: 1)` fetches 365 days

**Root Cause**: StravaDataService ignores `daysBack` parameter

**Evidence**:
```swift
// TodayViewModel calls:
await fetchAndUpdateActivities(daysBack: 1)  // Should fetch 1 day
await fetchAndUpdateActivities(daysBack: 7)  // Should fetch 7 days
await fetchAndUpdateActivities(daysBack: 365) // Should fetch 365 days

// But StravaDataService does:
func fetchActivitiesIfNeeded() {
    // ALWAYS fetches 365 days, ignores daysBack!
}
```

### 3. Strava Auth Intermittent
**Problem**: First few API calls fail with `notAuthenticated`

**Possible Causes**:
- Token refresh race condition
- Connection state not synced with token
- Backend auth check failing

**Evidence**:
```
🔍 [STRAVA] Restoring connection state: athleteId=104662
❌ [Strava] Failed to fetch activities: notAuthenticated
// ... later ...
✅ [Strava] Fetched 183 activities from API
```

---

## 🛠️ Required Fixes

### Fix 1: Don't Show "Downloading 0 Activities"
**Status**: ✅ FIXED

```swift
// Only show downloading status if count > 0
if stravaActivities.count > 0 {
    loadingStateManager.updateState(.downloadingActivities(count: stravaActivities.count, source: .strava))
}
```

### Fix 2: Investigate Cache Miss
**Status**: 🔍 NEEDS INVESTIGATION

**Action Items**:
1. Check UnifiedCacheManager persistence
2. Verify cache key format consistency
3. Check if cache is being invalidated
4. Verify TTL is 1 hour (not shorter)

**Debug Logging Needed**:
```swift
Logger.debug("🔍 [Cache] Checking key: strava:activities:365")
Logger.debug("🔍 [Cache] TTL: \(ttl)s")
Logger.debug("🔍 [Cache] Age: \(age)s")
Logger.debug("🔍 [Cache] Expired: \(isExpired)")
```

### Fix 3: Fix Incremental Loading
**Status**: ⚠️ CRITICAL - NEEDS FIX

**Problem**: StravaDataService doesn't respect `daysBack` parameter

**Solution**: Pass `daysBack` to StravaDataService

```swift
// TodayViewModel.swift
await stravaDataService.fetchActivities(daysBack: daysBack)

// StravaDataService.swift
func fetchActivities(daysBack: Int) async {
    let cacheKey = "strava:activities:\(daysBack)"
    // Use daysBack in API call
}
```

### Fix 4: Move 365-Day Fetch to True Background
**Status**: ⚠️ CRITICAL - NEEDS FIX

**Problem**: 365-day fetch blocks Phase 3 for 28 seconds

**Solution**: Use Task.detached with lower priority

```swift
// Priority 3: Full history (background, low priority) - don't wait for this
Task.detached(priority: .background) {
    await self.fetchAndUpdateActivities(daysBack: 365)
    // Don't update loading state - truly background
}
```

### Fix 5: Fix Strava Auth Race Condition
**Status**: 🔍 NEEDS INVESTIGATION

**Possible Solutions**:
1. Wait for token refresh before API calls
2. Retry failed auth calls once
3. Check connection state before each API call

---

## 📝 Implementation Plan

### Phase 1: Quick Wins (Immediate)
- [x] Don't show "Downloading 0 activities" status
- [ ] Remove premature downloading status (wait for actual count)
- [ ] Move 365-day fetch to Task.detached (truly background)

### Phase 2: Cache Investigation (High Priority)
- [ ] Add debug logging to UnifiedCacheManager
- [ ] Verify cache key format
- [ ] Check cache TTL
- [ ] Test cache persistence across app launches

### Phase 3: Incremental Loading (Critical)
- [ ] Pass `daysBack` parameter to StravaDataService
- [ ] Update cache keys to include `daysBack`
- [ ] Verify 1-day fetch only fetches 1 day
- [ ] Verify 7-day fetch only fetches 7 days

### Phase 4: Auth Reliability (Medium Priority)
- [ ] Add retry logic for auth failures
- [ ] Wait for token refresh before API calls
- [ ] Add connection state validation

---

## 🎯 Expected Results After Fixes

### Cache Working:
```
First Launch:
🌐 [Cache MISS] strava:activities:7 - fetching...
✅ [Strava] Fetched 4 activities from API (7 days)
💾 [Cache STORE] strava:activities:7 (cost: 4KB)

Second Launch (within 1 hour):
⚡ [Cache HIT] strava:activities:7 (age: 120s)
✅ Using cached 4 activities
```

### Incremental Loading Working:
```
Priority 1 (1 day):   Fetch 0-1 activities  (< 1s)
Priority 2 (7 days):  Fetch 4 activities    (< 2s)
Priority 3 (365 days): Fetch 183 activities (background, 20s)
```

### Performance:
```
Before: 28s to "Updated just now"
After:  8s to "Updated just now" (20s saved!)
```

---

## 🚨 Critical Issues Summary

1. **Cache Not Working** - Downloads 183 activities every time (should be cached)
2. **Incremental Loading Broken** - Fetches 365 days 3 times (should be 1, 7, 365)
3. **Background Task Blocking** - 28s delay for "Updated just now" (should be instant)
4. **Auth Intermittent** - First API calls fail (should succeed)
5. **Status Mismatch** - Shows "downloading" after download complete (should be in sync)

---

## 📊 Log Analysis

### Cache Misses (Should Be Hits):
```
🌐 [Cache MISS] strava:activities:365 - fetching...
🌐 [Cache MISS] strava:activities:7 - fetching...
🌐 [Cache MISS] strava:activities:120 - fetching...
```

### Auth Failures (Should Succeed):
```
❌ [Strava] Failed to fetch activities: notAuthenticated
⚠️ Could not sync athlete info from Strava: notAuthenticated
```

### Duplicate Fetches (Should Be Deduplicated):
```
📊 [INCREMENTAL] Fetching today's activities...
📊 [INCREMENTAL] Fetching this week's activities...
📊 [INCREMENTAL] Fetching full activity history in background...
// All 3 fetch 365 days!
```

---

**CRITICAL**: The app is downloading 183 activities (90KB) on EVERY app open instead of using cache. This is a major performance and data usage issue that needs immediate attention.
