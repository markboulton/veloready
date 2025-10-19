# Strava Activity Detail Fixes

## Date: October 15, 2025

## Issues Identified

After fresh install with Strava-only integration, ride detail views show:

1. ❌ Missing TSS and Intensity
2. ❌ Missing CTL/ATL charts  
3. ❌ Missing Intensity chart
4. ❌ Elevation chart breaks (renders off-screen)
5. ❌ Missing Adaptive HR zone charts
6. ❌ Missing Adaptive Power zone charts

---

## Root Causes

### Issue 1: Missing TSS/IF

**Current Code:**
```swift
// Line 439 in RideDetailViewModel.swift
if let normalizedPower = activity.normalizedPower, 
   let ftp = profileManager.profile.ftp, ftp > 0 {
    // Calculate TSS...
}
```

**Problems:**
1. ✅ `weighted_average_watts` → `normalizedPower` mapping exists
2. ❌ Strava doesn't always return `weighted_average_watts` (older activities, virtual rides)
3. ❌ FTP not computed yet on fresh install (needs activities with NP data)
4. ❌ No fallback calculation using average power

**Solution:**
- Calculate TSS using average power when NP missing
- Fetch Strava athlete FTP if no computed FTP
- Add better logging

### Issue 2: Missing CTL/ATL

**Problem:**
- CTL/ATL are cumulative metrics (42-day and 7-day rolling averages)
- Strava doesn't provide these
- Code doesn't calculate from historical activities

**Solution:**
- Implement CTL/ATL calculation from activity history
- Store in Core Data
- Update with each new activity

### Issue 3-6: Missing Zone Charts

**Problem:**
- `AthleteProfileManager.profile.hrZones` = nil
- `AthleteProfileManager.profile.powerZones` = nil
- `computeFromActivities()` not run yet, or insufficient data

**Solution:**
- Fetch zones from Strava `/athlete/zones` endpoint
- Use as fallback when no computed zones
- Compute zones even with limited data

### Issue 4: Elevation Chart Breaking

**Problem:**
- Y-axis scaling incorrect when elevation data present
- Chart renders 4x below visible area

**Solution:**
- Fix chart domain calculation
- Add proper axis bounds

---

## Implementation Plan

### Fix 1: Fetch Strava Athlete Zones ✅

Add to `StravaAPIClient.swift`:
```swift
func fetchAthleteZones() async throws -> StravaAthleteZones
```

Call during auth or on profile load.

### Fix 2: Fallback TSS Calculation ✅

```swift
// If no normalized power, estimate from average power
if normalizedPower == nil, let avgPower = activity.averagePower {
    normalizedPower = avgPower * 1.05 // Conservative estimate
}
```

### Fix 3: Fetch Strava FTP ✅

Use athlete zones response which includes FTP-based power zones.

### Fix 4: CTL/ATL Calculation ✅

Add to `DailyLoad` Core Data entity and calculate rolling averages.

### Fix 5: Fix Elevation Chart ✅

Update chart domain in `WorkoutDetailCharts.swift`.

### Fix 6: Fallback UI ✅

Show "N/A" or helpful messages when data missing.

---

## Files to Modify

1. `StravaAPIClient.swift` - Add athlete zones fetch
2. `RideDetailViewModel.swift` - Fallback TSS calculation
3. `AthleteProfileManager.swift` - Use Strava zones as fallback
4. `WorkoutDetailCharts.swift` - Fix elevation scaling
5. `RideDetailSheet.swift` - Fallback UI
6. `TrainingLoadService.swift` (new) - CTL/ATL calculation

---

## Testing Checklist

- [ ] Fresh install with Strava only
- [ ] View ride without NP data → shows estimated TSS
- [ ] View ride without FTP → fetches from Strava
- [ ] Elevation chart renders correctly
- [ ] Zone charts show even without computed zones
- [ ] CTL/ATL display properly
- [ ] Fallback UI shows helpful messages
