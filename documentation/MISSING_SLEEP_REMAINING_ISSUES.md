# Missing Sleep Data - Remaining Issues

## ✅ What's Working
1. Sleep ring shows grey "?" when no data
2. Sleep cache cleared when data is outdated
3. Recovery score recalculates with `nil` sleep inputs
4. AI brief gets `null` deltas when sleep missing
5. Backend uses separate cache key for missing data responses

## ⚠️ Remaining Issues

### 1. **UI Refresh Cascade**
**Problem:** When sleep data is detected as missing, it triggers:
- Sleep score recalculation → clears cache → triggers recovery score refresh → triggers AI brief refresh
- This causes multiple UI updates and looks messy

**Solution:** Defer the recovery score refresh until after initial UI load, or batch all refreshes together

---

### 2. **Recovery Ring Shows "?"**
**Problem:** Recovery ring shows "?" underneath when sleep data is missing

**Current behavior:** Recovery score is calculated but shows "?" label
**Expected:** Recovery score should show the actual score (46) with a note that it's based on limited data

**Fix location:** `TodayView.swift` - recovery ring display logic

---

### 3. **Wellness Alert Still Shows**
**Problem:** Wellness alert shows "Red - Several key metrics significantly elevated" even when sleep data is missing

**Current behavior:** Alert is based on HRV/RHR trends from old sleep data
**Expected:** Alert should be disabled or show different message when sleep data is missing

**Fix location:** Wellness trend analysis service - add check for missing sleep data

---

### 4. **AI Brief Still Mentions "Poor Sleep"**
**Problem:** Even with `null` sleep delta, the AI brief says something about poor sleep

**Possible causes:**
1. Backend cache not cleared (should be fixed now with separate cache key)
2. AI prompt not handling `null` correctly
3. Few-shot example not strong enough

**Test:** Wait for Netlify deployment to complete, then test again

---

### 5. **Recovery Score Alcohol Detection**
**Problem:** Recovery score dropped from 52 to 46 due to alcohol detection penalty

**Current behavior:** 
```
🍷 Overnight HRV Change: 6.2% (alcohol threshold: -15%)
🍷 RHR Change: 17.1% (alcohol threshold: +10%)
🍷 Light alcohol impact detected - applying 3pt penalty
```

**Issue:** When sleep data is missing, overnight HRV is estimated from a 12-hour window, which may not be accurate

**Expected:** Alcohol detection should be disabled or use different logic when sleep data is missing

**Fix location:** `RecoveryScoreService.swift` - alcohol detection logic

---

## Recommended Next Steps

### **Priority 1: Fix AI Brief Response**
1. Test after Netlify deployment completes
2. If still showing old response, check backend logs
3. May need to strengthen the few-shot example or adjust prompt

### **Priority 2: Disable Wellness Alert**
```swift
// In WellnessTrendAnalysisService or wherever alert is generated
if sleepScoreService.currentSleepScore == nil {
    // Don't show wellness alert when sleep data is missing
    return nil
}
```

### **Priority 3: Fix Recovery Ring Label**
```swift
// In TodayView.swift
if let recoveryScore = viewModel.recoveryScoreService.currentRecoveryScore {
    let title = recoveryScore.inputs.sleepDuration == nil 
        ? "Limited Data" 
        : recoveryScore.bandDescription
    
    CompactRingView(
        score: recoveryScore.score,
        title: title,
        band: recoveryScore.band,
        animationDelay: 0.0
    ) { }
}
```

### **Priority 4: Disable Alcohol Detection**
```swift
// In RecoveryScoreService.swift - alcohol detection section
guard sleepScore != nil else {
    print("🍷 Skipping alcohol detection - no sleep data available")
    return baseScore
}
```

### **Priority 5: Smooth UI Refresh**
Consider deferring recovery score refresh:
```swift
// In SleepScoreService.swift
Task {
    // Wait a bit to avoid UI cascade
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    await RecoveryScoreService.shared.forceRefreshRecoveryScoreIgnoringDailyLimit()
}
```

---

## Testing Checklist

- [ ] AI brief shows "no sleep data" message (not "poor sleep")
- [ ] Wellness alert is hidden when sleep data is missing
- [ ] Recovery ring shows score (not "?") with "Limited Data" label
- [ ] No alcohol penalty applied when sleep data is missing
- [ ] UI doesn't flash/refresh multiple times on app launch

---

**Status:** Partial implementation complete. Core functionality works but UX needs refinement.
**Date:** Oct 12, 2025
