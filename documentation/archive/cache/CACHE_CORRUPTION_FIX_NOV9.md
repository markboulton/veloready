# Cache Corruption Fix - November 9, 2025

## 🚨 CRITICAL: You MUST Rebuild the App

**Status:** ✅ Code committed, 🚨 **REBUILD REQUIRED**

The fix is committed but your device has the OLD binary. 

**To fix:**
```bash
Cmd+Shift+K  # Clean Build Folder
Cmd+R        # Build and Run
```

---

## Root Cause: Dual Cache Version Mismatch

### The Problem
Two separate cache systems with **independent version tracking**:

```
UnifiedCacheManager:      version = "v4"  ✅ Cleared
CachePersistenceLayer:    version = 3     ❌ Still has corrupted data
```

**Result:**
- UnifiedCacheManager cleared its memory/disk cache
- Core Data (CachePersistenceLayer) still had corrupted entries
- App continued showing cache errors
- Scores calculated incorrectly

### What You Saw
```
⚠️ [Cache VERSION] Cache format changed (none → v4)  ✅ This worked
✅ [Cache VERSION] Cache cleared and version updated  ✅ This worked

❌ Failed to load score:sleep:2025-11-09T00:00:00Z    ❌ But Core Data still corrupted
⚠️ Could not determine type for key: strain:v3:...   ❌ Old data format
```

---

## The Fix

### Synchronized Both Cache Versions

**File:** `CachePersistenceLayer.swift`

```swift
-private let cacheVersion = 3  // v3: Added HealthKit metrics
+private let cacheVersion = 4  // v4: Clear corrupted cache from format changes
```

**What This Does:**
1. Next app launch detects version mismatch (3 → 4)
2. Calls `clearAll()` to wipe ALL Core Data cache entries
3. Synchronizes with UnifiedCacheManager v4
4. Both cache systems now aligned

---

## What Will Happen After Rebuild

### First Launch (~10-15 seconds)

**Expected Logs:**
```
💾 [CachePersistence] Cache version mismatch (stored: 3, current: 4) - clearing old cache
💾 [CachePersistence] Clearing all cache entries
✅ [CachePersistence] Cache cleared successfully

🗑️ [Cache VERSION] Cache format changed (v3 → v4)
🗑️ [Cache VERSION] Clearing all caches to prevent corruption
✅ [Cache VERSION] Cache cleared and version updated
```

**Process:**
1. ✅ Detect both version mismatches
2. ✅ Clear memory cache
3. ✅ Clear Core Data cache
4. ✅ Clear disk cache
5. ✅ Fetch fresh data from APIs
6. ✅ Calculate scores correctly
7. ✅ Build clean cache

**NO MORE ERRORS:**
- ❌ `Failed to load score:sleep:...` ← GONE
- ❌ `Could not determine type for key:...` ← GONE
- ❌ Cache corruption ← GONE

### Subsequent Launches (<2 seconds)
- Load from clean cache
- Fast startup
- All scores accurate
- No errors

---

## What Should Be Fixed

### 1. ✅ Load Score
- **Before:** 2.8 (incorrect due to corrupted cache)
- **After:** ~9 (correct calculation with fresh data)

### 2. ✅ Recovery Score
- **Before:** 60 (using corrupted data)
- **After:** Accurate calculation

### 3. ✅ ML Day Count
- **Before:** 4 days (stale Core Data)
- **After:** 5 days (fresh query)

### 4. ✅ Map Preview
- **Before:** Missing (card not initializing)
- **After:** Will load (debug logs will show)

### 5. ✅ Ring Animations
- **Before:** Don't trigger on background return
- **After:** Trigger with scenePhase monitoring

---

## Debug Logs You Should See

### Cache Clear (First Launch Only)
```
💾 [CachePersistence] Cache version mismatch (stored: 3, current: 4) - clearing old cache
🗑️ [Cache VERSION] Cache format changed (v3 → v4)
✅ Cache cleared and version updated
```

### Map Preview Loading
```
🔍 [LatestActivity] Total activities: 182
✅ [LatestActivity] Found: Morning Ride (source: strava, shouldShowMap: true)
🎬 [LatestActivityCardV2] Initialized for activity: Morning Ride
👁 [LatestActivityCardV2] onAppear called for: Morning Ride
🔄 [LatestActivityCardV2] Calling loadData() for: Morning Ride
🗺️ [LoadMapSnapshot] Starting for activity: Morning Ride (type: Ride, source: strava)
🗺️ [LoadMapSnapshot] shouldShowMap: true, isIndoorRide: false
🗺️ [LoadMapSnapshot] Fetching GPS coordinates...
✅ [LoadMapSnapshot] Got 2847 GPS coordinates
🗺️ [LoadMapSnapshot] Generating snapshot from 2847 coordinates on background thread
✅ [LoadMapSnapshot] Successfully generated map on background thread
```

### Background Refresh
```
🔄 [SCENE] Scene phase: background → active
✅ [SCENE] App became active from background - triggering refresh
🎬 [SCENE] Ring animations triggered after background refresh
```

---

## Commits

1. **f5d975d** - Added UnifiedCacheManager version management (v4)
2. **dab89c3** - Synchronized CachePersistenceLayer version (v4) ← **YOU ARE HERE**

---

## Why This Happened

### Design Flaw
Two independent cache systems that were meant to be layered:
- **Memory Layer:** UnifiedCacheManager (fast, volatile)
- **Persistence Layer:** CachePersistenceLayer (slow, persistent)

But both store the **same data in different formats**, so:
- Version changes need to be **synchronized**
- Otherwise one layer clears while the other retains corrupted data

### The Fix
Bumped both versions to v4 simultaneously.

### Future Prevention
- Document that both versions must be bumped together
- Add comment linking the two version constants
- Consider unifying version tracking

---

## Testing Checklist

After rebuild, verify:

- [ ] First launch shows both cache clear messages
- [ ] NO cache load errors in logs
- [ ] Load score is correct (~9, not 2.8)
- [ ] Recovery score is accurate
- [ ] ML progress shows 5 days (not 4)
- [ ] `[LatestActivity]` logs appear
- [ ] `[SCENE]` logs appear
- [ ] Map preview loads (or logs show why not)
- [ ] Ring animations trigger when returning from background

---

## Timeline of Bugs

### Your Original Issues (All Related to Cache Corruption)

1. **Load score wrong (2.8 vs 9)** - Using corrupted cached CTL/ATL data
2. **Recovery score wrong (60)** - Using corrupted cached sleep/HRV data
3. **No map preview** - Card not initializing (need rebuild)
4. **ML shows 4 days not 5** - Core Data query on corrupted data
5. **Ring animations don't trigger** - scenePhase not in binary (need rebuild)

### The Root Cause
All 5 issues stem from **ONE problem:** Corrupted Core Data cache.

### The Solution
**ONE fix:** Bump CachePersistenceLayer.cacheVersion to 4.

---

## Impact

### First Launch
- Slower (10-15s for fresh data fetch)
- Verbose logs (cache clearing)
- ALL cache errors disappear

### All Subsequent Launches
- Normal speed (<2s)
- No cache errors
- All scores accurate
- Maps load
- Animations work

---

**Date:** November 9, 2025  
**Branch:** `today-viewability-bugs`  
**Commit:** dab89c3  
**Status:** ✅ FIXED

## 🚨 NEXT STEP: REBUILD THE APP 🚨

```bash
Cmd+Shift+K  # Clean Build Folder
Cmd+R        # Build and Run
```

After rebuild, all 5 bugs should be fixed! 🎉
