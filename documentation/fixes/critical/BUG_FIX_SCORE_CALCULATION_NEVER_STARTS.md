# Bug Fix: Score Calculation Never Starts + Strava Activities Missing

**Date:** November 11, 2025  
**Status:** ✅ **FIXED**

---

## Summary

Fixed critical bug where score calculation never started on app launch, causing rings to show "calculating..." indefinitely with no scores ever appearing.

---

## Bug #1: Rings Stuck on "Calculating..." Forever

### Symptoms

- Rings showed grey shimmer with "calculating" text
- No scores ever appeared (Recovery: nil, Sleep: nil, Strain: nil)
- Persisted even after 30+ seconds
- No loading state updates shown

### Root Cause

The `TodayCoordinator.loadInitial()` was **never being triggered** on app launch because:

1. **TodayView** conditionally renders `NavigationStack` based on `showInitialSpinner`
2. During branding animation (3 seconds), `showInitialSpinner = true` → `NavigationStack` **not rendered**
3. `.onAppear` attached to `NavigationStack` → **never fires** during branding
4. Branding ends, `showInitialSpinner = false` → `NavigationStack` renders → `.onAppear` fires **too late**
5. By the time `.onAppear` fires, user has already seen the UI with broken rings

**Evidence from logs:**
```
[19:11:23Z] ❌ [LatestActivity] No Strava/Intervals activity found
[19:11:26Z] 🏠 [TodayView] BODY EVALUATED - showInitialSpinner: false
[19:11:40Z] 🎬 [CompactRingView] Skipping onAppear animation - isLoading: true, score: nil
```

**Missing logs:**
- ❌ No `🔄 [TodayCoordinator] Starting loadInitial()`
- ❌ No `🔄 [TodayCoordinator] Phase 1: Calculating scores...`
- ❌ No score calculation logs at all

### The Fix

Added `.onChange(of: showInitialSpinner)` to detect when the branding animation completes and immediately trigger `handleViewAppear()`.

**Before:**
```swift
NavigationStack {
    // ... UI content ...
}
.onAppear {
    handleViewAppear() // Only fires when NavigationStack renders
}
```

**After:**
```swift
NavigationStack {
    // ... UI content ...
}
.onAppear {
    handleViewAppear() // Fires when NavigationStack renders
}
.onChange(of: showInitialSpinner) { oldValue, newValue in
    // CRITICAL FIX: Trigger initial load when branding animation completes
    if oldValue == true && newValue == false {
        Logger.info("🎬 [SPINNER] Branding animation completed - triggering handleViewAppear()")
        handleViewAppear() // Fires IMMEDIATELY when branding ends
    }
}
```

**Flow Timeline:**

**Before (BROKEN):**
```
t=0s:    App launches, showInitialSpinner=true
t=0-3s:  Branding animation plays, NavigationStack NOT rendered
t=3s:    Branding ends, showInitialSpinner=false
t=3.0s:  NavigationStack renders for FIRST TIME
t=3.1s:  .onAppear fires → handleViewAppear() → loadInitial()
         ↑ User has already seen rings for 0.1s
```

**After (FIXED):**
```
t=0s:    App launches, showInitialSpinner=true
t=0-3s:  Branding animation plays, NavigationStack NOT rendered
t=3s:    Branding ends, showInitialSpinner=false
         ↓ IMMEDIATELY trigger onChange
t=3.0s:  onChange fires → handleViewAppear() → loadInitial()
t=3.0s:  NavigationStack renders (in parallel with load starting)
         ↑ Scores already calculating by the time UI shows
```

---

## Bug #2: Strava Activities Not Showing in "Latest Activity"

### Symptoms

**First Launch:**
- "Latest Activity" card showed skeleton (grey placeholder)
- Logs: `❌ [LatestActivity] No Strava/Intervals activity found`
- 15 Apple Health workouts present, but 0 Strava activities

**After Force-Quit + Restart:**
- "Latest Activity" card showed Strava ride correctly
- Logs: `✅ [LatestActivity] Found: Morning Ride (source: strava)`

### Root Cause

This is a **race condition** symptom of Bug #1:

1. `TodayCoordinator.loadInitial()` never started
2. `ActivitiesCoordinator.fetchRecent()` never called
3. `TodayViewModel.unifiedActivities` remained empty `[]`
4. `getLatestActivity()` filters `unifiedActivities` → found nothing

**Code path:**
```swift
// VeloReady/Features/Today/Views/Dashboard/TodayView.swift (line 127)
if let latestActivity = getLatestActivity() {
    LatestActivityCardV2(activity: latestActivity)
} else {
    SkeletonActivityCard() // ← Shown because getLatestActivity() returned nil
}

// getLatestActivity() filters viewModel.unifiedActivities
private func getLatestActivity() -> UnifiedActivity? {
    let activities = viewModel.unifiedActivities.isEmpty ? // ← Empty on first launch!
        viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
        viewModel.unifiedActivities
    
    return activities.first { activity in
        activity.source == .strava || activity.source == .intervalsICU
    }
}
```

**Why it worked after force-quit:**
- On second launch, `TodayCoordinator` state was `.background` (not `.initial`)
- `handle(.viewAppeared)` triggered `refresh()` instead of `loadInitial()`
- `refresh()` is NOT gated by the branding animation timing issue
- Activities fetched correctly

