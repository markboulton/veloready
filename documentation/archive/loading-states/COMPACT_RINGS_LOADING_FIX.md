# Compact Rings Janky Loading - Fixed

## Problem

On the Today page, compact rings appeared one by one in a janky, staggered manner:
- Recovery and Strain often loaded together
- Sleep appeared 1-2 seconds later
- Created an unpolished, disjointed loading experience

## Root Cause

Each score service (`RecoveryScoreService`, `SleepScoreService`, `StrainScoreService`) publishes its score independently as soon as it finishes calculating. The view immediately displayed each ring as its score became available, with no coordination between the three rings.

**Flow:**
1. Recovery calculates → Ring 1 appears
2. Strain calculates → Ring 3 appears
3. Sleep finishes 1-2s later → Ring 2 appears

This created a janky, one-by-one appearance instead of a smooth, coordinated reveal.

## The Fix

Implemented **coordinated loading state** that waits until ALL scores are ready before displaying any rings.

### 1. Added `allScoresReady` State

**File:** `RecoveryMetricsSectionViewModel.swift`

```swift
@Published private(set) var allScoresReady: Bool = false // True when all scores are loaded
```

### 2. Added Coordination Logic

```swift
/// Check if all scores are ready to display
/// Waits until recovery, sleep (or sleep loading complete), and strain are all available
private func checkAllScoresReady() {
    let recoveryReady = recoveryScore != nil
    let sleepReady = sleepScore != nil || !isSleepLoading // Ready if we have score OR loading is complete
    let strainReady = strainScore != nil
    
    let wasReady = allScoresReady
    allScoresReady = recoveryReady && sleepReady && strainReady
    
    if !wasReady && allScoresReady {
        Logger.debug("✅ [VIEWMODEL] All scores ready - recovery: \(recoveryReady), sleep: \(sleepReady), strain: \(strainReady)")
    }
}
```

**Key Logic:**
- Recovery ready: `recoveryScore != nil`
- Sleep ready: `sleepScore != nil || !isSleepLoading` (ready if we have score OR loading finished)
- Strain ready: `strainScore != nil`
- All ready: All three conditions must be true

### 3. Updated All Score Observers

Each observer now calls `checkAllScoresReady()` when its score changes:

```swift
recoveryScoreService.$currentRecoveryScore
    .sink { [weak self] score in
        self?.recoveryScore = score
        self?.checkAllScoresReady()  // ✅ NEW
    }
    .store(in: &cancellables)

sleepScoreService.$currentSleepScore
    .sink { [weak self] score in
        self?.sleepScore = score
        self?.checkAllScoresReady()  // ✅ NEW
    }
    .store(in: &cancellables)

sleepScoreService.$isLoading
    .sink { [weak self] loading in
        self?.isSleepLoading = loading
        self?.checkAllScoresReady()  // ✅ NEW
    }
    .store(in: &cancellables)

strainScoreService.$currentStrainScore
    .sink { [weak self] score in
        self?.strainScore = score
        self?.checkAllScoresReady()  // ✅ NEW
    }
    .store(in: &cancellables)
```

### 4. Updated View to Show Loading State

**File:** `RecoveryMetricsSection.swift`

```swift
// Show loading state until all scores are ready
if !viewModel.allScoresReady {
    // Loading state - show grey rings with shimmer for all three
    HStack(spacing: Spacing.xxl) {
        loadingRingView(title: TodayContent.Scores.recoveryScore, delay: 0.0)
        loadingRingView(title: TodayContent.Scores.sleepScore, delay: 0.1)
        loadingRingView(title: TodayContent.Scores.loadScore, delay: 0.2)
    }
} else if showSleepRing {
    // Standard 3-ring layout - ALL RINGS APPEAR TOGETHER
    HStack(spacing: Spacing.xxl) {
        recoveryScoreView
        sleepScoreView
        loadScoreView
    }
}
```

### 5. Added Loading Ring Helper

```swift
@ViewBuilder
private func loadingRingView(title: String, delay: Double) -> some View {
    VStack(spacing: 16) {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
        
        CompactRingView(
            score: nil,
            title: "",
            band: RecoveryScore.RecoveryBand.optimal,
            animationDelay: delay,
            action: {},
            centerText: nil,
            animationTrigger: animationTrigger,
            isLoading: true  // Shows grey shimmer ring
        )
    }
    .frame(maxWidth: .infinity)
}
```

## How It Works Now

### Loading Sequence

```
1. App launches
2. All three rings show grey shimmer (loading state)
3. Recovery calculates → checkAllScoresReady() → still false
4. Strain calculates → checkAllScoresReady() → still false
5. Sleep finishes → checkAllScoresReady() → TRUE! ✅
6. All three rings appear together with smooth animations
```

### Visual Experience

**Before:**
```
[Grey Ring]  [Grey Ring]  [Grey Ring]
     ↓
[92 Ring]    [Grey Ring]  [Grey Ring]  ← Recovery appears
     ↓
[92 Ring]    [Grey Ring]  [2.1 Ring]   ← Strain appears
     ↓
[92 Ring]    [93 Ring]    [2.1 Ring]   ← Sleep appears (janky!)
```

**After:**
```
[Grey Ring]  [Grey Ring]  [Grey Ring]  ← All loading
     ↓
[92 Ring]    [93 Ring]    [2.1 Ring]   ← All appear together! ✅
```

## Expected Log Output

```
🔄 [VIEWMODEL] Recovery score changed via Combine: 92
🔄 [VIEWMODEL] Strain score changed via Combine: 2.1466396255873517
🔄 [VIEWMODEL] Sleep score changed via Combine: 93
✅ [VIEWMODEL] All scores ready - recovery: true, sleep: true, strain: true
```

## Benefits

✅ **Smooth, coordinated loading** - All rings appear together
✅ **No janky stagger** - No more one-by-one appearance
✅ **Clear loading state** - Grey shimmer rings indicate calculation in progress
✅ **Better perceived performance** - Feels faster and more polished
✅ **Maintains fast startup** - Still shows cached data immediately, just waits to reveal all together

## Edge Cases Handled

### Sleep Loading Takes Longer

If sleep calculation takes significantly longer:
- All three rings show grey shimmer
- User sees clear "calculating" state
- When sleep finishes, all three reveal together

### Sleep Has No Data

```swift
let sleepReady = sleepScore != nil || !isSleepLoading
```

If sleep loading completes but returns no data:
- `sleepScore` is `nil` but `isSleepLoading` is `false`
- `sleepReady` becomes `true` (loading is complete)
- Rings can display even without sleep score

### Cached Data Available

Services load cached scores synchronously on init:
- Rings may appear immediately if all cached
- Or show loading state if any score is missing
- Smooth transition in both cases

## Files Modified

- `VeloReady/Features/Shared/ViewModels/RecoveryMetricsSectionViewModel.swift`
  - Added `allScoresReady` @Published property
  - Added `checkAllScoresReady()` method
  - Updated all score observers to call `checkAllScoresReady()`

- `VeloReady/Features/Today/Views/Dashboard/Sections/RecoveryMetricsSection.swift`
  - Added conditional check for `allScoresReady`
  - Shows loading rings when not ready
  - Added `loadingRingView()` helper method

## Testing

✅ Build successful
✅ All 28 critical unit tests passed
✅ Pre-commit hook validated

## Next Steps

1. **Force close and relaunch the app**
2. **Observe the Today page loading**
3. **Expected behavior:**
   - All three rings show grey shimmer initially
   - All three rings appear together when ready
   - Smooth, coordinated animation
   - No janky one-by-one appearance

---

**Status:** ✅ Fixed and committed (commit: b3a0651)
