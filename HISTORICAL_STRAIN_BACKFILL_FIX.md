# Historical Strain/Load Backfill Fix

## 🐛 Problem

Historical strain scores in the Load Analysis page show as **2.0 (flat line)** for all days except today:

**Logs show**:
```
📊 [LOAD CHART] Record 1: 2025-10-17 23:00:00 +0000 - Strain: 2.0
📊 [LOAD CHART] Record 2: 2025-10-18 23:00:00 +0000 - Strain: 2.0
...
📊 [LOAD CHART] Record 42: 2025-11-16 00:00:00 +0000 - Strain: 7.703324198962627
```

**Impact**:
- 7-day trend: 6 days at 2.0, only today shows real value (7.7)
- 30-day trend: 29 days at 2.0, only today shows real value
- 60-day trend: 59 days at 2.0, only today shows real value
- Charts are **useless** - can't analyze training load trends
- User has activities on these days (visible in logs: "4 x 8", "4 x 9", "Mixed, post-storm")

---

## 🔍 Root Cause Analysis

### The Backfill Flow

```swift
// TodayCoordinator.swift - triggers on app launch
await BackfillService.shared.backfillAll(days: 60, forceRefresh: true)

// BackfillService.swift - orchestrates backfill
func backfillAll() {
    await backfillHistoricalPhysioData(days: 60)  // 1. HealthKit data (HRV, RHR, sleep)
    await backfillTrainingLoad(days: 42)           // 2. CTL/ATL/TSS → DailyLoad
    await backfillScores(days: 60)                 // 3. Recovery/Sleep/Strain
}
```

### The Bug: Missing DailyLoad for Strava/HealthKit Activities

**`backfillTrainingLoad()` only processes Intervals.icu activities**:

```swift
// BackfillService.swift:86-120
func backfillTrainingLoad(days: Int = 42, forceRefresh: Bool = false) async {
    // Try Intervals.icu first
    let intervalsActivities = try? await IntervalsAPIClient.shared.fetchRecentActivities(limit: 200, daysBack: 60)
    
    if !intervalsActivities.isEmpty {
        let activitiesWithTSS = intervalsActivities.filter { ($0.tss ?? 0) > 0 }
        Logger.data("Found \(activitiesWithTSS.count) Intervals activities with TSS")
        
        for activity in activitiesWithTSS {
            // Calculate progressive CTL/ATL, save to DailyLoad
        }
    }
    
    // ❌ PROBLEM: If no Intervals data, do nothing!
    if progressiveLoad.isEmpty {
        Logger.data("No activities found to backfill")
        return  // ← This is the bug!
    }
}
```

**Result**: No `DailyLoad` entries created for historical dates.

### The Cascading Failure: Strain Backfill Defaults to 2.0

**`backfillStrainScores()` depends on `DailyLoad`**:

```swift
// BackfillService.swift:440-445
guard let load = try context.fetch(loadRequest).first else {
    // ❌ No training load data, set minimal NEAT strain
    scores.strainScore = 2.0  // ← This is why everything is 2.0!
    updatedCount += 1
    continue
}
```

**Result**: All historical strain scores default to 2.0.

### The Evidence

**From logs**:
```
📊 [CTL/ATL BACKFILL] Found 0 Intervals activities with TSS
📊 [CTL/ATL BACKFILL] No activities found to backfill
```

BUT the user HAS activities:
```
🔍 [Performance]    Activity 1: '4 x 8' - startDateLocal: '2025-11-11T18:13:35Z'
🔍 [Performance]    Activity 2: '4 x 9' - startDateLocal: '2025-11-13T06:24:24Z'
🔍 [Performance]    Activity 3: 'Mixed, post-storm' - startDateLocal: '2025-11-16T12:36:58Z'
```

These are **Strava activities**, not Intervals.icu! The backfill **ignores them**.

---

## ✅ The Fix

**Make `backfillTrainingLoad()` process Strava + HealthKit activities**:

### Strategy

1. **Try Intervals.icu first** (best data quality - has TSS)
2. **Fall back to Strava** (calculate TSS from power/NP + duration)
3. **Fall back to HealthKit** (calculate TRIMP as TSS equivalent)
4. **Merge all sources** by date to get comprehensive training load

