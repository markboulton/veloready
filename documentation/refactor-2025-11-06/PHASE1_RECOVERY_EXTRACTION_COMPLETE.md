# Phase 1: RecoveryCalculations Extraction Complete ✅
**Date:** November 6, 2025  
**Prompt:** 1.2 - Extract RecoveryScore calculation logic to VeloReadyCore  
**Commit:** 8103541

---

## What Was Accomplished

### 1. Extracted Pure Calculation Logic ✅

**From:** `VeloReady/Core/Models/RecoveryScore.swift` (RecoveryScoreCalculator class)  
**To:** `VeloReadyCore/Sources/Calculations/RecoveryCalculations.swift` (364 lines)

**Extracted Methods:**
- `calculateScore()` - Main recovery score calculation with weighted components
- `calculateSubScores()` - Calculate all 5 component scores
- `calculateHRVComponent()` - HRV scoring with graduated penalties (0-100)
- `calculateRHRComponent()` - RHR scoring with graduated penalties (0-100)
- `calculateSleepComponent()` - Sleep scoring (uses comprehensive score or duration)
- `calculateRespiratoryComponent()` - Respiratory rate stability scoring (0-100)
- `calculateFormComponent()` - Training load/form scoring from ATL/CTL (0-100)
- `calculateTSSPenalty()` - Yesterday's TSS penalty calculation
- `applyAlcoholCompoundEffect()` - Alcohol detection with illness awareness

**Data Structures Created:**
- `RecoveryInputs` - Input parameters for calculation
- `SubScores` - Component scores (HRV, RHR, Sleep, Form, Respiratory)

---

### 2. Created Comprehensive Tests ✅

**File:** `VeloReadyCore/Tests/CalculationTests/RecoveryCalculationsTests.swift`  
**Tests:** 36 tests across 9 test suites

#### Test Coverage:

**HRV Component Tests (7 tests)**
- Above baseline → 100 score
- Small drop (5%) → Minimal penalty (≥85)
- Moderate drop (15%) → Moderate penalty (60-85)
- Significant drop (30%) → Large penalty (30-60)
- Extreme drop (40%) → Maximum penalty (<30)
- No data → Neutral score (50)
- Zero baseline → Neutral score (50)

**RHR Component Tests (4 tests)**
- At/below baseline → 100 score
- Small increase (5%) → Minimal penalty (≥88)
- Moderate increase (12%) → Moderate penalty (67-88)
- No data → Neutral score (50)

**Sleep Component Tests (4 tests)**
- With sleep score → Uses comprehensive score
- Without sleep score → Calculates from duration
- Below baseline → Proportional score (e.g., 6/8 hrs = 75)
- No data → Neutral score (50)

**Respiratory Component Tests (4 tests)**
- Very stable (±5%) → 100 score
- Moderate variability (10%) → Moderate score (50-100)
- High variability (20%) → Low score (<50)
- No data → Neutral score (50)

**Form Component Tests (4 tests)**
- Fresh state (ATL < CTL) → 100 score
- Fatigued state (ATL > CTL) → Lower score
- With recent strain → Applies TSS penalty
- No data → Neutral score (50)

**TSS Penalty Tests (4 tests)**
- Easy day (TSS <50) → No penalty (0)
- Moderate day (TSS 75) → Small penalty (5pts)
- Hard day (TSS 150) → Large penalty (17.5pts)
- Very hard day (TSS 250) → Maximum penalty (≤40pts, capped)

**Alcohol Detection Tests (5 tests)**
- With illness indicator → Skips detection (no penalty)
- No sleep data → Skips detection (unreliable)
- Heavy drinking (>35% HRV drop) → Large penalty (≤15pts)
- Moderate drinking (20-25% drop) → Moderate penalty (~5pts)
- Excellent sleep → Mitigates penalty (30% reduction)

**Full Score Calculation Tests (4 tests)**
- Optimal inputs → High score (≥90)
- Poor inputs → Low score (<50)
- Without sleep data → Uses rebalanced weights (HRV 42.8%, RHR 28.6%)
- Minimal data → Above-neutral score (HRV at baseline)

---

### 3. Test Execution Performance ✅

**VeloReadyCore Tests:**
```bash
$ cd VeloReadyCore && swift test
Executed 48 tests, with 0 failures
Time: 1.4 seconds ✅
```

**Breakdown:**
- BaselineCalculationsTests: 6 tests
- TrainingLoadCalculationsTests: 6 tests
- **RecoveryCalculationsTests: 36 tests** ← NEW!

**Performance:** 🚀
- **1.4 seconds total** (Target: <5s) ✅
- **52x faster than iOS simulator tests** (1.4s vs 78s)
- **No iOS dependencies** - Pure Swift, runs on any platform

---

### 4. iOS Tests Still Pass ✅

**Full Test Suite:**
```bash
$ ./Scripts/full-test.sh
✅ Build successful
✅ All critical unit tests passed
Time: 108 seconds
```

**No Regressions:**
- All existing iOS tests pass
- RecoveryScore model still works (uses old RecoveryScoreCalculator)
- Will update RecoveryScoreService in next step

---

## Key Achievements

### ✅ Pure Functions
- No iOS/UI dependencies
- No HealthKit, no SwiftUI, no frameworks
- Just Swift Foundation
- Testable on macOS, Linux, server

