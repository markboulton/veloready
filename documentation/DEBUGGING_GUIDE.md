# Debugging Guide - Strava Activity Issues

## Date: October 15, 2025

## I've Added Comprehensive Logging

The app now logs **everything** at every critical decision point. This will help us identify exactly where things are failing.

---

## How to Debug

### Step 1: Run App in Xcode
```bash
# Open in Xcode
open /Users/markboulton/Dev/VeloReady/VeloReady.xcodeproj

# Run on Simulator or Device
# Cmd+R
```

### Step 2: Open Console
- Xcode → View → Debug Area → Show Debug Area (Cmd+Shift+Y)
- Make sure "Console" tab is selected

### Step 3: View a Strava Activity
- Navigate to any Strava ride (e.g., "Shortened Mechanical")
- Tap to open detail view

### Step 4: Check Logs
Look for these log sections marked with emojis:

---

## Log Markers to Look For

### 🏁 RideDetailSheet Rendering
```
🏁 ========== RIDE DETAIL SHEET RENDERING ==========
🏁 Original Activity ID: strava_12345
🏁 Original Activity TSS: nil
🏁 Original Activity IF: nil
🏁 Enriched Activity: NIL or EXISTS
🏁 Enriched Activity TSS: 85.0 (if exists)
🏁 Profile FTP: 250.0
🏁 Profile Power Zones: 8 zones
```

**What to check:**
- Is "Enriched Activity" NIL or EXISTS?
- If EXISTS, does it have TSS/IF values?
- Does Profile have FTP and zones?

---

### 🟠 Strava Activity Loading
```
🟠 ========== LOADING STRAVA ACTIVITY DATA ==========
🟠 Strava Activity ID: 12345
🟠 Fetching streams from Strava API...
🟠 Received 5 stream types from Strava
```

**What to check:**
- Did streams fetch successfully?
- How many stream types received?

---

### 🟠 TSS Calculation
```
🟠 ========== TSS CALCULATION START ==========
🟠 Activity Average Power: 180.0
🟠 Activity Normalized Power: nil
🟠 Profile FTP: 250.0

🟠 ✅ Estimated NP from average power: 189W (avg power: 180W)
🟠 ✅ Using profile FTP: 250W

🟠 Checking TSS calculation requirements:
🟠   - NP available: true
🟠   - FTP available: true
🟠   - NP > 0: true

🟠 Calculated TSS: 75 (NP: 189W, IF: 0.76, FTP: 250W)
```

**What to check:**
- ✅ = Success, ❌ = Failure
- Does activity have average power?
- Is FTP available?
- Did TSS calculation succeed?

---

### 🟠 Zone Availability
```
🟠 ========== ENSURING ZONES AVAILABLE ==========
🟠 Current Profile State:
🟠   - FTP: 250.0
🟠   - Power Zones: 8 zones
🟠   - Max HR: 185.0
🟠   - HR Zones: 8 zones
```

**What to check:**
- Does profile have FTP before enrichment?
- Are power/HR zones generated?
- If missing, did Strava FTP fetch work?

---

### ⚡️ Power Zone Computation
```
⚡️ ========== COMPUTING POWER ZONE TIMES FROM STREAM DATA ==========
⚡️ Current adaptive power zones: [0, 142, 178, 213, 249, 284, 391, 999]
⚡️ Total samples: 3600, Power samples: 3400 (94%)
⚡️ Power Range: 50-400 W, Avg: 180 W

⚡️ ========== ZONE TIME DISTRIBUTION ==========
⚡️ Zone 1 (Active Recovery): 5:00 (8.3%)
⚡️ Zone 2 (Endurance): 45:00 (75.0%)
⚡️ Zone 3 (Tempo): 10:00 (16.7%)
```

**What to check:**
- ❌ "No power zones available" = zones missing
- ❌ "No power samples available" = no power data in ride
- ✅ Zone distribution shown = working!

---

### 🟠 Enriched Activity Created
```
🟠 ========== ENRICHED ACTIVITY CREATED ==========
🟠 Enriched TSS: 75.0
🟠 Enriched IF: 0.76
🟠 Enriched Power Zones: 7 zones
🟠 Enriched HR Zones: 7 zones
🟠 ✅ enrichedActivity SET on viewModel
```