### Implementation Plan

#### Step 1: Fetch Strava Activities

```swift
// After Intervals.icu check, fetch Strava
if progressiveLoad.isEmpty {
    Logger.data("📊 [CTL/ATL BACKFILL] Step 2: Fetching Strava activities...")
    
    do {
        let stravaActivities = try await StravaService.shared.fetchActivities(
            daysBack: days,
            includeDetails: true  // Need power/HR data
        )
        
        Logger.data("📊 [CTL/ATL BACKFILL] Found \(stravaActivities.count) Strava activities")
        
        // Calculate TSS for each activity
        for activity in stravaActivities {
            let tss = calculateTSSForActivity(activity)
            if tss > 0 {
                let date = Calendar.current.startOfDay(for: activity.startDate)
                // Add to progressiveLoad with progressive CTL/ATL calculation
            }
        }
    } catch {
        Logger.error("❌ [CTL/ATL BACKFILL] Strava fetch failed: \(error)")
    }
}
```

#### Step 2: Fall Back to HealthKit

```swift
// If still empty, try HealthKit
if progressiveLoad.isEmpty {
    Logger.data("📊 [CTL/ATL BACKFILL] Step 3: Falling back to HealthKit workouts...")
    
    let calculator = TrainingLoadCalculator()
    progressiveLoad = await calculator.calculateProgressiveTrainingLoadFromHealthKit()
    
    Logger.data("📊 [CTL/ATL BACKFILL] Calculated load for \(progressiveLoad.count) days from HealthKit")
}
```

#### Step 3: Calculate TSS from Activity Data

```swift
private func calculateTSSForActivity(_ activity: Activity) -> Double {
    // 1. Try power-based TSS (most accurate)
    if let np = activity.normalizedPower,
       let duration = activity.duration,
       let ftp = athleteProfile.adaptiveFTP,
       np > 0, ftp > 0 {
        let intensityFactor = np / ftp
        let tss = (duration / 3600) * intensityFactor * intensityFactor * 100
        Logger.debug("   Power-based TSS: \(String(format: "%.1f", tss))")
        return tss
    }
    
    // 2. Fall back to HR-based TRIMP
    if let avgHR = activity.averageHeartRate,
       let duration = activity.duration,
       let maxHR = athleteProfile.maxHR,
       let restingHR = athleteProfile.restingHR,
       duration > 0 {
        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
        let trimp = duration / 60 * hrReserve * 0.64 * exp(1.92 * hrReserve)
        Logger.debug("   HR-based TRIMP: \(String(format: "%.1f", trimp))")
        return trimp
    }
    
    // 3. Estimate from duration and activity type
    if let duration = activity.duration {
        let estimatedTSS = duration / 3600 * 50  // Assume moderate intensity
        Logger.debug("   Estimated TSS from duration: \(String(format: "%.1f", estimatedTSS))")
        return estimatedTSS
    }
    
    return 0
}
```

#### Step 4: Progressive CTL/ATL Calculation

```swift
private func calculateProgressiveLoad(
    activities: [Activity],
    days: Int
) -> [Date: (ctl: Double, atl: Double, tss: Double)] {
    var result: [Date: (ctl: Double, atl: Double, tss: Double)] = [:]
    var currentCTL: Double = 0
    var currentATL: Double = 0
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
    
    // Group activities by date
    var dailyTSS: [Date: Double] = [:]
    for activity in activities {
        let date = calendar.startOfDay(for: activity.startDate)
        let tss = calculateTSSForActivity(activity)
        dailyTSS[date, default: 0] += tss
    }
    
    // Calculate progressive CTL/ATL day by day
    var currentDate = startDate
    while currentDate <= today {
        let tss = dailyTSS[currentDate] ?? 0
        
        // Exponential decay
        let ctlDecay = exp(-1.0 / 42.0)  // 42-day fitness
        let atlDecay = exp(-1.0 / 7.0)   // 7-day fatigue
        
        currentCTL = currentCTL * ctlDecay + tss * (1 - ctlDecay)
        currentATL = currentATL * atlDecay + tss * (1 - atlDecay)
        
        if tss > 0 || currentCTL > 0 || currentATL > 0 {
            result[currentDate] = (ctl: currentCTL, atl: currentATL, tss: tss)
        }
        
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }
    
    return result
}
```

---

## 📊 Expected Results After Fix

### Before (Broken)

**7-Day Trend**:
```
Nov 10: 2.0 (flat)
Nov 11: 2.0 (flat) ← Should show activity "4 x 8"
Nov 12: 2.0 (flat)
Nov 13: 2.0 (flat) ← Should show activity "4 x 9"
Nov 14: 2.0 (flat)
Nov 15: 2.0 (flat)
Nov 16: 7.7 (only today shows real value!)
```

**Average**: 2.8 (wrong - inflated by today)

### After (Fixed)

**7-Day Trend** (example - actual values will vary):
```
Nov 10: 2.0 (rest day)
Nov 11: 8.5 (activity "4 x 8" - intervals workout)
Nov 12: 3.5 (light recovery)
Nov 13: 9.2 (activity "4 x 9" - intervals workout)
Nov 14: 2.5 (rest day)
Nov 15: 2.0 (rest day)
Nov 16: 7.7 (today's "Mixed, post-storm")
```

**Average**: 5.1 (realistic training load)

### Chart Visualization

**Before**: Flat line at 2.0 with sudden spike on today  
**After**: Realistic wave pattern showing training cycles

---

## 🔧 Implementation Steps

1. **Update `BackfillService.backfillTrainingLoad()`**:
   - Add Strava activity fetch after Intervals.icu
   - Add HealthKit fallback
   - Extract TSS calculation logic
   - Calculate progressive load from all sources

2. **Add helper method `calculateTSSForActivity()`**:
   - Power-based TSS (if available)
   - HR-based TRIMP (fallback)
   - Duration estimate (last resort)

3. **Add helper method `calculateProgressiveLoad()`**:
   - Group activities by date
   - Calculate daily TSS totals
   - Apply exponential decay formula
   - Build progressive CTL/ATL

4. **Add logging**:
   - Show which data source is being used
   - Log TSS calculation method per activity
   - Show daily TSS totals

5. **Test**:
   - Force refresh: `backfillAll(days: 60, forceRefresh: true)`
   - Verify `DailyLoad` entries created for historical dates
   - Verify strain scores calculated from TSS
   - Check charts show realistic trends

---

## 🎯 Success Criteria

✅ **DailyLoad entries exist for all dates with activities**  
✅ **Strain scores > 2.0 for training days**  
✅ **Strain scores ≈ 2.0 for rest days**  
✅ **7/30/60-day charts show realistic wave patterns**  
✅ **CTL/ATL values reflect actual training history**  
✅ **Backfill works for users without Intervals.icu**

---

## 📝 Testing Commands

```bash
# In Xcode console:
# 1. Force backfill
await BackfillService.shared.backfillAll(days: 60, forceRefresh: true)

# 2. Check DailyLoad entries
let request = DailyLoad.fetchRequest()
request.predicate = NSPredicate(format: "tss > 0")
let loads = try! context.fetch(request)
print("DailyLoad entries with TSS: \(loads.count)")

# 3. Check strain scores
let scoresRequest = DailyScores.fetchRequest()
scoresRequest.predicate = NSPredicate(format: "strainScore > 2.0")
let scores = try! context.fetch(scoresRequest)
print("Days with strain > 2.0: \(scores.count)")

# 4. Navigate to Load Analysis page and verify charts
```

---

## 🚨 Critical Notes

1. **This is not just a UI bug** - it's a data pipeline failure
2. **Affects all users** without Intervals.icu (or with incomplete Intervals data)
3. **Makes training load analysis useless** - the entire Load Analysis page
4. **Historical data needs force refresh** after fix is deployed
5. **The fix is in the backfill logic**, not the chart rendering

---

## 🔄 Related Issues

- Strain calculation for today works correctly (uses real-time HealthKit + Strava)
- The issue is ONLY with historical backfill
- Recovery and sleep backfills work correctly (they don't depend on DailyLoad)
- The chart rendering is correct (it shows whatever data exists in Core Data)

The problem is **data creation**, not **data visualization**.