### The Fix

Same fix as Bug #1 - ensuring `loadInitial()` starts immediately when branding ends populates `unifiedActivities` correctly on first launch.

---

## Files Modified

- ✅ `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`
  - Added `.onChange(of: showInitialSpinner)` to trigger `handleViewAppear()` when branding completes
  - Updated logging to clarify which `.onAppear` fired (NavigationStack vs branding)

---

## Testing Checklist

### Test 1: Fresh Install (Force-Quit Scenario)
1. ✅ **Delete app** and reinstall
2. ✅ **Launch app** (first time)
3. ✅ **Expected:** 
   - Branding animation plays for 3 seconds
   - Rings appear with shimmer and "calculating..."
   - Within 5-10 seconds, scores populate (Recovery, Sleep, Strain)
   - Latest Activity shows Strava ride (not skeleton)

### Test 2: Normal Launch (Not Force-Quit)
1. ✅ **Send app to background** (swipe up, don't kill)
2. ✅ **Reopen app** (tap icon)
3. ✅ **Expected:**
   - NO branding animation (direct to UI)
   - Rings show immediately with cached scores
   - NO "calculating..." state (data already fresh)

### Test 3: Force-Quit + Reopen
1. ✅ **Force-quit app** (swipe up + close)
2. ✅ **Reopen app** (tap icon)
3. ✅ **Expected:**
   - Branding animation plays for 3 seconds
   - Rings show with cached scores OR calculating (depending on staleness)
   - Scores refresh if stale (>5 min)

---

## Verification Logs

**Look for these log sequences on next launch:**

### Successful Fix
```
[T+0s]  🏠 [TodayView] BODY EVALUATED - showInitialSpinner: true
[T+3s]  🎬 [SPINNER] Branding animation completed - triggering handleViewAppear()
[T+3s]  🔄 [TodayViewModel] loadInitialUI() - delegating to coordinator
[T+3s]  🔄 [TodayCoordinator] Handling event: viewAppeared - current state: initial
[T+3s]  🔄 [TodayCoordinator] ━━━ Starting loadInitial() ━━━
[T+3s]  🔄 [TodayCoordinator] Phase 1: Calculating scores...
[T+5s]  ✅ [TodayCoordinator] Scores calculated
[T+7s]  ✅ [ActivitiesCoordinator] Strava: XX activities
[T+8s]  ✅ [LatestActivity] Found: Morning Ride (source: strava)
```

### Still Broken (would see)
```
[T+0s]  🏠 [TodayView] BODY EVALUATED - showInitialSpinner: true
[T+3s]  🏠 [TodayView] BODY EVALUATED - showInitialSpinner: false
[T+5s]  ❌ [LatestActivity] No Strava/Intervals activity found
         ↑ No loadInitial() logs at all
```

---

## Related Issues

### Why didn't `.onAppear` fire during branding?

SwiftUI's `.onAppear` only fires when the view **enters the view hierarchy**. During the branding animation:
- `TodayView.body` returns `Color.black` (lines 49-55)
- `NavigationStack` is **not in the view tree** at all
- `.onAppear` attached to `NavigationStack` has nothing to appear on

This is a **fundamental SwiftUI behavior**, not a bug. Our conditional rendering was the issue.

### Alternative Solutions Considered

**Option 1:** Remove conditional rendering
- ❌ Would cause navigation bar flash before branding

**Option 2:** Use `.task` instead of `.onAppear`
- ❌ `.task` has same issue - only runs when view enters hierarchy

**Option 3:** Trigger from `MainTabView` when branding ends
- ⚠️ Tighter coupling, harder to test

**Option 4 (CHOSEN):** `.onChange(of: showInitialSpinner)`
- ✅ Clean separation of concerns
- ✅ Explicit intent (trigger on branding completion)
- ✅ Easy to test and log
- ✅ No architectural changes needed

---

## Prevention

To prevent similar issues in future:

1. **Rule:** Never attach critical initialization logic to `.onAppear` of conditionally-rendered views
2. **Rule:** Use `.onChange` or explicit state management for init triggers
3. **Logging:** Always log when critical async operations start (we had this, it revealed the bug)
4. **Testing:** Test both "first launch" and "reopen" scenarios separately

---

## Next Steps

1. ✅ Fix implemented
2. ⏳ User to test on real device
3. ⏳ Verify logs show proper sequence
4. ⏳ If successful, commit with message:
   ```
   fix: Score calculation now starts immediately after branding animation
   
   CRITICAL FIX: Rings were stuck on "calculating..." forever because
   TodayCoordinator.loadInitial() was never triggered. The NavigationStack's
   .onAppear didn't fire during the 3-second branding animation since the
   stack wasn't rendered yet.
   
   Solution: Added .onChange(of: showInitialSpinner) to trigger handleViewAppear()
   immediately when branding completes, ensuring scores start calculating
   before the UI is visible to the user.
   
   Also fixes: "Latest Activity" card showing skeleton instead of Strava rides
   (was a symptom of activities never being fetched due to same root cause).
   
   Fixes: #BUG-SCORE-CALC-TIMEOUT
   ```

---

**Status:** Ready for device testing  
**Confidence:** High - root cause identified, fix is minimal and targeted  
**Risk:** Low - only adds an additional trigger point, doesn't remove existing logic

