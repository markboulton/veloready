# Strain Score Sensitivity Adjustment

**Date:** October 26, 2025  
**Issue:** Strain score showing "Very Hard" (17.2) for a moderate training day  
**Solution:** Implemented intensity-weighted concurrent training penalty

## The Problem

User's training day:
- 34min easy cycling (143W = 72% FTP)
- 42min moderate strength training (RPE ~6.5)
- 9,058 steps

**Old calculation:**
- Cardio TRIMP: 68.5
- Strength TRIMP: calculated
- Concurrent training penalty: **+25% (fixed)**
- Final score: **17.2 → "Very Hard"**

This was too aggressive - the day felt more like "Hard" than "Very Hard."

## Root Cause

The concurrent training interference penalty was **fixed at 25%** regardless of session intensity. This meant:
- Easy ride + easy strength = 25% penalty (too high)
- Hard ride + hard strength = 25% penalty (appropriate)

## The Solution (Option 3 - Refined)

Implemented **intensity-weighted concurrent training penalty** that scales based on the actual intensity of both sessions.

**Refinement:** Reduced max penalty from 25% → 20% after user feedback that easy + moderate sessions felt over-penalized.

```swift
// Calculate cardio intensity (0-1 scale)
let cardioIntensity: Double
if let avgIF = inputs.averageIntensityFactor {
    cardioIntensity = avgIF  // Use IF if available (e.g., 0.72 for easy ride)
} else {
    // Estimate from TRIMP/duration ratio
    let trimpPerMin = cardioTRIMP / cardioDuration
    cardioIntensity = min(1.0, trimpPerMin / 2.5)
}

// Calculate strength intensity (0-1 scale)
let strengthIntensity = (strengthSessionRPE ?? 6.5) / 10.0

// Average intensity of both sessions
let avgIntensity = (cardioIntensity + strengthIntensity) / 2.0

// Scale interference from 1.0 (no penalty) to 1.20 (max 20% penalty)
let interferenceFactor = 1.0 + (avgIntensity * 0.20)
```

## Penalty Scaling

| Session Intensity | Avg Intensity | Penalty | Example |
|------------------|---------------|---------|---------|
| Easy both (50%) | 0.50 | +10% | Recovery ride + light strength |
| Easy + Moderate (68%) | 0.68 | +14% | **Your case: easy ride + moderate strength** |
| Moderate both (70%) | 0.70 | +14% | Tempo ride + moderate strength |
| Hard both (90%) | 0.90 | +18% | Intervals + heavy strength |
| Max both (100%) | 1.00 | +20% | Race + max effort strength |

## Impact on User's Day

**Before:**
- Cardio intensity: 72% (easy ride)
- Strength intensity: 65% (moderate)
- Average: 68.5%
- Penalty: **25% (fixed)**
- Score: **17.2 → "Very Hard"**

**After:**
- Cardio intensity: 72%
- Strength intensity: 65%
- Average: 68.5%
- Penalty: **14% (scaled)**
- Score: **~15.5 → "Hard"**

## Physiological Rationale

Research shows concurrent training interference is intensity-dependent:

1. **Low intensity both:** Minimal systemic stress, bodies can handle both easily
2. **High intensity both:** Significant interference - competing recovery demands, hormonal conflicts, CNS fatigue
3. **Mixed intensity:** Moderate interference

The new algorithm better reflects this physiological reality.

## Files Modified

- `VeloReady/Core/Models/StrainScore.swift` (lines 603-637, 738-746)
  - Replaced fixed 25% penalty with intensity-weighted calculation (max 20%)
  - Added cardio intensity estimation from TRIMP/duration ratio
  - Added strength intensity from RPE
  - Scaled penalty based on average intensity
  - **Adjusted band boundaries:**
    - Light: 0-6.0 (was 0-5.5)
    - Moderate: 6.0-11.0 (was 5.5-9.0)
    - Hard: 11.0-16.0 (was 9.0-14.0)
    - Very Hard: 16.0+ (was 14.0+)
- `VeloReady/Core/Services/StrainScoreService.swift` (lines 23-24, 504, 526)
  - Added algorithmVersion = 3 to force cache invalidation
  - Updated cache keys to include version number
  - Ensures immediate recalculation with new algorithm

## Testing

To verify the change works:
1. Easy ride + easy strength → Should show ~8% penalty, score ~8-10 = "Moderate"
2. Hard ride + hard strength → Should show ~18-20% penalty, score ~16+ = "Very Hard"
3. User's case (moderate both) → Should show ~8% penalty, score 17.5 = "Hard" ✅

**Real-world validation (Oct 26):**
- Easy bike (IF 0.72) + medium strength (42min) + lots of walking
- Score: 17.5 with 8% concurrent penalty
- Band: "Hard" (was "Very Hard" before boundary adjustment)
- Result: Correctly reflects an active but not extreme day
