# Stress UI Implementation - Complete

**Date:** November 11, 2025  
**Implementation:** Hybrid Solution (Banner + Detail Sheet + Recovery Factors Card)

---

## Overview

Implemented the recommended hybrid approach from the Stress UI Strategy document:

1. **Stress Alert Banner** - Appears under recovery rings when stress is elevated
2. **Stress Analysis Sheet** - Comprehensive breakdown accessed via banner "Details" link
3. **Recovery Factors Card** - New card in Recovery Detail View showing component breakdowns
4. **Debug Switch** - Testing toggle in Debug settings

---

## Files Created

### 1. Data Models
**File:** `VeloReady/Core/Models/StressAlert.swift`

```swift
struct StressAlert {
    let severity: Severity          // .elevated or .high
    let acuteStress: Int           // 0-100
    let chronicStress: Int         // 0-100
    let trend: Trend               // .increasing, .stable, .decreasing
    let contributors: [StressContributor]
    let recommendation: String
    let detectedAt: Date
}

struct StressContributor {
    let name: String
    let type: ContributorType      // trainingLoad, sleepQuality, hrv, etc.
    let value: Int                 // 0-100 score
    let points: Int                // Points contributed to overall stress
    let description: String
    let status: Status             // optimal, good, elevated, high
}

struct RecoveryFactor {
    let type: FactorType           // stress, hrv, rhr, sleep, form
    let value: Int                 // 0-100 score
    let status: Status             // optimal, good, fair, low, high
    let weight: Double             // 0.0-1.0
}
```

### 2. Service Layer
**File:** `VeloReady/Core/Services/StressAnalysisService.swift`

- Singleton service following existing pattern
- Mock data generation for testing
- Integration with RecoveryScoreService and SleepScoreService
- Methods:
  - `analyzeStress()` - Main analysis (TODO: implement real calculation)
  - `getRecoveryFactors()` - Get factors for recovery card
  - `generateMockAlert()` - Create test alert
  - `enableMockAlert()` / `disableMockAlert()` - Debug controls

### 3. UI Components

#### StressBanner
**File:** `VeloReady/Design/Components/StressBanner.swift`

- Follows WellnessBanner and IllnessAlertBanner pattern
- Rounded corners, severity-based color
- Shows icon + message + "Details" link with blue arrow
- Tappable to open detail sheet

#### StressAnalysisSheet
**File:** `VeloReady/Features/Today/Views/DetailViews/StressAnalysisSheet.swift`

Comprehensive breakdown with sections:
1. **Current State** - Acute/Chronic stress levels with trend
2. **30-Day Trend** - Visual chart showing stress progression
3. **Contributors** - Detailed breakdown of factors (training load, sleep, HRV, temperature)
4. **What This Means** - Plain language explanation
5. **Recommendations** - Actionable guidance (recovery week, volume reduction, etc.)

#### RecoveryFactorsCard
**File:** `VeloReady/Features/Today/Views/Components/RecoveryFactorsCard.swift`

New card showing recovery component breakdown:
- **Design:** Follows StandardCard pattern
- **Progress Bars:** White indicators on dark background (2px height)
- **Labels:** Factor name on left, status (colored) on right
- **Factors Shown:**
  - Stress (inverted labels: Low is good, High is bad)
  - HRV
  - RHR
  - Sleep
  - Form (Training Load)

### 4. Content Localization
**File:** `VeloReady/Features/Today/Content/en/StressContent.swift`

All strings abstracted following content strategy:
- Banner messages
- Section titles
- Metrics labels
- Status labels (with smart labeling for stress vs other metrics)
- Recommendations
- Chart labels

---

## Integration Points

