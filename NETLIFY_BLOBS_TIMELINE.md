# Netlify Blobs Timeline - Why and When

**Date:** November 13, 2025  
**Purpose:** Understanding the Blobs implementation and its issues

---

## 📅 Timeline

### **October 18, 2025: Original Implementation**

**Commit:** `c5f07d5` - "Add centralized API endpoints for activities and streams"

**Why Blobs was added:**
- Part of "Phase 1: Backend API Centralization"
- Goal: Move all Strava API calls from iOS app to backend
- Implement proper caching to reduce Strava API usage
- Prepare for rate limiting and monitoring

**Original Design:**
```typescript
// api-streams.ts - STREAMS endpoint
const store = getStore("streams-cache");
const cached = await store.get(cacheKey, { type: "json" });
if (cached) {
  return cached; // 24-hour cache
}

// Fetch from Strava, then cache
await store.setJSON(cacheKey, streams, {
  metadata: { athleteId, activityId, cachedAt: Date.now() }
});
```

**Why Blobs for streams:** ✅ CORRECT CHOICE
- Streams are **immutable** (never change after creation)
- Large payloads (100KB-1MB per activity)
- 24-hour backend cache + 7-day iOS cache = optimal
- Stays compliant with Strava's 7-day caching rule

**Result:** ✅ Streams caching worked perfectly!

---

### **October 18-28, 2025: Blobs Issues**

**Multiple bug-fix commits:**
- `99f1e5b` - "Fix: Pass siteID and token explicitly to getStore"
- `e42c908` - "Use environment variables for Netlify Blobs authentication"
- `6b2a40b` - "Try NETLIFY_FUNCTIONS_TOKEN as fallback for Blobs"
- `bd77a67` - "Fix: Use text type for blob store get to prevent JSON parse errors"
- `37a9788` - "fix: Backend URL parsing error in Netlify Blobs initialization"

**Issues encountered:**
- Authentication errors with Blobs
- URL parsing problems with environment variables
- JSON serialization issues

**Resolution:** Eventually got Blobs working with proper environment setup

---

### **October 28, 2025: Extended Blobs to Activities**

**Commit:** `c5d3595` - "Strava cache fix"

**What changed:**
- Extended Blobs usage from JUST streams to ALSO activities
- Added Blobs caching to `listActivitiesSince()` in `strava.ts`

**Code added:**
```typescript
// listActivitiesSince() in strava.ts
const blobStore = getStore({ name: "strava-cache" });
const cached = await blobStore.get(cacheKey, { type: "text" });
if (cached) {
  return JSON.parse(cached); // Return cached activities
}

// Fetch from Strava, then cache
await blobStore.set(cacheKey, JSON.stringify(data), { metadata: { ttl: cacheTTL } });
```

**Why this was added:**
- Trying to reduce Strava API calls
- Thought Blobs would provide better cache control than Edge Cache
- Wanted programmatic cache invalidation capability

**The Fatal Flaw:** ❌
- **Netlify Blobs `ttl` metadata does NOT auto-expire!**
- The code set `{ metadata: { ttl: cacheTTL } }` but never checked it
- Blobs stayed cached indefinitely, serving stale data

---

### **November 13, 2025: The Strava Cache Fix (First Attempt)**

**Commit:** Earlier today (documented in `STRAVA_DATA_CACHE_FIX_NOV13.md`)

**Problem:** "4 x 9" ride from morning not appearing in app

**Fix implemented:**
- Added "smart cache TTL" logic: 5 min for recent, 1 hour for old
- Updated iOS app to use 5-minute cache for today's activities
- Updated backend to set different TTLs based on date range

**Code:**
```typescript
const now = Math.floor(Date.now() / 1000);
const sevenDaysAgo = now - (7 * 24 * 3600);
const isRecentActivities = afterEpochSec >= sevenDaysAgo;
const cacheTTL = isRecentActivities ? 300 : 3600; // 5 min vs 1 hour

await blobStore.set(cacheKey, JSON.stringify(data), { metadata: { ttl: cacheTTL } });
```

**The Problem:** ❌
- Still no expiration logic!
- Code SETS the TTL metadata but never CHECKS or DELETES expired blobs
- Blob from Nov 6 stayed cached, returned on Nov 13 with wrong dates

---

### **November 13, 2025: Today - Root Cause Discovery**

**Discovery:**
- From logs: `'4 x 9' - startDateLocal: '2025-11-06T20:34:07Z'` ← Nov 6 date!
- Netlify Blobs documentation: **TTL is metadata only, not automatic expiration**
- Backend never implemented manual expiration check

**Why it worked before Oct 28:**
- ✅ **Streams endpoint:** Large immutable data, 24h cache is fine
- ✅ **Edge Cache only:** Automatic expiration via Cache-Control headers
- ✅ **No Blobs on activities:** Edge Cache handled everything

**Why it broke after Oct 28:**
- ❌ Added Blobs to activities without implementing expiration logic
- ❌ Blobs never deleted, served stale data indefinitely
- ❌ Defeated the automatic Edge Cache expiration

---

## 🎯 Design Philosophy: What Went Wrong

### **Streams Endpoint: ✅ Correct Use of Blobs**

**Why Blobs is GOOD for streams:**
- ✅ Streams are **immutable** - never change
- ✅ Large payloads (100KB-1MB) - worth caching
- ✅ Long TTL (24 hours) is fine
- ✅ Manual management acceptable for rare edge cases

**Code pattern:**
```typescript
// GOOD: Blobs for large, immutable data
const cached = await store.get(cacheKey, { type: "json" });
if (cached) return cached;

const streams = await fetchFromStrava();
await store.setJSON(cacheKey, streams);
return streams;
```

