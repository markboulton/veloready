# Phase 1.4 - Strain Extraction Plan
**Status:** In Progress  
**Complexity:** HIGH (~600 lines of calculation logic)

## Current Situation

**StrainScoreCalculator location:**  
`/Users/markboulton/Dev/veloready/VeloReady/Core/Models/StrainScore.swift` (lines 202-818)

**Size:** ~616 lines of pure calculation logic

---

## Methods to Extract (Priority Order)

### Tier 1: Core Calculations (MUST EXTRACT)
1. **calculateTRIMP()** - line 752-778
   - Heart rate based TRIMP calculation
   - ~27 lines

2. **calculateBlendedTRIMP()** - line 781-817
   - HR + Power blended TRIMP
   - ~37 lines

3. **convertTRIMPToEPOC()** - line 714-718
   - TRIMP to EPOC conversion
   - ~5 lines

4. **calculateWhoopStrain()** - line 721-734
   - Whoop's logarithmic strain formula
   - ~14 lines

### Tier 2: Sub-Score Calculations
5. **calculateCardioLoad()** - line 284-308
   - TRIMP-based cardio scoring
   - ~25 lines

6. **calculateStrengthLoad()** - line 312-343
   - sRPE + sensor-based strength scoring
   - ~32 lines

7. **calculateNonExerciseLoad()** - line 347-378
   - Steps + calories + MET-minutes
   - ~32 lines

8. **calculateRecoveryFactor()** - line 382-412
   - HRV/RHR/Sleep recovery modulation
   - ~31 lines

### Tier 3: Helper Functions
9. **getWorkoutTypeMultiplier()** - line 440-468
   - Activity type multipliers
   - ~29 lines

10. **calculateMultiSelectionFactor()** - line 500-552
    - Muscle group compound factors
    - ~53 lines

11. **calculateWhoopStyleStrain()** - line 555-709
    - Complete Whoop algorithm
    - ~155 lines (COMPLEX)

12. **determineBand()** - line 738-747
    - Score to band mapping
    - ~10 lines

---

## Recommended Approach

### Option A: Full Extraction (2 hours)
- Extract all ~600 lines to VeloReadyCore
- Create comprehensive tests (30+ tests)
- Update StrainScoreService

### Option B: Core Extraction (1 hour) ← **RECOMMENDED**
- Extract Tier 1 (core TRIMP/EPOC/Whoop functions) - ~83 lines
- Extract Tier 2 (sub-scores) - ~120 lines
- Extract determineBand() - ~10 lines
- **Total:** ~213 lines extracted
- Leave Tier 3 helpers in iOS (depend on iOS models)
- Create 15-20 focused tests

### Option C: Minimal Extraction (30 mins)
- Extract only Tier 1 (TRIMP/EPOC/Whoop) - ~83 lines
- Create 10 basic tests
- Partial win, but incomplete

---

## Recommendation: Option B

**Why:**
- Extracts core calculation logic (~213 lines)
- Leaves complex iOS-specific helpers in place
- Achieves 80% of value with 40% of effort
- Realistic given token budget (112k remaining)

**What gets extracted:**
- TRIMP calculations (HR and HR+Power)
- EPOC conversion
- Whoop strain formula
- All sub-score calculations (cardio, strength, activity, recovery)
- Band determination

**What stays in iOS:**
- calculateWhoopStyleStrain() (uses iOS models heavily)
- Muscle group helpers (tied to iOS enums)
- Workout type helpers (tied to iOS enums)

---

## Next Steps (Option B)

1. Update StrainCalculations.swift with extracted methods (20 mins)
2. Create StrainCalculationsTests.swift (15-20 tests) (20 mins)
3. Update StrainScoreService to use VeloReadyCore (20 mins)
4. Test & verify (10 mins)
5. Commit & document (10 mins)

**Total:** ~80 minutes

---

## After Completion

**VeloReadyCore will have:**
- 77 tests total (62 current + 15 new)
- Execution time: <3 seconds
- All major calculations extracted

**Phase 1 Progress:**
- 80% complete
- Only final cleanup remaining

**Ready to proceed?**
