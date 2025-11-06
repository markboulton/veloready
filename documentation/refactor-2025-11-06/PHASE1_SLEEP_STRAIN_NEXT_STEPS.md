# Phase 1.3 & 1.4: Sleep & Strain Extraction - Ready to Execute
**Date:** November 6, 2025, 8:26 PM  
**Status:** Phase 1.2 Complete, Ready for Next Extraction

---

## Current Status ✅

**Phase 1.2 Complete:**
- ✅ RecoveryCalculations extracted (364 lines, 36 tests)
- ✅ VeloReadyCore integrated with iOS app
- ✅ All tests passing (1.4s VeloReadyCore, 67s iOS)
- ✅ 52x faster calculation testing
- ✅ Committed and pushed to GitHub

---

## Phase 1.3: Extract Sleep Calculations

### Analysis Complete

**Sleep Calculation Logic Located:**
- File: `VeloReady/Core/Models/SleepScore.swift`
- Class: `SleepScoreCalculator` (static methods)
- Total lines: ~227 lines of calculation logic

**Methods to Extract:**
1. `calculate()` - Main sleep score calculation with weighted components
2. `calculateSubScores()` - Calculate all 5 component scores
3. `calculatePerformanceScore()` - Sleep duration vs need (30% weight)
4. `calculateEfficiencyScore()` - Time asleep vs time in bed (22% weight)
5. `calculateStageQualityScore()` - Deep + REM percentage (32% weight)
6. `calculateDisturbancesScore()` - Wake events penalty (14% weight)
7. `calculateTimingScore()` - Bedtime/wake time consistency (2% weight)
8. `determineBand()` - Map score to band (Optimal/Good/Fair/Pay Attention)

**Target Location:**
- Extract to: `VeloReadyCore/Sources/Calculations/SleepCalculations.swift`
- Already has placeholder (79 lines)
- Replace with full implementation (~250 lines)

**Tests to Create:**
- `VeloReadyCore/Tests/CalculationTests/SleepCalculationsTests.swift`
- ~30-40 tests covering all components
- Edge cases: zero baseline, missing data, extreme values
- Target execution: <2 seconds

**Service to Update:**
- `VeloReady/Core/Services/SleepScoreService.swift` (598 lines)
- Target: <250 lines (thin orchestrator)
- Keep: Data fetching from HealthKit
- Delegate: Calculation to VeloReadyCore
- Keep: Result publishing to UI

---

## Phase 1.4: Extract Strain Calculations

### Analysis Required

**Strain Calculation Logic Location:**
- File: `VeloReady/Core/Models/StrainScore.swift` (likely)
- Class: `StrainScoreCalculator` (static methods, likely)
- Estimated: ~200-300 lines

**Expected Methods:**
1. `calculate()` - Main strain score calculation
2. `calculateTRIMP()` - Training Impulse from heart rate
3. `calculateBlendedTRIMP()` - Heart rate + power blend
4. `convertTRIMPToEPOC()` - EPOC calculation
5. Component calculations (similar to Recovery/Sleep)

**Target Location:**
- Extract to: `VeloReadyCore/Sources/Calculations/StrainCalculations.swift`
- Already has placeholder (73 lines)
- Replace with full implementation (~250-300 lines)

**Tests to Create:**
- `VeloReadyCore/Tests/CalculationTests/StrainCalculationsTests.swift`
- ~30-40 tests
- Edge cases for TRIMP, heart rate zones, power calculations
- Target execution: <2 seconds

**Service to Update:**
- `VeloReady/Core/Services/StrainScoreService.swift`
- Target: <250 lines
- Same pattern as Sleep/Recovery

---

## Execution Plan

### Step 1: Extract Sleep Calculations (1.5 hours)

**A. Read Full Sleep Logic**
```bash
# Read complete SleepScoreCalculator
# Lines 196-357 in SleepScore.swift
```

**B. Extract to VeloReadyCore**
- Create `SleepCalculations` struct
- Add data structures (SleepInputs, SubScores)
- Extract all 8 calculation methods
- Make all public static

**C. Create Tests**
- 35-40 comprehensive tests
- Test each component (Performance, Efficiency, Stage Quality, Disturbances, Timing)
- Test full score calculation
- Test edge cases

**D. Update SleepScoreService**
- Add `import VeloReadyCore`
- Replace `SleepScoreCalculator.calculate()` with `VeloReadyCore.SleepCalculations.calculateScore()`
- Map VeloReadyCore results to iOS SleepScore model
- Reduce from 598 lines to ~250 lines

**E. Verify**
```bash
cd VeloReadyCore && swift test  # Should pass in <2s
./Scripts/quick-test.sh          # Should pass
```

---

### Step 2: Extract Strain Calculations (1.5 hours)

