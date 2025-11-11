# Compact Rings Loading Behavior Fix

## Summary

Fixed the compact rings view loading behavior to distinguish between initial load and refresh states, providing a better user experience with coordinated animations on first load and smooth updates on refresh.

## Problem Statement

### Current Behavior (Before Fix)
1. **Initial Load**: Load score appeared immediately and animated, while Recovery and Sleep showed grey shimmer rings with "calculating" status
2. **Scores appeared one by one**: Recovery and Sleep appeared together after a couple seconds, with individual animations
3. **On Refresh**: All rings showed grey shimmer again, even though the user already had scores visible

### Desired Behavior (After Fix)
1. **Initial Load**: Wait until ALL scores are available, then show them together with coordinated animations
2. **Show grey shimmer with "calculating"** status until all scores are ready
3. **On Refresh**: Keep existing scores visible, just change status text to "calculating" (no grey rings)
4. **When new scores arrive**: Update values and trigger animations

## Implementation Details

### 1. Added `isInitialLoad` Property to ViewModel

**File**: `RecoveryMetricsSectionViewModel.swift`

```swift
// Track if this is initial load (true) or refresh (false)
@Published var isInitialLoad: Bool = true
```

This property tracks whether we're in the initial load phase (showing app for the first time) or in refresh mode (updating scores after app has been opened).

### 2. Updated `checkAllScoresReady()` Logic

**File**: `RecoveryMetricsSectionViewModel.swift`

The method now has two distinct behaviors:

#### Initial Load Mode:
- Waits for ALL required scores (Recovery and Strain) to be ready
- Waits for loading to complete for all services
- Once ready, transitions to refresh mode and triggers animations
- Shows grey shimmer rings with "calculating" status

```swift
if isInitialLoad {
    let allLoadingComplete = !isRecoveryLoading && !isSleepLoading && !isStrainLoading
    let hasRequiredScores = recoveryScore != nil && strainScore != nil
    allScoresReady = allLoadingComplete && hasRequiredScores
    
    if !wasReady && allScoresReady {
        isInitialLoad = false
        ringAnimationTrigger = UUID() // Trigger all animations together
    }
}
```

#### Refresh Mode:
- Shows scores immediately if ANY score exists
- Doesn't hide rings during refresh
- Shows "calculating" status text without grey rings
- Individual score observers trigger animations when scores update

```swift
else {
    let hasAnyScore = recoveryScore != nil || sleepScore != nil || strainScore != nil
    allScoresReady = hasAnyScore
}
```

### 3. Added Score Change Detection with Animation Triggers

**File**: `RecoveryMetricsSectionViewModel.swift`

Each score observer now:
1. Tracks the old score value
2. Detects when a score changes
3. Triggers animation ONLY during refresh mode (not initial load)

**Recovery Score**:
```swift
recoveryScoreService.$currentRecoveryScore
    .sink { [weak self] score in
        let oldScore = self?.recoveryScore?.score
        self?.recoveryScore = score
        
        // Trigger animation on refresh (not initial load)
        if let old = oldScore, let new = score?.score, old != new, self?.isInitialLoad == false {
            self?.ringAnimationTrigger = UUID()
        }
        
        self?.checkAllScoresReady()
    }
```

**Sleep Score**: Same pattern as Recovery

**Strain Score**: Same pattern, but waits for all scores on initial load

### 4. Added `isRefreshing` Parameter to CompactRingView

**File**: `CompactRingView.swift`

```swift
var isRefreshing: Bool = false // Shows "Calculating" status without grey ring (for refreshes)
```

This new parameter allows showing the "Calculating" status text WITHOUT the grey shimmer ring:
- `isLoading`: Grey ring + shimmer + "Calculating" (initial load)
- `isRefreshing`: Colored ring + "Calculating" (refresh with existing scores)

```swift
// Title - show "Calculating" when loading or refreshing, otherwise show band
if isLoading || isRefreshing {
    Text("Calculating")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(Color.text.tertiary)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
} else if score != nil {
    Text(title)
        // ... normal band display
}
```

### 5. Updated RecoveryMetricsSection to Use New Behavior

**File**: `RecoveryMetricsSection.swift`

Each ring now uses:
- `viewModel.ringAnimationTrigger` instead of parent `animationTrigger`
- `isRefreshing: viewModel.isRecoveryLoading && !viewModel.isInitialLoad`

This ensures:
- On initial load: Grey rings show until all ready
- On refresh: Rings stay visible with "calculating" status
- Animations trigger at the right time