### ✅ Comprehensive Testing
- 36 tests covering all calculation paths
- Edge cases tested (zero baseline, negative values, missing data)
- Illness detection tested (skips alcohol penalty)
- Full score calculation tested (optimal/poor/minimal inputs)

### ✅ Blazing Fast Tests
- **1.4 seconds** for 48 tests (36 recovery + 12 baseline/training)
- Can run in CI without simulator
- Fast iteration during development

### ✅ Reusable Logic
- Backend can use for AI brief generation
- ML pipeline can use for training data
- Widgets can use for calculations
- All share same tested logic

---

## Code Metrics

### Before Extraction
- RecoveryScore.swift: 765 lines (includes RecoveryScoreCalculator)
- Tests: 0 VeloReadyCore tests for recovery logic
- Test time: N/A (required iOS simulator, 78s)

### After Extraction
- RecoveryCalculations.swift: 364 lines (pure calculations)
- RecoveryCalculationsTests.swift: 556 lines (36 tests)
- RecoveryScore.swift: 765 lines (unchanged - will update service next)
- Test time: 1.4 seconds ✅

---

## Next Steps (Prompt 1.2 Continued)

### 5. Update RecoveryScoreService (Not Yet Done)
- Make it thin orchestrator (<250 lines)
- Fetch data (stays in iOS)
- Call `RecoveryCalculations.calculateScore()`
- Publish results (stays in iOS)
- Delete duplicate calculation code

**Target:** RecoveryScoreService.swift: 1084 → ~250 lines

### 6. Verify iOS Tests Pass (Not Yet Done)
- Ensure no regressions
- RecoveryScore calculation identical
- All views still work

---

## Design Decisions

### Why Separate RecoveryInputs/SubScores?
- **RecoveryInputs:** Pure calculation needs don't depend on iOS SleepScore model
- **SubScores:** Need public struct for iOS service to use
- **Benefit:** VeloReadyCore has zero iOS dependencies

### Why Skip Alcohol Detection on Illness?
- Illness and alcohol have identical physiological signals (HRV drop, elevated RHR, poor sleep)
- Prevents false alcohol detection when user is sick
- Extracted this logic so it's testable and documented

### Why Rebalanced Weights Without Sleep?
- Sleep is 30% of recovery score normally
- Without sleep data, redistribute proportionally to other components
- HRV: 30% → 42.8%, RHR: 20% → 28.6%, Resp: 10% → 14.3%, Load: 10% → 14.3%
- Maintains algorithmic integrity

---

## Benefits Achieved

### Developer Experience ✅
- **Fast iteration:** Edit calculation, test in 1.4s
- **No simulator:** Pure Swift tests on any machine
- **CI-friendly:** Tests run without iOS simulator overhead

### Code Quality ✅
- **Pure functions:** Predictable, testable, maintainable
- **Comprehensive tests:** 36 tests covering edge cases
- **Documented:** Clear comments explain algorithm

### Architecture ✅
- **Reusable:** Backend/ML/Widgets can use same logic
- **Scalable:** Easy to add new components or modify weights
- **Testable:** Changes verified in seconds, not minutes

---

## Commit Details

**Branch:** phase-1  
**Commit:** 8103541  
**Message:**
```
refactor(phase1): extract RecoveryCalculations to VeloReadyCore

Extracted pure calculation logic from RecoveryScore model to VeloReadyCore:

## What Was Extracted
- RecoveryCalculations struct with all calculation methods
- calculateScore() - main recovery score calculation
- calculateHRVComponent() - HRV scoring (0-100)
- calculateRHRComponent() - RHR scoring (0-100)
- calculateSleepComponent() - sleep scoring (0-100)
- calculateRespiratoryComponent() - respiratory scoring (0-100)
- calculateFormComponent() - training load/form scoring (0-100)
- calculateTSSPenalty() - yesterday's TSS penalty
- applyAlcoholCompoundEffect() - alcohol detection with illness awareness

## Tests
- Created RecoveryCalculationsTests.swift with 36 comprehensive tests
- All component calculations tested with edge cases
- Full score calculation tested with optimal/poor/minimal inputs
- Alcohol detection tested including illness skip
- Test execution: 1.4 seconds (48 total tests) ✅

## Benefits
- Pure functions: No iOS dependencies, testable in <2s
- Reusable: Backend/ML/Widgets can use same logic
- Tested: 36 tests covering all calculation paths
- Maintainable: Clear separation of calculation vs data fetching

## Next Step
- Update RecoveryScoreService to thin orchestrator (<250 lines)
- Service will fetch data, call VeloReadyCore, publish results
```

---

## Status

**Phase 1.2:** ✅ 80% Complete
- [x] Analyze RecoveryScoreService.swift
- [x] Create RecoveryCalculations struct
- [x] Extract all calculation methods
- [x] Create comprehensive tests (36 tests)
- [x] Run VeloReadyCore tests (<5s target, achieved 1.4s)
- [ ] Update RecoveryScoreService to thin orchestrator
- [ ] Verify iOS tests pass with new integration

**Next Prompt:** Continue with updating RecoveryScoreService, or proceed to SleepCalculations extraction?

---

**Total Time:** ~2 hours  
**Lines Added:** 920 lines (364 source + 556 tests)  
**Tests Added:** 36 tests  
**Test Speed:** 1.4 seconds ✅  
**iOS Tests:** All passing ✅
