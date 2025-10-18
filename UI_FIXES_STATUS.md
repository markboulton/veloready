# UI/UX Fixes Status

## ✅ COMPLETED

### 1. Fitness Trajectory Chart
**Status:** ✅ FIXED
- Complete rewrite based on Training Load chart
- Shows 7 days historical + 7 days projection
- Historical: colored lines with point markers (50% opacity)
- Projection: grey lines (30% opacity), no markers
- Today marker: dashed vertical line
- Projection uses CTL/ATL decay formulas
- Files: `FitnessTrajectoryChart.swift`, `WeeklyReportViewModel.swift`

### 2. Profile Settings Navigation
**Status:** ✅ FIXED
- Wrapped SettingsView in NavigationView
- All NavigationLinks now functional
- Sleep, Zones, Display, Notifications accessible
- File: `SettingsView.swift`

### 3. Metric Label Styling
**Status:** ✅ FIXED
- Applied `.metricLabel()` to Recovery Capacity component
- Applied to StatPill component (Avg Recovery, FTP, TSS)
- All labels now 9pt uppercase with consistent styling
- Files: `RecoveryCapacityComponent.swift`, `TrendsView.swift`

## 🔄 IN PROGRESS / PENDING

### 4. Weekly Performance Summary Refresh Issue
**Status:** ⚠️ NEEDS INVESTIGATION
**Issue:** User reports "Now it is just 4 lines after I refreshed"
**Logs show:** AI weekly summary error: cancelled (-999)
```
❌ [Performance] AI weekly summary error: Error Domain=NSURLErrorDomain Code=-999 "cancelled"
```
**Action needed:** Debug why AI summary requests are being cancelled on refresh

### 5. Ring and Metric Sizing (Recovery/Sleep/Load Detail Views)
**Status:** ⚠️ NEEDS FIXING
**Issue:** "On all of these pages, the ring and metric need to be the same size"
**Files to check:**
- `RecoveryDetailView.swift`
- `SleepDetailView.swift`
- `LoadDetailView.swift` (if exists)
**Action needed:** Ensure consistent ring size and metric display across all detail views

### 6. Trend Bar Chart Issues
**Status:** ⚠️ NEEDS MULTIPLE FIXES
**Issues:**
1. Shows 8 days instead of 7
2. Days in x-axis not aligned with bars
3. Remove % from each score at top, add % to axes
4. Make bars very dark grey with 2px colored top
5. Color the number at top same as bar color
6. 30/60 day shows 50% before certain point
7. For 30/60 days: show 30/60 bars (thinner), same styling, no numbers at top

**Action needed:** Complete redesign of trend bar chart component

### 7. Recovery Factors Colors
**Status:** ⚠️ NEEDS MAPPING
**Issue:** "Recovery factors numbers use the old colours. Map them to tokens"
**Action needed:** Find recovery factors component and map colors to design tokens

## 📝 NOTES

### Logs Analysis
- CTL/ATL data only exists for Saturday (Oct 18)
- Days Oct 12-17 show CTL=0.0, ATL=0.0
- This explains why Fitness Trajectory was showing zeros
- Projection now handles this by using last known values

### Build Status
- All changes compile successfully
- No new warnings introduced
- Ready for testing

## 🎯 NEXT STEPS

1. **Priority 1:** Fix weekly performance summary refresh (AI summary cancellation)
2. **Priority 2:** Fix trend bar chart (multiple issues)
3. **Priority 3:** Standardize ring/metric sizing across detail views
4. **Priority 4:** Map recovery factors colors to tokens

## 📊 COMMITS

1. `f3f12d2` - Fix: Fitness Trajectory chart and Settings navigation
2. `caeb8d3` - Fix: Apply metric label styling to Trends components
