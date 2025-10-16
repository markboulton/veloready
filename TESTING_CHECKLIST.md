# VeloReady Testing Checklist
## Unified Data Source Architecture Validation

---

## Pre-Testing Setup

### Test Accounts Required
- [ ] **Intervals.icu account** with recent activities (last 30 days)
- [ ] **Strava account** with recent activities (last 30 days)
- [ ] Device with HealthKit permissions enabled

### Test Data Requirements
- [ ] At least 5 cycling activities in last 30 days
- [ ] Mix of indoor/outdoor rides
- [ ] Mix of power-based and HR-only activities
- [ ] At least one activity from today

---

## Phase 1: Intervals.icu Only Testing

### Setup
- [ ] Disconnect from Strava (if connected)
- [ ] Connect to Intervals.icu
- [ ] Wait for initial data sync

### Activity Display
- [ ] **Activities tab** shows Intervals activities
- [ ] **Today tab** shows most recent ride
- [ ] Activity cards show correct metrics (distance, duration, TSS)
- [ ] Activity types display correctly (Ride, VirtualRide, etc.)
- [ ] Date formatting is consistent ("Today at 8pm", "Yesterday at 9am")

### Ride Detail View
- [ ] Open any cycling activity
- [ ] **Header** shows correct name, type, date
- [ ] **Metrics** display: Duration, Distance, Elevation
- [ ] **Power metrics** (if available): Avg/Max Power, NP, TSS, IF
- [ ] **HR metrics** (if available): Avg/Max HR, HR zones
- [ ] **Map** displays for outdoor rides
- [ ] **Map hidden** for virtual/indoor rides
- [ ] **Elevation chart** displays
- [ ] **Power curve** displays (if power data available)
- [ ] **Power zone distribution** chart displays
- [ ] **HR zone distribution** chart displays
- [ ] **Training Load chart** displays with CTL/ATL/TSB

### Training Load Chart
- [ ] Chart renders 37-day view (30 past + 7 future)
- [ ] Shows 3 lines: CTL (blue), ATL (orange), TSB (green)
- [ ] Today's ride highlighted with vertical line
- [ ] Legend shows current values
- [ ] Form description matches TSB value

### Today View Metrics
- [ ] **Load** value reflects today's activity
- [ ] **Cardio** value reflects today's TRIMP
- [ ] **Strain score** includes cycling activity
- [ ] **Recovery metrics** display correctly

### Adaptive FTP
- [ ] Go to Settings → Athlete Zones
- [ ] Tap "Recompute from Activities"
- [ ] FTP calculates from Intervals data
- [ ] Power zones update automatically
- [ ] Zone boundaries are reasonable

---

## Phase 2: Strava Only Testing

### Setup
- [ ] Disconnect from Intervals.icu
- [ ] Connect to Strava
- [ ] Wait for initial data sync

### Activity Display
- [ ] **Activities tab** shows Strava activities
- [ ] **Today tab** shows most recent ride
- [ ] Activity cards show correct metrics
- [ ] NO DIFFERENCE from Intervals display
- [ ] Same date formatting

### Ride Detail View (Critical - Must Match Intervals)
- [ ] Open any cycling activity
- [ ] **Header** identical to Intervals layout
- [ ] **All metrics** display (same as Intervals)
- [ ] **TSS calculated** if power data available
- [ ] **Intensity Factor** calculated from power/FTP
- [ ] **Map** displays for outdoor rides
- [ ] **Map hidden** for virtual rides
- [ ] **Elevation chart** displays
- [ ] **Power curve** displays
- [ ] **Zone charts** display with calculated zones
- [ ] **Training Load chart** displays with calculated CTL/ATL

### Training Load Chart (Critical)
- [ ] Chart renders with same 37-day view
- [ ] CTL/ATL **calculated from Strava activities**
- [ ] Values are reasonable (not 0, not extreme)
- [ ] Chart appearance identical to Intervals version
- [ ] All 3 lines display correctly

### Today View Metrics (Critical)
- [ ] **Load** value includes today's Strava ride
- [ ] **NOT showing 0** for cardio
- [ ] **Strain score** includes Strava activity
- [ ] Values match if same activities in both sources

