# Chart Logging Fix - Nov 16, 2025

## Issue Report
Charts on Recovery, Load, and Sleep detail pages showed confusing negative "filled days" in logs:
```
📊 [LOAD CHART] Filled -5 missing days with 0 strain ❌
📊 [LOAD CHART] Filled -12 missing days with 0 strain ❌
```

User reported charts showing "partial data (or data with 50%)" with "minimal data visible."

## Root Cause Analysis

### 1. **Logging Bug** (StrainDetailViewModel.swift:136)
Used wrong count when calculating filled days:

```swift
// ❌ WRONG
Logger.debug("Filled \(completeDataPoints.count - dataPoints.count) missing days...")
//                                             ^^^^^^^^^^^^^^^^^^
//                                             Raw count (with duplicates)
// Result: 7 - 12 = -5 days (NEGATIVE!)

// ✅ CORRECT
Logger.debug("Filled \(completeDataPoints.count - dataPointsByDate.count) missing days...")
//                                             ^^^^^^^^^^^^^^^^^^^^^
//                                             Deduplicated count
// Result: 7 - 7 = 0 days (ACCURATE!)
```

**Why this happened:**
- Core Data can return multiple records per day (different timestamps)
- Example: 6 walking activities on Nov 10 → 6 raw records → 1 unique day
- Using `dataPoints.count` (12 raw) instead of `dataPointsByDate.count` (7 unique) = negative math

### 2. **Visual Issue: Low Data Values**
Charts ARE fetching all data correctly, but user sees "minimal bars" because:

**Load Chart (7 days):**
- 4 days: 0.0 strain (rest days) → flat line at bottom
- 3 days: 2.4-7.5 strain (light activity) → small bars
- **Visual effect**: "Only 3 bars visible, looks like partial data"

**Recovery Chart (30 days):**
- Many days: 50.0 (baseline/default when limited data)
- Recent days: 46-71 (actual varying scores)
- **Visual effect**: "All bars same height at 50%, looks incomplete"

**Sleep Chart:**
- Missing nights → gaps in chart
- **Visual effect**: "Partial data showing"

## The Fix

### Code Changes
**File**: `VeloReady/Features/Shared/ViewModels/StrainDetailViewModel.swift`

**Line 136** - Fixed calculation:
```swift
// Before
Logger.debug("📊 [LOAD CHART] Filled \(completeDataPoints.count - dataPoints.count) missing days with 0 strain")

// After
Logger.debug("📊 [LOAD CHART] Filled \(completeDataPoints.count - dataPointsByDate.count) missing days with 0 strain")
```

**Line 135-137** - Added activity breakdown:
```swift
let nonZeroDays = strainValues.filter { $0 > 0 }.count
Logger.debug("📊 [LOAD CHART] Strain range: min=\(String(format: "%.1f", minStrain)), max=\(String(format: "%.1f", maxStrain)), avg=\(String(format: "%.1f", avgStrain))")
Logger.debug("📊 [LOAD CHART] Activity breakdown: \(nonZeroDays) days with training, \(completeDataPoints.count - nonZeroDays) rest days")
Logger.debug("📊 [LOAD CHART] Filled \(completeDataPoints.count - dataPointsByDate.count) missing days with 0 strain")
```

## Verification

### Before Fix
```
📊 [LOAD CHART] 12 records → 12 points for 7d view
📊 [LOAD CHART] Deduplicated to 7 unique days
📊 [LOAD CHART] Strain range: min=0.0, max=7.5, avg=1.8
📊 [LOAD CHART] Filled -5 missing days with 0 strain ❌ CONFUSING!
```

### After Fix
```
📊 [LOAD CHART] 12 records → 12 points for 7d view
📊 [LOAD CHART] Deduplicated to 7 unique days
📊 [LOAD CHART] Strain range: min=0.0, max=7.5, avg=1.8
📊 [LOAD CHART] Activity breakdown: 3 days with training, 4 rest days ✅ CLEAR!
📊 [LOAD CHART] Filled 0 missing days with 0 strain ✅ ACCURATE!
```

### Test Results
```bash
cd /Users/markboulton/Dev/veloready
./Scripts/quick-test.sh
```

**Result**: ✅ All tests pass (78s)

## Impact

### Developer Experience
- ✅ Logs now show accurate "filled days" count (0 instead of -5)
- ✅ Logs explain why data looks minimal (3 training days, 4 rest days)
- ✅ Easier debugging when charts show low values

### User Experience
- ℹ️ No user-facing changes (charts already working correctly)
- ℹ️ Charts display actual data accurately:
  - 0.0 strain = rest day (correct)
  - 50.0 recovery = baseline (correct)
  - Missing sleep = gap (correct)

### Code Quality
- ✅ Fixed off-by-one-style logging bug
- ✅ Added clarity with activity breakdown
- ✅ Maintains existing chart functionality

## What's NOT a Bug

The charts are working correctly:
1. ✅ Fetching correct number of days (7, 30, 60)
2. ✅ Deduplicating multiple records per day
3. ✅ Filling missing days with 0 for strain (rest days)
4. ✅ Displaying actual data values accurately
5. ✅ Using correct y-axis scales (0-18 for strain, 0-100 for recovery/sleep)

**The "minimal data" appearance is real data:**
- Real rest days (0 strain) → flat lines
- Real baseline scores (50 recovery) → uniform bars
- Real missing nights → gaps

## Files Modified

1. **StrainDetailViewModel.swift** (Lines 135-138)
   - Fixed: Use `dataPointsByDate.count` instead of `dataPoints.count`
   - Added: Activity breakdown logging

2. **CHART_MINIMAL_DATA_EXPLAINED.md** (New)
   - Documentation explaining why charts appear minimal
   - User guidance for getting more visible data

3. **CHART_LOGGING_FIX_SUMMARY.md** (This file)
   - Fix summary and verification

## Related Memories

This fix complements the previous chart granularity improvements:
- **CHART_GRANULARITY_FIX.md**: Fixed x-axis label stride (every 6 days for 30d, every 12 for 60d)
- **TRAINING_LOAD_CHART_FIXES.md**: RAG gradient coloring, interactive selection, tooltip display

## Status

✅ **COMPLETE** - Logging bug fixed, tests passing, documentation added

**Recommendation**: Merge this fix to reduce developer confusion when debugging chart data.
