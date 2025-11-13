# Strain Score Fix: Duration-Based TRIMP Fallback (CORRECT Implementation)

**Date**: November 13, 2024  
**Issue**: Strain score showing 1.7 for a 58-minute indoor ride  
**Root Cause**: Missing fallback for activities without HR data in StrainDataCalculator  
**Solution**: Added duration-based TRIMP estimation as Priority 4 fallback

---

## Problem

User's "4 x 9" indoor ride (58 minutes) was showing a strain score of **1.7** (displayed as **9** on the ring), which was far too low for an hour of cycling.

### Evidence from Logs

```
🔍 [Performance] 🔍 Found 1 unified activities for today (Intervals.icu or Strava)
🔍 [Performance]    Intervals/Strava Duration: 58min
🔍 [Performance] 🔍 Total TRIMP from 1 unified activities: 0.0
```

The activity was found with correct duration, but contributed **0.0 TRIMP** to the strain calculation.

---

## Root Cause Analysis

### The Issue

The TRIMP calculation in **`StrainDataCalculator.swift`** (actor-based calculator) had a priority system:

1. **Priority 1**: Calculate TSS from power + FTP
2. **Priority 2**: Use pre-calculated TSS from activity
3. **Priority 3**: Calculate TRIMP from HR + duration

**BUT**: If none of these data points were available, the activity was **silently skipped** (0 TRIMP).

### Why This Happened

- Strava's `/athlete/activities` endpoint **does NOT include `average_heartrate`** for some virtual/indoor rides
- The HR data **does exist in the streams** (we can see `heartrate` in stream data)
- But the summary endpoint doesn't include it, so the app has no HR value to calculate TRIMP
- Without HR, power, or pre-calculated TSS, the activity contributes 0 TRIMP

### The Misleading First Fix

Initially, I added the duration fallback to `StrainScoreService.swift` in the `calculateTRIMPFromActivities()` method. **This was WRONG** because:

- That method is NOT used by the current strain calculation
- The actual calculation happens in `StrainDataCalculator.swift` (actor-based)
- The old method in `StrainScoreService` is legacy code kept for backwards compatibility

---

## The Solution

### Code Change

Added **Priority 4** fallback in `StrainDataCalculator.calculateTRIMPFromUnifiedActivities()`:

```swift
// Priority 3: Estimate from HR
if let avgHR = activity.averageHeartRate,
   let duration = activity.duration,
   let maxHRValue = maxHR,
   let restingHRValue = restingHR {
    // ... HR-based TRIMP calculation ...
} else if let duration = activity.duration, duration > 0 {
    // Priority 4: FALLBACK - Estimate from duration alone
    // This handles cases where Strava doesn't include HR in summary
    // Use moderate intensity assumption (HR reserve ~0.6)
    let durationMinutes = duration / 60
    let estimatedHRReserve = 0.6  // Moderate intensity
    let estimatedTRIMP = durationMinutes * estimatedHRReserve
    totalTRIMP += estimatedTRIMP
    Logger.debug("   Activity: \(activity.name ?? "Unknown") - Duration-based estimate: \(String(format: "%.1f", estimatedTRIMP)) (duration: \(String(format: "%.1f", durationMinutes))m)")
} else {
    Logger.debug("   Activity: \(activity.name ?? "Unknown") - NO DATA, skipping")
}
```

### Calculation Logic

For a **58-minute ride** without HR data:
- Duration = 58 minutes
- Assumed HR reserve = 0.6 (moderate intensity ~60% of max effort)
- **Estimated TRIMP** = 58 × 0.6 = **~35 TRIMP**

This will result in a strain score of approximately **4-5** instead of 1.7.

---

## Impact

### Before Fix
- **Strain Score**: 1.7 (displayed as 9)
- **TRIMP from activity**: 0.0
- **Total TRIMP**: 3.5 (from steps/daily activity only)

### After Fix
- **Strain Score**: ~4-5 (displayed as ~19-21)
- **TRIMP from activity**: ~35
- **Total TRIMP**: ~38.5 (activity + daily activity)

---

## Why This is Conservative

The **0.6 multiplier** assumes moderate intensity:
- Equivalent to ~60% of HR reserve
- Zone 2-3 effort
- Sustainable endurance pace

This is **intentionally conservative** because:
1. We don't have actual HR data to calculate precise intensity
2. It's better to slightly underestimate than overestimate strain
3. Indoor rides without power meters are often lower intensity
4. The user can see the activity in their feed if they want more details

---

## Testing

### Expected Logs (After Fix)

```
🔍 [Performance] 🔍 Found 1 unified activities for today
🔍 [Performance]    Activity: 4 x 9 - Duration-based estimate: 34.9 (duration: 58.2m)
🔍 [Performance] 🔍 Total TRIMP from 1 unified activities: 34.9
🔍 [Performance]    Total Cardio Duration: 58min
🔍 [Performance]    Workout TRIMP: 34.9
🔍 [Performance]    Final Score: 4.3
```

### How to Test

1. Build and run the app in Xcode (clean build if needed)
2. Pull-to-refresh on the Today screen
3. Check the strain score - should be ~4-5 instead of 1.7
4. Check logs for "Duration-based estimate" message

---

## Future Improvements

### Option 1: Fetch HR from Streams
- Make a second API call to `/api/streams/{activity_id}` to get HR data
- Calculate average HR from the stream
- Use this for proper TRIMP calculation
- **Downside**: Extra API call per activity (impacts rate limits)

### Option 2: Backend Enrichment
- Backend fetches streams when returning activities
- Calculates and includes `average_heartrate` if missing
- Caches the enriched data
- **Downside**: Slower backend responses, more complex caching

### Option 3: User-Reported RPE
- Allow user to manually rate intensity (1-10 scale)
- Use RPE to estimate HR reserve percentage
- Store in metadata
- **Downside**: Requires user input

For now, the **duration-based estimate** is the best balance of:
- ✅ No extra API calls
- ✅ Works immediately  
- ✅ Reasonable accuracy for most rides
- ✅ Better than ignoring the activity entirely

---

## Files Changed

- `VeloReady/Core/Services/Calculators/StrainDataCalculator.swift` - Added Priority 4 fallback

## Commit

- Commit: `992437e`
- Branch: `main`

