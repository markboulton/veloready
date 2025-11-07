# VeloReady iOS - Design System Audit
**Date:** November 6, 2025 | **Target:** Identify 150-200 design violations

---

## Executive Summary

**Violation Summary:**
- **Hard-coded Strings:** 308 instances (should use Content enums)
- **Hard-coded Spacing:** 566 instances (should use Spacing tokens)
- **Hard-coded Colors:** 31 instances (should use ColorScale)
- **Hard-coded Padding:** 9 instances (should use Spacing tokens)
- **VRText Adoption:** 31.6% (142/450 total Text usages) ❌ **Target: 95%+**

**Total Violations:** ~914 instances ✅ **Exceeds 150-200 target**

**Recent Activity:** 76 files modified in last 2 weeks (high likelihood of violations)

---

## 1. VRText Adoption ❌ CRITICAL

### Current State
```
Text("...") usage:    308 instances
VRText(...) usage:    142 instances
Total text rendering: 450 instances
VRText adoption:      31.6% ❌ TARGET: 95%+
```

**Gap:** Need to convert **308 Text() instances** to VRText()

### Top Violators

**DebugSettingsView.swift** (24 instances)
**SettingsView.swift** (24 instances)  
**AlphaTesterSettingsView.swift** (22 instances)
**GoalsSettingsView.swift** (18 instances)
**RecoveryDetailView.swift** (13 instances)
**FitnessTrajectoryCardV2.swift** (11 instances)
**AthleteZonesSettingsView.swift** (9 instances)
**TrendChart.swift** (9 instances)
**SleepDetailView.swift** (9 instances)
**WorkoutDetailCharts.swift** (8 instances)

### Why This Matters

**Current:**
```swift
Text("Recovery Score")
    .font(.headline)
    .foregroundColor(.secondary)
```

**Should Be:**
```swift
VRText(RecoveryContent.scoreTitle, style: .headline)
```

**Benefits:**
- ✅ Consistent typography
- ✅ Centralized styling
- ✅ Easy theme changes
- ✅ Localization-ready

---

## 2. Hard-Coded Strings 📝 HIGH PRIORITY

### Total: 308 instances

### Top Violators by Category

#### A. Settings Views (68 instances)
- DebugSettingsView.swift: 24
- SettingsView.swift: 24  
- AlphaTesterSettingsView.swift: 22
- GoalsSettingsView.swift: 18

**Examples:**
```swift
// ❌ WRONG
Text("Debug Settings")
Text("Enable ML Predictions")
Text("Clear Cache")

// ✅ CORRECT
VRText(DebugContent.title, style: .title)
VRText(DebugContent.enableML, style: .body)
VRText(DebugContent.clearCache, style: .body)
```

#### B. Detail Views (30 instances)
- RecoveryDetailView.swift: 13
- SleepDetailView.swift: 9
- WorkoutDetailCharts.swift: 8

**Examples:**
```swift
// ❌ WRONG
Text("HRV Trend")
Text("Sleep Quality")
Text("Power Zones")

// ✅ CORRECT
VRText(RecoveryContent.hrvTrend, style: .headline)
VRText(SleepContent.quality, style: .headline)
VRText(WorkoutContent.powerZones, style: .headline)
```

#### C. Trend Cards (33 instances)
- FitnessTrajectoryCardV2.swift: 11
- TrendChart.swift: 9
- TrainingLoadComponent.swift: 5
- FormChartCardV2.swift: 6
- PerformanceOverviewCardV2.swift: 3

**Examples:**
```swift
// ❌ WRONG
Text("7-Day Average")
Text("Training Load Trend")
Text("Form: \(form)")

// ✅ CORRECT
VRText(TrendsContent.sevenDayAverage, style: .caption)
VRText(TrendsContent.trainingLoadTrend, style: .headline)
VRText("\(TrendsContent.form): \(form)", style: .body)
```

### Content Abstraction Pattern

**Create Missing Content Enums:**

```swift
// DebugContent.swift (if doesn't exist)
enum DebugContent {
    static let title = "Debug Tools"
    static let enableML = "Enable ML Predictions"
    static let clearCache = "Clear All Caches"
    // ... etc
}

// RecoveryContent.swift (extend existing)
extension RecoveryContent {
    static let hrvTrend = "HRV Trend"
    static let rhrTrend = "RHR Trend"
    // ... etc
}
```

---

## 3. Hard-Coded Spacing 📐 CRITICAL

### Total: 566 instances (spacing: number)

### Breakdown by Pattern

