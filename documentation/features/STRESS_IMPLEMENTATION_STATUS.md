# Stress Feature Implementation Status

**Last Updated:** November 11, 2025  
**Status:** Phase 1-2 Complete ✅ | Phase 3-4 Pending

---

## ✅ COMPLETED (Phases 1-2)

### Phase 1: UI Design & Integration
1. ✅ **StressBanner** - Matches `IllnessAlertBanner` design exactly
   - Icon in 44x44 circle (top-left)
   - Bold heading + severity badge
   - Description text in grey
   - Row of contributor icons (top 3)
   - Right-aligned 'i' icon
   - 5% opacity background with 4px left accent bar

2. ✅ **StressAnalysisSheet** - Matches `WellnessDetailSheet` design
   - Header with icon, title, and subtitle
   - Disclaimer section
   - "What We Noticed" text section
   - Uses `TrendChart` component (same as Recovery)
   - Contributor cards
   - Recommendations with bullet points

3. ✅ **RecoveryFactorsCard** - New card in Recovery Detail View
   - Shows component breakdown with progress bars
   - Stress appears at top (highest priority)
   - Consistent design system usage

4. ✅ **Debug Switch** - Testing toggle in Debug settings
   - Enable/disable mock stress alerts
   - Proper main-actor isolation

5. ✅ **Branding Animation Fix** - Fixed missing branding circles
   - Now shows on every fresh app launch
   - Correctly distinguishes kill vs background

### Phase 2: Real Stress Calculations
1. ✅ **Real-time Stress Score Algorithm**
   ```
   Acute Stress Score (0-100) =
     Physiological Stress (0-40) +
     Recovery Deficit (0-30) +
     Sleep Disruption (0-30)
   ```

2. ✅ **Component Breakdown:**
   - **HRV Stress (0-15 pts):** `(Baseline - Current) / Baseline × 50`, capped at 15
   - **RHR Stress (0-15 pts):** `(Current - Baseline) / Baseline × 150`, capped at 15
   - **Recovery Deficit (0-30 pts):** `(70 - Score) × 0.5` if recovery < 70
   - **Sleep Disruption (0-30 pts):** `(100 - SleepScore) × 0.2 + (WakeEvents × 2)`

3. ✅ **Smart Thresholds:**
   - 0-50: Normal (no alert shown)
   - 51-70: Elevated (amber alert)
   - 71-100: High (red alert)

4. ✅ **Real Data Integration:**
   - Uses `RecoveryScore.inputs` (hrv, rhr, baselines)
   - Uses `SleepScore.inputs` (sleepDuration, wakeEvents)
   - Generates alerts automatically when stress > 50
   - Calculates contributor severity & points

5. ✅ **Content Abstraction:**
   - All strings in `StressContent.swift`
   - Following existing localization strategy

---

## ⏳ PENDING (Phases 3-4)

### Phase 3: Historical Tracking & Real Charts

#### 1. Core Data Schema
**Need to add:**
```swift
@Model
class StressScore {
    var date: Date
    var acuteStress: Int // 0-100
    var chronicStress: Int // 7-day rolling average
    var physiologicalStress: Double
    var recoveryDeficit: Double
    var sleepDisruption: Double
    var hrvDeviation: Double
    var rhrDeviation: Double
    var trend: String // "increasing", "stable", "decreasing"
    var calculatedAt: Date
}
```

#### 2. Historical Data Service
**Create:** `StressHistoryService.swift`
- Save daily stress scores to Core Data
- Retrieve stress history for chart rendering
- Calculate 7-day rolling average (chronic stress)
- Detect multi-day trends

#### 3. Real Trend Charts
**Update:** `StressAnalysisService.getStressTrendData()`
- Currently returns mock data
- Should query `StressScore` from Core Data
- Group by period (7, 14, 30, 90 days)
- Calculate averages and trends

#### 4. Training Load Integration
**Get ATL/CTL from Intervals.icu:**
- Already available in `RecoveryScore.RecoveryInputs`
- Calculate Training Stress Balance (TSB = CTL - ATL)
- Add to stress contributor calculation:
  ```swift
  ratio = ATL / CTL
  if ratio < 0.8: Score = 0
  else if ratio < 1.0: Score = (ratio - 0.8) × 75
  else if ratio < 1.3: Score = 15 + ((ratio - 1.0) × 50)
  else: Score = 30
  ```

### Phase 4: Smart Thresholds & Personalization

#### 1. Athlete Profile-Based Thresholds
- Adjust thresholds based on training history
- Consider CTL (fitness) when determining severity
- Example: Pro cyclist with CTL=120 vs recreational rider with CTL=40

#### 2. Historical Pattern Analysis
- Detect normal stress ranges for individual athlete
- Alert when stress deviates significantly from personal baseline
- Example: If athlete normally runs 60-70 stress during build phases, don't alert at 65

#### 3. Recovery Context
- Consider recent recovery scores when calculating stress
- Weight stress differently if athlete has been recovering well
- Reduce false positives during planned overreach periods

