# Testing Checklist - Strain Score & AI Brief Fixes

**Date:** October 16, 2025  
**Changes:** Strain score duration fix, AI brief completed activities detection, Adaptive zones research validation

---

## 🧪 **Test 1: Strain Score with Intervals.icu Activity**

**What to test:** Verify strain score now includes full ride duration from Intervals.icu

- [ ] Open VeloReady app
- [ ] Ensure you have an Intervals.icu ride from today (your 6am ride)
- [ ] Navigate to Today view → Strain score
- [ ] **Verify:** Shows correct duration (50+ mins, not 23 mins)
- [ ] **Verify:** Score is higher (6-8 range, not 3.1)

**Expected Logs:**
```
🔍 Found 1 unified activities for today (Intervals.icu or Strava)
   HealthKit Duration: 0min
   Intervals/Strava Duration: 52min
   Total Cardio Duration: 52min
   Cardio TRIMP: 45.2
```

**Pass Criteria:**
- ✅ Duration matches actual ride time
- ✅ Strain score reflects full workout (not just HealthKit portion)
- ✅ Logs show "Intervals/Strava Duration" > 0

---

## 🧪 **Test 2: AI Daily Brief - Post-Workout**

**What to test:** Verify AI brief acknowledges completed workout and doesn't prescribe more work

- [ ] Hard refresh daily brief (pull down to refresh)
- [ ] **Verify:** Brief acknowledges your completed workout
- [ ] **Verify:** Doesn't prescribe more work (should focus on recovery)
- [ ] **Verify:** Mentions elevated RHR is normal post-exercise

**Expected Brief:**
```
Solid 52 TSS session done this morning. RHR elevated post-ride 
is normal. Focus on protein + carbs within 90 min and aim for 
8h sleep to consolidate gains.
```

**Expected Logs:**
```
AI BRIEF REQUEST DATA:
  Recovery: 63
  Sleep Delta: -1h
  HRV Delta: +2%
  RHR Delta: +3%
  TSB: +11
  TSS Range: 60-80
  Plan: none
  ✓ Completed Today:
    - 2 x 10: 52min, TSS: 52.0
  Today's Total TSS: 52.0
  No activities completed yet today
```

**Pass Criteria:**
- ✅ Brief mentions completed workout
- ✅ Provides recovery advice (not more training)
- ✅ Logs show "✓ Completed Today" with activity details
- ✅ Doesn't say "De-load with Z1 ride" after you already trained

---

## 🧪 **Test 3: Adaptive Zones Display**

**What to test:** Verify adaptive zones show correctly in Settings

- [ ] Go to Settings → Adaptive Zones
- [ ] **Verify:** Shows FTP value (e.g., 210W)
- [ ] **Verify:** Shows 7 power zones with values
- [ ] **Verify:** Shows 7 HR zones with values
- [ ] **Verify:** Shows data quality/confidence score

**Expected Logs:**
```
🎯 [Zones] Settings View Appeared
   FTP: 210W
   FTP Source: computed
   Power Zones: 7 zones
   Power Zone Values: [0, 115, 158, 189, 221, 252, 316]
   Max HR: 179bpm
   HR Source: computed
   HR Zones: 7 zones
   HR Zone Values: [0, 122, 148, 157, 168, 174, 179]
```

**Pass Criteria:**
- ✅ FTP displays (not just "211W" with no zones)
- ✅ All 7 power zones visible
- ✅ All 7 HR zones visible
- ✅ Logs confirm zones are populated

---

## 🧪 **Test 4: Data Window Verification (Pro vs Free)**

**What to test:** Verify correct data fetch periods based on subscription tier

- [ ] Check logs on app launch
- [ ] Note your subscription status (Pro or Free)
- [ ] Verify correct day window in logs

**If Pro User - Expected Logs:**
```
📊 [Activities] Fetch request: 120 days (capped to 120 for PRO tier)
📊 [FTP] Fetching activities for FTP computation (120 days, research-backed window)
✅ [FTP] Found 45 activities with power data
```

**If Free User - Expected Logs:**
```
📊 [Activities] Fetch request: 90 days (capped to 90 for FREE tier)
📊 [FTP] Fetching activities for FTP computation (90 days, research-backed window)
✅ [FTP] Found 30 activities with power data
```

**Pass Criteria:**
- ✅ Pro users: 120 days
- ✅ Free users: 90 days
- ✅ Logs explicitly state tier and window

---

## 🧪 **Test 5: Strava-Only User (Optional)**

**What to test:** Verify everything works with Strava instead of Intervals.icu

**Setup:**
- [ ] Disconnect Intervals.icu (temporarily)
- [ ] Ensure Strava is connected
- [ ] Do a Strava ride

**Verify:**
- [ ] Strain score includes Strava ride duration
- [ ] AI brief detects Strava activities
- [ ] Adaptive zones compute from Strava data
- [ ] Everything works identically to Intervals.icu

**Expected Logs:**
```
🔍 Found 1 unified activities for today (Intervals.icu or Strava)
📊 [Activities] Fetching from Strava (limit: 500)
✅ [Activities] Fetched 1 activities from Strava (filtered to 90 days)
```