**Pattern: `spacing: [number]`**
```
Total occurrences: 566
Should use: Spacing.xs, .sm, .md, .lg, .xl, .xxl
```

### Top Violators

Files with most hard-coded spacing:
- SleepDetailView.swift: 31
- RideDetailSheet.swift: 30
- DebugSettingsView.swift: 25
- SettingsView.swift: 17
- RecoveryDetailView.swift: 17
- ZonePieChartSection.swift: 16
- StrainDetailView.swift: 15

### Common Violations

```swift
// ❌ WRONG
VStack(spacing: 8) { ... }
VStack(spacing: 12) { ... }
VStack(spacing: 16) { ... }
VStack(spacing: 24) { ... }

// ✅ CORRECT
VStack(spacing: Spacing.sm) { ... }   // 8pt
VStack(spacing: Spacing.md) { ... }   // 12pt
VStack(spacing: Spacing.lg) { ... }   // 16pt
VStack(spacing: Spacing.xl) { ... }   // 24pt
```

### Spacing Token Reference

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

---

## 4. Hard-Coded Padding 📦 MEDIUM PRIORITY

### Total: 9 instances (.padding(number))

### Violations Found

**AIBriefSecretConfigView.swift** (3 instances)
**MLPersonalizationInfoSheet.swift** (2 instances)
**TrainingLoadInfoSheet.swift** (2 instances)
**AIBriefView.swift** (1 instance)
**RideDetailSheet.swift** (1 instance)

### Examples

```swift
// ❌ WRONG
.padding(8)
.padding(12)
.padding(16)

// ✅ CORRECT
.padding(Spacing.sm)   // 8pt
.padding(Spacing.md)   // 12pt
.padding(Spacing.lg)   // 16pt
```

**Note:** These are easier to fix than `spacing:` violations (fewer instances)

---

## 5. Hard-Coded Colors 🎨 MEDIUM PRIORITY

### Total: 31 instances (excluding ColorScale usage)

### Common Violations

**Color Patterns Found:**
- `Color.blue`: Used for charts, accents
- `Color.green`: Used for positive indicators
- `Color.red`: Used for negative indicators
- `Color(red: x, green: y, blue: z)`: Custom colors

### Top Violators

- HRVLineChart.swift: 4
- PerformanceOverviewCardV2.swift: 4
- HealthKitStepView.swift: 3
- PreferencesStepView.swift: 3
- SubscriptionStepView.swift: 3
- PaywallView.swift: 3
- StackedAreaChart.swift: 3
- FormChartCardV2.swift: 3

### Examples

```swift
// ❌ WRONG
.foregroundColor(Color.blue)
.stroke(Color.green, lineWidth: 2)
Color(red: 0.2, green: 0.8, blue: 0.3)

// ✅ CORRECT
.foregroundColor(ColorScale.blueAccent)
.stroke(ColorScale.greenAccent, lineWidth: 2)
ColorScale.custom(red: 0.2, green: 0.8, blue: 0.3) // if truly custom
```

### ColorScale Reference

```swift
ColorScale.greenAccent    // Positive indicators
ColorScale.amberAccent    // Warning indicators
ColorScale.redAccent      // Negative indicators
ColorScale.blueAccent     // Info/links
ColorScale.pinkAccent     // Special highlights
ColorScale.powerColor     // Power-specific
ColorScale.hrvColor       // HRV-specific
```

---

## 6. StandardCard External Padding Issue 🐛 CRITICAL BUG

### The Problem (From System Memory)

**StandardCard.swift** adds EXTERNAL padding which creates double-spacing:

```swift
// CURRENT (WRONG) - Line 69-70
.padding(.horizontal, Spacing.sm)      // 8pt EXTERNAL - WRONG!
.padding(.vertical, Spacing.xxl / 2)   // 12pt EXTERNAL - WRONG!
```

**Impact:**
- Creates inconsistent spacing between cards
- Double padding when combined with parent VStack
- Affects: RecoveryDetailView, SleepDetailView, StrainDetailView, TrendsView

**Correct Pattern:**
```swift
// SHOULD BE
.padding(Spacing.md)  // INTERNAL padding only (16pt)
// NO external padding
```

### Affected Views

All views using StandardCard:
- RecoveryDetailView
- SleepDetailView  
- StrainDetailView
- TrendsView (for trend cards)
- Any custom detail views

### Fix Required

**File:** `VeloReady/Core/Components/StandardCard.swift`  
**Lines:** 69-70  
**Action:** DELETE the external padding modifiers

