# Investigation Findings - Trends & Settings

## 1. ✅ FITNESS TRAJECTORY - ROOT CAUSE IDENTIFIED

### **Issue:** "No data available" shown in Fitness Trajectory section

### **Root Cause:**
The `loadCTLHistoricalData()` function depends on `DailyLoad` data being present:

```swift
for day in thisWeek {
    guard let date = day.date,
          let ctl = day.load?.ctl,  // ← Requires DailyLoad relationship
          let atl = day.load?.atl else {
        continue
    }
    // ...
}
```

### **Data Flow:**
1. `CacheManager.saveDailyData()` saves CTL/ATL to `DailyLoad` entity
2. `DailyScores` has relationship to `DailyLoad`
3. `WeeklyReportViewModel.loadCTLHistoricalData()` reads from this relationship

### **Possible Causes:**
- ✅ **Relationship exists** in Core Data model
- ❓ **Data not being saved** - Check if Intervals.icu provides CTL/ATL
- ❓ **Data not being fetched** - Check if relationship is properly loaded
- ❓ **Timing issue** - Data might not be available yet

### **Solution:**
Add debug logging to track data availability:

```swift
private func loadCTLHistoricalData() async {
    let thisWeek = getLast7Days()
    
    Logger.debug("📊 Loading CTL data for \(thisWeek.count) days")
    
    var dataPoints: [FitnessTrajectoryChart.DataPoint] = []
    
    for day in thisWeek {
        if let date = day.date {
            Logger.debug("  Day: \(date)")
            Logger.debug("    Has load: \(day.load != nil)")
            if let load = day.load {
                Logger.debug("    CTL: \(load.ctl), ATL: \(load.atl)")
            }
        }
        
        guard let date = day.date,
              let ctl = day.load?.ctl,
              let atl = day.load?.atl else {
            continue
        }
        
        let tsb = ctl - atl
        
        dataPoints.append(FitnessTrajectoryChart.DataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb
        ))
    }
    
    if !dataPoints.isEmpty {
        ctlHistoricalData = dataPoints
        Logger.debug("📈 CTL Historical: \(dataPoints.count) days loaded")
    } else {
        Logger.warning("⚠️ No CTL data available - check if Intervals.icu provides CTL/ATL")
    }
}
```

### **Next Steps:**
1. Add debug logging
2. Check Intervals.icu API response for CTL/ATL values
3. Verify CacheManager is saving the data
4. Check if relationship needs to be explicitly fetched

---

## 2. ✅ WELLNESS FOUNDATION - NEEDS MORE DATA

### **Current Implementation:**
The `WellnessFoundation` struct exists and is being calculated:

```swift
struct WellnessFoundation {
    let sleepQuality: Double        // Sleep score + consistency
    let recoveryCapacity: Double    // Avg recovery - penalty
    let hrvStatus: Double           // HRV trend + stability
    let stressLevel: Double         // RHR elevation + low recovery
    let consistency: Double         // Sleep + training regularity
    let nutrition: Double           // Inferred from recovery
    let overallScore: Double        // Weighted average
}
```

### **What's Being Calculated:**
- ✅ Sleep Quality (70% score + 30% consistency)
- ✅ Recovery Capacity (avg recovery - debt penalty)
- ✅ HRV Status (trend + stability)
- ✅ Stress Level (RHR + low recovery days)
- ✅ Consistency (sleep regularity)
- ✅ Nutrition (inferred from recovery)
- ✅ Overall Score (weighted average)

### **Issue:**
The data is being calculated but **NOT DISPLAYED** in the UI!

### **Solution:**
Create a `WellnessFoundationComponent` to display this data:

```swift
struct WellnessFoundationComponent: View {
    let wellness: WellnessFoundation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wellness Foundation")
                .font(.heading)
            
            if let wellness = wellness {
                // Overall Score
                HStack {
                    Text("Overall")
                        .metricLabel()
                    Spacer()
                    Text("\(Int(wellness.overallScore))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(wellness.overallScore))
                }
                
                // Individual Metrics
                VStack(spacing: Spacing.sm) {
                    metricRow("Sleep Quality", value: wellness.sleepQuality)
                    metricRow("Recovery Capacity", value: wellness.recoveryCapacity)
                    metricRow("HRV Status", value: wellness.hrvStatus)
                    metricRow("Stress Level", value: wellness.stressLevel, inverse: true)
                    metricRow("Consistency", value: wellness.consistency)
                }
            } else {
                Text("No wellness data available")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func metricRow(_ label: String, value: Double, inverse: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
            Spacer()
            Text("\(Int(value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(inverse ? scoreColor(100 - value) : scoreColor(value))
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}
```

### **Add to WeeklyReportView:**
```swift
// After Training Load Summary
SectionDivider()

// Wellness Foundation
WellnessFoundationComponent(wellness: viewModel.wellnessFoundation)
```

---

## 3. ❓ SLEEP TARGET SCORING IMPACT

### **Investigation Needed:**
Check if changing sleep target in settings affects scoring calculations.