### Adaptive FTP (Critical)
- [ ] Go to Settings → Athlete Zones
- [ ] Tap "Recompute from Activities"
- [ ] FTP calculates from **Strava power data**
- [ ] Power zones generate correctly
- [ ] Results similar to Intervals calculation

---

## Phase 3: Data Accuracy Comparison

### Same Activity in Both Sources
- [ ] Find an activity synced to both Intervals + Strava
- [ ] Compare TSS values (should be within 5%)
- [ ] Compare Intensity Factor (should match closely)
- [ ] Compare power zone times (should match)
- [ ] Compare HR zone times (should match)

### CTL/ATL Comparison
- [ ] Calculate CTL/ATL with Intervals connected
- [ ] Note values (e.g., CTL: 85.3, ATL: 42.1)
- [ ] Disconnect Intervals, connect Strava only
- [ ] Compare CTL/ATL from Strava data
- [ ] Values should be within 10% (different data sources may have slight variance)

### Metric Consistency
- [ ] TSS calculations use same formula
- [ ] Zone boundaries identical for same FTP
- [ ] Virtual ride detection works for both
- [ ] Date formatting identical

---

## Phase 4: Edge Cases & Error Handling

### Missing Data Scenarios
- [ ] Activity with **no power data** (HR-only)
  - [ ] Detail view still displays
  - [ ] HR zones calculate correctly
  - [ ] No TSS/IF shown (expected)
  - [ ] No crash or blank screen

- [ ] Activity with **no HR data** (power-only)
  - [ ] Detail view displays
  - [ ] Power metrics calculate
  - [ ] No HR zones (expected)
  - [ ] Training load chart works

- [ ] **No FTP set** in profile
  - [ ] App doesn't crash
  - [ ] Zones show "Set FTP to unlock"
  - [ ] Activities still display
  - [ ] Adaptive FTP offers calculation

### Virtual Ride Detection
- [ ] Open a **Zwift ride** (VirtualRide type)
  - [ ] Map section is hidden
  - [ ] Elevation chart is hidden
  - [ ] Power/HR metrics still display
  - [ ] Training load chart works

- [ ] Open an **outdoor ride**
  - [ ] Map displays
  - [ ] GPS route visible
  - [ ] Elevation chart shows

### Network Errors
- [ ] Turn on Airplane Mode
- [ ] Try to load activity detail
  - [ ] Cached data displays (if available)
  - [ ] Error message is helpful
  - [ ] App doesn't crash

- [ ] Reconnect network
- [ ] Pull to refresh works
- [ ] Data loads successfully

---

## Phase 5: Switching Between Sources

### Intervals → Strava Switch
- [ ] Start with Intervals connected
- [ ] Load an activity detail page
- [ ] Disconnect Intervals
- [ ] Connect Strava
- [ ] Go to Activities tab
- [ ] **Activities switch to Strava** seamlessly
- [ ] No crash, no data loss
- [ ] Today view updates correctly

### Strava → Intervals Switch
- [ ] Start with Strava only
- [ ] Connect Intervals.icu
- [ ] Activities switch to Intervals
- [ ] **Intervals takes priority** (higher quality data)
- [ ] Duplicate activities filtered correctly
- [ ] No crash, smooth transition

### Both Connected
- [ ] Connect both Intervals + Strava
- [ ] Activities tab shows **Intervals activities first**
- [ ] Strava-only activities also visible
- [ ] No duplicate activities shown
- [ ] Detail view prioritizes Intervals data

---

## Phase 6: Performance & UX

