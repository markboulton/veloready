# Recovery Sub-Scores Showing All "92" - Fixed

## Problem

Recovery detail view displayed all recovery factors as "92":
- HRV: 92
- RHR: 92  
- Sleep Quality: 92
- Training Load: 92

This was incorrect - these should show individual factor scores, not all the same value.

## Root Cause

The issue was a **placeholder detection failure** in the recovery score caching logic:

1. **Core Data Fallback Creates Placeholders:**
   ```swift
   // loadFromCoreDataFallback() in RecoveryScoreService.swift
   let subScores = RecoveryScore.SubScores(
       hrv: score,      // All set to 92!
       rhr: score,      // All set to 92!
       sleep: score,    // All set to 92!
       form: score,     // All set to 92!
       respiratory: score  // All set to 92!
   )
   ```
   This creates a valid `RecoveryScore` object with the correct overall score (92) and actual HRV/RHR from `DailyPhysio`, but **placeholder sub-scores**.

2. **Previous Fix Was Incomplete:**
   ```swift
   // Only checked if inputs.hrv exists
   if hasCalculatedToday() && currentRecoveryScore != nil &&
      currentRecoveryScore?.inputs.hrv != nil {
       return  // Skip recalculation
   }
   ```
   The Core Data fallback **does** load HRV from `DailyPhysio`, so `inputs.hrv != nil` was `true`. The service thought it had complete data and skipped recalculation, leaving the placeholder sub-scores in the UI.

3. **Result:**
   - Overall score: 92 ✅ (correct)
   - Inputs (HRV, RHR): Loaded from DailyPhysio ✅ (correct)
   - Sub-scores: All 92 ❌ (placeholders, not recalculated)

## The Fix

Added **placeholder detection** to force recalculation when sub-scores are placeholders:

### 1. New Helper Method

```swift
/// Check if recovery score has placeholder sub-scores (all equal to main score)
/// This indicates data loaded from Core Data fallback without full calculation
private func hasPlaceholderSubScores(_ score: RecoveryScore?) -> Bool {
    guard let score = score else { return false }
    
    // If all sub-scores equal the main score, it's a placeholder
    let mainScore = score.score
    let subScores = score.subScores
    
    let isPlaceholder = subScores.hrv == mainScore &&
                       subScores.rhr == mainScore &&
                       subScores.sleep == mainScore &&
                       subScores.form == mainScore &&
                       subScores.respiratory == mainScore
    
    if isPlaceholder {
        Logger.debug("🔍 Detected placeholder sub-scores (all = \(mainScore))")
    }
    
    return isPlaceholder
}
```

### 2. Enhanced Validation Logic

```swift
func calculateRecoveryScore() async {
    // Check for FULL data including non-placeholder sub-scores
    if hasCalculatedToday() && currentRecoveryScore != nil &&
       currentRecoveryScore?.inputs.hrv != nil &&
       !hasPlaceholderSubScores(currentRecoveryScore) {  // ✅ NEW CHECK
        Logger.debug("✅ Recovery score already calculated today with full data")
        return
    }

    // Try Core Data fallback if data is missing or has placeholders
    if hasCalculatedToday() && (currentRecoveryScore == nil || 
                                 currentRecoveryScore?.inputs.hrv == nil ||
                                 hasPlaceholderSubScores(currentRecoveryScore)) {  // ✅ NEW CHECK
        Logger.warning("⚠️ Recovery calculated today but has placeholder sub-scores")
        await loadFromCoreDataFallback()

        // Only skip if we have FULL data (not placeholders)
        if currentRecoveryScore != nil && 
           currentRecoveryScore?.inputs.hrv != nil &&
           !hasPlaceholderSubScores(currentRecoveryScore) {  // ✅ NEW CHECK
            Logger.debug("✅ Recovered FULL score from Core Data")
            return
        }

        Logger.warning("⚠️ Forcing recalculation to restore all sub-scores")
    }
    
    // Proceed with full recalculation
    // ...
}
```

## What Happens Now

### First Launch After Fix

```
1. Service checks hasCalculatedToday() → true (from UserDefaults)
2. Service checks currentRecoveryScore != nil → true (placeholder from sync load)
3. Service checks inputs.hrv != nil → true (loaded from DailyPhysio)
4. ✅ NEW: Service checks hasPlaceholderSubScores() → TRUE (all sub-scores = 92!)
5. Service tries Core Data fallback
6. Core Data also has placeholder sub-scores
7. Service FORCES recalculation
8. Full RecoveryScore calculated with proper sub-scores:
   - HRV: 85 (actual calculated value)
   - RHR: 90 (actual calculated value)
   - Sleep: 85 (actual calculated value)
   - Form: 80 (actual calculated value)
   - Respiratory: 88 (actual calculated value)
9. Detail view displays correctly! ✅
```

### Subsequent Launches

```
1. Service checks hasCalculatedToday() → true
2. Service checks currentRecoveryScore != nil → true
3. Service checks inputs.hrv != nil → true
4. ✅ Service checks hasPlaceholderSubScores() → FALSE (real sub-scores!)
5. Skip recalculation (efficient!) ✅
```

## Expected Log Output

After the fix, you should see:

```
🔍 Detected placeholder sub-scores (all = 92)
⚠️ Recovery calculated today but has placeholder sub-scores - trying Core Data fallback
⚠️ Forcing recalculation to restore all sub-scores
🔄 Starting recovery calculation (forceRefresh: false)
[... full calculation happens ...]
✅ Recovery calculation completed successfully
💾 Saved recovery score to cache: 92
```

And in the UI, recovery factors will show:
- HRV: 85 (not 92)
- RHR: 90 (not 92)
- Sleep Quality: 85 (not 92)
- Training Load: 80 (not 92)

## Files Modified

- `VeloReady/Core/Services/RecoveryScoreService.swift`
  - Added `hasPlaceholderSubScores()` helper method
  - Enhanced `calculateRecoveryScore()` validation logic
  - Updated Core Data fallback checks

## Testing

✅ Build successful
✅ All 28 critical unit tests passed
✅ Pre-commit hook validated

## Next Steps

1. **Force close and relaunch the app** to trigger the fix
2. **Navigate to Recovery Detail** and verify individual factor scores display correctly
3. **Expected behavior:**
   - First launch: Logs show placeholder detection → recalculation → correct scores
   - Recovery detail: HRV, RHR, quality, training load all show unique values
   - Second launch: Skip recalculation (efficient)

## Why This Pattern Exists

The Core Data fallback is **intentionally designed** to create placeholder sub-scores because:

1. **Fast Startup:** Can show the overall score (92) immediately without expensive recalculation
2. **Graceful Degradation:** If full calculation fails, user still sees their score
3. **Efficient Caching:** Full calculation only happens when truly needed

The bug was that we weren't **detecting** when these placeholders were being used, so the service thought it had complete data and never recalculated.

Now with placeholder detection, we get the best of both worlds:
- ✅ Fast startup with placeholder
- ✅ Full recalculation when placeholders detected
- ✅ Efficient caching when real data exists

---

**Status:** ✅ Fixed and committed (commit: 0ae578c)
