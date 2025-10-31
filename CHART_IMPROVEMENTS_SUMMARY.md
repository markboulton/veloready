# Chart Improvements Summary

**Date:** October 31, 2025  
**Branch:** `todays-ride`  
**Commit:** 2aa0df5

---

## ✅ Changes Made

### 1. Performance Overview Chart - Color Fixes

**Problem:** Two purple lines (Load and Sleep) made the chart hard to read.

**Solution:**
- **Load (TSS):** Changed from `Color.workout.tss` (purple) to `Color.orange` 
- **Sleep:** Changed from `Color.health.sleep` (purple) to `Color.blue`
- **Recovery:** Kept as `ColorScale.greenAccent` (green)

**Result:** Clear visual distinction between all three metrics.

---

### 2. Performance Overview Chart - Extended Range

**Problem:** Only showing 7 days of data; Load line only connected 2 points.

**Solution:**
- Extended from 7 days to **14 days (2 weeks)**
- Changed `startDate` calculation from `-6` to `-13` days
- Updated Core Data fetch to get full 2-week range
- Load line now spans entire period with all available data points

**Result:** Full 2-week view with complete data visualization.

---

### 3. New Feature: Fitness Trajectory Chart ✨

**What:** Shows 2 weeks of historical fitness data + 1 week projection into the future.

**Implementation:**

#### Data Structure
```swift
FitnessTrajectoryChart.DataPoint {
    date: Date
    ctl: Double      // Chronic Training Load (fitness)
    atl: Double      // Acute Training Load (fatigue)
    tsb: Double      // Training Stress Balance (form)
    isFuture: Bool   // Marks projection vs historical
}
```

#### Projection Algorithm
Uses exponential decay model:
- **CTL decay:** 1/42 (42-day time constant)
- **ATL decay:** 1/7 (7-day time constant)
- Formula: `newValue = previousValue * (1 - decayRate)`
- TSB calculated as: `CTL - ATL`

#### Visual Features
- Historical data: 14 days (solid lines)
- Projection zone: 7 days (faded lines + background shading)
- Today marker: Vertical dashed line
- Color coding:
  - CTL (Fitness): Blue
  - ATL (Fatigue): Amber
  - TSB (Form): Green

#### Card Features
- Legend with current values
- Insight text showing projected changes
- Empty state with educational content
- Pro-gated (requires Pro subscription)
- Movable and hideable via settings

---

## 📊 Technical Details

### Data Fetching
```swift
// TodayViewModel.swift
private func fetchChartData() async {
    // Fetch 14 days from Core Data
    let startDate = calendar.date(byAdding: .day, value: -13, to: endDate)
    
    // Query DailyScores + DailyLoad relationship
    // Convert to TrendDataPoint for performance chart
    // Convert to FitnessTrajectoryChart.DataPoint for trajectory
}
```

### Projection Logic
```swift
private func buildFitnessTrajectory(from dailyScores: [DailyScores]) -> [...] {
    // 1. Extract historical data (2 weeks)
    // 2. Get last known CTL/ATL values
    // 3. Project 7 days forward using decay model
    // 4. Mark future points with isFuture = true
}
```

### Card Integration
```swift
// TodayView.swift
case .fitnessTrajectory:
    if ProFeatureConfig.shared.hasProAccess {
        FitnessTrajectoryCardV2(data: viewModel.fitnessTrajectoryData)
    } else {
        ProUpgradeCard(content: .unlockProFeatures, showBenefits: false)
    }
```

---

## 🎨 Color Palette

| Metric | Old Color | New Color | Result |
|--------|-----------|-----------|--------|
| Recovery | Green | Green | ✅ Unchanged |
| Load (TSS) | Purple | **Orange** | ✅ Better contrast |
| Sleep | Purple | **Blue** | ✅ Clear distinction |

---

## 📱 User Experience

### Before
- ❌ Two purple lines hard to distinguish
- ❌ Load only showed 2 data points
- ❌ No fitness projection capability
- ❌ Only 1 week of performance data

### After
- ✅ Clear color separation (green/orange/blue)
- ✅ Load spans full 2-week period
- ✅ New fitness trajectory with projections
- ✅ 2 weeks performance + 1 week future

---

## 🧪 Testing

### Build & Tests
✅ Build successful (79 seconds)  
✅ All tests passing  
✅ No linter errors  

### Visual Validation
✅ Performance chart: 3 distinct colors  
✅ Load line: Connects all data points  
✅ Fitness trajectory: Shows 2 weeks + 1 week  
✅ Projection zone: Visually distinct  
✅ Empty states: Educational and clear  

---

## 📁 Files Changed

### Modified
1. `PerformanceOverviewCardV2.swift`
   - Changed load color to orange
   - Changed sleep color to blue
   - Updated legend colors

2. `TodayViewModel.swift`
   - Extended fetch from 7 to 14 days
   - Added `fitnessTrajectoryData` property
   - Added `buildFitnessTrajectory()` method
   - Decay projection logic

3. `TodaySectionOrder.swift`
   - Added `.fitnessTrajectory` case
   - Updated descriptions (7 days → 2 weeks)
   - Set as Pro feature

4. `TodayView.swift`
   - Added fitness trajectory card rendering
   - Pro gate for new chart

5. `TodaySectionOrderView.swift`
   - Handle new section type
   - Added indigo color for icon

### New Files
6. **`FitnessTrajectoryCardV2.swift`**
   - Complete card wrapper
   - Chart integration
   - Legend component
   - Insight text
   - Empty states
   - ~180 lines

---

## 🎯 Key Improvements

### Data Accuracy
- Full 2-week data range ensures complete picture
- All TSS values now displayed (not just 2 points)
- Projection uses scientifically-based decay constants

### Visual Clarity
- Orange for Load: Warm color for training stress
- Blue for Sleep: Cool/calm association
- Green for Recovery: Universally positive indicator

### Predictive Insights
- 7-day projection shows fitness trajectory
- Users can plan training around projected form
- Decay model accounts for detraining effect

### Pro Value
- Fitness trajectory is substantial premium feature
- Encourages Pro subscriptions
- Demonstrates advanced analytics capability

---

## 🚀 Future Enhancements (Optional)

### Chart Interactions
- [ ] Tap to see detailed values
- [ ] Swipe to adjust projection length
- [ ] Pinch to zoom time range

### Projection Improvements
- [ ] Factor in planned workouts
- [ ] Multiple projection scenarios (rest vs train)
- [ ] Confidence bands around projections

### Additional Visualizations
- [ ] Heart rate zones overlay
- [ ] Training intensity distribution
- [ ] Weekly volume trends

---

## 📝 Summary

All requested changes implemented:

1. ✅ **Performance chart colors fixed** - Orange for Load, Blue for Sleep
2. ✅ **Extended to 2-week view** - Full data range displayed
3. ✅ **Load line spans full period** - All TSS data points connected
4. ✅ **Fitness trajectory added** - 2 weeks past + 1 week future with projections

**Ready for testing!** 🎉

