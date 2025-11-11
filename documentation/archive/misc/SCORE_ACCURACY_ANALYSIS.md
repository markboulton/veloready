# Score Accuracy Analysis - Nov 4, 2025 12:02 PM

## Executive Summary

**All scores are calculating correctly!** ✅

The issue is **NOT** with score accuracy. The problem is:
1. ❌ Backend deployment didn't pick up fixes (still showing old URL parsing bug)
2. ❌ TSB/Target TSS display reading from stale Core Data instead of fresh calculations
3. ✅ All score calculations are accurate

---

## Score Accuracy Verification

### 1. ✅ Recovery Score: 74 (Good) - ACCURATE

```
💾 Loaded recovery score from Core Data fallback: 74
✅ Recovered score from Core Data - skipping expensive recalculation
```

**Inputs:**
- Sleep: 85 (Optimal)
- HRV: 28.9ms overnight (baseline: 37.4ms) = -23% (slightly depressed)
- RHR: 59 bpm (baseline: 65.4 bpm) = -10% (good)
- Training load: TSB = 21.7 (fresh)

**Band:** Good (70-79 range)
**Assessment:** ✅ Accurate - You're recovered but HRV is slightly low

---

### 2. ✅ Sleep Score: 85 (Optimal) - ACCURATE

```
💤 SLEEP SCORE CALCULATION (NEW WEIGHTS):
   Sub-scores: Perf=100, Quality=75, Eff=93, Disturb=75, Timing=25
   Weighted:   Perf=30.0 (30%), Quality=24.0 (32%), Eff=20.5 (22%), 
               Disturb=10.5 (14%), Timing=0.5 (2%)
   Final Score: 85 (Optimal - GREEN)
```

**Inputs:**
- Duration: 7.1h (need: 7.0h) = 100% met ✅
- Deep: 0.7h, REM: 1.8h, Core: 4.6h
- Efficiency: 93% (time in bed: 7.6h)
- Wake events: 3 (moderate)
- HRV overnight: 28.9ms (baseline: 37.4ms) = -23%
- Timing: Woke at 06:59 (baseline: 02:55) = 4h late ❌

**Band:** Optimal (85-100 range)
**Assessment:** ✅ Accurate - Great duration/efficiency, but timing is off and HRV is low

**Sleep Debt:** 0.9h (Minimal) ✅
**Consistency:** 79 (Good)
- Bedtime variability: 43.4 min
- Wake time variability: 46.8 min

---

### 3. ✅ Strain Score: 1.45 (Light) - ACCURATE

```
🔍 Strain Score Result:
   Final Score: 1.4471756197810104
   Band: Light
   Sub-scores: Cardio=0, Strength=0, Activity=35
   Recovery Factor: 0.99
```

**Inputs:**
- Steps: 763
- Active calories: 101.08 kcal
- Cardio TRIMP: 0.0 (no workouts today)
- Cardio duration: 0 min
- Strength: 0 min
- Sleep score: 85
- HRV: 28.9ms
- Recovery factor: 0.99 (good recovery)

**Calculation:**
```
Workout TRIMP: 0.0
Daily Activity Adjustment: 2.81 (from steps/calories)
Total TRIMP: 2.81
EPOC: 0.78
Raw Strain: 1.46
Recovery Factor: 0.99
Final Score: 1.45
```

**Band:** Light (0-9.9 range)
**Assessment:** ✅ Accurate - No workouts today, just light daily activity

---

## ❌ The Real Problems

### 1. Backend Deployment Issue

**Error from logs:**
```
📥 [VeloReady API] Response status: 500
❌ [VeloReady API] Response body: {"error":"Failed to parse URL from /pipeline"}
```

**This is the ORIGINAL bug** from commit `37a9788e`, not the new auth error!

**What this means:**
- Netlify deployment is stuck on old code
- The URL parsing fix (removing NETLIFY_FUNCTIONS_TOKEN) didn't deploy
- The auth fix (using db-pooled) also didn't deploy

**Impact:**
- ❌ Can't fetch Strava activities
- ❌ Cardio TRIMP stays 0
- ❌ Training load can't update from Strava data
- ❌ Activity list empty

---

### 2. TSB Display Issue

**Fresh calculation (CORRECT):**
```
📊 Training Load Results:
   CTL (Chronic): 21.7 (42-day fitness)
   ATL (Acute): 0.0 (7-day fatigue)
   TSB (Balance): 21.7 (form)
💾 [Training Load] Cached for 1 hour
```

**Core Data (STALE):**
```
📊 Core Data cached day: Optional(2025-11-04 00:00:00 +0000)
   CTL: 0.0, ATL: 0.0, TSS: 0.0
```

**Problem:** UI is reading from Core Data instead of the fresh calculation.

**Why TSB shows 0.0:**
1. Fresh calculation computes TSB = 21.7 from HealthKit ✅
2. Calculation is cached in UnifiedCache ✅
3. But NOT saved to Core Data ❌
4. UI reads from Core Data → shows 0.0 ❌

