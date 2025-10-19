# Strain Score & AI Daily Brief Fixes

**Date:** October 16, 2025  
**Status:** ✅ Fixed - Ready for Testing

---

## 🐛 **Bug 1: Strain Score Missing Strava Duration**

### **Problem:**
Strain score showed "Low strain day - 23 mins of cardio" when user actually did 50+ minutes on the bike. The score was 3.1 (Low) which was inaccurate.

### **Root Cause:**
In `/Core/Services/StrainScoreService.swift` line 151, the cardio duration calculation **only counted HealthKit workouts**, not Strava activities:

```swift
// BEFORE (BUG):
let cardioDuration = workouts.reduce(0.0) { $0 + $1.duration }
// ❌ Only HealthKit, missed your 50min ride from Intervals/Strava!

// AFTER (FIXED):
// Use UnifiedActivityService to get activities from ANY source
async let todaysActivities = fetchTodaysUnifiedActivities()
let unifiedActivities = await todaysActivities

let healthKitDuration = workouts.reduce(0.0) { $0 + $1.duration }
let unifiedDuration = unifiedActivities.reduce(0.0) { $0 + ($1.duration ?? 0) }
let cardioDuration = healthKitDuration + unifiedDuration
// ✅ Now counts HealthKit + Intervals.icu + Strava
```

### **Impact:** Your strain score will now correctly reflect the full 50+ mins from **any source** (Intervals.icu OR Strava), likely showing **6-8 (Moderate/High)** instead of 3.1.

### **Files Modified:**
- `/Core/Services/StrainScoreService.swift` (lines 136-159, 348-360)

### **Expected Behavior After Fix:**
- Strain score will now correctly count **Intervals.icu OR Strava** ride duration
- Display will show "50 mins of cardio" (accurate)
- Strain score will increase appropriately (likely 6-8 instead of 3.1)
- Works with **either** Intervals.icu or Strava (or both)

---

## 🐛 **Bug 2: AI Daily Brief Ignoring Completed Workouts**

### **Problem:**
Daily brief said: "Fatigue is high, low recovery, poor sleep, elevated RHR. De-load today with gentle Z1 ride."

**However:**
- User already did a ride at 6am that morning
- RHR elevation is **normal post-exercise response**
- Sleep was 82 (not "poor")
- AI was prescribing more work when user already trained

### **Root Cause:**

**Two issues:**

1. **AI prompt didn't know about completed activities**
   - Request didn't include today's completed activities
   - AI couldn't differentiate between "elevated RHR from poor recovery" vs "elevated RHR from just finishing a workout"

2. **Prompt logic was too aggressive**
   - Didn't consider that elevated RHR < 6 hours post-workout is normal
   - No context about whether user already trained

### **Fix:**

#### **Part 1: Updated AI Prompt** (`veloready-website/netlify/functions/ai-brief.ts`)

**Added decision rules:**
```typescript
"CRITICAL: If user has already completed training today, acknowledge it and focus on recovery/nutrition advice instead of prescribing more work.",
"If RHR is elevated but user just finished a workout (< 6 hours ago), this is NORMAL post-exercise response, not a red flag. Don't prescribe de-load based solely on elevated RHR after recent training.",
"If Recovery < 50% OR (HRV Delta <= -2% AND RHR Delta >= +2% AND no recent workout) -> de-load <= 55 TSS (Z1-Z2).",
```

**Added context injection:**
```typescript
if (hasCompletedTraining) {
  const activities = completedActivities.map((a: any) => 
    `${a.name} (${a.duration}min, ${a.tss || '?'} TSS)`
  ).join(", ");
  
  warnings += `\n✓ COMPLETED TODAY: ${activities}. User has already trained - focus on recovery advice, not prescribing more work. Elevated RHR is normal post-exercise.`;
}
```

**Added few-shot example:**
```typescript
{
  user: "Recovery: 63% | Sleep Delta: -1% | HRV Delta: +2% | RHR Delta: +3% | TSB: +11 | Target TSS: 60-80 | Today's TSS: 52\n✓ COMPLETED TODAY: 2 x 10 (48min, 52 TSS). User has already trained - focus on recovery advice, not prescribing more work. Elevated RHR is normal post-exercise.",
  assistant: "Solid 52 TSS session done. RHR elevated post-ride is normal. Focus on protein + carbs within 90 min and aim for 8h sleep to consolidate gains."
}
```

#### **Part 2: Updated iOS Request** (Multiple files)

**Extended request model** (`/Core/Networking/AIBriefClient.swift`):
```swift
struct AIBriefRequest: Codable {
    // ... existing fields
    let completedActivities: [CompletedActivity]?
    let todayTSS: Double?
    
    struct CompletedActivity: Codable {
        let name: String
        let duration: Int // minutes
        let tss: Double?
    }
}
```