**Pass Criteria:**
- ✅ Strava activities counted in strain score
- ✅ AI brief detects Strava workouts
- ✅ No errors or missing data

---

## 🧪 **Test 6: Tomorrow Morning (Before Workout)**

**What to test:** Verify AI brief prescribes workout when no activities completed yet

**Setup:**
- [ ] Open app first thing in morning (before any workout)
- [ ] Check daily brief

**Expected Brief:**
```
Recovery at 63%, HRV stable. Aim 65-70 TSS: Z2 endurance 
60 min. Fuel early and stay hydrated.
```

**Expected Logs:**
```
AI BRIEF REQUEST DATA:
  Recovery: 63
  Sleep Delta: +0h
  HRV Delta: +1%
  RHR Delta: 0%
  TSB: +5
  TSS Range: 60-80
  Plan: none
  No activities completed yet today
```

**Pass Criteria:**
- ✅ Brief prescribes workout (not recovery advice)
- ✅ Logs show "No activities completed yet today"
- ✅ Recommendation matches recovery state

---

## 🔍 **Key Log Patterns to Look For**

### **Strain Score Logs:**
```
🔄 Starting strain score calculation
🔍 Strain Score Inputs:
   Steps: 3451
   Active Calories: 245
   Cardio TRIMP: 45.2
   Cardio Duration: 52min
   Workout Types: [Cycling]
   Strength Duration: 0min
   
🔍 Found 1 unified activities for today (Intervals.icu or Strava)
   HealthKit Duration: 0min
   Intervals/Strava Duration: 52min
   Total Cardio Duration: 52min

🔍 Strain Score Result:
   Final Score: 6.8
   Band: Moderate
   Sub-scores: Cardio=5.2, Strength=0.0, Activity=1.6
```

### **AI Brief Logs:**
```
AI BRIEF REQUEST DATA:
  Recovery: 63
  Sleep Delta: -1h
  HRV Delta: +2%
  RHR Delta: +3%
  TSB: +11
  TSS Range: 60-80
  Plan: none
  ✓ Completed Today:
    - 2 x 10: 52min, TSS: 52.0
  Today's Total TSS: 52.0
  Expected Recommendation: AMBER zone training
```

### **Adaptive Zones Logs:**
```
📊 [Activities] Fetch request: 120 days (capped to 120 for PRO tier)
📊 [FTP] Fetching activities for FTP computation (120 days, research-backed window)
✅ [FTP] Found 45 activities with power data

========== COMPUTING ADAPTIVE ZONES FROM PERFORMANCE DATA ==========
Using modern sports science algorithms (CP model, power distribution, HR analysis)
Input: 45 activities (pre-filtered by subscription tier)

STAGE 1: Building Power-Duration Curve
  Activity 5: 2 x 10 - NP: 177W, Duration: 48min
    ✓ New best 20-min power: 177W

STAGE 2: Computing FTP Candidates
  Method 1 (60-min): 220W × 0.99 = 218W (weight: 1.5)
  Method 2 (20-min): 216W × 0.95 = 205W (weight: 0.9)
  Weighted FTP: 212W

✅ Adaptive FTP: 210W
Adaptive Power Zones: [0, 115, 158, 189, 221, 252, 316]
```

---

## ❌ **What to Report if Issues**

### **Issue 1: Strain Score Still Wrong**
**Report:**
- Current strain score value
- Actual ride duration vs displayed duration
- Logs showing duration calculation
- Screenshot of strain detail page

### **Issue 2: AI Brief Still Prescribing Work After Training**
**Report:**
- Full AI brief text
- Logs showing "AI BRIEF REQUEST DATA"
- Whether completed activities are detected
- Time of workout vs time of brief request

### **Issue 3: Zones Not Showing**
**Report:**
- Screenshot of Settings → Adaptive Zones
- Logs from Settings view appear
- FTP value and zone count from logs
- Subscription status (Pro/Free)

### **Issue 4: Strava Not Working**
**Report:**
- Logs showing unified activities fetch
- Whether Intervals.icu is connected
- Strava connection status
- Activity count from logs

---

## ✅ **Success Criteria Summary**

**All tests pass if:**

1. ✅ Strain score shows full ride duration (50+ mins, not 23 mins)
2. ✅ Strain score value is appropriate (6-8 for moderate ride, not 3.1)
3. ✅ AI brief acknowledges completed workouts
4. ✅ AI brief provides recovery advice after training (not more work)
5. ✅ AI brief understands elevated RHR post-exercise is normal
6. ✅ Adaptive zones display all 7 power and 7 HR zones
7. ✅ Data fetch respects Pro (120 days) vs Free (90 days) limits
8. ✅ Works identically with Intervals.icu OR Strava
9. ✅ Logs show detailed debugging information

---

## 📋 **Quick Test Order**

**Priority 1 (Your Reported Issues):**
1. Test 1 - Strain Score
2. Test 2 - AI Brief Post-Workout

**Priority 2 (Verify Related Changes):**
3. Test 3 - Adaptive Zones Display
4. Test 4 - Data Window Verification

**Priority 3 (Edge Cases):**
5. Test 5 - Strava-Only User
6. Test 6 - Tomorrow Morning Pre-Workout

---

**Start with Priority 1 tests and send me the logs!** 🎯
