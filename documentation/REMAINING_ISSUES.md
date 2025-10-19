# Remaining Issues - Batch 2

## ✅ ALL CRITICAL DATA ISSUES FIXED

### 1. TSS Showing 0 Despite CTL/ATL Calculation ✅ FIXED

**Solution Implemented:**
- Added `getDailyTSSFromActivities()` method to extract TSS per day
- Modified `calculateMissingCTLATL()` to include TSS in progressive load calculation
- Updated `updateDailyLoadBatch()` to save TSS alongside CTL/ATL
- File: `CacheManager.swift`, `TrainingLoadCalculator.swift`

**Performance Optimization:**
- Batch Core Data updates using background context
- Single save operation for all days
- Conditional updates (only if CTL/ATL < 1.0)

---

### 2. CTL/ATL Historical Data Missing ✅ FIXED

**Solution Implemented:**
- Modified `calculateMissingCTLATL()` to backfill last 42 days
- Uses progressive calculation with incremental EMA formula
- Calculates from earliest activity date to today
- Saves CTL/ATL/TSS for each day in batch operation
- File: `CacheManager.swift`

**Algorithm:**
```swift
// Incremental EMA update (O(n) complexity)
currentCTL = (tss * ctlAlpha) + (currentCTL * (1 - ctlAlpha))
currentATL = (tss * atlAlpha) + (currentATL * (1 - atlAlpha))

// where:
// ctlAlpha = 2.0 / 43.0  (42-day time constant)
// atlAlpha = 2.0 / 8.0   (7-day time constant)
```

**Baseline Estimation:**
- Uses first 2 weeks of activity to establish baseline
- Prevents "cold start" problem where fitness resets to zero
- More accurate CTL/ATL values from day one

---

### 3. Sleep Data Showing 24 Hours ✅ FIXED

**Solution Implemented:**
- Fixed variance calculation to use normalized bedtime values
- Added normalization step before calculating standard deviation
- Prevents 24+ hour values from skewing variance calculation
- File: `WeeklyReportViewModel.swift` Lines 607-614

**Code Change:**
```swift
// Before: Used raw bedtimeHours (could be 24+)
let bedtimeMinutes = bedtimeHours.map { $0 * 60 }

// After: Normalize before variance calculation
let normalizedBedtimes = bedtimeHours.map { $0 >= 24 ? $0 - 24 : $0 }
let bedtimeMinutes = normalizedBedtimes.map { $0 * 60 }
```

**Why This Works:**
- Bedtimes after midnight (00:00-05:59) are stored as 24.0-29.99 for averaging
- This prevents wrapping issues (e.g., averaging 23:00 and 01:00)
- But variance calculation needs normalized 0-24 values
- Now correctly shows bedtime variance in minutes

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
