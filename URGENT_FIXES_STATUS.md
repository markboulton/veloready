# Urgent Fixes Status & Debug Guide

**Date:** October 18, 2025 @ 5:30pm  
**Status:** Critical fixes applied with comprehensive logging  
**Action Required:** **REBUILD APP** - Many changes won't be visible without a clean build

---

## 🚨 **CRITICAL: YOU MUST REBUILD THE APP**

Changes to charts, colors, and layouts require a **full rebuild**:
```bash
# Clean build folders
rm -rf ~/Library/Developer/Xcode/DerivedData/VeloReady-*

# In Xcode:
Product → Clean Build Folder (Cmd+Shift+K)
Product → Build (Cmd+B)
Product → Run (Cmd+R)
```

**Why:** SwiftUI view changes, color token changes, and new components aren't hot-reloaded.

---

## ✅ **COMPLETED FIXES**

### **1. Recovery Trend Chart - Logging Added** ✅
```
📊 [RECOVERY CHART] Fetching data for period: X days
📊 [RECOVERY CHART] Date range: START to END
📊 [RECOVERY CHART] Fetched X days with recovery data
📊 [RECOVERY CHART] Returning X data points for X-day view
📊 [RECOVERY CHART] Sample dates: [dates...]
```

**What to check in logs:**
- Does it show 30 or 60 for period?
- How many days does it fetch from Core Data?
- How many data points are returned?

### **2. HRV Chart - RED with Logging** ✅
```
❤️ [HRV CHART] Fetching data for period: X days
❤️ [HRV CHART] Date range: START to END
❤️ [HRV CHART] Fetched X days with HRV data
❤️ [HRV CHART] Date: DATE, HRV: VALUE
❤️ [HRV CHART] Returning X data points for X-day view
```

**Changes:**
- **Color:** RED throughout (icon, line)
- **Line:** 1px solid, no gradient
- **Average line:** 1px dashed at average value
- **NO area fill** removed

### **3. RHR Chart - RED with Logging** ✅
```
💔 [RHR CHART] Fetching data for period: X days
💔 [RHR CHART] Date range: START to END
💔 [RHR CHART] Fetched X days with RHR data
💔 [RHR CHART] Date: DATE, RHR: VALUE
💔 [RHR CHART] Returning X data points for X-day view
```

**Changes:**
- **Color:** RED throughout (icon, candlesticks)
- **All candlesticks red** (no green/red distinction)
- **Note:** Currently using simulated min/max (±5% variation)
- **TODO:** Fetch real daily min/max HR from HealthKit

### **4. Sleep Trend Chart - Logging Added** ✅
```
💤 [SLEEP CHART] Fetching data for period: X days
💤 [SLEEP CHART] Date range: START to END
💤 [SLEEP CHART] Fetched X days with sleep data
💤 [SLEEP CHART] Returning X data points for X-day view
💤 [SLEEP CHART] Sample dates: [dates...]
```

### **5. Trend Chart Bars - DARKER** ✅
**Before:** `Color(.systemGray3).opacity(0.8)`  
**After:** `Color(.systemGray2)` - **fully opaque, darker grey**

### **6. Sleep Detail - Hypnogram ADDED** ✅
**Location:** After score breakdown, before metrics  
**Displays:** Full sleep hypnogram with purple gradient  
**Uses:**
- `SleepScore.inputs.sleepStages` (HKCategorySample array)
- `SleepScore.inputs.bedtime` and `wakeTime`
- Converts to `SleepHypnogramChart.SleepStageSample`

### **7. Sleep Detail - Purple Colors VERIFIED** ✅
**ALL colors ARE in the code:**

| Element | Color Token | Light Mode | Dark Mode |
|---------|-------------|------------|-----------|
| Sleep Duration | `ColorScale.sleepCore` | #8B7FBF (light purple) | #6680E6 (light blue) |
| Sleep Need | `ColorScale.sleepDeep` | #4B1F7F (dark purple) | #331966 (dark purple) |
| Efficiency | `ColorScale.sleepREM` | #6B4F9F (purple-blue) | #4F6BCC (turquoise) |
| Deep Sleep % | `ColorScale.sleepDeep` | #4B1F7F | #331966 |
| Wake Events | `.red` | ✅ RAG indicator | ✅ RAG indicator |
| Deep Sleep stage | `ColorScale.sleepDeep` | #4B1F7F | #331966 |
| REM Sleep stage | `ColorScale.sleepREM` | #6B4F9F | #4F6BCC |
| Core Sleep stage | `ColorScale.sleepCore` | #8B7FBF | #6680E6 |
| **Awake stage** | `ColorScale.sleepAwake` | **#C9B8E8 (light lilac)** ✨ | #FFCC66 (gold) |
| Recommendations | `ColorScale.sleepAwake` | #C9B8E8 | #FFCC66 |