**Result:** ✅ Works perfectly, no issues

---

### **Activities Endpoint: ❌ Wrong Use of Blobs**

**Why Blobs is BAD for activities:**
- ❌ Activities are **dynamic** - new ones added frequently
- ❌ Small payloads (5KB-20KB) - Edge Cache is fine
- ❌ Short TTL (5 min) requires frequent expiration
- ❌ Manual expiration logic adds complexity
- ❌ Edge Cache does this automatically!

**What was needed:**
```typescript
// WRONG: Manual cache with metadata TTL (not enforced)
await blobStore.set(cacheKey, data, { metadata: { ttl: 300 } });

// RIGHT: Let Edge Cache handle it automatically
return {
  statusCode: 200,
  headers: { 'Cache-Control': 'public, max-age=300' },
  body: JSON.stringify(activities)
};
```

**Result:** ❌ Stale data bugs, unnecessary complexity

---

## 📊 Comparison: Blobs vs Edge Cache

| Feature | Blobs | Edge Cache | Winner for Activities |
|---------|-------|------------|----------------------|
| **Auto Expiration** | ❌ No (manual only) | ✅ Yes (Cache-Control) | Edge Cache |
| **Global CDN** | ❌ Single region | ✅ Yes | Edge Cache |
| **Setup Complexity** | ⚠️ Code + env vars | ✅ Just headers | Edge Cache |
| **Expiration Logic** | ❌ Must implement | ✅ Automatic | Edge Cache |
| **Cost** | ✅ Free (1GB) | ✅ Free (included) | Tie |
| **Best For** | Large, immutable data | Small, dynamic data | Edge Cache |

---

## ✅ Correct Architecture (Back to Original)

### **Streams: Keep Blobs** ✅

```typescript
// api-streams.ts - NO CHANGES NEEDED
const store = getStore("streams-cache");
const cached = await store.get(cacheKey, { type: "json" });
if (cached) return cached; // 24h cache is fine for immutable data
```

**Why:** Streams are immutable, large, and rarely accessed. Blobs is perfect.

---

### **Activities: Use Edge Cache** ✅

```typescript
// strava.ts - REMOVE Blobs logic
export async function listActivitiesSince(athleteId: number, afterEpochSec: number, page: number, perPage = 200) {
  // Just fetch from Strava - no manual caching!
  const result = await withStravaAccess(athleteId, async (token) => {
    const url = `https://www.strava.com/api/v3/athlete/activities?after=${afterEpochSec}&page=${page}&per_page=${perPage}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` }});
    if (res.ok) {
      await logApiCall(athleteId, 'activities:list');
      return res.json();
    }
    throw new Error(`Strava API returned ${res.status}`);
  });
  return result;
}

// api-activities.ts - Let Edge Cache handle it
return {
  statusCode: 200,
  headers: {
    'Cache-Control': 'public, max-age=300',  // 5 minutes - automatic expiration!
  },
  body: JSON.stringify(activities)
};
```

**Why:** Activities are dynamic, small, and frequently updated. Edge Cache is perfect.

---

## 📝 Lessons Learned

### **When to Use Netlify Blobs:**
- ✅ Large payloads (> 100KB)
- ✅ Immutable data (never changes)
- ✅ Long cache times (hours/days)
- ✅ Need programmatic invalidation
- ✅ Willing to implement expiration logic

**Examples:**
- ✅ Activity streams (power, HR, cadence data)
- ✅ Pre-computed power curves
- ✅ User-uploaded files
- ✅ Historical aggregations

---

### **When to Use Edge Cache:**
- ✅ Small payloads (< 100KB)
- ✅ Dynamic data (changes frequently)
- ✅ Short cache times (minutes)
- ✅ Want automatic expiration
- ✅ Want global CDN distribution

**Examples:**
- ✅ Activity lists
- ✅ User profiles
- ✅ Wellness data
- ✅ Training load metrics

---

### **When to Use BOTH:**
- ✅ Multi-layer caching strategy
- ✅ Different TTLs for client vs server
- ✅ Offline-first iOS app design

**Example (Streams):**
```
iOS App: 7-day cache (offline support)
    ↓
Edge Cache: 24-hour cache (fast CDN)
    ↓
Netlify Blobs: Long-term cache (reduce API calls)
    ↓
Strava API: Origin (only if all caches miss)
```

---

## 🎯 Summary

### **Why Blobs was Added:**
- October 18: For streams (✅ GOOD - immutable, large data)
- October 28: Extended to activities (❌ BAD - dynamic, small data)

### **What Went Wrong:**
- Blobs TTL metadata is **not automatic expiration**
- Code never implemented expiration checking/deletion
- Blobs cached data indefinitely, served stale dates

### **The Fix:**
- ✅ **Keep Blobs for streams** (working perfectly)
- ✅ **Remove Blobs from activities** (use Edge Cache)
- ✅ **Back to original Oct 18 design** (proven to work)

### **Key Insight:**
**Your original architecture was brilliant.** The mistake was extending Blobs to activities without understanding that TTL is metadata-only. Edge Cache handles expiration automatically - trust it!

---

## 📚 Related Documents

- `BACKEND_CACHE_FIX.md` - Exact code changes to fix
- `STALE_CACHE_ROOT_CAUSE_ANALYSIS.md` - Deep technical analysis
- `API_AND_CACHE_STRATEGY_REVIEW.md` - Original architecture (was correct!)
- `STRAVA_DATA_CACHE_FIX_NOV13.md` - First attempt (partial fix)