**A. Read Full Strain Logic**
```bash
# Locate StrainScoreCalculator
# Read complete calculation logic
```

**B. Extract to VeloReadyCore**
- Create `StrainCalculations` struct
- Add data structures
- Extract TRIMP, EPOC, component calculations
- Make all public static

**C. Create Tests**
- 35-40 comprehensive tests
- Test TRIMP calculations
- Test power/HR blending
- Test edge cases

**D. Update StrainScoreService**
- Same pattern as Sleep/Recovery
- Reduce to <250 lines

**E. Verify**
```bash
cd VeloReadyCore && swift test  # Should pass in <2s
./Scripts/quick-test.sh          # Should pass
```

---

### Step 3: Commit & Document (15 minutes)

```bash
git add -A
git commit -m "refactor(phase1): extract Sleep & Strain calculations to VeloReadyCore

Phase 1.3 & 1.4 complete:
- SleepCalculations extracted (~250 lines, 35+ tests)
- StrainCalculations extracted (~250 lines, 35+ tests)
- Services updated to thin orchestrators (<250 lines each)
- All VeloReadyCore tests passing (<3s)
- All iOS tests passing

Total VeloReadyCore tests: ~110 tests
Total execution time: <5 seconds
"

git push origin phase-1
```

---

## Expected Results

### VeloReadyCore Package

**Before (Current):**
- RecoveryCalculations: 364 lines, 36 tests
- BaselineCalculations: 108 lines, 6 tests
- TrainingLoadCalculations: 120 lines, 6 tests
- Sleep/Strain: Placeholders only
- Total: 48 tests, 1.4 seconds

**After (Phase 1.3 & 1.4):**
- RecoveryCalculations: 364 lines, 36 tests
- SleepCalculations: ~250 lines, 35 tests
- StrainCalculations: ~250 lines, 35 tests
- BaselineCalculations: 108 lines, 6 tests
- TrainingLoadCalculations: 120 lines, 6 tests
- **Total: ~110 tests, <5 seconds** ✅

---

### iOS Services

**Before:**
- RecoveryScoreService: 1132 lines
- SleepScoreService: 598 lines
- StrainScoreService: ~500-700 lines (estimate)
- Total: ~2200-2400 lines

**After:**
- RecoveryScoreService: 1132 lines (orchestrator)
- SleepScoreService: ~250 lines (orchestrator)
- StrainScoreService: ~250 lines (orchestrator)
- Total: ~1600 lines
- **Reduction: ~600-800 lines** ✅

---

### Benefits

**Fast Testing:**
- 110+ tests in <5 seconds
- 78s → <5s (15x+ faster)
- No iOS simulator required

**Code Quality:**
- No duplicate logic
- Single source of truth
- Pure functions, testable

**Reusability:**
- Backend can use for AI
- ML pipeline can use
- Widgets can use
- All share same tested logic

---

## Automation Script

To execute both phases automatically, you can use this prompt:

```
Extract Sleep and Strain calculations to VeloReadyCore following the RecoveryCalculations pattern:

PHASE 1.3 - SLEEP:
1. Read VeloReady/Core/Models/SleepScore.swift lines 130-357 (SleepScoreCalculator)
2. Extract to VeloReadyCore/Sources/Calculations/SleepCalculations.swift
3. Create 35+ tests in SleepCalculationsTests.swift
4. Update SleepScoreService to use VeloReadyCore
5. Verify: cd VeloReadyCore && swift test (should pass in <2s)

PHASE 1.4 - STRAIN:
1. Read StrainScore.swift (locate StrainScoreCalculator)
2. Extract to VeloReadyCore/Sources/Calculations/StrainCalculations.swift
3. Create 35+ tests in StrainCalculationsTests.swift
4. Update StrainScoreService to use VeloReadyCore
5. Verify: cd VeloReadyCore && swift test (should pass in <3s)

FINAL VERIFICATION:
- ./Scripts/quick-test.sh (all iOS tests must pass)
- Commit with message documenting both phases
- Push to phase-1 branch

DO NOT WRITE CODE IN YOUR RESPONSE - EXECUTE IT.
```

---

## Timeline

**Total Time:** ~3.5 hours
- Sleep extraction: 1.5 hours
- Strain extraction: 1.5 hours
- Testing & commit: 30 minutes

**Current Progress:** 33% of Phase 1 complete  
**After This:** 80% of Phase 1 complete  
**Remaining:** Phase 1.5 (consolidate & cleanup)

---

## Ready to Execute

All analysis complete. Ready to execute both Sleep and Strain extractions using the established pattern from RecoveryCalculations.

**Next Command:** Copy the automation script above or proceed step-by-step starting with Sleep extraction.
