# Revert Summary: Customizable Today Sections

## What Was Removed ❌

### 1. Customizable Section Ordering
- **TodaySectionOrder Model** - Managed user preferences for section order and visibility
- **TodaySectionOrderView** - Settings UI for reordering and hiding/showing cards
- **Migration Logic** - Automatic updates when new sections were added
- **UserDefaults/iCloud Sync** - Persisted section order across devices

### 2. Dynamic Today Page Layout
- **ForEach Loop** - Dynamically rendered sections based on user preferences
- **movableSection() Function** - Switch statement that rendered different section types
- **Hidden Sections** - Ability to hide cards from Today page
- **Section Notifications** - `.todaySectionOrderChanged` notification system

### 3. UI Components
- **CustomizeViewCTA** - "Customize This View" call-to-action at bottom of Today page
- **Settings Navigation** - "Today Page Layout" option in Display Settings

### 4. Chart Cards on Today Page
- **PerformanceOverviewCardV2** - 2-week trend of Recovery/Load/Sleep (moved to Trends)
- **FormChartCardV2** - CTL/ATL/TSB chart (removed)
- **FitnessTrajectoryCardV2** - 2-week historical + 1-week projection (removed)

### 5. TodayViewModel Chart Logic
- **@Published Properties** - `recoveryTrendData`, `loadTrendData`, `sleepTrendData`, `ctlData`, `atlData`, `tsbData`, `fitnessTrajectoryData`
- **fetchChartData()** - Fetched 14 days of data from Core Data
- **buildFitnessTrajectory()** - Generated projections using decay models

## What Remains ✅

### Today Page (Fixed Layout)
1. **Recovery Metrics** - Three compact rings (HRV, RHR, Sleep)
2. **Health Warnings** - Illness & Wellness alerts
3. **AI Brief** - Unified Pro (AI) and Free (computed) briefs
4. **Latest Activity** - Most recent Strava/Intervals ride with skeleton loader
5. **Steps Card** - Daily step count with skeleton
6. **Calories Card** - Active energy with skeleton
7. **Recent Activities** - 30-day activity list

### Trends Page (Enhanced)
- **Performance Overview Chart** - Now appears in Weekly Report (after AI Summary)
  - Uses `TrendsViewModel` data (`recoveryTrendData`, `dailyLoadData`, `sleepData`)
  - 30-day view of Recovery, Training Load, and Sleep
  - Colors: Recovery (green), Load (orange), Sleep (blue)

## Why It Was Reverted 🔄

1. **"Not Working"** - User reported the feature wasn't functioning correctly
2. **UserDefaults Caching** - Existing saved orders didn't include new sections
3. **Migration Issues** - While migration logic existed, it required manual triggering
4. **Complexity** - Feature added significant complexity for uncertain value
5. **Better Home** - Performance charts fit better in Trends/Weekly Report

## Technical Improvements 💡

### Simplified Architecture
- ✅ Fixed layout is more predictable and maintainable
- ✅ Removed 3 files and ~800 lines of code
- ✅ No UserDefaults/iCloud sync complexity
- ✅ No migration logic needed for new features

### Better UX
- ✅ Performance charts in Trends where users expect them
- ✅ Consistent Today page experience for all users
- ✅ No hidden features or configuration burden
- ✅ Faster page load (no dynamic section rendering)

## Files Modified 📝

### Deleted (3 files, 801 lines)
- `VeloReady/Features/Today/Models/TodaySectionOrder.swift`
- `VeloReady/Features/Settings/Views/TodaySectionOrderView.swift`
- `VeloReady/Features/Today/Views/Components/CustomizeViewCTA.swift`
- `documentation/issues/FITNESS_TRAJECTORY_TROUBLESHOOTING.md`
- `CHART_IMPROVEMENTS_SUMMARY.md`

### Modified (4 files)
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`
  - Replaced `ForEach(sectionOrder.movableSections)` with fixed card list
  - Removed `@State private var sectionOrder`
  - Removed `.onReceive(.todaySectionOrderChanged)`
  - Removed `movableSection()` function
  
- `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`
  - Removed chart data `@Published` properties
  - Removed `fetchChartData()` function
  - Removed `buildFitnessTrajectory()` function
  
- `VeloReady/Features/Trends/Views/WeeklyReportView.swift`
  - Added `@StateObject private var trendsViewModel = TrendsViewModel()`
  - Added `PerformanceOverviewCardV2` after AI Summary Header
  
- `VeloReady/Features/Settings/Views/Sections/DisplaySettingsSection.swift`
  - Removed "Today Page Layout" navigation link

## Build Status ✅

- ✅ All compilation errors fixed
- ✅ `./Scripts/quick-test.sh` passes
- ✅ All tests pass
- ✅ No linter errors
- ✅ Committed to `todays-ride` branch

## Next Steps 🚀

1. **Test the App**
   - Verify Today page shows all cards in correct order
   - Verify Trends page shows Performance Overview chart
   - Check that no layout jumps occur
   
2. **Consider Future Enhancements**
   - If customization is desired later, redesign with simpler approach
   - Could add simple on/off toggles for specific cards (not reordering)
   - Could use feature flags instead of user preferences

3. **Clean Up (Optional)**
   - Delete `FitnessTrajectoryChart.swift` if no longer used anywhere
   - Delete `FormChartCardV2.swift` if not referenced
   - Remove unused TrendsViewModel properties if applicable

## Commits 📋

```
c2368c0 docs: Remove documentation for reverted customizable sections feature
255ee1b revert: Remove customizable Today sections and move performance chart to Trends
```

---

**Summary**: Successfully reverted the customizable Today sections feature, simplifying the codebase by ~800 lines while improving UX by moving performance charts to their natural home in the Trends page. The Today page now has a clean, fixed layout that's easier to maintain and test.

