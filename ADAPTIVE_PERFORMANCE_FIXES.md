# Adaptive Performance & AI Brief Fixes

**Date:** November 15, 2025

## Issues Fixed

### 1. ✅ AI Brief Cache Loading (Enhanced Logging)

**Problem:**
- Brief didn't load despite being viewed "couple hours ago"
- No visibility into Core Data cache checks
- Scores took 62 seconds to calculate, brief waited entire time

**Root Cause:**
- Insufficient logging made it impossible to debug cache issues
- AI Brief waits for all 3 scores (recovery, sleep, strain) before fetching
- No way to see if Core Data cache was checked or why it failed

**Solution:**
Added detailed logging to `AIBriefService.swift`:
```swift
// Now shows:
🤖 [AI Brief] fetchBrief called - bypassCache: false
🤖 [AI Brief] Checking Core Data for today's cached brief...
📂 [AI Brief] Loading from Core Data for date: 2025-11-15
📂 [AI Brief] Core Data query returned 1 DailyScores
✅ [AI Brief] Found cached brief (234 chars)
```

**Benefit:**
- Can now diagnose why cache doesn't load
- Shows if DailyScores exists but aiBriefText is empty
- Clear visibility into cache hit/miss

---

### 2. ✅ Sparklines - Fixed Last Value Mismatch

**Problem:**
- Sparklines show **SIMULATED DATA**, not real historical activities
- Last point didn't match current FTP/VO2 due to random noise
- Misleading "training progression" that's purely generated

**Example:**
- Current FTP: 199W
- Sparkline last point: 203W (random noise added)
- **User confusion:** "Why doesn't sparkline match current value?"

**Solution:**
Updated `AthleteProfile.swift`:
```swift
// Lines 1220-1222
if day == days - 1 {
    values.append(current)  // EXACT match on last point
}
```

**Added TODOs for future:**
```swift
/// TODO: Replace with REAL historical data from activities (currently simulated)
/// Should query activities from last 30 days and calculate FTP at each point
```

**Benefit:**
- Sparkline now ends at exact current value
- No more confusing 199W vs 203W discrepancies
- Clear documentation that data is simulated

---

### 3. ✅ Chart Value Mismatches - Fixed 6-Month Chart

**Problem:**
- Chart showed FTP: 203W, header showed FTP: 199W
- Chart showed VO2: 36, header showed VO2: 35
- Random noise on EVERY data point, including last one

**Root Cause:**
`calculate6MonthHistorical()` added random noise to all 26 weekly points:
```swift
// OLD CODE (WRONG)
let ftpNoise = Double.random(in: -0.02...0.02) * currentFTP
let vo2Noise = Double.random(in: -0.025...0.025) * currentVO2
// Applied to ALL points, including last one
```

**Solution:**
Updated `AthleteProfile.swift` lines 1311-1333:
```swift
let isLastPoint = (week == weeks - 1)

if isLastPoint {
    // No noise on last point - must match current values exactly
    ftp = currentFTP  // 199W
    vo2 = currentVO2  // 35 ml/kg/min
} else {
    // Apply noise only to earlier points
    let ftpNoise = Double.random(in: -0.02...0.02) * currentFTP
    // ...
}
```

**Benefit:**
- Chart last point: FTP 199W, VO2 35 (exact match)
- Header values: FTP 199W, VO2 35 (exact match)
- No more user confusion about mismatched values

---

### 4. ✅ Design System - Gradient Extraction

**Problem:**
- Hardcoded gradient in `AdaptivePerformanceDetailView.swift`:
```swift
// BEFORE (WRONG)
LinearGradient(
    gradient: Gradient(colors: [
        (selectedMetric == .ftp ? ColorScale.purpleAccent : ColorScale.blueAccent).opacity(0.2),
        (selectedMetric == .ftp ? ColorScale.purpleAccent : ColorScale.blueAccent).opacity(0.0)
    ]),
    startPoint: .top,
    endPoint: .bottom
)
```

**Solution:**
Created `Gradients.swift` design system file:
```swift
enum Gradients {
    enum ChartFill {
        static func areaGradient(
            color: Color,
            topOpacity: Double = 0.2,
            bottomOpacity: Double = 0.0
        ) -> LinearGradient { ... }
        
        static var ftp: LinearGradient { areaGradient(color: ColorScale.purpleAccent) }
        static var vo2: LinearGradient { areaGradient(color: ColorScale.blueAccent) }
        static var power: LinearGradient { areaGradient(color: ColorScale.powerColor) }
        static var hrv: LinearGradient { areaGradient(color: ColorScale.hrvColor) }
    }
}
```

Updated usage:
```swift
// AFTER (CORRECT)
.foregroundStyle(selectedMetric == .ftp ? Gradients.ChartFill.ftp : Gradients.ChartFill.vo2)
```

**Benefit:**
- Consistent gradients across all charts
- Single source of truth for gradient opacity
- Easy to update all charts at once
- Design system compliant

---

## Why Scores Took 62 Seconds

From your logs, the app was doing massive parallel work on launch:
- ✅ Fetching 90 days of activities (cache miss)
- ✅ Calculating illness detection (7 days of wellness data)
- ✅ Processing 178 days of ML training data
- ✅ Fetching 6-month historical performance
- ✅ Multiple Core Data queries
- ✅ Training load calculations

**Optimization opportunities:**
1. Stagger non-critical calculations (run after UI appears)
2. Cache historical performance for 24 hours
3. Skip ML processing if done today
4. Prefetch activities in background on previous app close

---

## Files Modified

1. **AIBriefService.swift** - Enhanced cache logging
2. **AthleteProfile.swift** - Fixed sparkline & chart value mismatches
3. **Gradients.swift** - NEW: Design system gradients
4. **AdaptivePerformanceDetailView.swift** - Use design system gradient

---

## Known Issues (Not Fixed)

### Sparklines Still Simulated
The 30-day sparklines are **NOT real data**. They're generated to look realistic but don't reflect actual activity history.

**What it should do:**
- Query activities from last 30 days
- Calculate FTP at each point using power-duration curve
- Calculate VO2 at each point using HR/power data
- Show REAL progression, including plateaus and drops

**Current behavior:**
- Generates smooth upward progression
- Always trends toward current value
- Purely cosmetic, not data-driven

**Estimated effort to fix:** 4-6 hours
- Need to implement daily FTP calculation from activities
- Cache results for performance
- Handle missing data (days without activities)

---

## Testing

1. **Clean build and run**
2. **AI Brief:** Check logs for cache loading messages
3. **Sparklines:** Verify last point matches current FTP/VO2
4. **Chart:** Verify chart "Current" matches header values
5. **Gradients:** Verify consistent styling across charts

---

## Next Steps

### Short-term (Optional)
- Implement real sparkline data from activities
- Optimize score calculation to < 30 seconds
- Add loading skeleton for AI brief

### Medium-term (Recommended)
- Replace all simulated historical data with real calculations
- Add caching for 6-month performance data
- Stagger non-critical background calculations
