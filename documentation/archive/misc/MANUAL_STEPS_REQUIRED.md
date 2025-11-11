# Manual Steps Required - VeloReadyCore Integration

## Current Status
✅ VeloReadyCore package created and tested (48 tests passing in 1.4s)  
✅ RecoveryCalculations extracted and tested (36 tests)  
✅ RecoveryScoreService updated to use VeloReadyCore  
❌ **BLOCKED:** VeloReadyCore needs to be added as Xcode dependency

---

## REQUIRED: Add VeloReadyCore to Xcode Project

### Step 1: Open Xcode
```bash
open VeloReady.xcodeproj
```

### Step 2: Add Local Package
1. In Xcode, go to **File > Add Package Dependencies...**
2. Click the **"Add Local..."** button (bottom left)
3. Navigate to and select the `VeloReadyCore` folder
4. Click **"Add Package"**

### Step 3: Link to Target
1. In the dialog that appears, ensure **VeloReady** target is selected
2. Check the **VeloReadyCore** library checkbox
3. Click **"Add Package"**

### Step 4: Verify
Build the project:
```bash
./Scripts/quick-test.sh
```

Should see:
```
✅ Build successful
✅ All critical unit tests passed
```

---

## What Changed

### Files Modified
1. **RecoveryScoreService.swift** (1132 lines)
   - Added `import VeloReadyCore`
   - Replaced `RecoveryScoreCalculator.calculate()` with `VeloReadyCore.RecoveryCalculations.calculateScore()`
   - Replaced duplicate `calculateCTL()` with `VeloReadyCore.TrainingLoadCalculations.calculateCTL()`
   - Replaced duplicate `calculateATL()` with `VeloReadyCore.TrainingLoadCalculations.calculateATL()`
   - Maps VeloReadyCore results back to iOS `RecoveryScore` model

2. **RecoveryScoreServiceExtensions.swift** (NEW - 15 lines)
   - Added `determineBand()` helper method

---

## Why This Matters

### Before (Old Architecture)
```
RecoveryScoreService (1084 lines)
  ├── Data fetching (HealthKit, Intervals, Strava)
  ├── Calculation logic (duplicated with RecoveryScoreCalculator)
  └── Publishing results

RecoveryScoreCalculator (in RecoveryScore.swift)
  └── Same calculation logic (duplicate)
```

### After (New Architecture)
```
RecoveryScoreService (1132 lines - thin orchestrator)
  ├── Data fetching (HealthKit, Intervals, Strava) ← STAYS IN iOS
  ├── Calls VeloReadyCore for calculations ← DELEGATES TO CORE
  └── Publishing results ← STAYS IN iOS

VeloReadyCore (pure Swift, no iOS deps)
  ├── RecoveryCalculations (364 lines) ← TESTABLE IN 1.4s
  ├── TrainingLoadCalculations (120 lines) ← REUSABLE
  └── 48 tests passing ← FAST, RELIABLE
```

### Benefits
✅ **Fast testing:** 1.4s vs 78s (52x faster)  
✅ **Reusable:** Backend/ML/Widgets can use same logic  
✅ **No duplication:** Single source of truth for calculations  
✅ **No iOS dependencies:** Pure Swift, runs anywhere  

---

## What's Next (After Adding Package)

Once VeloReadyCore is added and tests pass:

### Phase 1.2 Remaining
- ✅ Extract RecoveryCalculations
- ✅ Create comprehensive tests  
- ✅ Update RecoveryScoreService
- ❌ **ADD PACKAGE DEPENDENCY** ← YOU ARE HERE
- ❌ Verify all iOS tests pass

### Phase 1.3 (Next)
- Extract SleepCalculations
- Extract StrainCalculations
- Update corresponding services

---

## Troubleshooting

### Build Error: "Unable to find module dependency: 'VeloReadyCore'"
**Cause:** Package not added to Xcode project  
**Solution:** Follow Step 2 above

### Package Not Showing in "Add Local"
**Verify:** VeloReadyCore/Package.swift exists:
```bash
ls -la VeloReadyCore/Package.swift
```
Should show the Package.swift file

### Tests Fail After Adding Package
**Run:** VeloReadyCore tests first to verify:
```bash
cd VeloReadyCore && swift test
```
Should see: `Executed 48 tests, with 0 failures`

---

## Documentation

**Full details:**
- `documentation/refactor-2025-11-06/PHASE1_RECOVERY_EXTRACTION_COMPLETE.md`
- `documentation/refactor-2025-11-06/PHASE1_SETUP_COMPLETE.md`

**Branch:** `phase-1`  
**Commits:**
- `8103541` - Extract RecoveryCalculations to VeloReadyCore
- `cc248d3` - Organize VeloReadyCore structure and documentation
- `<next>` - Integrate VeloReadyCore with iOS app ← PENDING

---

## Summary

**You're 95% done with Phase 1.2!** Just need to add the package in Xcode and verify tests pass.

**Estimated time:** 2 minutes (manual Xcode step)

**After this:** Ready to proceed with Sleep & Strain calculations extraction!
