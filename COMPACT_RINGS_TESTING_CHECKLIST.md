# Compact Rings Loading Behavior - Testing Checklist

## Overview

This checklist helps verify that the compact rings loading behavior works correctly after the implementation changes.

## Test Scenarios

### ✅ Test 1: Initial Load (Cold Start)

**Setup**:
1. Force quit the VeloReady app completely
2. Clear app from background
3. Reopen the app

**Expected Behavior**:
- [ ] All three rings (Recovery, Sleep, Load) show as **grey with shimmer effect**
- [ ] Each ring shows **"Calculating"** status text below it
- [ ] Rings remain grey until **ALL scores are ready**
- [ ] Once all scores are calculated:
  - [ ] All three rings appear with their colors **simultaneously**
  - [ ] All three rings animate **together** (coordinated animation)
  - [ ] Status text changes from "Calculating" to band name (e.g., "Optimal", "Excellent", "Easy")
  - [ ] Score numbers fade in as rings animate

**Failure Indicators**:
- ❌ Rings appear one by one (staggered appearance)
- ❌ Load ring appears first with score, while others are grey
- ❌ Rings animate at different times

---

### ✅ Test 2: Refresh (App Reopened)

**Setup**:
1. With app showing scores (e.g., Recovery: 92, Sleep: 93, Load: 2.1)
2. Navigate away from the app (go to home screen)
3. Wait a few seconds
4. Reopen the app

