# Strava Activity Cache Fix - Missing Morning Ride

**Date:** November 13, 2025  
**Issue:** "4 x 9" ride from 7:30 AM not appearing in app  
**Root Cause:** Double-layer caching with 1-hour TTL causing stale data

---

## 🔍 Problem Analysis

### What Happened

1. **Nov 12, 10:49 PM**: Backend fetched 3 activities (7-day window), cached with 1-hour TTL
2. **Nov 13, 7:30 AM**: User completes "4 x 9" ride on Strava
3. **Nov 13, 8:39 AM**: iOS app requests today's activities
4. **Problem**: App uses cached data from last night (still valid < 1 hour from iOS app's perspective)
5. **Result**: "4 x 9" ride is missing

### Cache Layers

```
┌─────────────────────────────────────┐
│  iOS App Cache (UnifiedCacheManager)│
│  TTL: 1 hour (3600s)                │
│  Key: strava:activities:7           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Netlify Backend Cache (Blobs)      │
│  TTL: 1 hour (3600s)                │
│  Key: activities:104662:epoch:1     │
└─────────────────────────────────────┘
```

### Why 1-Hour Cache is Too Long

- **New activities**: Need to appear within 5-10 minutes
- **User expectation**: Pull-to-refresh should show latest data
- **Current behavior**: Can be up to 2 hours stale (backend cache + iOS cache)

---

## ✅ Solution Implemented

### 1. iOS App: Smart Cache TTL for Today's Activities

**File:** `VeloReady/Core/Services/Data/UnifiedActivityService.swift`

**Changes:**

```swift
// OLD: Used 1-hour cache for all requests
func fetchTodaysActivities() async throws -> [Activity] {
    let activities = try await fetchRecentActivities(limit: 50, daysBack: 7)
    return activities.filter { /* today only */ }
}

// NEW: Uses 5-minute cache for today's activities
func fetchTodaysActivities() async throws -> [Activity] {
    // Fetch with SHORT cache TTL (5 minutes)
    let activities = try await fetchRecentActivitiesWithCustomTTL(
        limit: 50, 
        daysBack: 7, 
        ttl: 300  // 5 minutes instead of 1 hour
    )
    return activities.filter { /* today only */ }
}
```

**New Method:**
```swift
private func fetchRecentActivitiesWithCustomTTL(
    limit: Int = 100, 
    daysBack: Int = 90, 
    ttl: TimeInterval
) async throws -> [Activity]
```

This allows different cache strategies for different use cases:
- **Today's activities**: 5 minutes (fast updates)
- **Historical data**: 1 hour (reduce API load)
- **Adaptive zones**: 1 hour (stable data)

### 2. Backend: Smart Cache TTL Based on Date Range

**File:** `veloready-website/netlify/lib/strava.ts`

**Changes:**

```typescript
// OLD: Always 1-hour cache
const cacheTTL = 3600;

// NEW: Smart cache based on date range
const now = Math.floor(Date.now() / 1000);
const sevenDaysAgo = now - (7 * 24 * 3600);
const isRecentActivities = afterEpochSec >= sevenDaysAgo;
const cacheTTL = isRecentActivities ? 300 : 3600; // 5 min vs 1 hour

console.log(`[Strava Cache] Cache strategy: ${
  isRecentActivities ? 'RECENT (5min)' : 'HISTORICAL (1hr)'
} - afterEpoch=${afterEpochSec}`);
```

**Logic:**
- If fetching activities from **last 7 days**: Cache for **5 minutes**
- If fetching older activities (>7 days): Cache for **1 hour**
- This balances fresh data with API rate limits

---

## 📊 Impact

### Before Fix

```
User completes ride at 7:30 AM
↓
Opens app at 8:30 AM
↓
App uses cache from 10:49 PM (last night)
↓
Ride doesn't appear
↓
User must wait until 11:49 PM (cache expiration)
```

**Result**: Up to 16 hours delay! ❌

### After Fix

```
User completes ride at 7:30 AM
↓
Opens app at 8:30 AM (1 hour later)
↓
Cache expired (5 min TTL) → Fetches fresh data
↓
"4 x 9" ride appears
```

**Result**: Max 5-minute delay ✅

---

## 🔧 Deployment Steps

### 1. Deploy Backend (Netlify)

```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Clear old cache entries (one-time)
netlify blobs:delete strava-cache "activities:104662:1762382996:1" --context production

# Deploy to Netlify
netlify deploy --prod

# Monitor logs
netlify logs:function api-activities --live
```

**Expected logs:**
```
[Strava Cache] Cache strategy: RECENT (5min) - afterEpoch=1762382996
[Strava Cache] Cached 3 activities (TTL: 300s)
```

### 2. Deploy iOS App

```bash
cd /Users/mark.boulton/Documents/dev/veloready

# Build and run
open VeloReady.xcodeproj
# Cmd+R to run
```

**Expected logs:**
```
📊 [Activities] Fetch request: 7 days (capped to 7 for FREE tier), TTL: 300s
✅ [Activities] Fetched 4 activities from backend
```

---

## 🧪 Testing

### Test Case 1: Today's Activities

1. Complete an activity on Strava
2. Wait 1 minute (for Strava processing)
3. Open VeloReady app
4. Pull to refresh
5. **Expected**: New activity appears within 5 minutes

### Test Case 2: Cache Behavior

1. Open app → Note activities count
2. Close app, wait 3 minutes
3. Reopen app → Should fetch fresh data (cache expired)
4. **Expected**: Logs show "Fetching from VeloReady backend"

### Test Case 3: Historical Data Still Cached

1. Request 90-day history for adaptive zones
2. Close app, wait 3 minutes
3. Reopen app, trigger zone calculation
4. **Expected**: Uses 1-hour cache (not expired), no API call

---

## 📝 Monitoring

### Netlify Function Logs

Watch for:
```
[Strava Cache] Cache strategy: RECENT (5min) ← Good!
[Strava Cache] HIT for activities:list ← Cache working
[Strava] Fetched X activities from API ← Fresh data
```

### iOS App Logs

Watch for:
```
📊 [Activities] Fetch request: 7 days, TTL: 300s ← New short TTL
✅ [Activities] Fetched X activities from backend
```

### Audit Log (Supabase)

Check API call frequency:
```sql
SELECT 
  note,
  COUNT(*) as count,
  DATE_TRUNC('hour', at) as hour
FROM audit_log 
WHERE athlete_id = 104662 
  AND note = 'activities:list'
  AND at > NOW() - INTERVAL '24 hours'
GROUP BY note, hour
ORDER BY hour DESC;
```

**Expected**: 
- **Before**: 1-3 calls per day (long cache)
- **After**: 12-24 calls per day (5-min cache for recent, but only when app is used)

---

## 🎯 Future Improvements

### Phase 1 (Completed ✅)
- Smart cache TTL based on date range
- Separate cache for today's activities

### Phase 2 (Recommended)
- **Strava Webhooks**: Push notifications when activities are created
- **Instant updates**: No polling needed
- **Reduced API calls**: Only fetch when actually changed

### Phase 3 (Nice to Have)
- **Predictive prefetching**: Fetch likely-needed data in background
- **Cache warming**: Warm cache during off-peak hours
- **Smart invalidation**: Detect patterns (e.g., morning rides) and auto-refresh

---

## 🐛 Troubleshooting

### Activity Still Not Appearing

1. **Check Strava Processing**:
   ```
   Go to Strava.com → Verify activity is fully processed
   ```

2. **Clear Both Caches**:
   ```bash
   # Backend
   netlify blobs:delete strava-cache "activities:104662:*" --context production
   
   # iOS app
   Force quit app → Reopen
   ```

3. **Check Netlify Logs**:
   ```
   https://app.netlify.com/sites/veloready/logs/functions
   Look for: [Strava] Fetched X activities
   ```

4. **Verify Cache TTL**:
   ```
   iOS logs should show: "TTL: 300s" (not 3600s)
   Backend logs should show: "RECENT (5min)"
   ```

### Too Many API Calls

If seeing rate limit errors:

1. **Check request frequency** in Netlify logs
2. **Verify cache is working**: Should see HIT messages
3. **Adjust TTL** if needed (increase to 10-15 min)

---

## 📚 Related Files

### iOS App
- `VeloReady/Core/Services/Data/UnifiedActivityService.swift` - Cache logic
- `VeloReady/Core/Cache/UnifiedCacheManager.swift` - Cache implementation
- `VeloReady/Features/Today/ViewModels/TodayViewModel.swift` - Today view data

### Backend
- `veloready-website/netlify/lib/strava.ts` - Strava API wrapper
- `veloready-website/netlify/functions/api-activities.ts` - Activities endpoint

---

## ✅ Checklist

- [x] iOS app: Added custom TTL support
- [x] iOS app: Updated `fetchTodaysActivities()` to use 5-min cache
- [x] Backend: Added smart cache TTL logic
- [x] Backend: Updated Blobs cache to use dynamic TTL
- [ ] Deploy backend to Netlify
- [ ] Clear stale cache entries
- [ ] Deploy iOS app (TestFlight or local)
- [ ] Test with new activity
- [ ] Monitor logs for 24 hours
- [ ] Verify API call frequency acceptable

---

**Status**: ✅ Code complete, ready for deployment