### Load Times
- [ ] Activity list loads in < 2 seconds
- [ ] Activity detail opens in < 1 second
- [ ] Training load chart renders in < 2 seconds
- [ ] Map loads progressively (doesn't block UI)
- [ ] No stuttering or lag when scrolling

### Memory & Stability
- [ ] Open 10+ activities in sequence
- [ ] No memory warnings in console
- [ ] App remains responsive
- [ ] No crashes after extended use

### UI Consistency
- [ ] **Same fonts** across all views
- [ ] **Same colors** for metrics
- [ ] **Same spacing** and padding
- [ ] **Same animations** for loading states
- [ ] No visual differences between Intervals/Strava views

### Logging Quality
- [ ] Open Xcode Console
- [ ] Logs indicate which data source is being used
- [ ] Errors are descriptive and actionable
- [ ] Success messages confirm operations
- [ ] TSS/CTL/ATL calculations logged

---

## Phase 7: Real-World Workflow

### Morning Routine Test
1. [ ] Complete a morning ride (real or simulated)
2. [ ] Sync to Strava/Intervals
3. [ ] Open VeloReady
4. [ ] **Today view** shows today's ride in Load
5. [ ] **Activities tab** shows ride at top
6. [ ] Open ride detail
7. [ ] All metrics display correctly
8. [ ] Training load chart includes today's TSS
9. [ ] Strain score reflects workout

### Multi-Activity Day
1. [ ] Have 2+ activities in one day (e.g., morning ride + evening walk)
2. [ ] **Strain score** includes both activities
3. [ ] **Load metric** shows cycling contribution
4. [ ] **Cardio metric** includes all cardio work
5. [ ] Activity list shows all activities

### Weekly Review
1. [ ] Go to Activities tab
2. [ ] Review last 7 days
3. [ ] All rides display
4. [ ] Training load trends visible
5. [ ] Can see CTL/ATL progression

---

## Critical Success Criteria

### Must Pass (Blockers)
- [ ] ✅ **Training Load Chart displays for Strava activities**
- [ ] ✅ **Today view Load/Cardio NOT showing 0 for Strava rides**
- [ ] ✅ **TSS calculates correctly from Strava power data**
- [ ] ✅ **CTL/ATL calculate from Strava activities**
- [ ] ✅ **Virtual rides detected from Strava (map hidden)**
- [ ] ✅ **No duplicate conversion logic remains**
- [ ] ✅ **UnifiedActivityService used throughout**
- [ ] ✅ **ActivityConverter used for all Strava conversions**

### Should Pass (Important)
- [ ] ✅ Adaptive FTP works with Strava data
- [ ] ✅ Power zones calculate from Strava
- [ ] ✅ HR zones calculate from Strava
- [ ] ✅ Same UI regardless of data source
- [ ] ✅ No crashes with missing data
- [ ] ✅ Smooth switching between sources

### Nice to Have (Enhancement)
- [ ] ⭐ Load times under 1 second
- [ ] ⭐ Zero memory warnings
- [ ] ⭐ Detailed logging for debugging
- [ ] ⭐ Helpful error messages

---

## Regression Testing

### Previously Fixed Issues
- [ ] Training Load Chart now shows for Strava activities
- [ ] Today view includes Strava rides in strain calculation
- [ ] Map correctly hidden for VirtualRide type
- [ ] Date formatting consistent ("Today at 8pm" style)
- [ ] Virtual ride detection works for both sources

---

## Bug Reporting Template

If you find issues, report with:
```
**Issue:** Brief description
**Data Source:** Intervals / Strava / Both
**Steps to Reproduce:**
1. Step one
2. Step two
3. Expected vs Actual

**Screenshots:** (if applicable)
**Console Logs:** (if available)
**Priority:** Blocker / High / Medium / Low
```

---

## Sign-Off

### Tester Information
- **Tester Name:** _______________
- **Test Date:** _______________
- **App Version:** _______________
- **Device:** _______________
- **iOS Version:** _______________

### Results Summary
- **Total Tests:** ___ / ___
- **Passed:** ___
- **Failed:** ___
- **Blocked:** ___
- **Not Tested:** ___

### Overall Assessment
- [ ] ✅ **APPROVED** - Ready for release
- [ ] ⚠️ **APPROVED WITH CAVEATS** - Minor issues, can release
- [ ] ❌ **NOT APPROVED** - Critical issues, needs fixes

### Notes
```
Add any additional observations, concerns, or recommendations here.
```

---

## Quick Test (Smoke Test)

If time-constrained, run this minimal test:

1. [ ] Connect to Strava
2. [ ] Open today's ride
3. [ ] Verify Training Load Chart displays
4. [ ] Verify Today view shows Load > 0
5. [ ] Verify TSS calculated (if power data)
6. [ ] Verify map hidden for virtual rides
7. [ ] Switch to Intervals
8. [ ] Verify same ride displays identically

**Estimated time:** 15 minutes

---

## Full Test Suite

**Estimated time:** 2-3 hours

All phases above completed thoroughly.
