# Missing Sleep Data Fix - Complete ✅

## Problem
When user doesn't wear Apple Watch overnight:
- Sleep score showed cached value from yesterday (e.g., 90 - green ring)
- AI brief received `null` deltas but didn't acknowledge missing data
- User had no indication that data was stale

## Root Causes

### 1. **Cache Not Cleared**
`SleepScoreService` loaded cached score from yesterday on app launch, even when no new sleep data was available.

### 2. **Backend Didn't Handle Null Values**
Backend AI function treated `null` as `0`, making it indistinguishable from "perfect" data.

---

## Changes Made

### **iOS App**

#### **1. SleepScoreService.swift**
Added cache clearing when no sleep data is available:

```swift
// Use real data
let realScore = await calculateRealSleepScore()
currentSleepScore = realScore

// Save to persistent cache for instant loading next time
if let score = currentSleepScore {
    saveSleepScoreToCache(score)
} else {
    // ✅ Clear cache if no sleep data available (user didn't wear watch)
    clearSleepScoreCache()
    print("🗑️ Cleared sleep score cache - no data available")
}
```

Added `clearSleepScoreCache()` function:
```swift
/// Clear sleep score cache
private func clearSleepScoreCache() {
    userDefaults.removeObject(forKey: cachedSleepScoreKey)
    userDefaults.removeObject(forKey: cachedSleepScoreDateKey)
}
```

**Impact:** When no sleep data is detected, the cache is cleared and `currentSleepScore` becomes `nil`.

#### **2. AIBriefClient.swift**
Made health deltas optional:
```swift
struct AIBriefRequest: Codable {
    let recovery: Int
    let sleepDelta: Double?    // ✅ Optional
    let hrvDelta: Double?      // ✅ Optional
    let rhrDelta: Double?      // ✅ Optional
    let tsb: Double
    let tssLow: Int
    let tssHigh: Int
    let plan: String?
}
```

#### **3. AIBriefService.swift**
Return `nil` instead of `0.0` when data is missing:
```swift
private func calculateSleepDelta(recovery: RecoveryScore) -> Double? {
    guard let sleep = recovery.inputs.sleepDuration,
          let baseline = recovery.inputs.sleepBaseline,
          baseline > 0 else {
        return nil  // ✅ Clear signal that data is missing
    }
    return (sleep - baseline) / 3600.0
}
```

#### **4. CompactRingView.swift**
Support optional scores and show "?" for missing data:
```swift
struct CompactRingView: View {
    let score: Int? // ✅ Optional
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: ringWidth)
                
                if let score = score {
                    // Normal colored ring
                    Circle().trim(from: 0, to: progressValue)
                        .stroke(colorForBand(band), ...)
                    Text("\(score)")
                        .foregroundColor(colorForBand(band))
                } else {
                    // ✅ Missing data indicator
                    Text("?")
                        .foregroundColor(Color(.systemGray3))
                }
            }
            Text(title)
        }
    }
}
```

#### **5. TodayView.swift**
Check for missing sleep data and pass `nil` to ring view:
```swift
if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
    CompactRingView(
        score: nil,           // ✅ Shows "?"
        title: "No Data",
        band: SleepScore.SleepBand.poor,
        animationDelay: 0.1
    ) { }
}
```

---

### **Backend (veloready-website)**

#### **netlify/functions/ai-brief.ts**

**1. Handle null values in buildUserContent():**
```typescript
function buildUserContent(payload: any) {
  const { recovery, sleepDelta, hrvDelta, rhrDelta, tsb, tssLow, tssHigh, plan } = payload ?? {};
  
  // ✅ Check for missing data
  const hasSleepData = sleepDelta !== null && sleepDelta !== undefined;
  const hasHRVData = hrvDelta !== null && hrvDelta !== undefined;
  const hasRHRData = rhrDelta !== null && rhrDelta !== undefined;
  
  // ✅ Build metrics line with "N/A" for missing data
  const metricsLine = [
    `Recovery: ${recovery}%`,
    hasSleepData ? `Sleep Delta: ${Math.round(sleepDelta * 100)}%` : `Sleep Delta: N/A`,
    hasHRVData ? `HRV Delta: ${Math.round(hrvDelta * 100)}%` : `HRV Delta: N/A`,
    hasRHRData ? `RHR Delta: ${Math.round(rhrDelta * 100)}%` : `RHR Delta: N/A`,
    `TSB: ${tsb}`,
    `Target TSS: ${tssLow}-${tssHigh}`,
    plan ? `Plan: ${plan}` : null
  ].filter(Boolean).join(" | ");
  
  // ✅ Add warning if critical data is missing
  let warning = "";
  if (!hasSleepData) {
    warning = "\n⚠️ Sleep data unavailable (user did not wear watch overnight). Provide recommendations based on recovery score and other available metrics. Suggest wearing watch for better insights.";
  }
  
  return `${CONTEXT_PREFIX}\n${DECISION_RULES}\n${metricsLine}${warning}`;
}
```

**2. Added few-shot example for missing data:**
```typescript
{
  user: "Recovery: 57% | Sleep Delta: N/A | HRV Delta: N/A | RHR Delta: N/A | TSB: +5 | Target TSS: 60-80 | Plan: none\n⚠️ Sleep data unavailable (user did not wear watch overnight). Provide recommendations based on recovery score and other available metrics. Suggest wearing watch for better insights.",
  assistant: "Recovery at 57% but no sleep data from last night. Aim 65-70 TSS: Z2 endurance 60-75 min. Wear your watch tonight for better insights tomorrow."
}
```

---

## Expected Behavior

### **With Sleep Data:**
- Sleep ring shows colored score (e.g., 90 - green)
- AI brief mentions sleep quality
- All deltas calculated normally

### **Without Sleep Data (User Didn't Wear Watch):**
- Sleep ring shows grey "?" with "No Data" label
- AI brief says: "Recovery at 57% but no sleep data from last night. Aim 65-70 TSS: Z2 endurance 60-75 min. Wear your watch tonight for better insights tomorrow."
- Recovery score still calculated (using other available metrics)

---

## Testing

### **Test Case 1: Simulate Missing Sleep Data**
1. Delete sleep score cache: Settings → Debug → Clear Caches
2. Force sleep service to return nil (or don't wear watch overnight)
3. Open app
4. **Expected:**
   - Sleep ring shows grey "?"
   - Title shows "No Data"
   - AI brief acknowledges missing data

### **Test Case 2: Normal Sleep Data**
1. Wear watch overnight
2. Open app next morning
3. **Expected:**
   - Sleep ring shows colored score
   - AI brief mentions sleep quality

---

## Deployment

### **iOS App:**
- Changes committed to VeloReady repo
- Build successful ✅
- Ready to test

### **Backend:**
- Changes committed to veloready-website repo
- Pushed to GitHub ✅
- Netlify auto-deployment triggered ✅
- Live at: https://veloready.app/ai-brief

---

## Files Modified

### **iOS:**
- `VeloReady/Core/Services/SleepScoreService.swift`
- `VeloReady/Core/Networking/AIBriefClient.swift`
- `VeloReady/Core/Services/AIBriefService.swift`
- `VeloReady/Features/Today/Views/Components/CompactRingView.swift`
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

### **Backend:**
- `veloready-website/netlify/functions/ai-brief.ts`

---

**Status:** ✅ Complete and deployed
**Date:** Oct 12, 2025
**Next:** Test with real missing sleep data scenario
