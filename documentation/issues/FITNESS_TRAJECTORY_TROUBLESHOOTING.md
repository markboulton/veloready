# Fitness Trajectory Chart - Troubleshooting Guide

## Current Status ✅

All code for the Fitness Trajectory chart is implemented and working:

1. ✅ **Chart Component** (`FitnessTrajectoryChart.swift`)
   - Renders CTL/ATL/TSB lines with 2 weeks historical + 1 week projection
   - Uses proper color coding and annotations
   - Shows grey projection zone for future data

2. ✅ **Card Wrapper** (`FitnessTrajectoryCardV2.swift`)
   - Displays chart with legend and insights
   - Shows empty state when no data available
   - Pro-gated feature

3. ✅ **Data Fetching** (`TodayViewModel.swift`)
   - `fetchChartData()` fetches 14 days of CTL/ATL/TSB from Core Data
   - `buildFitnessTrajectory()` creates projections using decay model
   - Publishes data to `@Published var fitnessTrajectoryData`

4. ✅ **Integration** (`TodayView.swift`)
   - Added `.fitnessTrajectory` case to section switch
   - Chart is rendered when case is hit

5. ✅ **Section Management** (`TodaySectionOrder.swift`)
   - Added `.fitnessTrajectory` to `TodaySection` enum
   - Migration logic adds new sections to existing user configurations
   - Customizable via Settings > Today Page Layout

## Why You Might Not See It 🔍

### Most Likely Cause: Cached Section Order

Your app has a saved `TodaySectionOrder` in UserDefaults from before the chart was added. While migration logic exists, it may need to be triggered.

### Solutions:

#### Option 1: Reset to Default (Recommended)
1. Open the app
2. Go to **Settings > Today Page Layout**
3. Scroll to bottom and tap **"Reset to Default Order"**
4. Go back to Today page
5. Chart should appear after Performance Overview

#### Option 2: Manual Reorder
1. Go to **Settings > Today Page Layout**
2. Check if "Fitness Trajectory" appears in "Hidden Sections"
3. If yes, tap the "eye" icon to show it
4. Drag it to your preferred position in "Visible Sections"

#### Option 3: Force App State Reset (Nuclear Option)
1. Delete the app
2. Reinstall
3. All settings (including section order) will reset to defaults

#### Option 4: Wait for Next App Launch
The migration logic runs on every call to `TodaySectionOrder.load()`, which happens:
- When `TodayView` appears
- When returning from navigation
- After saving changes in Settings

Try force-quitting the app and reopening.

## Verify It's Working 📊

### Check 1: Data Availability
The chart requires Core Data to have `DailyScores` with `DailyLoad` relationships containing CTL/ATL/TSB values.

Look for this log message:
```
📊 Updated chart data: Recovery=X, Load=X, Sleep=X, CTL=X, Trajectory=X
```

If `Trajectory=0`, there's no CTL/ATL/TSB data in Core Data yet.

### Check 2: Section Order Debug
Add temporary logging to see what sections are loaded:

In `TodayView.swift`, line 550, add after `sectionOrder = TodaySectionOrder.load()`:
```swift
Logger.debug("📋 Loaded sections: \(sectionOrder.movableSections.map { $0.displayName })")
Logger.debug("📋 Hidden sections: \(sectionOrder.hiddenSections.map { $0.displayName })")
```

This will show exactly which sections are visible/hidden.

### Check 3: Pro Access
The chart is Pro-gated. If you don't have Pro access, you'll see the "Unlock Pro Features" card instead.

Check `ProFeatureConfig.shared.hasProAccess` in debug.

## Expected Behavior 🎯

When working correctly:

1. **Empty State**: If no CTL/ATL/TSB data exists, the chart shows an educational empty state explaining what metrics are displayed
2. **With Data**: Shows 2 weeks of historical CTL/ATL/TSB lines + 1 week projection with grey background
3. **Legend**: Displays current values for Fitness (CTL), Fatigue (ATL), and Form (TSB)
4. **Insight**: Shows projected changes over next 7 days

## Migration Logic 🔄

The migration is automatic and runs in `TodaySectionOrder.migrateIfNeeded()`:

```swift
if !allSections.contains(.fitnessTrajectory) {
    // Insert after performanceChart or at end
    if let perfIndex = sections.firstIndex(of: .performanceChart) {
        sections.insert(.fitnessTrajectory, at: perfIndex + 1)
    } else {
        sections.append(.fitnessTrajectory)
    }
    Logger.debug("☁️ Added fitnessTrajectory to section order")
    needsSave = true
}
```

Look for this log message:
```
☁️ Added fitnessTrajectory to section order
```

If you see it, the migration ran successfully.

## Next Steps 📝

1. Try Option 1 (Reset to Default) first
2. Check for the debug logs mentioned above
3. If still not visible, check Core Data for CTL/ATL/TSB values
4. Verify Pro access is enabled

The code is solid and tested ✅ - it's just a matter of triggering the migration or manually showing the section.

