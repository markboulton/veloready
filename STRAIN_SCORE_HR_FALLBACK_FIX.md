# Strain Score Fix: Duration-Based TRIMP Fallback for Missing HR Data

**Date**: November 13, 2024  
**Issue**: Strain score showing 1.7 for a 58-minute indoor ride  
**Root Cause**: Strava API not including `average_heartrate` for virtual/indoor rides  
**Solution**: Duration-based TRIMP estimation fallback

---

## Problem

User reported strain score of **1.7** (displayed as **~9** on ring scale) for a 1-hour indoor ride, which was far too low. Investigation revealed:

```
🔍 [Performance] 📊 [TodaysActivities] Found 1 activities for today
🔍 [Performance] 🔍 Total TRIMP from 1 unified activities: 0.0
```

The activity was found but contributing **zero TRIMP** to the strain calculation.

## Root Cause Analysis

### Data Flow
1. ✅ Strava `/athlete/activities` API includes `average_heartrate` field
2. ✅ Backend passes through JSON unchanged  
3. ✅ iOS `StravaActivity` model has `average_heartrate` property
4. ✅ `ActivityConverter` maps it to `Activity.averageHeartRate`
5. ❌ **Strava returns `null` for `average_heartrate`** for some virtual/indoor rides

### Why Strava Returns Null

According to Strava Community Hub and developer reports:
- Virtual/indoor rides on gym bikes often don't include HR in the summary endpoint
- HR data exists in the **streams** but not in the **activity summary**
- This is a known Strava API limitation/quirk

### Example Activity
- **Name**: "4 x 9"
- **Date**: Nov 13, 2025, 6:24 AM
- **Duration**: 58 minutes (3523 seconds moving time)
- **Type**: Virtual Ride
- **HR Data**: Available in streams, but `average_heartrate: null` in summary
- **Result**: TRIMP = 0.0 → Strain only from steps/calories = 1.7

## Solution

### TRIMP Calculation Hierarchy

The strain calculation now follows this priority:

1. **TSS** (Training Stress Score) - Most accurate for cycling with power
   ```swift
   if let tss = activity.tss, tss > 0 {
       totalTRIMP += tss
   }
   ```

2. **HR-based TRIMP** - Accurate when HR summary is available
   ```swift
   else if let duration = activity.duration, let avgHR = activity.averageHeartRate {
       let durationMinutes = duration / 60
       let hrReserve = calculateHeartRateReserve(averageHR: avgHR)
       let trimpForActivity = durationMinutes * hrReserve
       totalTRIMP += trimpForActivity
   }
   ```

3. **Duration-based Estimate** - NEW FALLBACK for missing HR
   ```swift
   else if let duration = activity.duration, duration > 0 {
       let durationMinutes = duration / 60
       let estimatedHRReserve = 0.6  // Moderate intensity assumption
       let estimatedTRIMP = durationMinutes * estimatedHRReserve
       totalTRIMP += estimatedTRIMP
   }
   ```

### Conservative Estimate

The fallback uses **HR reserve of 0.6**, which represents:
- **Moderate intensity** (Zone 3)
- Equivalent to ~70% of max HR
- Conservative to avoid overestimating strain
- Reasonable for most indoor trainer sessions

### Expected Results

For a 58-minute activity:
- **Before**: TRIMP = 0.0 → Strain = 1.7 (only steps/calories)
- **After**: TRIMP = 58 × 0.6 = 34.8 → Strain = ~8-10 (reasonable for 1hr ride)

## Implementation

### Files Changed
- `VeloReady/Core/Services/Scoring/StrainScoreService.swift`
  - Added `else if` clause for duration-based fallback
  - Added logging to show when estimate is used

### Logging
New logs will show:
```
🔍 Processing activity '4 x 9' for TRIMP:
   📊 Activity data: duration=3523.0, avgHR=nil, tss=nil, normalizedPower=nil
   ⚠️ No HR data in summary - using duration-based estimate
   ✅ Estimated TRIMP: 34.8 (duration: 58.7m, assumed moderate intensity)
🔍 Total TRIMP from activities: 34.8
```

## Testing

### Test Case 1: Virtual Ride with HR Streams but No Summary
- **Activity**: Indoor ride, 58 minutes, HR in streams
- **Expected**: Duration-based TRIMP ~35
- **Strain**: Should show 8-10 (realistic)

### Test Case 2: Activity with HR Summary
- **Activity**: Outdoor ride with HR
- **Expected**: HR-based TRIMP (more accurate)
- **Fallback**: Not used

### Test Case 3: Activity with TSS
- **Activity**: Power-based ride
- **Expected**: TSS used directly
- **Fallback**: Not used

## Future Improvements

### Option 1: Fetch HR from Streams (More Accurate)
When `average_heartrate` is null in summary:
1. Fetch streams for the activity
2. Calculate average HR from stream data
3. Use real HR-based TRIMP

**Pros**: Accurate  
**Cons**: Additional API call, more complex, cache invalidation

### Option 2: Calculate TSS on Backend (Best for Power)
For activities with power data:
1. Backend calculates TSS using NP and duration
2. Include TSS in activity response
3. iOS uses TSS directly

**Pros**: Accurate for power-based activities  
**Cons**: Requires FTP lookup, backend changes

### Option 3: RPE Input (User-Driven)
Allow users to manually input RPE (Rate of Perceived Exertion):
1. Prompt after activity sync
2. Convert RPE to TRIMP estimate
3. Store for future use

**Pros**: User control, accurate for their perception  
**Cons**: Manual effort, may be forgotten

## Related Issues

### Similar Problems Solved
- **Stale Cache Bug**: Activities with wrong dates (Nov 6 instead of Nov 13)
  - Fix: Removed Netlify Blobs for activities, use Edge Cache
  - Doc: `BACKEND_CACHE_FIX.md`

- **DailyScores Not Saving**: Missing recovery/sleep/load data
  - Fix: Always update today's scores in `CacheManager`
  - Doc: `BUG_FIXES_NOV13_3.md`

### Known Limitations
1. Duration-based estimate is **conservative** - may underestimate high-intensity sessions
2. Does not account for **intervals** vs steady-state
3. Assumes **moderate intensity** for all missing HR activities

## Commit History

- `0ff97ce` - fix: Add duration-based TRIMP fallback for activities missing HR data
- `e9791b2` - debug: Add detailed logging for activity TRIMP calculation

## References

- Strava API Docs: [/athlete/activities](https://developers.strava.com/docs/reference/#api-Activities-getLoggedInAthleteActivities)
- Strava Community: [Missing average_heartrate field](https://communityhub.strava.com/developers-api-7/api-answer-changed-average-heartrate-and-max-heartrate-are-missing-amongst-others-9375)
- TRIMP Calculation: Edwards HR-based training impulse

