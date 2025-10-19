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

### 4. Trend Bar Chart
**Status:** ✅ FIXED
- Bars now very dark grey (systemGray5) with 2px colored top
- Numbers at top colored to match bar color
- % removed from top numbers, added to Y-axis labels
- 7-day view: shows numbers at top
- 30/60-day view: no numbers at top (cleaner)
- X-axis alignment fixed (removed .aligned preset)
- Grey grid lines (systemGray4)
- File: `TrendChart.swift`

### 5. Recovery Factors Colors
**Status:** ✅ FIXED
- Mapped `colorForScore()` to design tokens
- 80-100: ColorScale.greenAccent
- 60-80: ColorScale.blueAccent
- 40-60: ColorScale.amberAccent
- 0-40: ColorScale.redAccent
- File: `RecoveryDetailView.swift`

### 6. Ring and Metric Sizing
**Status:** ✅ VERIFIED
- RecoveryRingView: 160x160 (already correct)
- SleepHeaderSection: 160x160 (already correct)
- StrainHeaderSection: 160x160 (already correct)
- All rings consistent size across detail views

## 🔄 REMAINING

### 7. Weekly Performance Summary Refresh Issue
**Status:** ⚠️ NEEDS INVESTIGATION
**Issue:** User reports "Now it is just 4 lines after I refreshed"
**Logs show:** AI weekly summary error: cancelled (-999)
```
❌ [Performance] AI weekly summary error: Error Domain=NSURLErrorDomain Code=-999 "cancelled"
```
**Possible causes:**
- Multiple rapid refreshes cancelling previous requests
- View lifecycle issues (onDisappear cancelling tasks)
- Network timeout or connectivity issues
**Action needed:** 
- Add request deduplication
- Implement proper task cancellation handling
- Add retry logic for cancelled requests

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

1. **Priority 1:** Investigate weekly performance summary refresh (AI summary cancellation)
   - This appears to be a race condition or view lifecycle issue
   - May need to add request deduplication or debouncing

## 📊 COMMITS

1. `f3f12d2` - Fix: Fitness Trajectory chart and Settings navigation
2. `caeb8d3` - Fix: Apply metric label styling to Trends components
3. `499c6dd` - Fix: Trend bar chart styling and recovery factors colors

## 📈 SUMMARY

**Completed:** 6 out of 7 issues
**Remaining:** 1 issue (AI summary refresh)

All visual/UI fixes are complete. The remaining issue is a backend/networking concern that requires deeper investigation into the request lifecycle and cancellation handling.
