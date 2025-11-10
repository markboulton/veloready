# Critical Bugs Analysis - Load Score & Map Preview

## Bug #1: Load Score Dropped from 9.3 to 2.7

### Root Cause
```
❌ Recovery calculation failed: CancellationError()
```

The recovery calculation is being cancelled, which cascades to affect strain/load calculation.

### Why It's Happening
The scenePhase monitoring I added is triggering during app initialization, which may be causing:
1. Multiple refresh calls
2. Task cancellation
3. Recovery calculation timeout (8 second limit)

### The Fix
Need to add better guards to prevent scenePhase handler from running during initial load:

```swift
private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
    // CRITICAL: Only handle if we've completed initial load AND view is active
    guard viewState.hasCompletedTodayInitialLoad && isViewActive else {
        return
    }
    
    // Also check that we're not already loading
    guard !viewModel.isLoading else {
        return  
    }
    
    if oldPhase == .background && newPhase == .active {
        // ... refresh logic
    }
}
```

## Bug #2: No Map Preview for Latest Ride

### What's Missing
The enhanced logging I added is NOT appearing in the logs. This means:
- `loadMapSnapshot()` is never being called
- OR the card is not being created at all
- OR `onAppear` is not firing

### Possible Causes
1. The activity doesn't pass `shouldShowMap` check
2. The ViewModel is not being initialized
3. The card is being skipped due to some condition

### Debug Steps
1. Check if `getLatestActivity()` is returning the ride
2. Check if `shouldShowMap` returns true for the activity
3. Add logging to card initialization

## Bug #3: Cache Errors Still Present

Despite reverting Bug #6 fix, cache errors persist because:
1. The corrupted cache data is still in Core Data
2. Need to clear cache or add migration

### The Fix
Add cache version check and clear on version mismatch.

## IMMEDIATE ACTION

I'm reverting the scenePhase changes to fix Bug #1.
