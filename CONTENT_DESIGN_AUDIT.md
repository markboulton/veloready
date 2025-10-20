# Content & Design Abstraction Audit

## Executive Summary

**Scope:** Complete app cleanup - abstract all hardcoded content and design tokens
**Estimated Issues:** ~2,400+ instances requiring abstraction
**Priority:** High - Improves maintainability, localization readiness, and design consistency

---

## Findings

### 1. Content Strings
- **Hardcoded strings found:** ~1,027 instances
- **Current architecture:** ✅ Content files exist in `/Content/en/`
- **Issue:** Many views still use hardcoded strings instead of Content references

### 2. Design Tokens - Colors
- **Hardcoded colors found:** ~1,348 instances
- **Current architecture:** ✅ ColorPalette and ColorScale exist
- **Issue:** Direct use of `.green`, `.red`, `.blue`, `Color()` instead of semantic tokens

### 3. Design Tokens - Typography
- **Current architecture:** ✅ TypeScale exists with t-shirt sizing
- **Issue:** Inconsistent use of `.font(.system(size: X))` instead of TypeScale

### 4. Reusable Components
- **Current components:** Good foundation in `/Core/Components/`
- **Issue:** Repeated UI patterns not abstracted (e.g., section headers, metric cards)

---

## Cleanup Strategy

### Phase 1: Widget & Core Services (Priority: CRITICAL)
**Files:**
- `VeloReadyWidget/RideReadyWidget.swift` - Widget has hardcoded strings
- Core services with user-facing messages

**Actions:**
1. Create `WidgetContent.swift`
2. Abstract all widget strings
3. Abstract widget colors to ColorPalette

### Phase 2: Settings & Onboarding (Priority: HIGH)
**Files:**
- Settings sections (10+ files)
- Onboarding flows

**Actions:**
1. Audit existing SettingsContent.swift
2. Add missing strings
3. Abstract hardcoded colors

### Phase 3: Today/Dashboard (Priority: HIGH)
**Files:**
- Today view components
- Dashboard views
- Chart components

**Actions:**
1. Audit existing TodayContent.swift family
2. Abstract chart labels and tooltips
3. Create reusable chart components

### Phase 4: Activities & Reports (Priority: MEDIUM)
**Files:**
- Activities list and detail views
- Reports and trends

**Actions:**
1. Abstract activity-related strings
2. Create reusable activity components

### Phase 5: Design Token Sweep (Priority: HIGH)
**Scope:** Entire app

**Actions:**
1. Replace `.green` → `ColorPalette.success`
2. Replace `.red` → `ColorPalette.error`
3. Replace `.font(.system(size: 17))` → `TypeScale.font(size: .md)`
4. Create spacing constants (Spacing.swift)

### Phase 6: Reusable Components (Priority: MEDIUM)
**Create:**
1. `SectionHeaderView` - Consistent section headers
2. `MetricCardView` - Reusable metric display
3. `ScoreRingView` - Generic ring component
4. `BannerView` - Info/warning/error banners
5. `LoadingStateView` - Consistent loading states

---

## Implementation Plan

### Immediate Actions (This Session)
1. ✅ Create audit document
2. 🔄 Widget content abstraction
3. 🔄 Create WidgetContent.swift
4. 🔄 Abstract widget colors
5. 🔄 Create Spacing.swift for layout constants

### Next Session
1. Settings content cleanup
2. Today/Dashboard content cleanup
3. Create reusable components

---

## Benefits

### Maintainability
- Single source of truth for all content
- Easy to update copy across app
- Consistent terminology

### Localization
- Ready for i18n
- All strings in Content files
- Easy to add new languages

### Design Consistency
- Semantic color usage
- Consistent typography
- Reusable components reduce bugs

### Performance
- Smaller compiled code
- Fewer duplicate implementations
- Better code reuse

---

## Notes

- Existing architecture is solid - just needs consistent application
- No architectural changes needed
- Focus on systematic cleanup and abstraction
- Maintain existing patterns and conventions