### 1. TodayView
**File:** `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

**Added:**
- `@ObservedObject private var stressService = StressAnalysisService.shared`
- `@State private var showingStressDetailSheet = false`
- Stress banner placement (after RecoveryMetricsSection, before HealthWarningsCardV2)
- Sheet presentation for StressAnalysisSheet

**Code:**
```swift
// Stress Alert Banner (appears under rings when elevated)
if healthKitManager.isAuthorized,
   let alert = stressService.currentAlert,
   alert.isSignificant {
    StressBanner(alert: alert) {
        showingStressDetailSheet = true
    }
    .padding(.top, Spacing.md)
}
```

### 2. RecoveryDetailView
**File:** `VeloReady/Features/Today/Views/DetailViews/RecoveryDetailView.swift`

**Added:**
- RecoveryFactorsCard immediately after RecoveryHeaderSection
- Positioned above HealthWarningsCardV2

### 3. Debug Settings
**File:** `VeloReady/Features/Debug/Views/DebugFeaturesView.swift`

**Added:**
- "Show Stress Alert" toggle in Simulations section
- Enables/disables mock stress alert
- Visual indicator when enabled (amber warning icon)

### 4. ProFeatureConfig
**File:** `VeloReady/Core/Config/ProFeatureConfig.swift`

**Added:**
```swift
@Published var showStressAlertForTesting: Bool = 
    UserDefaults.standard.bool(forKey: "showStressAlertForTesting") {
    didSet { 
        UserDefaults.standard.set(showStressAlertForTesting, 
                                 forKey: "showStressAlertForTesting") 
    }
}
```

### 5. Icons
**File:** `VeloReady/Core/Design/Icons.swift`

**Added to Health enum:**
- `static let thermometer = "thermometer.medium"`
- `static let brain = "brain.head.profile"`

---

## Design System Compliance

### ✅ Colors
- Uses `ColorScale` for all severity colors (greenAccent, blueAccent, amberAccent, redAccent)
- Uses `ColorPalette.backgroundTertiary` for progress bar backgrounds
- Uses `Color.white` for progress bar indicators (as requested)
- Uses `Color.text.secondary` and `Color.text.primary` for labels

### ✅ Spacing
- Uses `Spacing.md`, `Spacing.sm`, `Spacing.xs`, `Spacing.lg`, `Spacing.xl` throughout
- Consistent with existing card layouts

### ✅ Typography
- Uses `.caption` for progress bar labels (matches "20% improving" under charts)
- Uses `.subheadline` for card content
- Uses `.title3` for metrics

### ✅ Components
- `StandardCard` for all card wrappers
- `NavigationGradientMask` in detail sheets
- Rounded corners (12px for banner, 16px for cards)
- Follows existing sheet presentation patterns

---

## Testing Instructions

### 1. Enable Debug Switch
1. Open VeloReady
2. Navigate to: **Settings → Debug → Features**
3. Scroll to **Simulations** section
4. Toggle **"Show Stress Alert"** ON
5. Return to Today view

### 2. Verify Banner Appearance
**Expected Result:**
- Amber/orange banner appears under the 3 recovery rings
- Banner shows: ⚠️ icon + "High Training Stress" message + "Details →" link
- Banner has rounded corners with amber background (10% opacity)
- Banner has amber border (30% opacity)

### 3. Test Banner Interaction
1. Tap anywhere on the banner
2. Sheet should slide up from bottom
3. Sheet shows comprehensive stress analysis

### 4. Verify Sheet Content
**Sections (in order):**
1. **Current State**
   - Acute Stress: 72 🟠
   - Chronic Stress: 78 🟠
   - Trend: ↗ Increasing

2. **30-Day Trend**
   - Bar chart showing stress progression
   - Legend: Low (green), Moderate (amber), High (red)
   - "You are here" marker at top

3. **Contributors**
   - Training Load: High (28 pts) - ATL/CTL = 1.3
   - Sleep Quality: Elevated (15 pts) - 4 wake events, 6.5h sleep
   - HRV: Elevated (12 pts) - 18% below baseline
   - Temperature: Elevated (8 pts) - 0.6°C above baseline

4. **What This Means**
   - Plain language explanation

5. **Recommendations**
   - ✅ Implement recovery week NOW
   - • Reduce volume by 50%
   - • Keep intensity at Z2 only
   - • Prioritize 8+ hours sleep
   - • Monitor HRV for recovery signs
   - Expected Recovery: 7-10 days

### 5. Test Recovery Factors Card
1. From Today view, tap on the Recovery ring
2. RecoveryDetailView opens
3. Scroll down - new card appears immediately after the large recovery ring
4. **Expected Content:**
   - Title: "Recovery Breakdown"
   - Subtitle: "Factors contributing to your recovery score"
   - 5 progress bars (sorted by weight):
     * Stress - Low (good) - Green - 35/100 progress
     * HRV - Good/Optimal - 40% weight
     * RHR - Good/Optimal - 30% weight  
     * Sleep - Good/Optimal - 20% weight
     * Form - Good/Fair - 10% weight

### 6. Verify Progress Bars
**Each bar should have:**
- Factor label on left (caption size, secondary color)
- Status on right (caption size, colored based on status)
- 2px white progress bar below
- Proper progress (e.g., 85/100 = 85% width)

### 7. Test Status Labels
**Stress (inverted):**
- 0-35: "Low" (green) - good
- 36-60: "Moderate" (blue/amber)
- 61-80: "Elevated" (amber)
- 81-100: "High" (red) - bad

**Other Metrics (normal):**
- 80-100: "Optimal" (green)
- 60-79: "Good" (blue)
- 40-59: "Fair" (amber)
- 0-39: "Low" (red)

### 8. Disable Debug Switch
1. Return to Debug settings
2. Toggle "Show Stress Alert" OFF
3. Return to Today view
4. Banner should disappear
5. Recovery Factors Card still shows (real data)

---

## Edge Cases Tested

### ✅ No Alert State
- When `showStressAlertForTesting = false`
- Banner does not appear
- No layout shift

### ✅ Sheet Dismissal
- Swipe down to dismiss
- Tap "Got it" button
- Sheet closes smoothly

### ✅ Real Data Integration
- RecoveryFactorsCard pulls real scores from:
  - RecoveryScoreService
  - SleepScoreService
- Shows actual sub-scores when available

### ✅ Empty States
- If no recovery score available, factors show default states
- If no sleep score, sleep factor omitted

---

## Implementation Notes

### Why Mock Data?
The stress calculation algorithm is complex and requires:
1. 30-day historical data for chronic stress
2. 7-day sliding window for acute stress
3. Temperature baseline tracking (not yet implemented)
4. Training load ratio calculation (ATL/CTL)

**Current State:** Mock data allows UI testing while algorithms are developed

### Next Steps (Phase 2)
1. Implement `StressAnalysisService.analyzeStress()` with real calculations
2. Add background analysis (similar to wellness/illness detection)
3. Connect to temperature tracking (when available)
4. Add real 30-day trend data
5. Implement alert thresholds:
   - Show banner when: `chronicStress >= 61 OR acuteStress >= 71`
   - Update every hour
   - Persist dismissal state

### Content Strategy
All strings follow the content abstraction pattern:
- Defined in `StressContent.swift`
- Localized (ready for i18n)
- Easy to update without touching views

---

## Accessibility

### ✅ VoiceOver Support
- Banner: Reads severity + message + "Details button"
- Sheet: All sections labeled
- Progress bars: Include value in accessibility label

### ✅ Dynamic Type
- All text uses system fonts
- Scales appropriately

### ✅ Color Contrast
- Status colors pass WCAG AA (4.5:1 on dark backgrounds)
- White progress bars visible on all backgrounds

---

## Performance

### ✅ Efficient Rendering
- Banner only renders when alert exists
- Sheet uses lazy loading
- Progress bars use GeometryReader (minimal overhead)

### ✅ Memory Management
- Singleton services prevent duplication
- Mock data generated once, reused
- No heavy computations on main thread

---

## Visual Consistency

### ✅ Matches Existing Patterns
- **WellnessBanner** - Same layout, different content
- **IllnessDetailSheet** - Similar structure
- **Recovery Detail Cards** - Consistent styling
- **Debug Toggles** - Same pattern as wellness/illness

### ✅ Design System
- Uses atomic components (StandardCard, etc.)
- Follows spacing scale
- Uses color scale
- Typography matches spec

---

## Files Modified Summary

| File | Changes | Lines Changed |
|------|---------|---------------|
| `StressAlert.swift` | Created | 243 |
| `StressContent.swift` | Created | 108 |
| `StressAnalysisService.swift` | Created | 186 |
| `StressBanner.swift` | Created | 80 |
| `StressAnalysisSheet.swift` | Created | 289 |
| `RecoveryFactorsCard.swift` | Created | 95 |
| `TodayView.swift` | Modified | +17 |
| `RecoveryDetailView.swift` | Modified | +3 |
| `DebugFeaturesView.swift` | Modified | +18 |
| `ProFeatureConfig.swift` | Modified | +5 |
| `Icons.swift` | Modified | +2 |
| **TOTAL** | **6 new, 5 modified** | **~1,046** |

---

## Success Criteria

### ✅ All Requirements Met
1. ✅ Stress banner under rings (like wellness/illness)
2. ✅ Banner shows elevated stress message from strategy doc
3. ✅ "Details" link with blue arrow (tappable)
4. ✅ Sheet with comprehensive Stress Analysis wireframe
5. ✅ All components from design system
6. ✅ All content abstracted per strategy
7. ✅ Debug switch in existing debug section
8. ✅ Recovery Factors Card in Recovery Detail View
9. ✅ Progress bars with white indicators
10. ✅ Status labels aligned right, colored appropriately
11. ✅ Smart labeling for stress (Low = good, High = bad)
12. ✅ Factors sorted by weight (most important first)

---

## Known Limitations

1. **Mock Data Only** - Real stress calculation not yet implemented
2. **Static Trend Chart** - Uses random data for visualization
3. **No Historical Persistence** - Alert state not saved between sessions
4. **No Dismissal Logic** - Banner reappears every time (unlike wellness)

These are intentional for Phase 1 (UI implementation). Phase 2 will add:
- Real stress calculations
- Historical tracking
- Alert persistence and dismissal
- Background analysis

---

## Conclusion

The stress UI implementation is **complete and ready for testing**. All components follow the existing design system, content is properly abstracted, and the debug switch allows easy testing without real data.

**Status:** ✅ Ready for QA  
**Phase:** Phase 1 (UI) Complete  
**Next:** Phase 2 (Algorithm Implementation)

