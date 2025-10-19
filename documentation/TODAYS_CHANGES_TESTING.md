# Testing Guide - Today's Changes (Oct 18, 2025)

## 🎯 **Quick Test - 10 Minutes**

### **1. Weekly Report (Trends Tab)**
- [ ] Open Trends tab
- [ ] Check weekly report is **shorter** (4 paragraphs instead of 5)
- [ ] Verify it's still comprehensive and actionable
- [ ] Check loading time (should be fast due to caching)

### **2. Compact Ring Labels (Today Tab)**
- [ ] Open Today tab
- [ ] Look at the compact rings chart (Optimal/Productive/Maintaining)
- [ ] Verify labels are **lowercase** and **white** (not grey)
- [ ] Verify labels are **larger** and easier to read

### **3. Metric Labels (Trends Tab)**
- [ ] Go to Trends → Weekly Report
- [ ] Look at "Training Load Summary" section
- [ ] Verify labels (Total TSS, Training Time, Workouts) are:
  - [ ] **UPPERCASE**
  - [ ] **Grey color**
  - [ ] **Consistent spacing**

### **4. Ride Metadata Labels (Activity Detail)**
- [ ] Open any ride from Activities tab
- [ ] Look at the metadata at top (Duration, Distance, TSS, NP, etc.)
- [ ] Verify labels are:
  - [ ] **UPPERCASE**
  - [ ] **Grey color**
  - [ ] **Consistent with training load labels**

### **5. Data Sources (Settings)**
- [ ] Go to Settings → Data Sources
- [ ] Verify **Garmin is NOT listed** (only Intervals.icu, Strava, Apple Health)
- [ ] Scroll to "Priority Order" section
- [ ] Read the footer text - should explain what priority does with example

### **6. Adaptive Zones (Settings)**
- [ ] Go to Settings → Adaptive Zones
- [ ] Verify **NO "PRO" badge** next to "Adaptive Zones"
- [ ] Should just say "Adaptive Zones" cleanly

### **7. Feedback (Settings)**
- [ ] Go to Settings → Send Feedback
- [ ] Write test feedback
- [ ] Toggle "Include diagnostic logs" ON
- [ ] Tap "Send Feedback"
- [ ] Check email draft has **attachment** (veloready-logs.txt)
- [ ] Verify logs are in file, not inline in email body

### **8. Sign Out (Settings)**
- [ ] Go to Settings → Account
- [ ] Look at "Sign Out from Intervals.icu" button
- [ ] Verify it has **subtitle**: "Disconnect your account and remove access"

---

## 🔍 **Debug Logging Test - 5 Minutes**

### **Fitness Trajectory Logging**
- [ ] Enable debug logging: Settings → Advanced → Debug Logging ON
- [ ] Go to Trends tab
- [ ] Open Xcode Console
- [ ] Look for logs starting with "📊 Loading CTL data"
- [ ] Should show each day's CTL/ATL values or "No load data"
- [ ] Should warn if no CTL data available

**What to look for:**
```
📊 Loading CTL data for 7 days
  Oct 12: CTL=74.2, ATL=68.5
  Oct 13: No load data
  Oct 14: CTL=75.1, ATL=69.2
  ...
📈 CTL Historical: 5 days loaded
```

OR if no data:
```
⚠️ No CTL data available (7 days without load data)
   Check if Intervals.icu provides CTL/ATL values in wellness data
```

---

## 📋 **Settings Verification - 5 Minutes**

### **Sleep Target Impact**
- [ ] Go to Settings → Sleep Target
- [ ] Note current target (e.g., 8 hours)
- [ ] Check Today tab → Sleep Score
- [ ] Note the score (e.g., 85)
- [ ] Change target to 7 hours
- [ ] Wait for recalculation
- [ ] Check if sleep score changed (should increase if you slept 7h+)

**Expected:** If you slept 7h with 8h target = 87.5% performance. With 7h target = 100% performance.

