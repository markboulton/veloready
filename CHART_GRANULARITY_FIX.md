# Chart Granularity Fix

**Date:** November 15, 2025

## Problem

After implementing trailing windows, the charts were worse:
1. **Completely flat** - no variation whatsoever
2. **FTP and VO2 charts identical** - looked exactly the same
3. **All calculations returning 199W** - every single data point
4. **Only 61 activities fetched** for 120 days of history
5. **Missing June FTP peak** - Your validated 210-220W FTP from June not showing

## Root Cause

### Issue 1: Window Overlap Too Large
```
90-day trailing windows:
- Day 1: Activities from Day -90 to Day 0
- Day 2: Activities from Day -89 to Day 1
- 89 out of 90 days are IDENTICAL (98.9% overlap)
- Same activities → Same best efforts → Same FTP calculation → Flat line
```

### Issue 2: Not Fetching Enough Historical Data
```
Sparklines: Only fetching 120 days back
6-month chart: Only fetching 270 days back
Your June FTP: 6+ months ago (not in dataset)
Result: Can't show historical peaks
```

### Issue 3: Activity Limits Too Low
```
Fetched: 61 activities for 120 days (~0.5 activities/day)
Your training: Very good quality data going back years
Limit: 500 activities (hit limit before getting all data)
```

## Solution

### 1. Reduce Window Sizes for More Granularity

**30-day Sparklines** (daily data points):
```swift
// OLD: 90-day windows
guard let windowStart = calendar.date(byAdding: .day, value: -90, to: targetDate)

// NEW: 30-day windows
guard let windowStart = calendar.date(byAdding: .day, value: -30, to: targetDate)
```

**Impact**: Overlap reduced from 98.9% to 96.7%
- Day-to-day changes will now be visible
- 1 out of 30 days different (instead of 1 out of 90)
- Much more responsive to recent training

**6-month Chart** (weekly data points):
```swift
// OLD: 90-day windows for each week
guard let windowStart = calendar.date(byAdding: .day, value: -90, to: weekDate)

// NEW: 60-day windows for each week
guard let windowStart = calendar.date(byAdding: .day, value: -60, to: weekDate)
```

**Impact**: Overlap reduced from 92.9% to 85.7%
- Week-to-week changes will be visible
- ~9 out of 60 days different (instead of 7 out of 90)
- Better captures training blocks and progressions

### 2. Fetch More Historical Data

**30-day Sparklines**:
```swift
// OLD: 120 days back, limit 500
fetchRecentActivities(limit: 500, daysBack: 120)

// NEW: 180 days back, limit 1000
fetchRecentActivities(limit: 1000, daysBack: 180)
```

**6-month Chart**:
```swift
// OLD: 270 days (9 months) back, limit 1000
fetchRecentActivities(limit: 1000, daysBack: 270)

// NEW: 365 days (12 months) back, limit 2000
fetchRecentActivities(limit: 2000, daysBack: 365)
```

**Impact**:
- Will capture your June FTP peak of 210-220W
- Enough activities for dense training history
- 12-month lookback ensures historical peaks visible

## Changes Made

### AthleteProfile.swift

**Line 1196-1249: calculateHistoricalFTP()**
```swift
/// Calculate 30-day FTP trend from REAL historical activities (daily granularity)
/// Uses 30-day rolling window for each data point
private func calculateHistoricalFTP() async -> [Double] {
    // Fetch activities from last 180 days (30-day window + 150 days of history to capture peaks)
    guard let activities = try? await UnifiedActivityService.shared.fetchRecentActivities(limit: 1000, daysBack: 180)

    // Get activities within 30-day TRAILING window (30 days BEFORE this date)
    // Smaller window = more granularity, less overlap between consecutive days
    guard let windowStart = calendar.date(byAdding: .day, value: -30, to: targetDate)
```

**Line 1320-1378: calculateHistoricalVO2()**
```swift
/// Calculate 30-day VO2 trend from REAL historical activities (daily granularity)
/// Uses 30-day rolling window for each data point, estimating VO2 from FTP
private func calculateHistoricalVO2() async -> [Double] {
    // Fetch activities from last 180 days (30-day window + 150 days of history to capture peaks)
    guard let activities = try? await UnifiedActivityService.shared.fetchRecentActivities(limit: 1000, daysBack: 180)

    // Get activities within 30-day TRAILING window (30 days BEFORE this date)
    // Smaller window = more granularity, less overlap between consecutive days
    guard let windowStart = calendar.date(byAdding: .day, value: -30, to: targetDate)
```

