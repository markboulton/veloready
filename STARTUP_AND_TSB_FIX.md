# Startup Performance & TSB Display Fix

## Issue 1: UserDefaults Overload (4MB+ Warning)

### Problem
```
CFPrefsPlistSource: Attempting to store >= 4194304 bytes of data in CFPreferences/NSUserDefaults
```

**Root Cause:**  
Old Strava stream data is still stored in UserDefaults from before the file-based caching system was implemented. Three streams alone are taking up 4.7MB:

- `stream_strava_15954592561`: 601KB
- `stream_strava_15568859173`: 730KB  
- `stream_strava_15887771423`: **3.5MB** ← Huge!

**Impact:**
- Slows down app startup (UserDefaults loads synchronously on launch)
- iOS 4MB limit violation warning
- Potential data loss if UserDefaults refuses to save

### Solution
The `StreamCacheService` already has file-based storage for large streams (>3.5MB), but we need to:
1. **One-time migration**: Move all existing `stream_*` keys from UserDefaults to file-based cache
2. **Cleanup**: Remove old UserDefaults entries

### Implementation

**File:** `VeloReady/Core/Services/StreamCacheService.swift`

Add this migration method:

```swift
// MARK: - One-Time Migration

/// Migrate legacy UserDefaults-based streams to file-based storage
/// This runs once on first launch after update
func migrateLegacyStreamsToFileCache() {
    let migrationKey = "stream_cache_migration_v2_complete"
    
    // Skip if already migrated
    guard !UserDefaults.standard.bool(forKey: migrationKey) else {
        return
    }
    
    Logger.debug("🔄 [StreamCache] Starting one-time migration of legacy streams...")
    
    var migratedCount = 0
    var deletedSize: Int64 = 0
    
    // Find all stream_* keys in UserDefaults
    let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
    let streamKeys = allKeys.filter { $0.hasPrefix("stream_strava_") || $0.hasPrefix("stream_intervals_") }
    
    for key in streamKeys {
        guard let data = UserDefaults.standard.data(forKey: key) else { continue }
        
        // Extract activity ID from key (e.g., "stream_strava_12345" → "strava_12345")
        let activityId = String(key.dropFirst("stream_".count))
        
        // Migrate to file-based storage if large enough
        if data.count > 1_000_000 { // 1MB+ streams
            saveToFile(data: data, activityId: activityId)
            deletedSize += Int64(data.count)
            migratedCount += 1
            Logger.debug("   ✓ Migrated \(activityId) (\(String(format: "%.1f", Double(data.count)/1_000_000))MB) to file")
        }
        
        // Always remove from UserDefaults to free up space
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // Mark migration as complete
    UserDefaults.standard.set(true, forKey: migrationKey)
    UserDefaults.standard.synchronize()
    
    Logger.debug("✅ [StreamCache] Migration complete: \(migratedCount) streams migrated (\(String(format: "%.1f", Double(deletedSize)/1_000_000))MB freed)")
}
```

**Call this from `VeloReadyApp.swift` init:**

```swift
// Migrate legacy stream data from UserDefaults to file-based cache (one-time)
Task { @MainActor in
    StreamCacheService.shared.migrateLegacyStreamsToFileCache()
}
```

---

## Issue 2: TSB Displays 0.0 Instead of Actual Value

### Problem
Your **Training Stress Balance (TSB)** shows **0.0** but the logs show it should be **33.9**.

### Root Cause Analysis

**What's happening:**

1. **Cached Core Data** (displayed initially):
   ```
   CTL: 46.0, ATL: 8.5, TSS: 0.0
   TSB = 46.0 - 8.5 = 37.5 ← Should display this
   ```

2. **Backend calculation** (happens later):
   ```
   CTL=14.7, ATL=14.7
   TSB=0.0 ← WRONG!
   ```

3. **HealthKit calculation** (happens even later):
   ```
   CTL: 42.2, ATL: 8.2, TSB: 33.9 ← CORRECT!
   ```