**Light lilac (#C9B8E8) IS implemented** for Awake in light mode!

---

## 🔧 **DEBUGGING GUIDE**

### **Step 1: Check Logs**
Run the app and navigate to each chart. Look for the emoji-prefixed logs:

```bash
# In Xcode Console, filter by:
📊 # Recovery chart
❤️ # HRV chart
💔 # RHR chart
💤 # Sleep chart
```

### **Step 2: Verify Data Counts**
Expected logs for **30-day view**:
```
📊 [RECOVERY CHART] Fetching data for period: 30 days
📊 [RECOVERY CHART] Fetched X days with recovery data  # Should be close to 30
📊 [RECOVERY CHART] Returning X data points for 30-day view  # Should match fetch count
```

**If X is 0 or much less than 30:**
- Not enough historical data in Core Data
- Check `DailyScores` entity has 30+ days with `recoveryScore > 0`

### **Step 3: Verify 30/60 Day Data Exists**
Check Core Data:
```swift
// In Debug console:
po try? PersistenceController.shared.container.viewContext.count(for: DailyScores.fetchRequest())
```

Expected: 30+ days of data

### **Step 4: Check Chart Visibility**
If bars are invisible even with logging showing data:
1. **Bar width** - might be too thin on 30/60 day views
2. **Chart domain** - Y-axis might be incorrectly scaled
3. **Color** - systemGray2 should be visible, but check display settings

---

## ⚠️ **KNOWN ISSUES REMAINING**

### **1. RHR Candlesticks - Simulated Data** ⚠️
**Current:** Using ±5% variation around daily RHR average  
**Needed:** Fetch actual min/max HR samples from HealthKit per day

```swift
// TODO in RecoveryDetailView.swift line 522:
// Fetch actual min/max HR from HealthKit samples for true candlestick
```

### **2. Fitness Trajectory - Metrics Placement** ⚠️
**Issue:** "Move the metrics next to the point they correspond on the chart"  
**Current:** Metrics are in legend at top  
**Needed:** Annotation overlays on chart points

**File:** `FitnessTrajectoryChart.swift`  
**Required Change:** Add `.annotation()` modifiers to `PointMark` elements

### **3. Weekly Sleep Hypnogram - Y-Axis Mapping** ⚠️
**Issue:** "The data does not map to the y axis correctly"  
**File:** `SleepHypnogramChart.swift`  
**Current Y-positions:**
```swift
case .awake: return 1.0  // Top
case .rem: return 0.75
case .core: return 0.5
case .inBed: return 0.2
case .deep: return 0.0   // Bottom
```

**Check:**
- Are labels aligned with data segments?
- Do grid lines at 0.2, 0.5, 0.75, 1.0 match stage positions?

### **4. Week Over Week - No Visual Change** ⚠️
**Issue:** "Week over week has not changed"  
**File:** `WeekOverWeekComponent.swift`  
**Previous Change:** Restructured columns with fixed widths

**Possible causes:**
- Change not visible due to no rebuild
- Layout still doesn't look correct
- Need different alignment approach

---

## 📋 **VERIFICATION CHECKLIST**

After rebuilding, verify each item:

### **Recovery Detail**
- [ ] Recovery trend shows 30 bars on 30-day view
- [ ] Recovery trend shows 60 bars on 60-day view
- [ ] Bars are DARK GREY and fully opaque
- [ ] HRV chart is RED with 1px line
- [ ] HRV chart has dashed average line
- [ ] RHR chart is RED with candlesticks
- [ ] All charts have logs in console

### **Sleep Detail**
- [ ] Hypnogram appears after score breakdown
- [ ] Hypnogram shows purple gradient stages
- [ ] All metric cards use purple tones
- [ ] Sleep Duration is light purple
- [ ] Sleep Need is dark purple
- [ ] Awake stage is **light lilac** (#C9B8E8) in light mode
- [ ] Wake Events stays RED (correct)

### **Trends**
- [ ] Fitness Trajectory lines are 25% opacity
- [ ] Fitness Trajectory dots are outlined with black center
- [ ] Legend colors match chart lines (blue/amber/mint)

---

## 🐛 **COMMON PROBLEMS**

### **Problem: "I don't see any changes"**
**Solution:** You MUST rebuild. Simulator cache holds old views.

### **Problem: "30-day chart shows 0 data points"**
**Check logs:** If logs show `Fetched 0 days`, you don't have 30 days of historical data yet.

**Temporary solution:** Enable mock data:
```swift
#if DEBUG
ProFeatureConfig.shared.showMockDataForTesting = true
#endif
```

### **Problem: "Colors still look wrong"**
1. Check light vs dark mode - colors are different
2. Verify `ColorScale.swift` has the new sleep tokens
3. Check if old color references still exist

### **Problem: "Hypnogram doesn't show"**
Check:
- `SleepScore.inputs.sleepStages` is not empty
- `SleepScore.inputs.bedtime` exists
- `SleepScore.inputs.wakeTime` exists
- Logs should show if conversion fails

---

## 📊 **NEXT STEPS**

1. **REBUILD APP** - Clean + Build + Run
2. **Check all logs** - Filter by emoji prefixes
3. **Verify data counts** - Should see actual numbers in logs
4. **Report back** - Share specific log lines showing issues

### **When reporting issues:**
```
Include:
- Specific log lines (📊 ❤️ 💔 💤)
- Screenshot of problematic chart
- Period selected (7/30/60 days)
- Expected vs actual behavior
```

---

## 🎯 **FILES CHANGED IN THIS SESSION**

1. **RecoveryDetailView.swift** - Added logging to data fetchers
2. **HRVLineChart.swift** - RED color, 1px line, average line
3. **RHRCandlestickChart.swift** - RED candlesticks
4. **TrendChart.swift** - Darker bars (systemGray2)
5. **SleepDetailView.swift** - Added hypnogram section, logging

---

## ✅ **COMMIT HISTORY**

- `05c3229` - Comprehensive logging and chart colors
- `4eb049b` - Hypnogram added to Sleep Detail

**All changes pushed to `main` branch.**

---

**BUILD THE APP AND CHECK THE LOGS!** 🚀