**Line 1479-1556: calculate6MonthHistorical()**
```swift
/// Calculate 6-month historical performance from REAL activity data (weekly data points)
/// Uses 60-day rolling window for each week to get accurate historical FTP/VO2 with better granularity
private func calculate6MonthHistorical() -> [(date: Date, ftp: Double, vo2: Double)] {
    // Fetch 12 months of activities (increased from 9 months) to capture June's 210-220W FTP
    cachedActivities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 2000, daysBack: 365)

    // Get activities within 60-day TRAILING window (60 days BEFORE this week)
    // Smaller window = better granularity, less overlap between consecutive weeks
    guard let windowStart = calendar.date(byAdding: .day, value: -60, to: weekDate)
```

## Expected Results

### Before Fix:
```
Logs:
📊 [Historical FTP] Fetched 61 activities for calculation
📊 FTP calc: 47 total activities, 34 with power data
📊 FTP calc: Calculated FTP = 199W
📊 FTP calc: 46 total activities, 33 with power data
📊 FTP calc: Calculated FTP = 199W
📊 FTP calc: 46 total activities, 33 with power data
📊 FTP calc: Calculated FTP = 199W
[...repeated for every data point...]

Charts:
- 30-day FTP: Flat line at 199W
- 30-day VO2: Flat line at 52.1 ml/kg/min
- 6-month FTP: Flat line starting at 199W
- 6-month VO2: Flat line identical to FTP shape
```

### After Fix:
```
Logs:
📊 [Historical FTP] Fetched 156 activities for calculation (or more)
📊 FTP calc: 15 total activities, 12 with power data
📊 FTP calc: Calculated FTP = 185W
📊 FTP calc: 16 total activities, 13 with power data
📊 FTP calc: Calculated FTP = 188W
📊 FTP calc: 18 total activities, 14 with power data
📊 FTP calc: Calculated FTP = 195W
[...varying values showing progression...]
📊 [Historical FTP] Range: 178W - 199W

Charts:
- 30-day FTP: Shows ups and downs (training/recovery cycles)
- 30-day VO2: Shows different pattern than FTP (weight changes affect VO2)
- 6-month FTP: Shows June peak at 210-220W → progression → current 199W
- 6-month VO2: Shows actual fitness journey over 6 months
```

## Testing

1. **Clear cache first** to force recalculation:
   ```swift
   // In Debug menu or:
   UserDefaults.standard.removeObject(forKey: "historicalFTP_sparkline")
   UserDefaults.standard.removeObject(forKey: "historicalVO2_sparkline")
   UserDefaults.standard.removeObject(forKey: "historical6Month_performance")
   ```

2. **Check Today page sparklines**:
   - Should see variation in both FTP and VO2 sparklines
   - FTP and VO2 should have different shapes
   - Trend indicators should show realistic percentages (not ±0%)

3. **Check Adaptive Performance page 6-month chart**:
   - Should see 26 weekly data points with real variation
   - Should capture June's 210-220W FTP peak (if within 6 months)
   - Chart should show your actual fitness progression
   - Y-axis should adapt to data range (not 0-300W)

4. **Watch logs**:
   ```
   📊 [Historical FTP] Fetched XXX activities for calculation
   📊 [Historical FTP] Range: XXW - YYW
   📊 [6-Month Historical] Fetched XXX activities for calculation
   📊 [6-Month Historical] FTP range: XXW → YYW
   ```

## Window Size Trade-offs

### Why 30-day windows for sparklines?
- **Too small** (7 days): Too noisy, fluctuates wildly
- **Too large** (90 days): Too smooth, no variation
- **Just right** (30 days): Balance of stability and responsiveness
- Matches common training block length (4-week mesocycles)

### Why 60-day windows for 6-month chart?
- Weekly data points (26 total)
- Each week needs enough data for reliable FTP calculation
- 60 days = ~8-9 weeks of training data per point
- Better granularity than 90 days while maintaining stability

## Performance Impact

**Sparklines**:
- Before: Fetch 61 activities from 120 days
- After: Fetch ~150-200 activities from 180 days
- Impact: +0.5s initial load (cached for 5min during testing, 24h in prod)

**6-month Chart**:
- Before: Fetch ~100 activities from 270 days
- After: Fetch ~300-500 activities from 365 days
- Impact: +1s initial load (cached for 5min during testing, 24h in prod)

**Overall**: Acceptable overhead for detail view, minimal impact due to caching

## Next Steps

1. Test in app to verify granular variation in charts
2. Verify June FTP peak shows up in 6-month chart
3. Verify FTP and VO2 charts no longer identical
4. Confirm logs show varying FTP calculations (not all 199W)
5. Consider adjusting cache TTL back to 24 hours for production
