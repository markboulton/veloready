# Remaining Issues - Batch 2

## 🔴 CRITICAL DATA ISSUES

### 1. TSS Showing 0 Despite CTL/ATL Calculation

**Symptoms:**
- Logs show: "Weekly TSS: 0.0 from 0 days"
- But CTL=76.14916113219194, ATL=17.043128012322843 exist
- Training time and workout count also show 0

**Analysis:**
From logs on Oct 18:
```
Day 0-5: TSS=0.0, CTL=0.0, ATL=0.0
Day 6: TSS=0.0, CTL=76.14916113219194, ATL=17.043128012322843
```

**Root Cause:**
CTL/ATL are being calculated but TSS is not being saved to `DailyLoad.tss` field.

**Location:**
- `WeeklyReportViewModel.swift` Line 286-290 (reads from day.load?.tss)
- Need to check where TSS is written to Core Data

**Fix Required:**
1. Find where CTL/ATL calculation happens (CacheManager.calculateMissingCTLATL)
2. Ensure TSS is also saved when CTL/ATL are calculated
3. Verify DailyLoad entity has tss field and it's being populated

---

### 2. CTL/ATL Historical Data Missing

**Symptoms:**
- Only Oct 18 has CTL/ATL data
- Days Oct 12-17 show CTL=0.0, ATL=0.0
- Fitness Trajectory chart has no historical data

**Analysis:**
From logs:
```
Oct 12: CTL=0.0, ATL=0.0
Oct 13: CTL=0.0, ATL=0.0
Oct 14: CTL=0.0, ATL=0.0
Oct 15: CTL=0.0, ATL=0.0
Oct 16: CTL=0.0, ATL=0.0
Oct 17: CTL=0.0, ATL=0.0
Oct 18: CTL=76.1, ATL=17.0
```

**Root Cause:**
`CacheManager.calculateMissingCTLATL()` is only calculating for today, not backfilling historical days.

**Location:**
- `WeeklyReportViewModel.swift` Line 707
- `CacheManager.swift` - calculateMissingCTLATL() method

**Fix Required:**
1. Modify calculateMissingCTLATL() to backfill last 42 days
2. Use progressive calculation from earliest activity
3. Save CTL/ATL for each day, not just today

---

### 3. Sleep Data Showing 24 Hours

**Symptoms:**
- Logs show: "Bedtime: 00:00 = 24.0h" and "Wake: 00:01 = 0.016666666666666666h"
- Some days showing 24 hours of sleep

**Analysis:**
From logs:
```
Bedtime: 00:00 = 24.0h
Bedtime: 00:01 = 24.016666666666666h
Bedtime: 00:07 = 24.116666666666667h
Bedtime: 00:09 = 24.15h
Bedtime: 00:25 = 24.416666666666668h
Bedtime: 00:04 = 24.066666666666666h
Average bedtime: 23.985714285714288h (raw: 23.985714285714288)

Wake: 07:07 = 7.116666666666666h
Wake: 00:01 = 0.016666666666666666h
Wake: 00:07 = 0.11666666666666667h
Wake: 00:09 = 0.15h
Wake: 00:25 = 0.4166666666666667h
Wake: 06:55 = 6.916666666666667h
Wake: 06:54 = 6.9h
Average wake time: 3.0904761904761906h
```

**Root Cause:**
Time conversion issue - bedtimes after midnight (00:00-00:59) are being treated as 24.0+ hours instead of 0.0-1.0 hours.

**Location:**
- `SleepScoreService.swift` or `WeeklyReportViewModel.swift`
- Time calculation for circadian rhythm analysis

**Fix Required:**
1. Handle midnight crossover properly
2. Bedtime 00:00 should be 0.0h (or 24.0h if meant to represent late night)
3. Need to determine if 00:00 bedtime means midnight (start of day) or end of previous day
4. Likely need to use 24-hour format with proper date handling

---

## ⚠️ MEDIUM PRIORITY

### 4. Legend Color Mapping

**Status:** NEEDS VERIFICATION

**Task:**
Verify that Fitness Trajectory chart legend colors match the actual line colors:
- CTL line: Color.button.primary.opacity(0.5)
- ATL line: Color.semantic.warning.opacity(0.5)
- TSB line: ColorScale.greenAccent.opacity(0.5)

**Action:**
Find the legend component and ensure it uses the same colors.

---

## 📋 INVESTIGATION STEPS

### For TSS Issue:
1. Search for where DailyLoad.tss is set
2. Check CacheManager.calculateMissingCTLATL() implementation
3. Verify TSS calculation from activities
4. Add logging to TSS save operation

### For CTL/ATL Historical:
1. Review CacheManager.calculateMissingCTLATL()
2. Check if it's using progressive calculation
3. Verify it saves to Core Data for each day
4. May need to trigger backfill on app launch

### For Sleep 24h Issue:
1. Find circadian rhythm calculation code
2. Review time conversion logic
3. Check if using Date components properly
4. Test with various bedtime scenarios (before/after midnight)

---

## 🎯 PRIORITY ORDER

1. **TSS = 0 Issue** (Blocks training metrics)
2. **CTL/ATL Historical** (Blocks fitness trajectory)
3. **Sleep 24h Data** (Incorrect visualization)
4. **Legend Colors** (Visual polish)

---

## 📝 NOTES

- All UI fixes from Batch 2 are complete and committed
- These remaining issues are data/calculation problems, not UI issues
- May require changes to Core Data save logic
- Should add unit tests for these calculations
