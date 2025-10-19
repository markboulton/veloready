# Missing Sleep Data Handling - Implementation Complete ✅

## Summary

Implemented proper handling for missing sleep data (when user doesn't wear Apple Watch overnight). The app now distinguishes between "no data" and "poor sleep" by using optional values and showing a grey "?" indicator instead of a misleading score.

---

## Changes Made

### **1. AI Brief Request Model** (`AIBriefClient.swift`)

**Changed:** Made health deltas optional to support missing data
```swift
struct AIBriefRequest: Codable {
    let recovery: Int
    let sleepDelta: Double?    // ✅ Now optional
    let hrvDelta: Double?      // ✅ Now optional
    let rhrDelta: Double?      // ✅ Now optional
    let tsb: Double
    let tssLow: Int
    let tssHigh: Int
    let plan: String?
}
```

**Impact:** Backend AI can now detect when data is missing and adjust recommendations accordingly.

---

### **2. AI Brief Service** (`AIBriefService.swift`)

**Changed:** Delta calculation functions return `nil` instead of `0.0` when data is missing

```swift
// Before: Returned 0.0 when no data
private func calculateSleepDelta(recovery: RecoveryScore) -> Double {
    guard let sleep = recovery.inputs.sleepDuration,
          let baseline = recovery.inputs.sleepBaseline,
          baseline > 0 else {
        return 0.0  // ❌ Misleading - AI thinks sleep was perfect
    }
    return (sleep - baseline) / 3600.0
}

// After: Returns nil when no data
private func calculateSleepDelta(recovery: RecoveryScore) -> Double? {
    guard let sleep = recovery.inputs.sleepDuration,
          let baseline = recovery.inputs.sleepBaseline,
          baseline > 0 else {
        return nil  // ✅ Clear signal that data is missing
    }
    return (sleep - baseline) / 3600.0
}
```

**Also updated:**
- `calculateHRVDelta()` → returns `Double?`
- `calculateRHRDelta()` → returns `Double?`

**Debug logging updated:**
```swift
print("📊   Sleep Delta: \(request.sleepDelta.map { String(format: "%.1f", $0) + "h" } ?? "nil")")
print("📊   HRV Delta: \(request.hrvDelta.map { String(format: "%.1f", $0) + "%" } ?? "nil")")
print("📊   RHR Delta: \(request.rhrDelta.map { String(format: "%.1f", $0) + "%" } ?? "nil")")
```

---

### **3. Compact Ring View** (`CompactRingView.swift`)

**Changed:** Support optional scores and show "?" for missing data

```swift
struct CompactRingView: View {
    let score: Int? // ✅ Now optional (was: Int)
    let title: String
    let band: any ScoreBand
    let animationDelay: Double
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring (always grey)
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                if let score = score {
                    // Normal colored ring with score
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(colorForBand(band), ...)
                    
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(colorForBand(band))
                } else {
                    // ✅ Missing data indicator
                    Text("?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(.systemGray3))
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
```

**Visual Result:**
- **With data:** Green/amber/red ring with score number
- **Without data:** Grey ring with "?" in center

---

### **4. Today View** (`TodayView.swift`)

**Changed:** Check for missing sleep data and show "?" indicator

```swift
// Sleep Score (center)
if let sleepScore = viewModel.sleepScoreService.currentSleepScore {
    NavigationLink(destination: SleepDetailView(sleepScore: sleepScore)) {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(TodayContent.Scores.sleepScore)
                    .font(.headline)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // ✅ Show ? if no sleep data
            if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
                CompactRingView(
                    score: nil,
                    title: "No Data",
                    band: SleepScore.SleepBand.poor,
                    animationDelay: 0.1
                ) {
                    // Empty action
                }
            } else {
                CompactRingView(
                    score: sleepScore.score,
                    title: sleepScore.bandDescription,
                    band: sleepScore.band,
                    animationDelay: 0.1
                ) {
                    // Empty action
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(PlainButtonStyle())
}
```

---

## Backend Changes Required

The backend AI brief function needs to handle optional deltas:

```typescript
// Example backend prompt adjustment
if (request.sleepDelta === null) {
  prompt += "\n⚠️ Sleep data unavailable - user did not wear watch overnight.";
  prompt += "\nProvide recommendations based on recovery score only.";
  prompt += "\nSuggest wearing watch for better insights.";
} else {
  prompt += `\nSleep: ${request.sleepDelta > 0 ? '+' : ''}${request.sleepDelta.toFixed(1)}h vs baseline`;
}
```

**Expected AI output when no sleep data:**
> "Your recovery score is 57 (Amber). Unfortunately, I don't have sleep data from last night - make sure to wear your Apple Watch while sleeping for better insights. Based on your recovery score alone, I recommend moderate training today..."

---

## Testing Checklist

### **Test Case 1: Normal Sleep Data**
- [x] Wear Apple Watch overnight
- [x] Open app next morning
- [x] Sleep ring shows colored score (e.g., 90 - Excellent)
- [x] AI brief mentions sleep quality

### **Test Case 2: Missing Sleep Data**
- [ ] Don't wear Apple Watch overnight
- [ ] Open app next morning
- [ ] Sleep ring shows grey "?" with "No Data" label
- [ ] AI brief acknowledges missing data
- [ ] Recovery score still calculated (using other metrics)

### **Test Case 3: Partial Data**
- [ ] Wear watch but remove mid-sleep
- [ ] Verify app handles partial sleep sessions
- [ ] Check if "?" appears or partial score shown

---

## User Experience

### **Before:**
- Missing sleep data → showed `0` delta
- AI thought sleep was perfect (0 deviation from baseline)
- Misleading recommendations

### **After:**
- Missing sleep data → shows `nil` delta
- AI knows data is missing
- Provides appropriate recommendations
- Visual "?" indicator clearly shows missing data
- User understands they need to wear watch

---

## Related Files

**Modified:**
- `VeloReady/Core/Networking/AIBriefClient.swift`
- `VeloReady/Core/Services/AIBriefService.swift`
- `VeloReady/Features/Today/Views/Components/CompactRingView.swift`
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

**Backend (needs update):**
- `veloready-website/netlify/functions/ai-brief.ts`

---

## Build Status

✅ **Build successful** (warnings are pre-existing, not related to this change)

---

**Implementation Date:** Oct 12, 2025
**Status:** ✅ Complete (pending backend AI prompt update)
