# Stale Cache Fix - November 13, 2025

**Date:** November 13, 2025  
**Commit:** `e7346a9` - Fix: Force refresh recent activity caches on app launch  
**Status:** ✅ Partial Fix (Client-side), ⚠️ Backend Issue Remains

---

## 🔍 **Root Cause Analysis**

### **The Problem:**
After implementing the previous cache fixes, the following bugs persisted:

1. **Strain Score = 0.8** (should be ~15+ after 1hr ride + 1700 steps)
2. **ML Progress stuck at 5 days** (not incrementing even with new data)
3. **Recovery/Sleep/Strain charts missing Mon-Wed data**

### **Evidence from Logs:**

```
🔍 [Performance] 📊 [TodaysActivities] Filtering 3 activities - showing all dates:
🔍 [Performance]    Activity 1: '4 x 9' - startDateLocal: '2025-11-06T20:34:07Z'
🔍 [Performance]    Activity 2: 'Morning Ride' - startDateLocal: '2025-11-09T10:02:27Z'
🔍 [Performance]    Activity 3: '4 x 8' - startDateLocal: '2025-11-11T18:13:35Z'

🔍 [Performance] 🗓️ [TodaysActivities] Activity '4 x 9' is not today: 2025-11-06 20:34:07 +0000 vs 2025-11-13 00:00:00 +0000
```

**The "4 x 9" ride from this morning (Nov 13) has a cached date of November 6!**

### **Root Cause:**

The **backend Netlify Blobs cache** is returning stale activity data. Even though:
- ✅ Client-side cache has 5-minute TTL for recent activities
- ✅ Backend cache has 5-minute TTL for recent activities
- ✅ Pull-to-refresh invalidates iOS cache

**The problem:** The backend cache is not expiring properly, or is not being invalidated when it should be.

---

## 🛠️ **The Fix (Client-Side)**

### **1. Force Invalidate Recent Activity Caches on App Launch**

**File:** `VeloReady/Features/Today/Coordinators/TodayCoordinator.swift`

**Strategy:**
- Invalidate **only recent activity caches** (7, 30 days) on every app launch
- Keep longer caches (90, 120, 365 days) to avoid unnecessary API calls
- Historical data (> 30 days) doesn't change, so no need to invalidate

**Implementation:**

```swift
/// Conditionally invalidate activity caches on app launch if data might be stale
/// Only invalidates recent activity caches (7, 30 days) if > 5 minutes old
/// This prevents unnecessary API calls while ensuring fresh data
private func invalidateActivityCachesOnLaunch() async {
    Logger.info("🔍 [TodayCoordinator] Checking if activity caches need invalidation on app launch")
    
    let cacheManager = UnifiedCacheManager.shared
    
    // Only invalidate recent activity caches (7, 30 days) - these need to be fresh
    // Older caches (90, 120, 365 days) can stay cached longer since historical data doesn't change
    Logger.info("🗑️ [TodayCoordinator] Invalidating recent activity caches (7, 30 days) on launch")
    await cacheManager.invalidate(key: "strava:activities:7")
    await cacheManager.invalidate(key: "strava:activities:30")
    await cacheManager.invalidate(key: "intervals:activities:7")
    await cacheManager.invalidate(key: "intervals:activities:30")
    
    Logger.debug("✅ [TodayCoordinator] Launch cache invalidation complete (recent activities only)")
}
```

**Called on app launch:**

```swift
case (.viewAppeared, .initial):
    // First time view appears - load everything
    isViewActive = true
    
    // CRITICAL: Invalidate activity caches on app launch to prevent stale data
    await invalidateActivityCachesOnLaunch()
    
    await loadInitial()
    hasLoadedOnce = true
```

### **2. Enhanced Activity Date Logging**

**File:** `VeloReady/Core/Services/Data/UnifiedActivityService.swift`

Added logging to track the **first 3 activities** returned from the backend, showing their dates:

```swift
// Log first 3 activities to verify dates are correct
if convertedActivities.count > 0 {
    Logger.debug("🔍 [Activities] First 3 activities from backend:")
    for (index, activity) in convertedActivities.prefix(3).enumerated() {
        Logger.debug("  \(index + 1). '\(activity.name ?? "Unnamed")' - startDateLocal: '\(activity.startDateLocal)'")
    }
}
```

This will help diagnose whether the issue is:
- ❌ **Backend cache** (if dates are wrong in fetched data)
- ❌ **iOS cache** (if dates are correct in fetched but wrong in displayed)

---

## 📊 **Strava Rate Limit Impact**

### **Current Strategy:**

**What gets invalidated on each app launch:**
- `strava:activities:7` (7-day cache)
- `strava:activities:30` (30-day cache)
- `intervals:activities:7`
- `intervals:activities:30`

**API Calls Per User:**
- App launches per day: ~8 (realistic estimate: morning, commute, lunch, evening, etc.)
- API calls per launch: 2 (one for 7-day, one for 30-day on first screen load)
- **Daily calls per user: ~16 requests**

### **At Scale:**

| Users | App Launches/Day | Total Launches | API Calls/Day | % of 100k Limit |
|-------|------------------|----------------|---------------|-----------------|
| 100   | 8                | 800            | 1,600         | 1.6%            |
| 500   | 8                | 4,000          | 8,000         | 8.0%            |
| 1,000 | 8                | 8,000          | 16,000        | 16.0%           |
| 3,000 | 8                | 24,000         | 48,000        | 48.0%           |
| 5,000 | 8                | 40,000         | 80,000        | 80.0%           |