**What to check:**
- This should appear if TSS calculation succeeded
- Confirms enriched activity has data
- Confirms it was set on viewModel

---

## Common Failure Patterns

### Pattern 1: No Power Data
```
🟠 ❌ No power data available (avg or normalized)
🟠 ❌ ========== TSS CALCULATION FAILED ==========
```
**Cause:** Activity has no power meter data  
**Expected:** This is normal for some rides  
**Fix:** None needed - app should show "N/A"

### Pattern 2: No FTP
```
🟠 No FTP in profile, fetching from Strava...
🟠 ❌ Strava athlete has no FTP set
🟠 ❌ Cannot generate power zones - no FTP available
```
**Cause:** Neither computed FTP nor Strava FTP available  
**Fix:** User needs to set FTP in Strava or Settings

### Pattern 3: Enriched Activity Not Set
```
🏁 Enriched Activity: NIL
```
**Cause:** loadActivityData() never completed or failed  
**Look For:** Error messages in Strava loading section  
**Fix:** Check why stream fetch failed

### Pattern 4: Zones Not Generated
```
⚡️ ❌ No power zones available from profile
```
**Cause:** ensureZonesAvailable() didn't run or failed  
**Look For:** ensureZonesAvailable logs earlier  
**Fix:** Check why zone generation failed

---

## What to Share With Me

When you see issues, share these specific log sections:

1. **🏁 RideDetailSheet Rendering** (shows final state)
2. **🟠 TSS Calculation** (shows if/why it failed)
3. **🟠 Zone Availability** (shows if zones exist)
4. **⚡️ Power Zone Computation** (shows if zones calculated)

Copy the logs from console and paste them - I'll be able to pinpoint the exact problem.

---

## Expected Log Flow (Working)

```
🏁 ========== RIDE DETAIL SHEET RENDERING ==========
🏁 Enriched Activity: NIL  ← First render, not loaded yet
🏁 Profile FTP: 250.0
🏁 Profile Power Zones: 8 zones

🏁 RideDetailSheet: .task triggered - loading activity data
🟠 ========== LOADING STRAVA ACTIVITY DATA ==========

🟠 ========== ENSURING ZONES AVAILABLE ==========
🟠 ✅ FTP already exists: 250W
🟠 ✅ Power zones already exist: 8 zones
🟠 ✅ HR zones already exist: 8 zones

🟠 ========== TSS CALCULATION START ==========
🟠 ✅ Estimated NP from average power: 189W
🟠 ✅ Using profile FTP: 250W
🟠 Calculated TSS: 75

🟠 ========== ENRICHED ACTIVITY CREATED ==========
🟠 Enriched TSS: 75.0
🟠 Enriched IF: 0.76
🟠 Enriched Power Zones: 7 zones
🟠 ✅ enrichedActivity SET on viewModel

🏁 ========== RIDE DETAIL SHEET RENDERING ==========
🏁 Enriched Activity: EXISTS  ← Second render after loading
🏁 Enriched Activity TSS: 75.0
🏁 Enriched Activity IF: 0.76
```

**This is what success looks like!**

---

## Quick Checklist

Before sharing logs, check:
- [ ] Viewing a Strava activity (ID starts with "strava_")
- [ ] Console visible in Xcode
- [ ] Logs show 🏁 and 🟠 markers
- [ ] Can see TSS CALCULATION START section
- [ ] Can see ENRICHED ACTIVITY section (or failure)

---

## My Hypothesis

Based on your report:
1. ✅ HR chart showing = HR zones work
2. ❌ No TSS = Calculation failing or not running
3. ❌ No Intensity = Same as TSS
4. ❌ No power zones = Power zones missing or not calculated

**Most likely causes:**
- Activities don't have power data (no power meter)
- Strava athlete has no FTP set
- enrichedActivity not being used by UI (but we fixed this!)

**Logs will tell us which one!**

---

## Status: READY TO DEBUG

Build compiles ✅  
Logging complete ✅  
Ready for testing ✅  

Run the app and share the logs - we'll fix this! 🔧
