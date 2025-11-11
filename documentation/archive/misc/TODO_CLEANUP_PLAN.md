# TODO Cleanup Plan - 45 Total

## CATEGORY 1: DELETE - Outdated/No Longer Relevant (20 TODOs)

### TrendsViewModel.swift (5 TODOs)
- ❌ Line 126: "Implement historical FTP tracking" → Out of scope
- ❌ Line 234: "Calculate weekly TRIMP from HealthKit" → Out of scope, Intervals.icu sufficient
- ❌ Line 312: "Calculate actual intensity distribution" → Mock data acceptable for now
- ❌ Line 344-354: "Get actual HRV/RHR/TSB/sleep debt" → Mock acceptable for risk calculation
- **Action:** Delete all 7 TODOs, keep mock data for overtraining risk

### TodayViewModel.swift (3 TODOs)
- ❌ Line 223: "Implement wellness fetching" → IntervalsCache deleted, not needed
- ❌ Line 610: "Implement wellness fetching if needed" → Same as above
- ❌ Line 832: "Add Wahoo detection" → Not implementing Wahoo integration
- **Action:** Delete comments, functionality not needed

### TodayView.swift (3 TODOs)
- ❌ Line 294: "Implement sleep data fetching" → Already implemented via cards
- ❌ Line 303: "Implement HRV data fetching" → Already implemented via cards  
- ❌ Line 312: "Implement RHR data fetching" → Already implemented via cards
- **Action:** Delete, these cards are debug/placeholder code

### RideSummaryService.swift (4 TODOs)
- ❌ Line 142: "Parse intervals from activity" → Not available from API
- ❌ Line 143: "Add fueling to activity model" → Not tracked
- ❌ Line 144: "Add RPE to activity model" → Not in Intervals.icu API
- ❌ Line 147: "Add user goals" → Out of scope for ride summary
- **Action:** Delete all, features not in current scope

### WeeklyReportViewModel.swift (3 TODOs)
- ❌ Line 386: "Calculate from actual zone time data" → Mock acceptable
- ❌ Line 660: "Calculate from workout times" → Not needed
- ❌ Line 896: "Integrate with ML model" → Future feature
- **Action:** Delete, mock data acceptable

### Other Files (2 TODOs)
- ❌ RestingHRCardV2.swift Line 15: "Calculate personal baseline" → Mock acceptable
- ❌ PaywallView.swift Lines 191-194: "Open terms/privacy URL" → Not implemented yet
- **Action:** Delete both

---

## CATEGORY 2: DELETE - Simple Comment Removal (15 TODOs)

### Onboarding (3 TODOs)
- ❌ SubscriptionStepView Line 141: "Implement actual subscription flow" → Already logs correctly
- ❌ ProfileSetupStepView Lines 140,143: "Fetch athlete name from Strava/Intervals" → Using fallback "Athlete"
- **Action:** Delete comments, keep existing behavior

### Strain/Activity Views (2 TODOs)
- ❌ StrainDetailView Lines 453-454: "Implement continuous HR data collection" → Not in scope
- **Action:** Delete, nil values are correct

### Services (5 TODOs)
- ❌ TRIMPCalculator (2): Mock data comments
- ❌ DataSourceManager (2): Placeholder comments  
- ❌ WatchConnectivityManager (2): TODO placeholders
- ❌ SleepScoreService (1): Integration note
- ❌ ActivityDeduplicationService (1): Enhancement note
- **Action:** Delete all comment TODOs

### Networking/ML (3 TODOs)
- ❌ RideSummaryClient (1): Cache note
- ❌ AIBriefClient (1): Error handling note
- ❌ MLTelemetryService (1): Privacy note
- **Action:** Review and delete if comments are outdated

---

## CATEGORY 3: FIX NOW - Simple Fixes (10 TODOs)

### AppCoordinator (2 TODOs)
- ✅ Line ~50: Check for actual implementation issues
- **Action:** Read file and verify if TODOs are still valid

### IconTestView (1 TODO)
- ✅ Debug view - likely can delete entire TODO
- **Action:** Check if still needed

### Other Services (7 TODOs)
- Check each file individually for quick fixes

---

## Summary

**Total: 45 TODOs**
- DELETE (Category 1): 20 TODOs - Outdated/out of scope
- DELETE (Category 2): 15 TODOs - Simple comment removals
- FIX/REVIEW (Category 3): 10 TODOs - Need individual review

**Target: 0 TODOs remaining**
**Estimated Time: 1-2 hours**

---

## Execution Plan

1. **Batch delete Category 1** (20 TODOs) - 30 min
2. **Batch delete Category 2** (15 TODOs) - 20 min  
3. **Review and fix Category 3** (10 TODOs) - 30 min
4. **Final verification** - 10 min
5. **Commit** - 5 min

**Total: ~1.5 hours**
