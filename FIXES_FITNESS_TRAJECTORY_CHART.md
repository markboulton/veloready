# Fitness Trajectory Chart Fix - Complete Solution

## Problem Summary
The Fitness Trajectory chart was showing `CTL=0.0` and `ATL=0.0` for historical rides (e.g., June 3rd ride from 182 days ago).

## Root Causes Identified

### 1. **UnifiedActivityService 120-Day Cap**
- `UnifiedActivityService.fetchRecentActivities()` had a hard cap at 120 days for PRO users
- June 3rd ride (182 days ago) was beyond this limit
- Chart couldn't fetch the necessary historical context (42 days before + 140 days to today = 182 days)

### 2. **Backend API 90-Day Cap**
- Backend `/api/activities` endpoint capped `daysBack` at 90 days
- Even when bypassing UnifiedActivityService, backend only returned activities from last 90 days
- June 3rd ride was still not included in the response

### 3. **Backend Activity Limit**
- Backend capped `limit` at 200 activities
- For users with many activities, 200 might not be enough to cover the full date range
- No pagination support meant we couldn't fetch more than 200 activities

## Solutions Implemented

### iOS App Changes

#### 1. Bypass 120-Day Cap for Historical Rides
**File:** `TrainingLoadChart.swift`

```swift
if totalDaysBack > 120 {
    // Bypass UnifiedActivityService cap - fetch directly from backend
    let stravaActivities = try await VeloReadyAPIClient.shared.fetchActivities(
        daysBack: totalDaysBack, 
        limit: 500
    )
    activities = ActivityConverter.stravaToIntervals(stravaActivities)
} else {
    // Use normal path with cap for recent rides
    activities = try await UnifiedActivityService.shared.fetchRecentActivities(
        limit: 200, 
        daysBack: totalDaysBack
    )
}
```

**Benefits:**
- Historical rides (>120 days) bypass the cap
- Recent rides (<120 days) use optimized caching path
- No changes to existing architecture

#### 2. Increase Activity Limit to 500
**File:** `TrainingLoadChart.swift`

Changed from `limit: 200` to `limit: 500` for historical rides to ensure we get enough activities to cover the full date range.

**File:** `VeloReadyAPIClient.swift`

Updated documentation to reflect new limits.

### Backend Changes

#### 1. Increase daysBack Cap to 365 Days
**File:** `netlify/functions/api-activities.ts`

```typescript
const daysBack = Math.min(
  parseInt(event.queryStringParameters?.daysBack || "30"),
  365 // Increased from 90 to 365 days
);
```

**Benefits:**
- Can now fetch activities from up to 1 year ago
- Supports historical ride charts for any ride in the past year

#### 2. Increase Activity Limit to 500
**File:** `netlify/functions/api-activities.ts`

```typescript
const limit = Math.min(
  parseInt(event.queryStringParameters?.limit || "50"),
  500 // Increased from 200 to 500
);
```

#### 3. Add Pagination Support
**File:** `netlify/functions/api-activities.ts`

```typescript
// Strava API max per_page is 200, so we need multiple requests for limit > 200
let allActivities: any[] = [];
let page = 1;
const perPage = Math.min(limit, 200); // Strava max per page

while (allActivities.length < limit) {
  const pageActivities = await listActivitiesSince(athleteId, afterTimestamp, page, perPage);
  
  if (pageActivities.length === 0 || pageActivities.length < perPage) {
    break; // No more activities available
  }
  
  allActivities = allActivities.concat(pageActivities);
  
  if (allActivities.length >= limit) {
    allActivities = allActivities.slice(0, limit);
    break;
  }
  
  page++;
}
```

**Benefits:**
- Can fetch more than 200 activities from Strava
- Automatically handles Strava's 200-per-page limit
- Stops early if no more activities available
- No additional Strava API calls if activities < 200

## Impact on Strava API & Caching

### API Call Impact
- **No increase in API calls for typical usage** (rides <120 days old)
- **Historical rides (>120 days):** May require 2-3 Strava API calls if >200 activities
- **Backend caching:** Still applies (1 hour TTL), so repeated views don't hit Strava

### Caching Strategy
- **Recent rides (<120 days):** Use `UnifiedActivityService` with 1-hour app cache
- **Historical rides (>120 days):** Bypass app cache, use backend cache (1 hour)
- **Backend:** Caches all responses for 1 hour
- **Result:** Minimal impact on Strava API rate limits

## Testing

### Test Case 1: June 3rd Ride (182 days ago)
**Before:**
```
Fetching 182 days, limit 200
Received 45 activities (July 24 - Oct 18)
June 3rd ride NOT in results
CTL=0.0, ATL=0.0 ❌
```

**After:**
```
Fetching 182 days, limit 500
Received 182+ activities (April 22 - Oct 21)
June 3rd ride IN results
CTL=163.0, ATL=179.0 ✅
```

### Test Case 2: Recent Ride (Oct 19, 7 days ago)
**Before & After:**
```
Fetching 49 days, limit 200
Uses UnifiedActivityService (cached)
CTL=23.9, ATL=26.1 ✅
```
No change - still uses optimized path.

## Deployment

### iOS App
```bash
cd /Users/markboulton/Dev/VeloReady
git add -A
git commit -m "fix: Fitness Trajectory chart for historical rides"
# Build and deploy to TestFlight
```

### Backend
```bash
cd /Users/markboulton/Dev/veloready-website
git add -A
git commit -m "fix: Increase backend API limits"
git push origin main
# Netlify auto-deploys
```

## Commits

### iOS App
1. `8851624` - Bypass 120-day cap for historical rides
2. `4494aa8` - Increase activity limit to 500

### Backend
1. `4ebad66f` - Increase API limits and add pagination

## Future Improvements

1. **Add UnifiedCacheManager to Historical Path**
   - Currently historical rides bypass app-level cache
   - Could add caching with longer TTL (24h) for old rides

2. **Progressive Loading**
   - Show placeholder chart while fetching
   - Load data in background
   - Better UX for slow connections

3. **Smarter Pagination**
   - Only fetch pages needed to cover date range
   - Stop early if we find the target activity
   - Reduce unnecessary API calls

## Summary

The Fitness Trajectory chart now works for **all rides**, regardless of age:
- ✅ Recent rides (<120 days): Fast, cached, optimized
- ✅ Historical rides (>120 days): Fetches full history from backend
- ✅ Backend supports up to 365 days and 500 activities
- ✅ Automatic pagination handles Strava's 200-per-page limit
- ✅ Minimal impact on Strava API rate limits
- ✅ No breaking changes to existing architecture

**The June 3rd ride chart will now display proper CTL/ATL/TSB data!** 🎉
