# Phase 2: Core Calculations Migration

## Overview
Extract and test the core business logic that calculates your training, recovery, and wellness scores. This phase focuses on moving **pure calculations** (no HealthKit/CoreData dependencies) to `VeloReadyCore`.

## Goals
1. ✅ **Independent Testing** - Test calculations on macOS without iOS simulator
2. ✅ **Fast CI** - Calculations tested in < 30 seconds on GitHub Actions
3. ✅ **Prevent Regressions** - Catch calculation bugs before they reach production
4. ✅ **Clear Ownership** - Single source of truth for each algorithm

## What Gets Extracted

### 1. Training Load Calculations (`TrainingLoadCalculations`)
**Pure Functions:**
- `calculateCTL(dailyValues: [Double]) -> Double`
- `calculateATL(dailyValues: [Double]) -> Double`
- `calculateTSB(ctl: Double, atl: Double) -> Double`
- `calculateExponentialAverage(values: [Double], days: Int) -> Double`
- `groupActivitiesByDate([Activity], calendar: Calendar) -> [Date: Double]`
- `calculateProgressiveLoad(dailyTSS: [Date: Double], startDate: Date, endDate: Date) -> [Date: (ctl: Double, atl: Double)]`

**Constants:**
```swift
let ctlAlpha = 2.0 / 43.0  // 42-day time constant
let atlAlpha = 2.0 / 8.0   // 7-day time constant
let baselineCTLMultiplier = 0.7
let baselineATLMultiplier = 0.4
```

**Why:** CTL/ATL are critical to the entire app. A bug here affects Recovery, Strain, and all recommendations.

### 2. Strain Score Calculations (`StrainCalculations`)
**Pure Functions:**
- `calculateStrainScore(inputs: StrainInputs) -> StrainScore`
- `calculateCardioLoad(trimp: Double, duration: Double?, intensityFactor: Double?) -> Int`
- `calculateStrengthLoad(rpe: Double, duration: Double, volume: Double?, sets: Int?, bodyMass: Double?) -> Int`
- `calculateNonExerciseLoad(steps: Int?, activeCalories: Double?) -> Int`
- `calculateRecoveryFactor(hrv: Double?, hrvBaseline: Double?, rhr: Double?, rhrBaseline: Double?, sleepQuality: Int?) -> Double`
- `determineStrainBand(score: Double) -> StrainBand`

**Constants:**
```swift
let cardioScaleFactor = 35.0
let strengthScaleFactor = 1.2
let nonExerciseScaleFactor = 25.0
let dailyCap = 20.0
let recoveryModulationRange = 0.15
```

**Why:** Strain is the core "daily output" metric. Must be accurate and consistent.

### 3. Recovery Score Calculations (`RecoveryCalculations`)
**Pure Functions:**
- `calculateRecoveryScore(inputs: RecoveryInputs) -> RecoveryScore`
- `calculateHRVScore(hrv: Double, baseline: Double) -> Int`
- `calculateRHRScore(rhr: Double, baseline: Double) -> Int`
- `calculateSleepScore(sleepDuration: Double, baseline: Double) -> Int`
- `calculateRespiratoryScore(rate: Double?, baseline: Double?) -> Int`
- `calculateFormScore(atl: Double, ctl: Double, yesterdayTSS: Double?) -> Int`
- `applyAlcoholCompoundEffect(baseScore: Double, hrvScore: Int, rhrScore: Int, sleepScore: Int) -> Double`
- `determineRecoveryBand(score: Int) -> RecoveryBand`

**Constants:**
```swift
let hrvWeight = 0.30
let rhrWeight = 0.20
let sleepWeight = 0.30
let respiratoryWeight = 0.10
let loadWeight = 0.10
```

**Why:** Recovery drives training recommendations. A bug here could cause overtraining or undertraining.

### 4. Sleep Score Calculations (`SleepCalculations`)
**Pure Functions:**
- `calculateSleepScore(inputs: SleepInputs) -> SleepScore`
- `calculatePerformanceScore(sleepDuration: Double, sleepNeed: Double) -> Int`
- `calculateEfficiencyScore(sleepDuration: Double, timeInBed: Double) -> Int`
- `calculateStageQualityScore(sleepDuration: Double, deepSleep: Double, remSleep: Double) -> Int`
- `calculateDisturbancesScore(wakeEvents: Int) -> Int`
- `calculateTimingScore(bedtime: Date, wakeTime: Date, baselineBedtime: Date, baselineWakeTime: Date) -> Int`
- `determineSleepBand(score: Int) -> SleepBand`

**Constants:**
```swift
let performanceWeight = 0.30
let efficiencyWeight = 0.22
let stageQualityWeight = 0.32
let disturbancesWeight = 0.14
let timingWeight = 0.02
```

**Why:** Sleep quality affects recovery and strain calculations. Must be accurate.