### **Files to Check:**
- `SleepScoreService.swift` - Look for sleep target usage
- `RecoveryScoreService.swift` - Check if sleep target impacts recovery
- Settings persistence and usage

### **Expected Behavior:**
Sleep target should affect:
- Sleep score calculation (% of target achieved)
- Recovery score (sleep is a component)
- Effort target recommendations

### **Test:**
1. Change sleep target from 8h → 7h
2. Check if sleep score changes for same duration
3. Verify recovery score adjusts accordingly

---

## 4. ❓ DATA SOURCE PRIORITY EXPLANATION

### **Current Implementation:**
```swift
// Default priority: Intervals.icu > Strava > Apple Health
sourcePriority = [.intervalsICU, .strava, .appleHealth]
```

### **What It Does:**
When multiple sources provide the same data type, the app uses the highest priority source.

### **User Impact:**
- **Activities:** Intervals.icu first, then Strava, then Apple Health
- **Wellness:** Intervals.icu first, then Apple Health
- **Metrics:** Intervals.icu first, then Strava

### **Issue:**
No explanation in UI about what ordering does!

### **Solution:**
Add footer text to Priority Section in DataSourcesSettingsView:

```swift
Section {
    // ... existing priority list ...
} header: {
    Text("Priority Order")
} footer: {
    Text("When multiple sources provide the same data, VeloReady uses the highest priority source. For example, if both Intervals.icu and Strava have today's ride, the Intervals.icu version will be used because it includes power analysis and training metrics. Drag to reorder.")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

---

## 5. ❓ DISPLAY PREFERENCES VERIFICATION

### **Settings to Check:**
- Unit system (metric/imperial)
- Distance units (km/miles)
- Temperature units (C/F)
- Weight units (kg/lbs)

### **Investigation:**
1. Do these settings persist?
2. Do they trigger recalculations?
3. Or just display formatting?

### **Expected:**
Should be **display-only** (no recalculations needed)

### **Files to Check:**
- `DisplayPreferencesView.swift`
- `UnitPreferences.swift` or similar
- Usage in formatters

---

## 6. ❓ NOTIFICATIONS FUNCTIONALITY

### **Investigation:**
1. Does the toggle actually work?
2. Are notifications scheduled?
3. What triggers them?

### **Files to Check:**
- `NotificationManager.swift` or similar
- Settings persistence
- Notification scheduling logic

### **Expected Notifications:**
- Daily brief ready
- Weekly report ready
- Recovery alerts
- Training reminders

---

## 7. 🔧 FEEDBACK LOG ATTACHMENT

### **Current Issue:**
Send feedback doesn't attach logs to email

### **Solution:**
```swift
func sendFeedback() {
    // Collect logs
    let logs = Logger.exportLogs() // Implement this
    
    // Create temporary file
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("veloready-logs-\(Date().timeIntervalSince1970).txt")
    
    try? logs.write(to: tempURL, atomically: true, encoding: .utf8)
    
    // Create mail composer with attachment
    let mailComposer = MFMailComposeViewController()
    mailComposer.setToRecipients(["support@veloready.com"])
    mailComposer.setSubject("VeloReady Feedback")
    
    if let logData = try? Data(contentsOf: tempURL) {
        mailComposer.addAttachmentData(
            logData,
            mimeType: "text/plain",
            fileName: "veloready-logs.txt"
        )
    }
    
    // Present
    present(mailComposer, animated: true)
}
```

---

## 8. 🔧 PROFILE LOADING ISSUE

### **Issue:**
Spinner shows when loading user info

### **Investigation:**
1. What's causing the delay?
2. Where is user info coming from?
3. Can we cache it?

### **Solution Options:**
1. **Cache user info** locally
2. **Add user editing** capability
3. **Pull from connected services** (Intervals.icu, Strava)
4. **Add avatar picker** from photo library

---

## 9. ❓ SIGN OUT CLARIFICATION

### **Issue:**
Unclear what account user is signing out of

### **Current:**
Just says "Sign Out"

### **Solution:**
```swift
Button(role: .destructive) {
    // Sign out action
} label: {
    HStack {
        Image(systemName: "rectangle.portrait.and.arrow.right")
        VStack(alignment: .leading) {
            Text("Sign Out")
            Text("Disconnect from Intervals.icu")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

---

## SUMMARY

### **Immediate Fixes Needed:**
1. ✅ Add debug logging to fitness trajectory
2. ✅ Create WellnessFoundationComponent
3. ✅ Add data source priority explanation
4. ✅ Fix feedback log attachment
5. ✅ Clarify sign out button

### **Investigations Needed:**
1. ❓ Sleep target scoring impact
2. ❓ Display preferences functionality
3. ❓ Notifications functionality
4. ❓ Profile loading delay
5. ❓ iCloud sync status (from memory)

### **Data Issues:**
1. ❓ Fitness trajectory - check if Intervals.icu provides CTL/ATL
2. ❓ Wellness foundation - data calculated but not displayed
