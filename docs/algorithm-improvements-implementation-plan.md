# Algorithm Improvements Implementation Plan

**Based on:** Sports Science Analysis (November 2025)
**Status:** Phases 1-5 Complete (Core Calculations)

---

## Overview

This document outlines the phased implementation of algorithm improvements identified in the sports science analysis. Each phase is designed to be independently testable and deployable.

---

## Phase 1: Quick Wins - Sleep & Baseline Reliability ✅ COMPLETE

**Branch:** `feature/algorithm-improvements-phase1`
**Estimated Effort:** 1-2 days
**Priority:** High
**Impact:** Immediate reliability improvements

### Tasks

- [x] **1.1 Rebalance Sleep Score Weights**
  - Reduce stage quality weight from 32% to 22% (wearable accuracy is 50-65%)
  - Increase performance (duration) weight from 30% to 38%
  - Keep efficiency at 22%, disturbances at 14%, timing at 4%
  - File: `VeloReadyCore/Sources/Calculations/SleepCalculations.swift`

- [x] **1.2 Use Personalized Stage Quality by Default**
  - Modify `calculateStageQualityScore` to call `calculatePersonalizedStageQualityScore`
  - Add fallback to fixed thresholds if no baseline available
  - File: `VeloReadyCore/Sources/Calculations/SleepCalculations.swift`