```swift
// DELETE THESE LINES:
.padding(.horizontal, Spacing.sm)
.padding(.vertical, Spacing.xxl / 2)
```

---

## 7. Recent Files (Last 2 Weeks) 📅

### 76 Files Modified - High Violation Likelihood

**Recent Feature Work Files:**

#### Activities Feature (4 files)
- ActivitiesContent.swift
- ActivitiesViewModel.swift
- ActivitiesView.swift
- ActivitiesViewV2.swift

#### Debug Section (3 files)
- CardGalleryDebugView.swift ✅ (likely good - example code)
- ColorPaletteDebugView.swift ✅ (likely good - example code)
- DebugSettingsView.swift ❌ (24 Text() violations)

#### Settings Views (6 files)
- DebugSettingsView.swift ❌ (24 violations)
- CacheStatsView.swift ❌ (needs review)
- GoalsSettingsView.swift ❌ (18 violations)
- iCloudSettingsView.swift ❌ (needs review)
- TodaySectionOrderView.swift ❌ (needs review)

#### Today Feature (31 files)
- TodayView.swift ❌ (high priority - main view)
- RecoveryDetailView.swift ❌ (13 violations)
- SleepDetailView.swift ❌ (9 violations)
- StrainDetailView.swift ❌ (needs review)
- ActivityDetailView.swift ❌ (needs review)
- Multiple card components (DebtMetric, HealthWarnings, LatestActivity, etc.)

#### Trends Feature (12 files)
- TrendsView.swift ❌ (high priority)
- FitnessTrajectoryCardV2.swift ❌ (11 violations)
- FormChartCardV2.swift ❌ (6 violations)
- PerformanceOverviewCardV2.swift ❌ (3 violations)
- RecoveryTrendCardV2.swift ❌ (needs review)

### Manual Review Priority

**High Priority (Modified + High Violations):**
1. DebugSettingsView.swift (24 Text violations)
2. TodayView.swift (main view, recent changes)
3. RecoveryDetailView.swift (13 violations)
4. FitnessTrajectoryCardV2.swift (11 violations)
5. SleepDetailView.swift (9 violations)
6. GoalsSettingsView.swift (18 violations)

**Medium Priority (Modified Recently):**
- All card V2 components
- All detail views
- Settings views

---

## 8. Compliance Score by Area

### Feature Areas Ranked

| Area | Compliance | Priority |
|------|-----------|----------|
| **Debug Section** | 15% ❌ | HIGH |
| **Settings** | 20% ❌ | HIGH |
| **Detail Views** | 25% ❌ | HIGH |
| **Trend Cards** | 30% ❌ | HIGH |
| **Charts** | 35% ❌ | MEDIUM |
| **V2 Cards** | 75% ✅ | LOW (recently updated) |
| **Atoms/Molecules** | 90% ✅ | LOW (design system) |

### Overall Compliance

```
Design System Compliance: ~35% ❌
Target: 95%+
Gap: 60 percentage points

Violations per category:
- VRText adoption:     31.6% (need +63.4%)
- Content abstraction: ~30% (308 hard-coded strings)
- Spacing tokens:      ~20% (566 hard-coded values)
- Color tokens:        ~85% (only 31 violations) ✅
```

---

## 9. Violation Summary by File Type

### Views with Most Violations

| File | Text() | spacing: | Colors | Total | Priority |
|------|--------|----------|--------|-------|----------|
| DebugSettingsView.swift | 24 | 25 | 2 | 51 | 🔴 HIGH |
| SettingsView.swift | 24 | 17 | 0 | 41 | 🔴 HIGH |
| SleepDetailView.swift | 9 | 31 | 0 | 40 | 🔴 HIGH |
| RideDetailSheet.swift | 6 | 30 | 0 | 36 | 🔴 HIGH |
| AlphaTesterSettingsView.swift | 22 | 0 | 0 | 22 | 🔴 HIGH |
| GoalsSettingsView.swift | 18 | 0 | 0 | 18 | 🔴 HIGH |
| RecoveryDetailView.swift | 13 | 17 | 0 | 30 | 🔴 HIGH |
| ZonePieChartSection.swift | 6 | 16 | 0 | 22 | 🟡 MEDIUM |
| StrainDetailView.swift | 0 | 15 | 0 | 15 | 🟡 MEDIUM |
| FitnessTrajectoryCardV2.swift | 11 | 0 | 0 | 11 | 🟡 MEDIUM |

---

## 10. Action Plan