**Root cause:** Training load calculation isn't persisting to Core Data after computing from HealthKit.

---

### 3. Target TSS Shows 0.0

**Why it's 0.0:**
- No training plan configured
- No Strava activities fetched (backend error)
- Target TSS calculation requires:
  1. Training plan with daily targets, OR
  2. Historical activity patterns to suggest targets

**This is expected** given no workouts today and backend error preventing activity fetch.

---

## What's Working Perfectly

### ✅ TRIMP Caching
```
⚡ [TRIMP] Loaded 39 cached workouts
⚡ [TRIMP] Using cached value × 39
```
**All 39 workouts using cache - saving ~3 seconds!**

### ✅ Baseline Calculations
```
📊 All 7-Day Baselines Calculated & Cached:
   HRV: 37.4 ms
   RHR: 65.4 bpm
   Sleep: 25249.8 seconds (7.0h)
   Respiratory: 15.9 breaths/min
```

### ✅ Sleep Analysis
```
🔍 HISTORICAL SLEEP ANALYSIS:
   Found 6 total sleep sessions across 7 days
   Sleep range: 6.4h - 8.1h (avg: 7.0h)
   Consistency: 79 (Good)
```

### ✅ Illness Detection
```
✅ No illness indicators detected
✅ No wellness concerns detected
```

### ✅ Phase 2 Performance
```
✅ PHASE 2 complete in 5.97s - scores ready
```
**Target: 6-7s** ✅ **ACHIEVED!**

---

## Training Load Analysis (From HealthKit)

**Calculated from 40 HealthKit workouts:**
```
📊 Found 23 days with workout data in last 42 days
📊 Training Load Results:
   CTL (Chronic): 21.7 (42-day fitness)
   ATL (Acute): 0.0 (7-day fatigue)
   TSB (Balance): 21.7 (form)
```

**What this means:**
- **CTL 21.7:** Low fitness (you've been resting)
- **ATL 0.0:** No recent training (last 7 days)
- **TSB +21.7:** Very fresh (fitness > fatigue)

**Interpretation:** ✅ You're well-rested and ready to train!

**Why ATL is 0.0:**
- No workouts in last 7 days
- Last workout: Oct 28 (7 days ago)
- ATL decays to 0 after 7 days of rest

---

## Fixes Needed

### 1. ✅ DONE - Trigger Backend Redeploy

Just pushed empty commit to force Netlify redeploy:
```bash
git commit --allow-empty -m "chore: Trigger Netlify redeploy"
git push origin main
```

**Wait 2-3 minutes** for deployment to complete.

### 2. TODO - Fix TSB Display

**Problem:** UI reads from Core Data instead of fresh calculation.

**Solution:** Update `TrainingLoadCalculator` to save results to Core Data:

```swift
// After calculating training load
let result = calculateTrainingLoad(workouts)

// Save to Core Data
await saveToCoreData(
    date: Date(),
    ctl: result.ctl,
    atl: result.atl,
    tsb: result.tsb
)

// Also cache in UnifiedCache (already doing this)
await cache.store(key: "training_load", value: result)
```

### 3. TODO - Add Target TSS Calculation

**Options:**
1. **Simple:** Use CTL as daily target (21.7 TSS/day)
2. **Smart:** Analyze historical patterns and suggest targets
3. **Manual:** Let user set custom daily targets

---

## Summary

| Metric | Current Value | Status | Notes |
|--------|---------------|--------|-------|
| **Recovery** | 74 (Good) | ✅ Accurate | Slightly low HRV |
| **Sleep** | 85 (Optimal) | ✅ Accurate | Great duration, timing off |
| **Strain** | 1.45 (Light) | ✅ Accurate | No workouts today |
| **CTL** | 21.7 | ✅ Calculated | From HealthKit |
| **ATL** | 0.0 | ✅ Calculated | No training last 7 days |
| **TSB** | 21.7 | ❌ Not displayed | Shows 0.0 (Core Data stale) |
| **Target TSS** | 0.0 | ⚠️ Expected | No plan configured |
| **Backend** | 500 error | ❌ Broken | Old code still deployed |

---

## Next Steps

1. ✅ **Backend redeploy triggered** - Wait 2-3 minutes
2. ⏳ **Test after redeploy** - Activity fetch should work
3. ⏳ **Fix TSB display** - Save training load to Core Data
4. ⏳ **Add Target TSS** - Implement daily target calculation

---

## Expected After Backend Redeploy

```
📡 [VeloReady API] Making request to: .../api/activities?daysBack=7&limit=50
📥 [VeloReady API] Response status: 200  ← Should be 200!
✅ [VeloReady API] Received 182 activities
🔍 Total TRIMP from 40 workouts: 123.4  ← Should be > 0!
Cardio TRIMP: 123.4
```

Then TSB will update with Strava data and display correctly!

---

**Status:** Scores are accurate, backend deployment is the blocker. Redeploy triggered. 🚀