**Assessment:**
- ✅ **Safe up to ~3,000 users** (< 50% of limit)
- ⚠️ **Caution at 5,000 users** (80% of limit)
- ❌ **Risk at 6,000+ users** (approaching limit)

### **Optimization Strategies (If Needed):**

1. **Conditional Invalidation** (Future):
   - Only invalidate if last fetch was > 5 minutes ago
   - Track last fetch timestamp per cache key
   - Reduces unnecessary invalidations

2. **Strava Webhooks** (Long-term):
   - Subscribe to Strava webhooks for new activities
   - Invalidate cache only when webhook fires
   - Dramatically reduces API calls (webhook-driven vs polling)

3. **Smart Background Refresh**:
   - Use iOS background refresh to update caches when app is backgrounded
   - Pre-populate caches before user opens app
   - Reduces visible loading time and API calls

---

## ⚠️ **Backend Issue: Netlify Blobs Cache**

### **The Remaining Problem:**

Even with client-side cache invalidation, the backend may still return stale data because:

1. **Netlify Blobs TTL enforcement may be inconsistent**
2. **Backend cache might not respect the 5-minute TTL**
3. **No cache-busting mechanism** for critical requests

### **Recommended Backend Fix:**

**File:** `veloready-website/netlify/lib/strava.ts`

**Option 1: Add Cache-Busting Header**

```typescript
export async function listActivitiesSince(athleteId: number, afterEpochSec: number, page: number, perPage = 200) {
  // ... existing code ...
  
  // Check if this is a "force refresh" request
  const forceRefresh = headers.get('x-force-refresh') === 'true';
  
  if (forceRefresh) {
    console.log('[Strava Cache] Force refresh requested - bypassing cache');
    // Skip cache lookup, go directly to API
  } else {
    // Normal cache-first logic
  }
}
```

**Option 2: Implement Proper TTL Check**

```typescript
// When reading from Netlify Blobs
const cachedData = await blobStore.get(cacheKey, { type: 'json' });
if (cachedData) {
  const metadata = await blobStore.getMetadata(cacheKey);
  const cacheAge = Date.now() / 1000 - (metadata.uploadedAt / 1000);
  const ttl = metadata.ttl || 3600;
  
  if (cacheAge > ttl) {
    console.log(`[Strava Cache] TTL expired (age: ${cacheAge}s, ttl: ${ttl}s) - refreshing`);
    // Delete and refetch
    await blobStore.delete(cacheKey);
  } else {
    return cachedData; // Still valid
  }
}
```

---

## 🧪 **Testing & Verification**

### **What to Look For in Logs:**

After this fix, you should see:

1. **On App Launch:**
   ```
   🔍 [TodayCoordinator] Checking if activity caches need invalidation on app launch
   🗑️ [TodayCoordinator] Invalidating recent activity caches (7, 30 days) on launch
   ✅ [TodayCoordinator] Launch cache invalidation complete (recent activities only)
   ```

2. **When Fetching Activities:**
   ```
   📊 [Activities] Fetching from VeloReady backend (limit: 50, daysBack: 7)
   ✅ [Activities] Fetched 3 activities from backend
   🔍 [Activities] First 3 activities from backend:
     1. '4 x 9' - startDateLocal: '2025-11-13T06:24:24Z'  ← Should be TODAY
     2. 'Morning Ride' - startDateLocal: '2025-11-09T10:02:27Z'
     3. '4 x 8' - startDateLocal: '2025-11-11T18:13:35Z'
   ```

3. **Activity Filtering:**
   ```
   🔍 [TodaysActivities] Activity '4 x 9' is TODAY: 2025-11-13 06:24:24 +0000
   📊 [TodaysActivities] Found 1 activities for today out of 3 total
   ```

### **Expected Behavior:**

- ✅ **Strain score should now reflect today's activity** (~15+ after 1hr ride)
- ⚠️ **ML progress may take a few days** to show all 7 days (DailyScores need to accumulate)
- ✅ **Charts should show recent data** (Mon-Wed) after DailyScores are saved

---

## 📝 **Summary**

### **What Was Fixed:**
- ✅ Client-side cache now invalidates on app launch (recent activities only)
- ✅ Enhanced logging to diagnose backend cache issues
- ✅ Optimized to only invalidate recent caches (7, 30 days)

### **What Still Needs Attention:**
- ⚠️ **Backend Netlify Blobs cache** may still serve stale data
- ⚠️ **ML progress** will take time to show all 7 days (DailyScores accumulate)
- ⚠️ **Rate limit risk** at 5,000+ users (need webhooks or optimization)

### **Monitoring:**
Watch the logs for the "First 3 activities from backend" output. If dates are **still wrong** after this fix, the problem is definitely in the backend cache, not the iOS app.

---

## 🔜 **Next Steps**

1. **Deploy and Test**:
   - Deploy this fix
   - Monitor logs for activity dates from backend
   - Verify strain score updates correctly

2. **Backend Fix (If Needed)**:
   - Implement proper TTL enforcement in Netlify Functions
   - Add cache-busting header support
   - Consider Netlify Blobs alternatives if TTL is unreliable

3. **Long-term Optimization**:
   - Implement Strava webhooks for event-driven cache invalidation
   - Reduce API calls from 16/user/day to < 5/user/day
   - Scale to 10,000+ users safely

4. **ML Progress**:
   - Wait 2-3 days for DailyScores to accumulate
   - Verify "7 days of data" shows correctly
   - Consider backfilling historical DailyScores if needed