- [x] **1.3 Add Sleep Context Awareness**
  - Add optional `previousDayTSS` parameter to sleep calculation
  - If TSS > 150 yesterday, expect +10-15% deep sleep (don't penalize)
  - File: `VeloReadyCore/Sources/Calculations/SleepCalculations.swift`

- [x] **1.4 Add Gender-Aware TRIMP Zone Exponent**
  - Make zone weight exponent configurable (default 2.0)
  - Research suggests 1.67 for women, 1.92 for men
  - File: `VeloReadyCore/Sources/Calculations/StrainCalculations.swift`

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- All existing tests pass
- Sleep scores show less volatility from stage data
- Duration becomes primary driver of sleep score

---

## Phase 2: HRV Rolling Average & CV Metric ✅ COMPLETE

**Branch:** `feature/algorithm-improvements-phase2`
**Estimated Effort:** 3-5 days
**Priority:** High
**Impact:** Most impactful reliability fix per research

### Tasks

- [x] **2.1 Add 7-Day Rolling LnRMSSD Calculation**
  - New function: `calculateRollingHRVAverage(hrvValues: [Double], days: Int = 7) -> Double?`
  - Store daily LnRMSSD values for rolling calculation
  - File: `VeloReadyCore/Sources/Calculations/BaselineCalculations.swift`

- [x] **2.2 Add HRV Coefficient of Variation (CV)**
  - New function: `calculateHRVCV(hrvValues: [Double]) -> Double?`
  - CV = (standard deviation / mean) * 100
  - Higher CV = less stable = need more recovery
  - File: `VeloReadyCore/Sources/Calculations/BaselineCalculations.swift`

- [x] **2.3 Update Recovery Calculation to Use Rolling HRV**
  - Add `rollingHrvAverage` and `hrvCV` to `RecoveryInputs`
  - Modify `calculateHRVComponent` to prefer rolling average
  - Add CV-based modifier (high CV → reduce score by 5-10 points)
  - File: `VeloReadyCore/Sources/Calculations/RecoveryCalculations.swift`

- [x] **2.4 Add HRV Trend Detection**
  - Compare 7-day average to 30-day baseline
  - Detect improving/declining/stable trends
  - New struct: `HRVTrend { direction: .improving/.declining/.stable, magnitude: Double }`
  - File: `VeloReadyCore/Sources/Calculations/BaselineCalculations.swift`

- [ ] **2.5 Update iOS Data Fetching** (deferred to UI integration)
  - Fetch 7 days of HRV history for rolling average
  - Calculate and pass CV to recovery calculator
  - Files: `VeloReady/Core/Services/Calculators/RecoveryScoreCalculator.swift`, `HealthKitManager.swift`

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- Rolling HRV average reduces day-to-day score volatility
- CV metric correctly identifies unstable HRV patterns
- Trend detection catches improving/declining patterns

---

## Phase 3: Training Load Enhancements ✅ COMPLETE

**Branch:** `feature/algorithm-improvements-phase3`
**Estimated Effort:** 3-5 days
**Priority:** Medium
**Impact:** Better user understanding and accuracy

### Tasks

- [x] **3.1 Add Half-Life Display Values**
  - Calculate and expose half-life: `halfLife = timeConstant / 2.8854`
  - CTL half-life: 14.5 days, ATL half-life: 2.4 days
  - Add to model for UI display
  - File: `VeloReadyCore/Sources/Calculations/TrainingLoadCalculations.swift`

- [x] **3.2 Add Session RPE (sRPE) Support**
  - New function: `calculateSRPE(rpe: Int, durationMinutes: Double) -> Double`
  - sRPE = RPE × duration (Foster method)
  - Use as fallback when HR data unavailable
  - File: `VeloReadyCore/Sources/Calculations/StrainCalculations.swift`

- [x] **3.3 Add Training Type Classification**
  - Classify workouts: endurance, threshold, VO2max, strength, recovery
  - Based on time-in-zone distribution or IF
  - File: `VeloReadyCore/Sources/Calculations/StrainCalculations.swift`

- [x] **3.4 Add TSS Penalty Context to Recovery**
  - Show user: "Yesterday's TSS (185) is reducing your recovery by X points"
  - Transparent explanation of form score contribution
  - File: `VeloReadyCore/Sources/Calculations/RecoveryCalculations.swift`

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- Half-life values displayed correctly
- sRPE calculation matches Foster method
- Training types correctly classified

---

## Phase 4: Adaptive Personalization ✅ COMPLETE

**Branch:** `feature/algorithm-improvements-phase4`
**Estimated Effort:** 5-7 days
**Priority:** Medium
**Impact:** Individual accuracy improvements

### Tasks

- [x] **4.1 Adaptive Baseline Weighting**
  - Weight recent 7 days more heavily than older data
  - Exponentially-weighted baseline instead of simple median
  - File: `VeloReadyCore/Sources/Calculations/BaselineCalculations.swift`

- [x] **4.2 Personal Sleep Stage Baselines**
  - Track user's 30-day deep/REM percentages
  - Use these as personal targets instead of fixed 15%/20%
  - File: `VeloReadyCore/Sources/Calculations/SleepCalculations.swift`

- [x] **4.3 Configurable Time Constants (Foundation)**
  - Allow CTL/ATL time constants to be user-configurable
  - Default: 42/7, Range: 30-60 / 5-10
  - File: `VeloReadyCore/Sources/Calculations/TrainingLoadCalculations.swift`

- [x] **4.4 Recovery Profile Detection**
  - Analyze user's historical recovery patterns
  - Detect: "fast recoverer" vs "slow recoverer"
  - Adjust scoring sensitivity based on profile
  - Files: `BaselineCalculations.swift`, `RecoveryCalculations.swift`

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- Baselines adapt faster to user changes
- Personal sleep targets reflect individual patterns
- Time constants can be adjusted

---

## Phase 5: HRV-Guided Training Recommendations ✅ COMPLETE

**Branch:** `feature/algorithm-improvements-phase5`
**Estimated Effort:** 5-7 days
**Priority:** High (Competitive Edge)
**Impact:** Major differentiator in market

### Tasks

- [x] **5.1 Daily Readiness Classification**
  - Based on HRV trend + CV + recovery score
  - Categories: "Train Hard", "Train Moderate", "Train Easy", "Rest"
  - New file: `VeloReadyCore/Sources/Calculations/ReadinessCalculations.swift`

- [x] **5.2 Training Recommendation Logic**
  - If HRV trend improving + low CV + recovery > 70 → "Train Hard"
  - If HRV stable + moderate CV + recovery 50-70 → "Train Moderate"
  - If HRV declining or high CV or recovery < 50 → "Rest/Easy"
  - File: `VeloReadyCore/Sources/Calculations/ReadinessCalculations.swift`

- [x] **5.3 Recommendation Confidence Score**
  - Based on data quality and historical accuracy
  - Show user: "85% confident you should train hard today"
  - File: `VeloReadyCore/Sources/Calculations/ReadinessCalculations.swift`

- [ ] **5.4 iOS UI Integration** (deferred to UI phase)
  - Display recommendation on Today view
  - Show reasoning: "HRV is 8% above baseline, CV is low (4.2%)"
  - Files: iOS UI components

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- Recommendations align with research-validated HRV-guided protocols
- Users understand why recommendation was made
- Confidence score reflects data quality

---

## Phase 6: Advanced Features (Future)

**Branch:** `feature/algorithm-improvements-phase6`
**Estimated Effort:** 2-4 weeks
**Priority:** Low (Long-term)
**Impact:** Cutting-edge differentiation

### Tasks

- [ ] **6.1 Individualized Time Constants**
  - Learn user's fitness/fatigue decay rates over 3-6 months
  - Requires performance data to validate model fit
  - Banister impulse-response model implementation

- [ ] **6.2 iTRIMP (Individualized TRIMP)**
  - If lactate threshold data available from Intervals.icu
  - Use individual HR-lactate relationship
  - +6% accuracy over standard TRIMP

- [ ] **6.3 Banister Fitness-Fatigue Model**
  - Separate fitness and fatigue tracking
  - More accurate than TSB for performance prediction
  - Complex but experimentally validated

- [ ] **6.4 Multi-Day Recovery Projection**
  - Given current state + planned training
  - Project recovery over next 3-7 days
  - "If you do planned workout tomorrow, recovery will be X"

- [ ] **6.5 ML Fatigue Classification**
  - Train model on user's historical data
  - Use 11-24 HRV features (per research)
  - Personalized fatigue state prediction

### Testing
```bash
scripts/quick-test.sh
```

### Success Criteria
- Individual time constants improve performance predictions
- ML model outperforms rule-based scoring

---

## Implementation Notes

### Branch Strategy
```
main
└── feature/algorithm-improvements-phase1
    └── feature/algorithm-improvements-phase2
        └── feature/algorithm-improvements-phase3
            └── ... (each phase branches from previous)
```

### Commit Convention
```
feat(sleep): Rebalance weights - duration 38%, stage quality 22%
feat(hrv): Add 7-day rolling LnRMSSD average
feat(baseline): Add CV calculation for HRV stability
fix(recovery): Use rolling HRV instead of single-day
```

### Testing Requirements
- All changes must pass `scripts/quick-test.sh`
- New calculations should have unit tests
- Verify no regression in existing scores

### Rollback Plan
- Each phase is independent
- Can disable new features via feature flags if issues arise
- Keep old calculation methods available as fallback

---

## Progress Tracking

| Phase | Status | Branch | Started | Completed |
|-------|--------|--------|---------|-----------|
| Phase 1 | ✅ Complete | `feature/algorithm-improvements-phase1` | Nov 2025 | Nov 2025 |
| Phase 2 | ✅ Complete | `feature/algorithm-improvements-phase2` | Nov 2025 | Nov 2025 |
| Phase 3 | ✅ Complete | `feature/algorithm-improvements-phase3` | Nov 2025 | Nov 2025 |
| Phase 4 | ✅ Complete | `feature/algorithm-improvements-phase4` | Nov 2025 | Nov 2025 |
| Phase 5 | ✅ Complete | `feature/algorithm-improvements-phase5` | Nov 2025 | Nov 2025 |
| Phase 6 | ⚪ Not Started | - | - | - |

---

## References

- Plews et al. (2013) - LnRMSSD, 7-day rolling average
- Morton et al. (1990) - Banister TRIMP validation
- PMC 8507742 - HRV-guided training meta-analysis
- Sports Medicine Open (2022) - Fitness-fatigue model limitations
- Foster (1998) - Session RPE method
