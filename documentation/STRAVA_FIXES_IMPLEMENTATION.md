# Strava Data Fixes - Implementation Guide

## Executive Summary

You're experiencing 6 issues with Strava-only fresh installs because:
1. **FTP not computed yet** → Can't calculate TSS
2. **Zones not computed yet** → No zone charts
3. **CTL/ATL not tracked** → No training load charts
4. **Elevation chart scaling broken** → Renders off-screen
5. **No fallback calculations** → Everything fails silently

## Quick Wins (Highest Impact)

### 1. Use Strava Athlete FTP as Fallback ✅

**File:** `AthleteProfileManager.swift`

**Location:** In `computeFromActivities()` method, before FTP computation

```swift
// NEW: Use Strava FTP as fallback if no activities with NP yet
func useStravaFTPIfAvailable() async {
    if profile.ftp == nil || profile.ftp == 0 {
        do {
            let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
            if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                Logger.data("📊 Using Strava FTP as fallback: \(stravaFTP)W")
                profile.ftp = Double(stravaFTP)
                profile.ftpSource = .intervals // Mark as from external source
                profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: Double(stravaFTP))
            }
        } catch {
            Logger.warning("Could not fetch Strava athlete data: \(error)")
        }
    }
}
```

**Call it:** Add at top of `computeFromActivities()`:
```swift
func computeFromActivities(_ activities: [IntervalsActivity]) async {
    await useStravaFTPIfAvailable() // NEW LINE
    
    Logger.data("=========================================")
    // ... rest of existing code
}
```

---

### 2. Fallback TSS Calculation ✅

**File:** `RideDetailViewModel.swift`

**Location:** In `loadStravaActivityData()`, replace lines 438-442:

```swift
// OLD CODE:
if let normalizedPower = activity.normalizedPower, let ftp = profileManager.profile.ftp, ftp > 0 {
    let intensityFactor = normalizedPower / ftp
    let duration = activity.duration ?? 0
    let tss = (duration * normalizedPower * intensityFactor) / (ftp * 36.0)
    
    Logger.debug("🟠 Calculated TSS: \(Int(tss))")
    // ...
}

// NEW CODE:
var normalizedPower = activity.normalizedPower
var ftp = profileManager.profile.ftp

// Fallback 1: Estimate NP from average power if missing
if normalizedPower == nil, let avgPower = activity.averagePower, avgPower > 0 {
    normalizedPower = avgPower * 1.05 // Conservative NP estimate
    Logger.debug("🟠 Estimated NP from average power: \(Int(normalizedPower!))W")
}

// Fallback 2: Try to get FTP from Strava athlete if not computed
if ftp == nil || ftp == 0 {
    do {
        let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
        if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
            ftp = Double(stravaFTP)
            Logger.debug("🟠 Using Strava FTP: \(Int(ftp!))W")
        }
    } catch {
        Logger.warning("Could not fetch Strava FTP: \(error)")
    }
}

// Calculate TSS if we have both NP and FTP
if let np = normalizedPower, let ftpValue = ftp, ftpValue > 0, np > 0 {
    let intensityFactor = np / ftpValue
    let duration = activity.duration ?? 0
    let tss = (duration * np * intensityFactor) / (ftpValue * 36.0)
    
    Logger.debug("🟠 Calculated TSS: \(Int(tss)) (NP: \(Int(np))W, IF: \(String(format: "%.2f", intensityFactor)), FTP: \(Int(ftpValue))W)")
    
    // Create new activity with TSS and IF
    enriched = IntervalsActivity(
        id: enriched.id,
        name: enriched.name,
        description: enriched.description,
        startDateLocal: enriched.startDateLocal,
        type: enriched.type,
        duration: enriched.duration,
        distance: enriched.distance,
        elevationGain: enriched.elevationGain,
        averagePower: enriched.averagePower,
        normalizedPower: np, // Use calculated/fallback NP
        averageHeartRate: enriched.averageHeartRate,
        maxHeartRate: enriched.maxHeartRate,
        averageCadence: enriched.averageCadence,
        averageSpeed: enriched.averageSpeed,
        maxSpeed: enriched.maxSpeed,
        calories: enriched.calories,
        fileType: enriched.fileType,
        tss: tss,
        intensityFactor: intensityFactor,
        atl: enriched.atl,
        ctl: enriched.ctl,
        icuZoneTimes: enriched.icuZoneTimes,
        icuHrZoneTimes: enriched.icuHrZoneTimes
    )
} else {
    Logger.warning("🟠 Cannot calculate TSS - missing data (NP: \(normalizedPower != nil), FTP: \(ftp != nil && ftp! > 0))")
}
```

---

### 3. Fix Elevation Chart Scaling ✅

**File:** `WorkoutDetailCharts.swift`

**Location:** Find the elevation chart section (around line 500), update chart domain:

```swift
// OLD:
.chartYAxis {
    AxisMarks(position: .leading)
}

// NEW:
.chartYScale(domain: elevationDomain())
.chartYAxis {
    AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel()
    }
}

// Add helper method:
private func elevationDomain() -> ClosedRange<Double> {
    let elevations = displaySamples.map { $0.elevation }.filter { $0 > 0 }
    guard !elevations.isEmpty else {
        return 0...100 // Default range
    }
    
    let minElev = elevations.min() ?? 0
    let maxElev = elevations.max() ?? 100
    let padding = (maxElev - minElev) * 0.1 // 10% padding
    
    return (minElev - padding)...(maxElev + padding)
}
```