**Expected Behavior**:
- [ ] Rings stay **visible with their current scores and colors** (NOT grey)
- [ ] Status text changes to **"Calculating"** below each ring
- [ ] Scores remain visible (92, 93, 2.1) during calculation
- [ ] As each new score arrives:
  - [ ] Score updates to new value
  - [ ] Ring animates to new value
  - [ ] Status text changes from "Calculating" to band name
  - [ ] Each score can update independently (don't wait for all)

**Failure Indicators**:
- ❌ Rings turn grey during refresh
- ❌ Scores disappear during refresh
- ❌ No "Calculating" status shown
- ❌ Rings don't animate when scores change

---

### ✅ Test 3: Pull-to-Refresh

**Setup**:
1. With app showing scores
2. Pull down on the Today view to trigger refresh

**Expected Behavior**:
- [ ] Same behavior as Test 2 (Refresh)
- [ ] Rings stay visible with current scores
- [ ] "Calculating" status appears
- [ ] Rings animate as new scores arrive

---

### ✅ Test 4: Score Changes During Refresh

**Setup**:
1. Open app with cached scores
2. Wait for recalculation
3. Observe if any scores change (e.g., new activity added changes Load score)

**Expected Behavior**:
- [ ] If Recovery score changes (e.g., 92 → 94):
  - [ ] Ring animates from old position to new position
  - [ ] Number updates with fade effect
  - [ ] Status text updates
- [ ] If Sleep score changes:
  - [ ] Same animation behavior
- [ ] If Load score changes:
  - [ ] Same animation behavior
- [ ] Each score animates **independently** as it updates

---

### ✅ Test 5: No Sleep Data Scenario

**Setup**:
1. Test with an account that has no sleep data
2. Or enable debug "Simulate No Sleep Data" option

**Expected Behavior**:

**Initial Load**:
- [ ] Recovery and Load rings show grey with "Calculating"
- [ ] Sleep ring shows grey with "Calculating"
- [ ] Wait for Recovery + Load to be ready (Sleep is optional)
- [ ] Once ready, show scores together

**Refresh**:
- [ ] Recovery and Load show colored rings with "Calculating"
- [ ] Sleep shows "?" with no "Calculating" status
- [ ] Recovery and Load animate as scores arrive

---

### ✅ Test 6: Fast Network / Cached Scores

**Setup**:
1. Open app with good network and recent cached scores
2. Scores calculate very quickly (< 1 second)

**Expected Behavior**:

**Initial Load**:
- [ ] Grey rings may only show briefly (< 1 second)
- [ ] All rings appear together once ready
- [ ] Coordinated animation happens

**Refresh**:
- [ ] Colored rings with "Calculating" may only show briefly
- [ ] Each ring animates as score updates
- [ ] Smooth transitions even if fast

---

### ✅ Test 7: Slow Network / Long Calculation

**Setup**:
1. Enable network throttling or use slow connection
2. Scores may take 5+ seconds to calculate

**Expected Behavior**:

**Initial Load**:
- [ ] Grey rings with shimmer remain visible for entire duration
- [ ] "Calculating" status shows consistently
- [ ] No timeout or blank state
- [ ] All rings appear together once ready (even if 5+ seconds)

**Refresh**:
- [ ] Colored rings stay visible entire time
- [ ] "Calculating" status shows entire time
- [ ] No rings disappear or turn grey
- [ ] Smooth updates as scores arrive

---

### ✅ Test 8: Navigation Back to Today

**Setup**:
1. From Today view with visible scores
2. Navigate to a detail view (Recovery Detail, Sleep Detail, or Strain Detail)
3. Navigate back to Today

**Expected Behavior**:
- [ ] Rings remain visible with scores (no reload animation)
- [ ] No "Calculating" status appears
- [ ] No grey rings appear
- [ ] Scores stay stable

**Failure Indicators**:
- ❌ Rings disappear and reload
- ❌ Grey rings appear briefly
- ❌ Unnecessary animations trigger

---

## Debug Logging

Look for these log messages to understand what's happening:

### Initial Load Logs:
```
💪 [VIEWMODEL] checkAllScoresReady - isInitialLoad: true
⏳ [VIEWMODEL] Still loading - recovery: true, sleep: true, strain: true
💪 [VIEWMODEL] ✅ All scores ready on initial load - transitioning to refresh mode
✅ [VIEWMODEL] All scores ready on initial load - recovery: 92, sleep: 93, strain: 2.1
```

### Refresh Logs:
```
💪 [VIEWMODEL] checkAllScoresReady - isInitialLoad: false
💪 [VIEWMODEL] checkAllScoresReady (refresh mode) - hasAnyScore: true, allScoresReady: true
🎬 [VIEWMODEL] Recovery score changed from 92 → 94, triggering ring animation
```

### Score Change Logs:
```
🔄 [VIEWMODEL] Recovery score changed via Combine: 94
🎬 [VIEWMODEL] Recovery score changed from 92 → 94, triggering ring animation
```

---

## Common Issues and Solutions

### Issue: Rings appear one by one on initial load
**Diagnosis**: `checkAllScoresReady()` not waiting for all scores
**Fix**: Check that `isInitialLoad = true` on first load and `allLoadingComplete` logic is correct

### Issue: Rings turn grey on refresh
**Diagnosis**: `isRefreshing` not being set correctly
**Fix**: Check that `viewModel.isRecoveryLoading && !viewModel.isInitialLoad` condition is working

### Issue: No animations on score changes
**Diagnosis**: `ringAnimationTrigger` not updating
**Fix**: Check score observers are detecting changes and updating trigger UUID

### Issue: Rings don't animate together on initial load
**Diagnosis**: Animation trigger not firing when `allScoresReady` transitions
**Fix**: Check that `ringAnimationTrigger = UUID()` is called in `checkAllScoresReady()`

---

## Performance Checks

- [ ] Initial load feels smooth (no janky stagger)
- [ ] Grey shimmer animation is smooth (60fps)
- [ ] Ring animations are smooth (no stuttering)
- [ ] "Calculating" text transitions smoothly
- [ ] No perceived delay between score ready and ring animation
- [ ] Refresh doesn't cause UI flicker

---

## Accessibility Checks

- [ ] VoiceOver announces "Calculating" status
- [ ] VoiceOver announces score values when ready
- [ ] VoiceOver announces band names (Optimal, Excellent, etc.)
- [ ] Ring animations don't interfere with VoiceOver
- [ ] "Calculating" text is readable at all accessibility text sizes

---

## Edge Cases

### Multiple Rapid Refreshes
- [ ] Pull to refresh multiple times rapidly
- [ ] Rings should handle gracefully (no crashes)
- [ ] Latest scores should win

### App Backgrounding During Calculation
- [ ] Start refresh, immediately background app
- [ ] Bring app back to foreground
- [ ] Should continue from where it left off or restart cleanly

### Network Error During Calculation
- [ ] Simulate network error mid-calculation
- [ ] Should show error state or fallback to cached scores
- [ ] No grey rings stuck forever

---

## Sign-Off

Once all tests pass, this feature is ready for production.

**Tested by**: _______________  
**Date**: _______________  
**Device/Simulator**: _______________  
**iOS Version**: _______________  

**Notes**:

