# UI Fixes Batch 2 - Recovery, Profile, Sleep, Load

## Status: IN PROGRESS

## 1. RECOVERY DETAIL ✅

### Issue A: 30 & 60 day charts show same number of bars (12)
**Root Cause:** TrendChart is generating correct number of data points but rendering may be constrained
**Fix:** Verify data generation in `getHistoricalRecoveryData()` - currently returns empty array for real data
**File:** `/VeloReady/Features/Today/Views/DetailViews/RecoveryDetailView.swift`
**Status:** NEEDS FIX - Line 343 returns empty array `return []`

### Issue B: Grey is too light
**Root Cause:** Bar color uses `Color(.systemGray5)` which is very light
**Fix:** Change to darker grey like `Color(.systemGray3)` or `Color(.systemGray4)`
**File:** `/VeloReady/Features/Today/Views/Charts/TrendChart.swift` Line 100
**Status:** READY TO FIX

---

## 2. LOAD DETAIL ✅

### Issue: Load trend chart data is not showing
**Root Cause:** `getHistoricalLoadData()` returns empty array (Line 344 in StrainDetailView.swift)
**Fix:** Implement real historical data tracking from Core Data DailyScores
**File:** `/VeloReady/Features/Today/Views/DetailViews/StrainDetailView.swift`
**Status:** NEEDS IMPLEMENTATION

---

## 3. PROFILE - FITNESS TRAJECTORY ✅

### Issue A: No historical data for 7 days earlier to today
**Root Cause:** Logs show CTL=0.0, ATL=0.0 for days Oct 12-17, only Oct 18 has data
**Fix:** Need to investigate why CTL/ATL calculation isn't populating historical days
**File:** `/VeloReady/Features/Trends/ViewModels/WeeklyReportViewModel.swift`
**Status:** NEEDS INVESTIGATION

### Issue B: Forward project should be zoned as grey zone behind the line
**Current:** Projection uses grey lines (30% opacity)
**Requested:** Grey zone/area behind the projection lines
**Fix:** Add AreaMark or RectangleMark for projection zone
**File:** `/VeloReady/Features/Trends/Views/Charts/FitnessTrajectoryChart.swift`
**Status:** NEEDS DESIGN

### Issue C: Legend colours do not map to the lines
**Current:** Lines use Color.button.primary, Color.semantic.warning, ColorScale.greenAccent
**Fix:** Need to verify legend component and ensure color mapping
**File:** Need to find legend component
**Status:** NEEDS INVESTIGATION

---

## 4. TRAINING LOAD SUMMARY ✅

### Issue A: Add line between top metrics section and Training Pattern section
**Fix:** Add SectionDivider() or Divider() between sections
**File:** `/VeloReady/Features/Trends/Views/Components/TrainingLoadComponent.swift`
**Status:** READY TO FIX

### Issue B: Metrics show 0 for TSS, training time, and workouts
**Root Cause:** Logs show "Weekly TSS: 0.0 from 0 days"
**Fix:** Need to investigate why weeklyTSS is 0 when CTL data exists
**File:** `/VeloReady/Features/Trends/ViewModels/WeeklyReportViewModel.swift`
**Status:** NEEDS INVESTIGATION

### Issue C: Add line between Training Pattern and Intensity distribution
**Fix:** Add Divider() between sections
**File:** `/VeloReady/Features/Trends/Views/Components/TrainingLoadComponent.swift`
**Status:** READY TO FIX

---

## 5. SLEEP SCHEDULE ✅

### Issue A: Avg bedtime, avg wake, Consistency labels - use small caps caption pattern
**Current:** Uses `.font(.caption)` and `.foregroundColor(.text.secondary)`
**Fix:** Apply `.metricLabel()` modifier (9pt uppercase with tracking)
**File:** `/VeloReady/Features/Trends/Views/Components/SleepScheduleComponent.swift`
**Status:** READY TO FIX

### Issue B: Week over week changes needs better layout
**Status:** NEEDS CLARIFICATION - where is this section?

### Issue C: Hypnogram Y axis wrong way around - Red (awake) needs to be at top
**Current:** yPosition for awake is 0.2, deep is 1.0 (deep at top)
**Fix:** Invert yPosition values so awake=1.0 (top), deep=0.2 (bottom)
**File:** `/VeloReady/Features/Trends/Views/Charts/SleepHypnogramChart.swift` Lines 49-58
**Status:** READY TO FIX

### Issue D: Date from Sun to Thur showing 24 hours asleep - wrong data
**Root Cause:** Logs show "Found 7 total sleep sessions" but bedtime/wake calculations seem off
**Example from logs:** "Bedtime: 00:00 = 24.0h" and "Wake: 00:01 = 0.016666666666666666h"
**Fix:** Need to investigate sleep data parsing and time calculations
**File:** `/VeloReady/Services/Scoring/SleepScoreService.swift` or ViewModel
**Status:** NEEDS INVESTIGATION

### Issue E: Upward arrows use wrong green
**Current:** Likely using `.green` or old color
**Fix:** Use `ColorScale.greenAccent` or `Color.status.authenticated`
**Status:** NEEDS FILE LOCATION

### Issue F: Polarised tick uses wrong green - should use RPE status tick pattern
**Current:** Line 92-94 in TrainingLoadComponent.swift uses `.green`
**Fix:** Create reusable StatusIndicator component from strength training, use ColorScale.greenAccent
**File:** `/VeloReady/Features/Trends/Views/Components/TrainingLoadComponent.swift`
**Status:** NEEDS COMPONENT ABSTRACTION

### Issue G: Ensure all colours map to design tokens
**Status:** AUDIT NEEDED

---

## PRIORITY ORDER

1. **Quick Wins (30 min)**
   - Fix grey color in TrendChart (systemGray5 → systemGray4)
   - Add dividers in TrainingLoadComponent
   - Apply .metricLabel() to SleepScheduleComponent
   - Fix hypnogram Y-axis inversion

2. **Medium Complexity (1-2 hours)**
   - Implement historical data for Recovery/Load trend charts
   - Add grey zone for fitness trajectory projection
   - Fix arrow and tick colors to use design tokens
   - Create reusable StatusIndicator component

3. **Complex Investigation (2+ hours)**
   - Fix CTL/ATL historical data population
   - Fix TSS/training time showing 0
   - Investigate 24-hour sleep data issue
   - Verify legend color mapping

---

## DESIGN TOKENS REFERENCE

```swift
// Greens
ColorScale.greenAccent  // Primary green for positive indicators
Color.status.authenticated  // Alternative green

// Greys
Color(.systemGray3)  // Darker grey
Color(.systemGray4)  // Medium grey (recommended for bars)
Color(.systemGray5)  // Light grey (current, too light)

// Other
ColorScale.blueAccent
ColorScale.amberAccent
ColorScale.redAccent
Color.semantic.warning
Color.button.primary
```