---

### 4. Add Fallback UI for Missing Data ✅

**File:** `RideDetailSheet.swift`

**Location:** Replace metric cards with versions that handle nil:

```swift
// OLD:
RideMetricCard(
    title: "Intensity",
    value: formatIntensity(activity.intensityFactor ?? 0)
)

RideMetricCard(
    title: "Load",
    value: formatLoad(activity.tss ?? 0)
)

// NEW:
RideMetricCard(
    title: "Intensity",
    value: activity.intensityFactor != nil ? formatIntensity(activity.intensityFactor!) : "N/A"
)
.opacity(activity.intensityFactor != nil ? 1.0 : 0.5)

RideMetricCard(
    title: "Load",
    value: activity.tss != nil ? formatLoad(activity.tss!) : "N/A"
)
.opacity(activity.tss != nil ? 1.0 : 0.5)
```

---

### 5. Ensure Zones Are Computed ✅

**File:** `AthleteProfileManager.swift`

**Location:** In `computeFromActivities()`, after FTP computation, add minimum zone generation:

```swift
// After FTP computation (around line 372)
// NEW: Generate default zones even if FTP computation failed
if profile.powerZones == nil || profile.powerZones!.isEmpty {
    if let ftp = profile.ftp, ftp > 0 {
        profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
        Logger.data("Generated default power zones from FTP: \(Int(ftp))W")
    }
}

if profile.hrZones == nil || profile.hrZones!.isEmpty {
    if let maxHR = profile.maxHR, maxHR > 0 {
        profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
        Logger.data("Generated default HR zones from max HR: \(Int(maxHR))bpm")
    }
}
```

---

### 6. Basic CTL/ATL Tracking ✅

**File:** Create new `TrainingLoadCalculator.swift`

```swift
import Foundation

/// Calculates CTL (Chronic Training Load) and ATL (Acute Training Load)
/// CTL = 42-day exponentially weighted moving average of TSS
/// ATL = 7-day exponentially weighted moving average of TSS
class TrainingLoadCalculator {
    
    /// Calculate CTL and ATL for activities
    /// - Parameter activities: Array of activities sorted by date (oldest first)
    /// - Returns: Dictionary mapping activity ID to (CTL, ATL, TSB)
    static func calculateTrainingLoad(for activities: [IntervalsActivity]) -> [String: (ctl: Double, atl: Double, tsb: Double)] {
        var result: [String: (ctl: Double, atl: Double, tsb: Double)] = [:]
        
        // Sort by date (oldest first)
        let sortedActivities = activities.sorted { a, b in
            guard let dateA = ISO8601DateFormatter().date(from: a.startDateLocal),
                  let dateB = ISO8601DateFormatter().date(from: b.startDateLocal) else {
                return false
            }
            return dateA < dateB
        }
        
        var currentCTL: Double = 0
        var currentATL: Double = 0
        
        // Time constants
        let ctlTC: Double = 42.0  // 42 days for CTL
        let atlTC: Double = 7.0   // 7 days for ATL
        
        for activity in sortedActivities {
            let tss = activity.tss ?? 0
            
            // Exponentially weighted moving average
            // Formula: newValue = oldValue + (TSS - oldValue) / timeConstant
            currentCTL = currentCTL + (tss - currentCTL) / ctlTC
            currentATL = currentATL + (tss - currentATL) / atlTC
            
            // TSB (Training Stress Balance) = CTL - ATL
            let tsb = currentCTL - currentATL
            
            result[activity.id] = (ctl: currentCTL, atl: currentATL, tsb: tsb)
        }
        
        return result
    }
}
```

**Usage:** Call this after fetching activities and update the `IntervalsActivity` objects with CTL/ATL values.

---

## Testing Plan

### Step 1: Test FTP Fallback
1. Fresh install, connect Strava only
2. Ensure Strava FTP is used
3. Check Settings → Athlete Zones shows FTP

### Step 2: Test TSS Calculation
1. View any ride
2. Check if TSS appears (even without weighted_average_watts)
3. Check logs for fallback messages

### Step 3: Test Charts
1. View ride with elevation
2. Ensure elevation chart renders in viewport
3. Check if zone charts appear (even if empty)

### Step 4: Test UI
1. View ride without TSS data
2. Should show "N/A" instead of "0.00"
3. Should be slightly greyed out

---

## Summary

**Root cause:** Fresh install with Strava lacks computed FTP and normalized power data.

**Solution:** 
1. ✅ Fetch FTP from Strava athlete profile as fallback
2. ✅ Estimate NP from average power when missing
3. ✅ Fix elevation chart scaling
4. ✅ Generate default zones even with limited data
5. ✅ Add fallback UI for missing data
6. ✅ Implement basic CTL/ATL tracking

**Impact:** All ride detail views will work properly on fresh installs with Strava-only data.

---

## Quick Implementation Checklist

- [ ] Add `useStravaFTPIfAvailable()` to AthleteProfileManager
- [ ] Update TSS calculation in RideDetailViewModel with fallbacks
- [ ] Fix elevation chart domain calculation
- [ ] Add N/A fallback UI to metric cards
- [ ] Ensure zones generated even with minimal data
- [ ] Add TrainingLoadCalculator for CTL/ATL
- [ ] Test with fresh install
- [ ] Verify all 6 issues resolved

---

## Estimated Time
- Implementation: 30-45 minutes
- Testing: 15 minutes
- Total: ~1 hour

The changes are straightforward - mostly adding fallback logic and better error handling.