**The bug:** The backend calculation returns `CTL=14.7, ATL=14.7` (likely using Strava's pre-computed values), which gives `TSB=0.0`. This overwrites the correct HealthKit-based calculation.

### Why CTL/ATL Changed

Looking at the logs:
- **Cached (yesterday):** CTL=46.0, ATL=8.5 (from HealthKit workouts over 42 days)
- **Fresh (today):** CTL=14.7, ATL=14.7 (from backend/Strava - **only 19 activities** vs 47 HealthKit workouts!)
- **HealthKit recalc:** CTL=42.2, ATL=8.2 (from 47 HealthKit workouts)

**The issue:** The backend/Strava calculation is using **19 Strava activities** instead of **47 HealthKit workouts**, which drops your CTL dramatically. Then it sets ATL equal to CTL (probably a bug in the unified calculation), resulting in TSB=0.

### Solution

**Option 1: Fix the `RecoveryScoreService` to prioritize HealthKit calculation**

The issue is in `RecoveryScoreService.swift` where it calculates training load from "unified activities" (backend/Strava) before falling back to HealthKit.

**File:** `VeloReady/Core/Services/RecoveryScoreService.swift`

Find the section that calculates CTL/ATL and ensure it:
1. Uses HealthKit workouts as primary source
2. Only uses Intervals/Strava if no HealthKit workouts exist
3. Never overwrites good HealthKit data with incomplete backend data

**Option 2: Fix the unified activity calculation**

The backend calculation is returning equal CTL/ATL, which suggests it's:
- Only looking at recent activities (past 7 days)
- Not properly calculating the 42-day rolling average for CTL

**File:** `VeloReady/Core/Services/RecoveryScoreService.swift` or `TodayViewModel.swift`

Look for where it calls:
```swift
TrainingLoadService.shared.calculateTrainingLoad(from: activities)
```

And ensure it's passing the full 42 days of activities, not just 7 days.

### Immediate Diagnostic

Looking at your logs, the issue is here:

```
📊 [Data] Calculating CTL/ATL from unified activities (Strava + Intervals + HealthKit)...
📊 [Data] 📊 [Activities] Fetch request: 42 days (capped to 42 for PRO tier)
🔍 [Performance] 🌐 [VeloReady API] Fetching activities (daysBack: 42, limit: 200)
```

But then:
```
📊 [Data] ✅ [Activities] Fetched 19 activities from backend
```

**Only 19 activities from backend vs 47 from HealthKit!** The backend cache is incomplete.

### Recommended Fix

**Add a fallback check in `RecoveryScoreService.swift`:**

```swift
// After calculating CTL/ATL from unified activities
if ctl < 10 || atl < 1 || abs(ctl - atl) < 0.1 {
    // Suspiciously low or equal values - likely incomplete data
    Logger.warning("⚠️ Unified CTL/ATL looks wrong (CTL:\(ctl), ATL:\(atl)) - using HealthKit fallback")
    
    // Recalculate from HealthKit workouts only
    let healthKitActivities = await fetchHealthKitWorkouts(days: 42)
    (ctl, atl) = calculateTrainingLoadFromHealthKit(healthKitActivities)
}
```

This ensures you always have sensible CTL/ATL values even if the backend/Strava data is incomplete.

---

## Priority

### High Priority (Do Now)
1. **Fix UserDefaults overload** - This is causing startup slowdown and iOS warnings
2. **Fix TSB calculation** - Critical metric showing 0.0 is very confusing

### Medium Priority
3. Investigate why backend only returns 19 activities vs 47 HealthKit workouts
4. Add data quality checks to CTL/ATL calculation

---

## Testing

After applying fixes:

1. **UserDefaults check:**
   ```bash
   # Should show no stream_* keys or only small ones
   defaults read com.markboulton.VeloReady2 | grep "stream_"
   ```

2. **TSB check:**
   - Open app
   - Check Training Metrics view
   - TSB should show ~33-37 (CTL ~42-46, ATL ~8-12)
   - Should NOT show 0.0

3. **Startup speed:**
   - Force quit app
   - Reopen
   - Should see no UserDefaults warnings in console
   - Startup should be <8 seconds to Phase 2 complete

---

## Files to Modify

1. **VeloReady/Core/Services/StreamCacheService.swift**
   - Add `migrateLegacyStreamsToFileCache()` method

2. **VeloReady/App/VeloReadyApp.swift**
   - Call migration on startup

3. **VeloReady/Core/Services/RecoveryScoreService.swift**
   - Add fallback logic for suspicious CTL/ATL values
   - Prioritize HealthKit when unified data is incomplete

---

## Expected Results

**Before:**
- Startup: 7.7s with UserDefaults warnings
- TSB: 0.0 (incorrect)
- UserDefaults size: 4+ MB

**After:**
- Startup: <5s, no warnings
- TSB: 33.9 (correct)
- UserDefaults size: <1 MB