### **Display Preferences**
- [ ] Go to Settings → Display Preferences
- [ ] Toggle "Metric Units" OFF (switch to imperial)
- [ ] Go back to Activities
- [ ] Verify distances show in **miles** instead of km
- [ ] Toggle back ON
- [ ] Verify switches back to **km**

### **Notifications**
- [ ] Go to Settings → Notifications
- [ ] Toggle "Sleep Reminders" ON
- [ ] Set reminder time
- [ ] **Note:** Actual notifications NOT implemented yet (UI only)
- [ ] Verify settings persist when you close and reopen

---

## ✅ **Expected Results**

### **Visual Changes:**
1. ✅ Weekly report is noticeably shorter
2. ✅ Compact ring labels are lowercase, white, larger
3. ✅ All metric labels are CAPS + GREY
4. ✅ No Garmin in data sources
5. ✅ No PRO badge on Adaptive Zones
6. ✅ Sign out has descriptive subtitle

### **Functional Changes:**
7. ✅ Feedback attaches logs as file
8. ✅ Data source priority has explanation
9. ✅ Debug logging shows CTL data availability
10. ✅ Sleep target affects sleep score
11. ✅ Display preferences work (metric/imperial)

---

## 🐛 **Known Limitations**

### **Not Implemented:**
1. **Notifications** - UI exists but doesn't schedule actual notifications
2. **Profile Editing** - No user editing or avatar picker yet
3. **Fitness Trajectory** - May show "No data" if Intervals.icu doesn't provide CTL/ATL

### **Needs Investigation:**
1. **Fitness Trajectory Data** - Check debug logs to see if CTL/ATL is available
2. **Wellness Foundation** - Already works, but user may want more metrics

---

## 📊 **What Changed (Technical)**

### **Files Modified:**
1. `weekly-report.ts` - Reduced output by 20%
2. `CompactRingsChart.swift` - Fixed label styling
3. `MetricLabelModifier.swift` - Created reusable modifier
4. `TrainingLoadComponent.swift` - Applied metric labels
5. `WorkoutDetailView.swift` - Applied metric labels
6. `DataSource.swift` - Removed Garmin
7. `DataSourcesSettingsView.swift` - Added priority explanation
8. `TrainingZonesSection.swift` - Removed PRO badge
9. `FeedbackView.swift` - Attach logs as file
10. `Logger.swift` - Added exportLogs() function
11. `AccountSection.swift` - Added sign out subtitle
12. `WeeklyReportViewModel.swift` - Added CTL debug logging

### **Files Created:**
1. `TRENDS_SETTINGS_AUDIT.md`
2. `INVESTIGATION_FINDINGS.md`
3. `SETTINGS_VERIFICATION.md`
4. `COMPREHENSIVE_WORK_SUMMARY.md`

---

## 🎉 **Success Criteria**

### **Must Work:**
- [ ] All visual changes visible
- [ ] Feedback logs attach as file
- [ ] Settings persist correctly
- [ ] No crashes or errors
- [ ] App builds and runs

### **Should Work:**
- [ ] Sleep target affects scoring
- [ ] Display preferences change units
- [ ] Debug logging shows CTL data
- [ ] Weekly report is shorter

### **Nice to Have:**
- [ ] Fitness trajectory shows data (depends on Intervals.icu)
- [ ] All documentation is clear
- [ ] Everything feels polished

---

## 📝 **Feedback Template**

If you find issues:

```
**Issue:** [Brief description]
**Location:** [Where in the app]
**Expected:** [What should happen]
**Actual:** [What actually happened]
**Priority:** [Blocker / High / Medium / Low]
**Screenshots:** [If applicable]
```

---

## ⏱️ **Time Estimates**

- **Quick Test:** 10 minutes
- **Debug Logging:** 5 minutes  
- **Settings Verification:** 5 minutes
- **Total:** ~20 minutes

---

## 🚀 **Ready to Test!**

All changes have been:
- ✅ Implemented
- ✅ Tested (builds successful)
- ✅ Committed to GitHub
- ✅ Documented

**Pull the latest changes and start testing!** 🎯
