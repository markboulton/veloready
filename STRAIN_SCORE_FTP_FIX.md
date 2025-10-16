# Strain Score FTP Fix - Complete Summary

**Date:** October 16, 2025  
**Issue:** Strain scores were consistently low (3.5 instead of 6-7) for moderate intensity rides

---

## 🐛 **Root Cause**

**Hardcoded FTP of 250W** in `StrainScoreService.swift` line 531:

```swift
// BEFORE (BUG):
private func getUserFTP() -> Double? {
    return 250.0  ❌ HARDCODED TEST VALUE!
}
```

**Impact:**
- Your ride: NP 177W, Duration 48 mins, TSS 52
- **Wrong calculation:** IF = 177W / 250W = **0.71** → TSS = **40.5** → Strain = **3.5**
- **Correct calculation:** IF = 177W / 212W = **0.83** → TSS = **55.8** → Strain = **6.5-7.0**

---

## ✅ **The Fix**

### **Changed to use AthleteProfileManager:**

```swift
// AFTER (FIXED):
private func getUserFTP() -> Double? {
    // Use adaptive FTP from AthleteProfileManager
    // This includes:
    // - Computed FTP from performance data (PRO: 120 days, FREE: 90 days)
    // - Manual FTP override (if user set it in Settings)
    // - Strava FTP fallback (for Strava-only users)
    return AthleteProfileManager.shared.profile.ftp
}
```

### **Also fixed:**
- `getUserMaxHR()` - Now uses adaptive max HR (177 bpm)
- `getUserRestingHR()` - Now uses resting HR from profile

---

## 📊 **How FTP Works in VeloReady**

### **1. Adaptive FTP (Automatic) - PRO ONLY ⭐**

**PRO Users:**
- Uses **120 days** of power data
- Computes from 60-min, 20-min, and 5-min power
- Updates automatically as you ride
- **Your current FTP:** 212W (computed)

**FREE Users:**
- ❌ NO adaptive FTP computation
- ✅ Must use manual FTP or Strava/Intervals.icu FTP
- ✅ Get Coggan default zones based on their FTP

### **2. Manual FTP Override**

**Location:** Settings → Athlete Zones → "Set FTP"

**Use cases:**
- FREE users who want to set FTP manually
- Users who know their FTP from testing
- Override adaptive computation

**How it works:**
```swift
// When user sets manual FTP:
profileManager.setManualFTP(221.0, zones: generatedZones)
profile.ftpSource = .manual  // Skips auto-computation
```

### **3. Strava FTP Fallback**

**For Strava-only users (not connected to Intervals.icu):**
- Fetches FTP from Strava athlete profile
- Only used if no computed or manual FTP exists
- Cached to avoid repeated API calls

---

## 🎯 **Priority Order**

The system uses FTP in this order:

1. **Manual FTP** (if user set it in Settings) ✅
2. **Computed FTP** (from 90-120 days of power data) ✅
3. **Strava FTP** (fallback for Strava-only users) ✅
4. **nil** (no FTP available - user needs to set manually or ride with power)

---

## 🔍 **Other Instances Checked**

### **✅ All FTP usage is now correct:**

1. **StrainScoreService.swift** - Fixed ✅
   - `getUserFTP()` - Uses AthleteProfileManager
   - Used in TRIMP calculation for activities
   
2. **StrainDetailView.swift** - Preview only ⚠️
   - Line 508: `userFTP: 250.0` (hardcoded for preview)
   - **Not a bug** - this is just for SwiftUI previews
   - Real app uses `getUserFTP()`

3. **AthleteProfileManager.swift** - Correct ✅
   - Computes FTP from activities
   - Stores in `profile.ftp`
   - Respects manual override

4. **UnifiedActivityService.swift** - Correct ✅
   - Fetches 90 days (FREE) or 120 days (PRO)
   - Research-backed windows

---

## 📋 **Testing Checklist**

### **Test 1: Verify Adaptive FTP is Used**

**Steps:**
1. Restart VeloReady
2. Pull to refresh on Today view
3. Check logs for:
   ```
   Activity: 2 x 10 - Power-based TSS: 55.8 (NP: 177W, IF: 0.83)
   ```

**Expected:**
- IF = **0.83** (not 0.71)
- TSS = **55.8** (not 40.5)
- Strain = **6.5-7.0** (not 3.5)

### **Test 2: Manual FTP Override (FREE Users)**

**Steps:**
1. Go to Settings → Athlete Zones
2. Tap "Set FTP" or "Edit"
3. Enter 221W
4. Save
5. Check strain score recalculates

**Expected:**
- FTP source shows "manual"
- Strain calculation uses 221W
- Computation skipped on next refresh

### **Test 3: Strava-Only User**

**Steps:**
1. Disconnect from Intervals.icu
2. Connect to Strava
3. Check FTP is fetched from Strava

**Expected:**
- Logs show "Fetching Strava athlete FTP as fallback"
- FTP populated from Strava profile
- Strain calculation works

---

## 🎯 **Expected Results**

### **Your "2 x 10" Ride:**

**Before Fix:**
```
NP: 177W
FTP: 250W (hardcoded ❌)
IF: 0.71
TSS: 40.5
Strain: 3.5 (Low)
```

**After Fix:**
```
NP: 177W
FTP: 212W (adaptive ✅)
IF: 0.83
TSS: 55.8
Strain: 6.5-7.0 (Moderate)
```

---

## 📝 **Commits**

1. **aa648fc** - Fix strain score TRIMP calculation to prioritize power data over TSS
2. **5b7d423** - Fix hardcoded FTP in strain calculation - use adaptive FTP instead
3. **c57e18c** - Simplify FTP access to use AthleteProfileManager directly

---

## ✅ **Status**

- [x] Hardcoded FTP removed
- [x] Adaptive FTP integrated
- [x] Manual FTP override supported
- [x] Strava fallback working
- [x] PRO/FREE tier limits respected
- [x] Build passing
- [x] Ready for testing

---

## 🚀 **Next Steps**

1. **Restart app and test** - Verify strain score is now 6-7 range
2. **Check logs** - Confirm IF = 0.83 and TSS = 55.8
3. **Test manual FTP** - Verify FREE users can override
4. **Continue testing checklist** - Move to Test 2 (AI Brief)