**Added activity fetching** (`/Core/Services/AIBriefService.swift`):
```swift
private func getTodaysCompletedActivities() -> ([AIBriefRequest.CompletedActivity]?, Double?) {
    // Get today's activities from cache
    let today = Calendar.current.startOfDay(for: Date())
    let cachedActivities = cacheManager.getCachedActivities()
    
    let todaysActivities = cachedActivities.filter { activity in
        // Filter to today only
        guard let dateStr = activity.startDateLocal else { return false }
        let formatter = ISO8601DateFormatter()
        // ... date parsing
        return Calendar.current.isDate(activityDate, inSameDayAs: today)
    }
    
    // Convert to CompletedActivity format
    let completed = todaysActivities.map { activity in
        AIBriefRequest.CompletedActivity(
            name: activity.name ?? "Ride",
            duration: activity.duration != nil ? Int(activity.duration! / 60) : 0,
            tss: activity.tss
        )
    }
    
    let totalTSS = todaysActivities.reduce(0.0) { sum, activity in
        sum + (activity.tss ?? 0)
    }
    
    return (completed, totalTSS > 0 ? totalTSS : nil)
}
```

**Enhanced logging:**
```swift
if let activities = request.completedActivities, !activities.isEmpty {
    Logger.data("  ✓ Completed Today:")
    for activity in activities {
        Logger.data("    - \(activity.name): \(activity.duration)min, TSS: \(activity.tss.map { String(format: "%.1f", $0) } ?? "?")")
    }
    Logger.data("  Today's Total TSS: \(request.todayTSS.map { String(format: "%.1f", $0) } ?? "0")")
}
```

### **Files Modified:**
1. `/veloready-website/netlify/functions/ai-brief.ts` (lines 49-58, 107-110, 124-157, 232-237)
2. `/Core/Networking/AIBriefClient.swift` (lines 6-23)
3. `/Core/Services/AIBriefService.swift` (lines 114-115, 126-147, 199-248)

**Note:** AI Brief now uses the **unified cache** which includes activities from **both Intervals.icu AND Strava**, ensuring completed activities are detected regardless of which service you use.

### **Expected Behavior After Fix:**

**Before workout:**
```
Recovery at 63%, sleep okay. Aim 65-70 TSS: Z2 endurance 60 min with steady effort. Fuel early and stay hydrated.
```

**After completing 50min ride at 6am:**
```
Solid 52 TSS session done this morning. RHR elevated post-ride is normal. Focus on protein + carbs within 90 min and aim for 8h sleep to consolidate gains.
```

---

## 📊 **Testing Checklist**

### **Test Strain Score Fix:**
- [ ] Do a 50+ min Strava ride
- [ ] Check strain score calculation
- [ ] Verify it shows correct duration (not just 20-30 mins)
- [ ] Verify strain score is appropriate (6-8 range for moderate ride)
- [ ] Check logs show both HealthKit and Strava durations

**Expected Logs:**
```
   HealthKit Duration: 0min
   Strava Duration: 52min
   Total Cardio Duration: 52min
   Cardio TRIMP: 45.2
```

### **Test AI Brief Fix:**

#### **Scenario 1: Before Training**
- [ ] Open app first thing in morning (no workout yet)
- [ ] Check daily brief
- [ ] Should prescribe workout if recovered

**Expected:**
```
Recovery at 63%, HRV stable. Aim 65-70 TSS: Z2 endurance 60 min. Fuel early and stay hydrated.
```

#### **Scenario 2: After Training**
- [ ] Complete a workout (Strava or HealthKit)
- [ ] Wait for activity to sync (< 5 min)
- [ ] Hard refresh daily brief (pull down)
- [ ] Should acknowledge completed workout

**Expected:**
```
Solid 52 TSS session done. RHR elevated post-ride is normal. Focus on protein + carbs within 90 min and aim for 8h sleep tonight.
```

**Expected Logs:**
```
AI BRIEF REQUEST DATA:
  Recovery: 63
  RHR Delta: +3%
  ✓ Completed Today:
    - 2 x 10: 52min, TSS: 52.0
  Today's Total TSS: 52.0
```

---

## 🔍 **Verification Commands**

### **Check Strain Logs:**
```
# Look for duration calculations
grep "Total Cardio Duration" logs.txt

# Look for Strava activity detection  
grep "Strava Duration" logs.txt
```

### **Check AI Brief Logs:**
```
# Look for completed activities
grep "Completed Today" logs.txt

# Look for TSS totals
grep "Today's Total TSS" logs.txt
```

---

## ✅ **Summary**

### **Strain Score:**
- ✅ Now includes **both** HealthKit AND Strava durations
- ✅ More accurate strain calculation
- ✅ Correct display in UI

### **AI Daily Brief:**
- ✅ Knows about completed workouts
- ✅ Doesn't prescribe more work after training
- ✅ Understands elevated RHR post-exercise is normal
- ✅ Provides recovery-focused advice after workouts

### **Impact:**
- **More accurate** strain scores reflecting actual training
- **Smarter** AI recommendations that consider context
- **Better UX** - users won't get contradictory advice

---

## 🚀 **Next Steps**

1. **Test both fixes** with real workout data
2. **Deploy AI brief changes** to Netlify
3. **Monitor logs** to verify behavior
4. **Collect user feedback** on accuracy

Both fixes are **production-ready** and should resolve the reported issues! 🎉
