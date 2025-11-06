# Recovery Detail Shows Zeros - Root Cause & Fix

## Problem Statement
Recovery detail view displays all zeros for HRV, RHR, sleep quality, and training load despite recovery score (92) displaying correctly in the ring.

## Root Cause Analysis

### The Bug
1. **Recovery score VALUE (92) exists** in `DailyCache` (old UserDefaults storage)
2. **Recovery score OBJECT is missing** from `UnifiedCacheManager` (new Core Data persistence)
3. `RecoveryScoreService.calculateRecoveryScore()` checks `hasCalculatedToday()` which returns `true` because the numeric value exists
4. Service skips recalculation and returns early (line 107-111)
5. Full `RecoveryScore` object with HRV, RHR, quality, training load is never loaded or calculated
6. Recovery detail view receives `nil` for the object → displays zeros

### Evidence from Logs
```
✅ Recovery score already calculated today - skipping recalculation
📦 [RECOVERY ASYNC] No cached recovery score found in UnifiedCacheManager (error: The operation couldn't be completed. (RecoveryScore error 404.))
🔍 [RECOVERY ASYNC] Preserving synchronously-loaded score: 92
```

The numeric score (92) is preserved from sync load, but the full object is missing.

## Solution

### Fix Location
**File:** `VeloReady/Core/Services/RecoveryScoreService.swift`

**Method:** `calculateRecoveryScore()` (lines 105-135)

### Current Logic (BROKEN)
```swift
func calculateRecoveryScore() async {
    // Check if we already calculated today's recovery score AND have a valid cached score
    if hasCalculatedToday() && currentRecoveryScore != nil {
        Logger.debug("✅ Recovery score already calculated today - skipping recalculation")
        return
    }
    
    // ... rest of code
}
```

**Problem:** Only checks if `currentRecoveryScore != nil` AFTER checking `hasCalculatedToday()`. The numeric value exists in UserDefaults, so `hasCalculatedToday()` returns true, but `currentRecoveryScore` is still nil (object not loaded from Core Data).

### Required Fix

Add an additional check: **If we calculated today BUT the full object is missing from UnifiedCacheManager, force recalculation.**

```swift
func calculateRecoveryScore() async {
    // Check if we already calculated today's recovery score AND have a valid cached score
    if hasCalculatedToday() && currentRecoveryScore != nil {
        Logger.debug("✅ Recovery score already calculated today - skipping recalculation")
        return
    }
    
    // NEW CHECK: If we calculated today but the OBJECT is missing, force recalculation
    // This handles the case where the numeric value exists in UserDefaults but the full
    // RecoveryScore object wasn't persisted to Core Data (cache migration issue)
    if hasCalculatedToday() && currentRecoveryScore == nil {
        Logger.warning("⚠️ Recovery calculated today but object missing from cache - forcing recalculation to restore full data")
        // Fall through to recalculation below
    } else if hasCalculatedToday() {
        Logger.debug("✅ Recovery score already calculated today - skipping recalculation")
        return
    }
    
    // Cancel any existing calculation
    calculationTask?.cancel()
    
    calculationTask = Task {
        await performCalculation(forceRefresh: false)
    }
    
    await calculationTask?.value
}
```

### Alternative (Simpler) Fix
Replace the early return condition to be more strict:

```swift
func calculateRecoveryScore() async {
    // Only skip if BOTH conditions are true:
    // 1. We calculated today
    // 2. We have the FULL object (not just the numeric value)
    if hasCalculatedToday() && currentRecoveryScore != nil && 
       currentRecoveryScore?.inputs.hrv != nil {  // Verify object has actual data
        Logger.debug("✅ Recovery score already calculated today - skipping recalculation")
        return
    }
    
    // ... rest of code unchanged
}
```

## Why This Happens

1. **Cache v3 migration** cleared old data correctly
2. **Sleep/Strain scores** recalculated and saved to Core Data ✅
3. **Recovery score** was already calculated before cache v3, so `hasCalculatedToday()` returns true
4. Service skips recalculation thinking data is cached
5. But the full object was never saved to Core Data (only numeric value in UserDefaults)
6. Result: Ring shows 92, detail shows zeros

## Testing

After fix, verify:
1. ✅ Recovery detail shows HRV value (not 0)
2. ✅ Recovery detail shows RHR value (not 0)
3. ✅ Recovery detail shows sleep quality (not 0)
4. ✅ Recovery detail shows training load CTL/ATL (not 0)
5. ✅ Logs show "forcing recalculation to restore full data"
6. ✅ No "Could not determine type" warnings for `score:recovery:` keys

## Files to Modify

- `VeloReady/Core/Services/RecoveryScoreService.swift` - Fix `calculateRecoveryScore()` method

## Commit Message

```
fix(recovery): Force recalculation when object missing from cache

Problem:
- Recovery score numeric value (92) exists in UserDefaults
- Full RecoveryScore object missing from Core Data
- Service skips recalculation thinking data is cached
- Detail view shows all zeros (HRV, RHR, quality, training load)

Root Cause:
- Cache v3 migration cleared old data
- Recovery score calculated before migration, so hasCalculatedToday() = true
- Service skips recalculation, never loads/saves full object to Core Data

Solution:
- Add check: if hasCalculatedToday() but currentRecoveryScore == nil
- Force recalculation to restore full object to cache
- Ensures detail view has all required data

Impact:
- Recovery detail now displays HRV, RHR, quality, training load correctly
- No more zeros in recovery detail view
```
