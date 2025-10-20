# Content & Design Abstraction - Implementation Guide

## Overview

This guide provides systematic patterns for cleaning up hardcoded content and design tokens across the VeloReady app.

---

## ✅ Created Assets

### Content Files
- ✅ `/VeloReadyWidget/Content/WidgetContent.swift` - Widget strings

### Design Token Files
- ✅ `/VeloReady/Core/Design/ColorPalette.swift` - Semantic colors
- ✅ `/VeloReady/Core/Design/ColorScale.swift` - Base color scale
- ✅ `/VeloReady/Core/Design/TypeScale.swift` - Typography scale
- ✅ `/VeloReady/Core/Design/Spacing.swift` - Layout spacing
- ✅ `/VeloReadyWidget/Design/WidgetDesignTokens.swift` - Widget-specific tokens

---

## Refactoring Patterns

### Pattern 1: Hardcoded Strings → Content

**Before:**
```swift
Text("Recovery")
Text("Sleep Quality")
Text("No data available")
```

**After:**
```swift
Text(TodayContent.Labels.recovery)
Text(SleepContent.Labels.quality)
Text(CommonContent.Errors.noData)
```

**Steps:**
1. Identify the feature area (Today, Settings, etc.)
2. Find or create appropriate Content file
3. Add string to relevant enum
4. Replace hardcoded string with Content reference

---

### Pattern 2: Hardcoded Colors → ColorPalette

**Before:**
```swift
.foregroundColor(.green)
.foregroundColor(.red)
.foregroundColor(.gray)
.background(Color.blue)
```

**After:**
```swift
.foregroundColor(ColorPalette.success)
.foregroundColor(ColorPalette.error)
.foregroundColor(ColorPalette.labelSecondary)
.background(ColorPalette.backgroundSecondary)
```

**Common Mappings:**
- `.green` → `ColorPalette.success`
- `.red` → `ColorPalette.error`
- `.yellow` / `.orange` → `ColorPalette.warning`
- `.gray` → `ColorPalette.labelSecondary` or `ColorPalette.neutral400`
- `.white` → `ColorPalette.labelPrimary`
- `.purple` → `ColorPalette.purple` or `ColorPalette.aiIconColor`
- `.blue` → `ColorPalette.blue`

**Context-Specific:**
- Recovery colors → `ColorPalette.recoveryColor(for: score)`
- Strain → `ColorPalette.strainMetric`
- Sleep → `ColorPalette.sleepMetric`
- HRV → `ColorPalette.hrvMetric`

---

### Pattern 3: Hardcoded Typography → TypeScale

**Before:**
```swift
.font(.system(size: 17))
.font(.system(size: 24, weight: .bold))
.font(.caption)
.font(.title)
```

**After:**
```swift
.font(TypeScale.font(size: TypeScale.md))
.font(TypeScale.font(size: TypeScale.lg, weight: .bold))
.font(TypeScale.font(size: TypeScale.xs))
.font(TypeScale.font(size: TypeScale.xl, weight: .bold))
```

**Size Mappings:**
- 48pt → `TypeScale.xxl`
- 34pt → `TypeScale.xl`
- 24pt → `TypeScale.lg`
- 22pt → `TypeScale.mlg`
- 17pt → `TypeScale.md`
- 15pt → `TypeScale.sm`
- 13pt → `TypeScale.xs`
- 11pt → `TypeScale.xxs`
- 10pt → `TypeScale.tiny`

---

### Pattern 4: Hardcoded Spacing → Spacing

**Before:**
```swift
.padding(16)
.padding(.horizontal, 20)
VStack(spacing: 12)
HStack(spacing: 8)
```

**After:**
```swift
.padding(Spacing.lg)
.padding(.horizontal, Spacing.xl)
VStack(spacing: Spacing.md)
HStack(spacing: Spacing.sm)
```

**Size Mappings:**
- 4pt → `Spacing.xs`
- 8pt → `Spacing.sm`
- 12pt → `Spacing.md`
- 16pt → `Spacing.lg`
- 20pt → `Spacing.xl`
- 24pt → `Spacing.xxl`
- 32pt → `Spacing.huge`

---

## Priority Files for Cleanup

### Critical (User-Facing)
1. ✅ `VeloReadyWidget/RideReadyWidget.swift` - Started
2. `Features/Today/Views/Dashboard/AIBriefView.swift`
3. `Features/Today/Views/Dashboard/RecoveryView.swift`
4. `Features/Today/Views/Dashboard/SleepView.swift`
5. `Features/Today/Views/Dashboard/StrainView.swift`

### High Priority
6. `Features/Settings/Views/Sections/*.swift` (10 files)
7. `Features/Onboarding/Views/*.swift`
8. `Features/Today/Views/Components/*.swift`

### Medium Priority
9. `Features/Activities/*.swift`
10. `Features/Reports/*.swift`
11. `Features/Trends/*.swift`

---

## Widget Cleanup Status

### ✅ Completed
- Created `WidgetContent.swift`
- Created `WidgetDesignTokens.swift`
- Partially refactored `MediumWidgetView` (Recovery ring)