## Test Strategy

### Critical Test Cases (Must Pass)

#### Training Load Tests
1. ✅ **CTL Calculation** - Verify 42-day EMA with known data
2. ✅ **ATL Calculation** - Verify 7-day EMA with known data
3. ✅ **Progressive Load** - Verify day-by-day CTL/ATL progression
4. ✅ **Baseline Estimation** - Verify initial CTL/ATL from early activities
5. ✅ **Empty Data** - Verify graceful handling of no activities
6. ✅ **Single Day** - Verify calculation with single activity

#### Strain Score Tests
1. ✅ **Cardio Load** - Verify TRIMP → Strain conversion
2. ✅ **Strength Load** - Verify sRPE → Strain conversion
3. ✅ **Non-Exercise Load** - Verify steps/calories → Strain
4. ✅ **Recovery Modulation** - Verify HRV/RHR adjustment
5. ✅ **Band Determination** - Verify score → band mapping
6. ✅ **Edge Cases** - Verify zero inputs, extreme values

#### Recovery Score Tests
1. ✅ **HRV Sub-Score** - Verify HRV deviation → score
2. ✅ **RHR Sub-Score** - Verify RHR deviation → score
3. ✅ **Sleep Sub-Score** - Verify sleep duration → score
4. ✅ **Weighted Combination** - Verify final score calculation
5. ✅ **Alcohol Detection** - Verify compound effect detection
6. ✅ **Band Determination** - Verify score → band mapping

#### Sleep Score Tests
1. ✅ **Performance Score** - Verify duration vs need
2. ✅ **Efficiency Score** - Verify sleep/bed ratio
3. ✅ **Stage Quality** - Verify deep+REM percentage
4. ✅ **Disturbances Score** - Verify wake events → score
5. ✅ **Timing Score** - Verify baseline deviation
6. ✅ **Weighted Combination** - Verify final score calculation

### Known-Good Test Data
Use **real data from successful calculations** to create regression tests:
- Example: If CTL=45.2, ATL=32.1 for a specific activity set, that's a test case
- Example: If Strain=12.3 for specific TRIMP/steps/HRV, that's a test case

## Implementation Plan

### Step 1: Extract Training Load (30 min)
- [x] Create `TrainingLoadCalculations.swift` in `VeloReadyCore`
- [x] Extract pure calculation functions
- [x] Write 6 comprehensive tests
- [x] Verify tests pass

### Step 2: Extract Strain Score (30 min)
- [x] Create `StrainCalculations.swift` in `VeloReadyCore`
- [x] Extract pure calculation functions
- [x] Write 6 comprehensive tests
- [x] Verify tests pass

### Step 3: Extract Recovery Score (30 min)
- [x] Create `RecoveryCalculations.swift` in `VeloReadyCore`
- [x] Extract pure calculation functions
- [x] Write 6 comprehensive tests
- [x] Verify tests pass

### Step 4: Extract Sleep Score (30 min)
- [x] Create `SleepCalculations.swift` in `VeloReadyCore`
- [x] Extract pure calculation functions
- [x] Write 6 comprehensive tests
- [x] Verify tests pass

### Step 5: Update iOS App (30 min)
- [x] Update `TrainingLoadCalculator.swift` to use `TrainingLoadCalculations`
- [x] Update `StrainScore.swift` to use `StrainCalculations`
- [x] Update `RecoveryScore.swift` to use `RecoveryCalculations`
- [x] Update `SleepScore.swift` to use `SleepCalculations`
- [x] Verify app compiles and tests pass

### Step 6: CI Integration (10 min)
- [x] Update GitHub Actions to run `swift test` for `VeloReadyCore`
- [x] Verify CI passes

## Expected Results

### Before
- ❌ No tests for calculation logic
- ❌ Calculation bugs go undetected until production
- ❌ Complex setup required to test (HealthKit, CoreData, etc.)

### After
- ✅ 24+ comprehensive tests for core calculations
- ✅ Tests run in < 30 seconds on macOS
- ✅ Calculation bugs caught immediately in CI
- ✅ Simple, pure functions easy to test and maintain

## Benefits

1. **Fast Feedback** - Know if calculations break in seconds
2. **Confidence** - Every deploy is validated against known-good results
3. **Documentation** - Tests serve as examples of how calculations work
4. **Refactoring Safety** - Can optimize algorithms without fear
5. **Cross-Platform** - Core logic can be reused in watchOS, macOS, etc.

## Success Metrics

- ✅ All 24+ tests pass
- ✅ GitHub Actions runs in < 2 minutes total
- ✅ 100% test coverage of calculation functions
- ✅ Zero regressions in existing functionality

---

**Status:** Ready to implement
**Estimated Time:** 2.5 hours
**Dependencies:** Phase 1 complete (✅)