**Example - Recovery Ring**:
```swift
CompactRingView(
    score: viewModel.recoveryScoreValue,
    title: viewModel.recoveryTitle,
    band: viewModel.recoveryBand ?? .optimal,
    animationDelay: 0.0,
    action: { },
    centerText: nil,
    animationTrigger: viewModel.ringAnimationTrigger,  // ✅ Use local trigger
    isLoading: false,
    isRefreshing: viewModel.isRecoveryLoading && !viewModel.isInitialLoad  // ✅ Show calculating on refresh
)
```

## Visual Flow

### Initial Load (First Time Opening App)

```
┌─────────────────────────────────────────┐
│  App Opens                               │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  Grey Rings + Shimmer                    │
│  "Calculating" status below each         │
│                                          │
│  [Grey Ring]  [Grey Ring]  [Grey Ring]  │
│  Calculating  Calculating  Calculating   │
└─────────────────────────────────────────┘
                ↓
     (Wait for ALL scores)
                ↓
┌─────────────────────────────────────────┐
│  All scores ready!                       │
│  - Set isInitialLoad = false             │
│  - Trigger ringAnimationTrigger          │
│  - All rings animate together            │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  Scores shown with animations            │
│                                          │
│    [92]         [93]         [2.1]      │
│  Optimal      Excellent     Easy         │
└─────────────────────────────────────────┘
```

### Refresh (App Re-opened or Pull-to-Refresh)

```
┌─────────────────────────────────────────┐
│  User reopens app or pulls to refresh   │
│                                          │
│  Current scores still visible:           │
│    [92]         [93]         [2.1]      │
│  Optimal      Excellent     Easy         │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  Refresh triggered (isInitialLoad=false) │
│  Rings stay visible!                     │
│                                          │
│    [92]         [93]         [2.1]      │
│  Calculating  Calculating  Calculating   │
│  ↑ Status changes, rings stay colored    │
└─────────────────────────────────────────┘
                ↓
     (Scores calculate in background)
                ↓
┌─────────────────────────────────────────┐
│  Recovery finishes → triggers animation  │
│    [94]         [93]         [2.1]      │
│  Optimal      Calculating  Calculating   │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  Strain finishes → triggers animation    │
│    [94]         [93]         [9.8]      │
│  Optimal      Calculating   Moderate     │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  Sleep finishes → triggers animation     │
│    [94]         [91]         [9.8]      │
│  Optimal      Excellent     Moderate     │
└─────────────────────────────────────────┘
```

## Key Benefits

✅ **Coordinated Initial Load**: All rings appear together with smooth animations on first launch

✅ **No Flash of Grey Rings**: On refresh, existing scores stay visible with just status text change

✅ **Individual Updates on Refresh**: Each score animates as it becomes available during refresh

✅ **Better Perceived Performance**: User always sees something meaningful (either loading state or actual scores)

✅ **Maintains Existing Caching**: Still loads cached scores instantly, just waits to reveal them together

✅ **Clearer Status Communication**: "Calculating" status appears in both modes, but with appropriate visual treatment

## Files Modified

1. `VeloReady/Features/Shared/ViewModels/RecoveryMetricsSectionViewModel.swift`
   - Added `isInitialLoad` property
   - Updated `checkAllScoresReady()` with dual behavior
   - Added score change detection to all observers
   - Trigger animations on refresh when scores change

2. `VeloReady/Features/Today/Views/Components/CompactRingView.swift`
   - Added `isRefreshing` parameter
   - Updated title display logic to handle refreshing state

3. `VeloReady/Features/Today/Views/Dashboard/Sections/RecoveryMetricsSection.swift`
   - Updated all CompactRingView instances to use `viewModel.ringAnimationTrigger`
   - Added `isRefreshing` parameter to all ring views
   - Proper loading state based on initial vs refresh

## Testing Notes

To test this fix:

1. **Initial Load Test**:
   - Force quit the app
   - Reopen it
   - Observe: All three rings should show grey shimmer with "Calculating"
   - Then all three appear together with coordinated animations

2. **Refresh Test**:
   - With app open, navigate away and back (or pull to refresh)
   - Observe: Rings stay visible with colored scores
   - Status text changes to "Calculating"
   - When new scores arrive, they update and animate individually

3. **Score Change Test**:
   - Open app with cached scores (e.g., recovery: 92)
   - Wait for recalculation
   - If score changes (e.g., recovery: 94), ring should animate

## Notes

- Sleep score is optional (no sleep data is OK)
- Required scores for initial load: Recovery + Strain
- Animation trigger is now managed by the ViewModel, not the parent View
- This maintains backward compatibility with existing loading state logic