### 🔄 In Progress
- `MediumWidgetView` - Sleep and Strain rings
- `SmallRecoveryView`
- `CircularRecoveryView`
- `RectangularRecoveryView`
- `InlineRecoveryView`

### ⏳ Pending
- Widget configuration strings
- Band name functions
- Animation constants

---

## Reusable Components to Create

### 1. ScoreRingView (Generic)
**Purpose:** Reusable ring component for any score
**Props:**
- `score: Int?`
- `label: String`
- `band: String?`
- `color: Color`
- `size: CGFloat`
- `showSparkles: Bool`

**Usage:**
```swift
ScoreRingView(
    score: 68,
    label: WidgetContent.Labels.recovery,
    band: "Good",
    color: WidgetDesignTokens.recoveryColor(for: 68),
    size: WidgetDesignTokens.Ring.sizeSmall,
    showSparkles: true
)
```

### 2. SectionHeaderView
**Purpose:** Consistent section headers
**Props:**
- `title: String`
- `subtitle: String?`
- `icon: String?`
- `action: (() -> Void)?`

### 3. MetricCardView
**Purpose:** Reusable metric display card
**Props:**
- `title: String`
- `value: String`
- `unit: String?`
- `color: Color`
- `trend: TrendDirection?`

### 4. BannerView
**Purpose:** Info/warning/error banners
**Props:**
- `type: BannerType` (.info, .warning, .error, .success)
- `message: String`
- `action: BannerAction?`

---

## Content File Organization

### Existing Structure (Keep)
```
/Core/Content/
  /en/
    - CommonContent.swift       # Shared strings
    - ComponentContent.swift    # UI component strings
    - ScoringContent.swift      # Scoring system strings
    - WellnessContent.swift     # Wellness metrics

/Features/[Feature]/Content/en/
    - [Feature]Content.swift    # Feature-specific strings
```

### Missing Content Files (Create)
- `WidgetContent.swift` ✅ Created
- `DebugContent.swift` - Debug menu strings
- `ErrorContent.swift` - Error messages
- `ValidationContent.swift` - Form validation messages

---

## Implementation Checklist

### Phase 1: Widget (Current)
- [x] Create WidgetContent.swift
- [x] Create WidgetDesignTokens.swift
- [ ] Refactor MediumWidgetView completely
- [ ] Refactor SmallRecoveryView
- [ ] Refactor CircularRecoveryView
- [ ] Refactor RectangularRecoveryView
- [ ] Refactor InlineRecoveryView
- [ ] Abstract widget configuration strings
- [ ] Abstract band name functions

### Phase 2: Core Components
- [ ] Audit `/Core/Components/*.swift`
- [ ] Abstract hardcoded strings
- [ ] Abstract hardcoded colors
- [ ] Abstract hardcoded typography
- [ ] Create reusable ScoreRingView
- [ ] Create reusable SectionHeaderView

### Phase 3: Settings
- [ ] Audit all Settings sections
- [ ] Update SettingsContent.swift
- [ ] Abstract colors and typography
- [ ] Standardize section headers

### Phase 4: Today/Dashboard
- [ ] Audit Today views
- [ ] Update TodayContent family
- [ ] Abstract chart strings
- [ ] Create reusable metric components

### Phase 5: Activities & Reports
- [ ] Audit Activities views
- [ ] Update ActivitiesContent.swift
- [ ] Audit Reports views
- [ ] Update ReportsContent.swift

### Phase 6: Final Sweep
- [ ] Search for remaining `.green`, `.red`, etc.
- [ ] Search for remaining hardcoded font sizes
- [ ] Search for remaining hardcoded spacing
- [ ] Run build and fix any issues

---

## Testing Strategy

After each phase:
1. Build the app - ensure no compilation errors
2. Run the app - verify UI looks identical
3. Check widget - verify it displays correctly
4. Test dark/light mode - ensure colors work
5. Test different screen sizes - ensure spacing works

---

## Notes

- **Don't change behavior** - Only abstract existing values
- **Maintain existing patterns** - Follow current architecture
- **Test incrementally** - Don't break working code
- **Document as you go** - Update this guide with learnings

---

## Quick Reference

### Import Statements Needed
```swift
// For Content
// (No import needed - same module)

// For Design Tokens
// (No import needed - same module)

// For Widget
import WidgetKit
```

### Common Replacements
```swift
// Strings
"Recovery" → WidgetContent.Labels.recovery
"--" → WidgetContent.Placeholder.noData

// Colors
.green → ColorPalette.success
.gray → ColorPalette.labelSecondary
Color.gray.opacity(0.2) → WidgetDesignTokens.Colors.background

// Typography
.font(.system(size: 24, weight: .bold)) → .font(.system(size: WidgetDesignTokens.Typography.scoreSize, weight: .bold))
.font(.caption) → .font(.system(size: TypeScale.xs))

// Spacing
.padding(16) → .padding(Spacing.lg)
VStack(spacing: 6) → VStack(spacing: WidgetDesignTokens.Spacing.verticalSpacing)
```

---

## Progress Tracking

**Total Estimated Instances:** ~2,400
**Completed:** ~50 (2%)
**Remaining:** ~2,350 (98%)

**Current Focus:** Widget cleanup
**Next Focus:** Core components