#### 4. Seasonal Adjustments
- Account for training phase (base, build, peak, recovery)
- Adjust thresholds based on proximity to goal event
- Allow higher stress during intentional overreach

---

## 📋 Implementation Priority Recommendations

### High Priority (Do Next)
1. **Historical Tracking** - Essential for chronic stress calculation
   - Core Data model for `StressScore`
   - Daily save mechanism
   - 7-day rolling average calculation

2. **Real Trend Charts** - Critical for user understanding
   - Replace mock data in `getStressTrendData()`
   - Query Core Data for historical scores
   - Show actual stress progression

### Medium Priority
3. **Training Load Integration** - Adds key contributor
   - Use existing ATL/CTL from `RecoveryInputs`
   - Calculate TSB-based stress component
   - More accurate stress for endurance athletes

### Lower Priority (Nice to Have)
4. **Smart Thresholds** - Personalization enhancement
   - Can be iterated on after initial rollout
   - Requires sufficient historical data (14-30 days minimum)
   - More complex, less urgent than core functionality

---

## 🧪 Testing Strategy

### Current Debug Capabilities
- ✅ Toggle mock stress alert in Debug menu
- ✅ View banner and detail sheet
- ✅ Test recovery factors card

### Additional Testing Needed
1. **Real Stress Calculation**
   - Verify calculations with known data
   - Test edge cases (missing HRV, RHR, sleep data)
   - Validate threshold triggers

2. **Historical Tracking** (Once implemented)
   - Verify Core Data persistence
   - Test data migration
   - Validate 7-day rolling average

3. **Performance**
   - Ensure calculations don't block UI
   - Test with large historical datasets
   - Verify cache invalidation

---

## 📊 Formula Reference

### Acute Stress (Today's Score)
```
Physiological Stress (0-40 points):
  HRV Stress = min(15, (Baseline - Current) / Baseline × 50)
  RHR Stress = min(15, (Current - Baseline) / Baseline × 150)
  Total = HRV Stress + RHR Stress

Recovery Deficit (0-30 points):
  If Recovery Score >= 70: Deficit = 0
  Else: Deficit = min(30, (70 - Recovery Score) × 0.5)

Sleep Disruption (0-30 points):
  Base = (100 - Sleep Score) × 0.2  // Max 20 points
  Wake Events Penalty = min(10, Wake Events × 2)
  Total = Base + Wake Events Penalty

Final Acute Stress = min(100, Physiological + Recovery Deficit + Sleep Disruption)
```

### Chronic Stress (7-Day Average)
```
Chronic Stress = 7-day rolling average of Acute Stress scores

TODO: Implement after historical tracking is added
```

### Training Load Component (TODO)
```
ratio = ATL / CTL
If ratio < 0.8: Score = 0  // Well recovered
Else If ratio < 1.0: Score = (ratio - 0.8) × 75  // Range: 0-15
Else If ratio < 1.3: Score = 15 + ((ratio - 1.0) × 50)  // Range: 15-30
Else: Score = 30  // Overreaching
```

---

## 📁 Files Modified/Created

### New Files
1. `VeloReady/Core/Models/StressAlert.swift` - Data models
2. `VeloReady/Core/Services/StressAnalysisService.swift` - Service layer
3. `VeloReady/Design/Components/StressBanner.swift` - Banner UI
4. `VeloReady/Features/Today/Views/DetailViews/StressAnalysisSheet.swift` - Detail sheet
5. `VeloReady/Features/Today/Views/Components/RecoveryFactorsCard.swift` - Factors card
6. `VeloReady/Features/Today/Content/en/StressContent.swift` - Localized strings

### Modified Files
1. `VeloReady/Core/Design/Icons.swift` - Added thermometer, brain icons
2. `VeloReady/Core/Config/ProFeatureConfig.swift` - Added debug toggle
3. `VeloReady/Features/Debug/Views/DebugFeaturesView.swift` - Added stress toggle
4. `VeloReady/Features/Today/Views/Dashboard/TodayView.swift` - Integrated banner
5. `VeloReady/Features/Today/Views/DetailViews/RecoveryDetailView.swift` - Added factors card
6. `VeloReady/App/VeloReadyApp.swift` - Fixed branding animation

---

## 🎯 Next Steps

**For User:**
1. Review implementation and decide priority for Phase 3-4
2. Test current functionality using Debug toggle
3. Provide feedback on stress calculation accuracy
4. Decide if training load integration is critical for launch

**For Implementation:**
1. Start with Core Data schema for historical tracking
2. Implement daily stress score persistence
3. Build 7-day rolling average calculator
4. Replace mock trend data with real queries
5. Add training load component when ready

---

## 📖 Documentation
- [Stress UI Strategy](./STRESS_UI_STRATEGY.md) - Original requirements
- [Stress UI Implementation](./STRESS_UI_IMPLEMENTATION.md) - Technical details
- [Stress UI Quick Start](./STRESS_UI_QUICK_START.md) - Testing guide
- [Scoring Methodology](./SCORING_METHODOLOGY.md) - Formula documentation