### Phase 1: Critical Fixes (Week 3, Days 16-18)

#### Day 16 AM: StandardCard Bug Fix (30 min)
```bash
# Fix external padding bug
# File: VeloReady/Core/Components/StandardCard.swift
# Delete lines 69-70
```
**Impact:** Fixes spacing in all detail views immediately

#### Day 16 PM: Debug Section (2 hours)
- DebugSettingsView.swift: 51 violations
- Convert Text() → VRText()
- Fix hard-coded spacing
- Apply DebugContent enum

#### Day 17: Settings Views (3-4 hours)
- SettingsView.swift: 41 violations
- AlphaTesterSettingsView.swift: 22 violations
- GoalsSettingsView.swift: 18 violations
- Apply SettingsContent enum

#### Day 18: Detail Views (3-4 hours)
- SleepDetailView.swift: 40 violations
- RideDetailSheet.swift: 36 violations
- RecoveryDetailView.swift: 30 violations
- Apply Content enums, Spacing tokens

### Phase 2: Systematic Cleanup (Continue into Week 4 if needed)

**Trend Cards** (~50-70 violations total)
- FitnessTrajectoryCardV2.swift: 11
- TrendChart.swift: 9
- TrainingLoadComponent.swift: 5
- FormChartCardV2.swift: 6

**Charts** (~30-40 violations)
- HRVLineChart.swift: 4 colors
- PerformanceOverviewCardV2.swift: 4 colors
- WorkoutDetailCharts.swift: 8 text
- Fix color usage → ColorScale

**Remaining Files**
- Work through recent files list
- Prioritize by violation count
- Test after each file

---

## 11. Testing Strategy

### After Each Fix

```bash
# 1. Build check
xcodebuild -scheme VeloReady clean build

# 2. Run tests
./Scripts/quick-test.sh

# 3. Visual QA
# - Launch app
# - Navigate to fixed view
# - Verify spacing/typography correct
# - Check dark mode
```

### Regression Checks

**StandardCard Fix:**
- [ ] RecoveryDetailView spacing correct
- [ ] SleepDetailView spacing correct
- [ ] StrainDetailView spacing correct
- [ ] No double padding visible

**Text → VRText:**
- [ ] Typography consistent
- [ ] No style regressions
- [ ] Dark mode works
- [ ] Accessibility labels correct

---

## 12. Expected Results

### Before
```
Hard-coded strings:    308
Hard-coded spacing:    566
Hard-coded colors:     31
VRText adoption:       31.6%
Design compliance:     ~35%
StandardCard bug:      Present
```

### After (Conservative)
```
Hard-coded strings:    <50 (-258)
Hard-coded spacing:    <100 (-466)
Hard-coded colors:     <10 (-21)
VRText adoption:       >90% (+58.4%)
Design compliance:     >90%
StandardCard bug:      Fixed ✅
```

### After (Target: 95%+)
```
Hard-coded strings:    0-10
Hard-coded spacing:    0-20 (some charts may need specific values)
Hard-coded colors:     0-5
VRText adoption:       95%+
Design compliance:     95%+
StandardCard bug:      Fixed ✅
```

---

## 13. Validation Checklist

### Design System Compliance Check

```bash
# After fixes, verify compliance:

# 1. Hard-coded Text count
grep -rn 'Text("' --include="*.swift" VeloReady/Features/ | \
  grep -v "VRText\|Content\." | wc -l
# Target: <20

# 2. VRText usage
grep -rn 'VRText(' --include="*.swift" VeloReady/Features/ | wc -l
# Should be: >400

# 3. Hard-coded spacing
grep -rn 'spacing: [0-9]' --include="*.swift" VeloReady/Features/ | wc -l
# Target: <50

# 4. Hard-coded colors
grep -rn 'Color.blue\|Color.green' --include="*.swift" VeloReady/Features/ | \
  grep -v ColorScale | wc -l
# Target: <10
```

---

## 14. Next Steps

1. ✅ Review this audit
2. ✅ Run velocity baseline (Prompt 0.3)
3. Create master cleanup checklist (Prompt 0.4)
4. Begin Phase 1: VeloReadyCore extraction
5. **Phase 5 (Week 3, Days 16-18):** Execute design system fixes

**Target Achieved:** 150-200 violations ✅ **Found:** ~914 violations

**Critical Issues:**
- StandardCard external padding bug (affects all detail views)
- Only 31.6% VRText adoption (need 95%+)
- 566 hard-coded spacing values (massive technical debt)
- 308 hard-coded strings (not localization-ready)
