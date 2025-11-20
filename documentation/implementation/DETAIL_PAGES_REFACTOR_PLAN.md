# Detail Pages Refactor Plan
**Branch:** `detail-pages-refactor`
**Date:** 2025-11-19
**Status:** Planning Complete - Ready for Execution

## Executive Summary

This document outlines a comprehensive refactor of the Recovery, Sleep, and Training Load detail pages to align with the architectural patterns established in the Today page refactor (Phase 5). The work is organized into phases prioritizing critical bug fixes first, followed by architectural improvements.

---

## Current State Analysis

### Architecture Overview

| Page | ViewModel | Lines | MVVM | Issues |
|------|-----------|-------|------|--------|
| Recovery Detail | RecoveryDetailViewModel | 612 | ✅ @Observable | Monolithic, duplicates trend logic |
| Sleep Detail | SleepDetailViewModel | 871 | ✅ @Observable | Monolithic, inline mini-charts |
| Training Load | None | 482 | ❌ Component-only | No ViewModel, embedded logic |

### Key Components

**Shared Components:**
- `TrendChart` - 7/30/60 day selector with bar/line/area charts (used by Recovery & Sleep)
- `StandardCard` - Standardized card wrapper
- `ProFeatureGate` - Pro feature gating
- `CardContainer` / `CardHeader` - Atomic components from Today page refactor

**Page-Specific Components:**
- `RecoveryHeaderSection` - Recovery ring visualization
- `SleepHeaderSection` - Sleep ring visualization
- `HRVCandlestickChart` / `RHRCandlestickChart` - Recovery-specific charts
- `SleepHypnogramChart` - Sleep stage visualization
- `TrainingLoadChart` - 21-day CTL/ATL/TSB chart (activity-centric)
- `TrainingLoadTrendCardV2` - Trends page chart (receives data from TrendsViewModel)

### Services & Dependencies

**Core Services:**
- `RecoveryScoreService` - Recovery calculations, current scores
- `SleepScoreService` - Sleep debt, consistency, current scores
- `PersistenceController` - Core Data access
- `UnifiedActivityService` - Activity fetching (120-day cap)
- `TrainingLoadCalculator` - CTL/ATL/TSB calculations
- `AthleteProfileManager` - User profile, FTP

**Data Models:**
- `TrendDataPoint` - Date + single value
- `HRVDataPoint` / `RHRDataPoint` - Candlestick data
- `TrainingLoadDataPoint` - CTL/ATL/TSB/date/isFuture
- `RecoveryScore` / `SleepScore` - Complex models with inputs/subScores

---

## Critical Issues Identified

### 🔴 Critical Bug: Training Load Missing Data

**Location:** `TrendsViewModel.swift:412-455` (`loadDailyLoadTrend`)

**Problem:**
```swift
// Line 135: Fetches 90 days of activities
let sharedActivities = try? await UnifiedActivityService.shared
    .fetchRecentActivities(limit: 500, daysBack: 90)

// Line 433: Filters for activities with CTL/ATL
activitiesForLoad = activities.filter { $0.ctl != nil && $0.atl != nil }
```

**Root Cause:**
- Activities from UnifiedActivityService don't have CTL/ATL calculated
- Filter removes ALL activities since none have these values
- Training load chart in Trends page shows empty/missing data for last 7+ days
- TrainingLoadChart component calculates CTL/ATL, but TrendsViewModel doesn't

**Impact:** Training load trends on Trends page show no data or incomplete data

**Fix Required:** Calculate CTL/ATL in TrendsViewModel before filtering (similar to TrainingLoadChart.swift:176-231)

---

### 🟡 Architectural Issues

#### 1. Missing Training Load DetailViewModel
- **Issue:** Training Load has no dedicated ViewModel
- **Current:** Logic embedded in TrainingLoadChart component (482 lines)
- **Impact:** Inconsistent architecture, harder to test, duplicate logic
- **Solution:** Create TrainingLoadDetailViewModel following Recovery/Sleep pattern

#### 2. Monolithic Detail Views
- **Issue:** RecoveryDetailView (612 lines), SleepDetailView (871 lines)
- **Current:** Large view files with inline section logic
- **Impact:** Hard to maintain, difficult to reuse sections
- **Solution:** Extract sections into composable components

#### 3. Duplicate Trend-Fetching Logic
- **Issue:** Each ViewModel has custom Core Data queries for trends
- **Current:** RecoveryDetailViewModel, SleepDetailViewModel, TrendsViewModel all fetch trends differently
- **Impact:** Code duplication, inconsistent behavior
- **Solution:** Create BaseDetailViewModel with shared trend logic

#### 4. Inconsistent Ring Components
- **Issue:** RecoveryHeaderSection and SleepHeaderSection have separate ring implementations
- **Current:** Two different ring visualization approaches
- **Impact:** Inconsistent UI, duplicate code
- **Solution:** Create unified RingHeaderView component

#### 5. Mixed Data Fetching Patterns
- **Issue:** Some ViewModels use init, others use .task, others use onAppear
- **Current:** Inconsistent data loading patterns
- **Impact:** Race conditions, performance issues
- **Solution:** Standardize on .task pattern with proper lifecycle management

---

## Refactor Plan: Phases

### Phase 1: Critical Bug Fix (Priority: URGENT)
**Goal:** Fix missing training load data in Trends page
**Time Estimate:** 1-2 hours
**Risk:** Low - isolated fix

#### Tasks:
1. **Fix TrendsViewModel.loadDailyLoadTrend()**
   - Add CTL/ATL calculation before filtering
   - Reuse logic from TrainingLoadChart.swift:176-231
   - Use TrainingLoadCalculator for progressive calculations

2. **Implementation:**
   ```swift
   private func loadDailyLoadTrend(activities: [Activity]?) async {
       guard let activities = activities else { return }

       // Get FTP for TSS enrichment
       let ftp = profileManager.profile.ftp

       // Enrich activities with TSS
       let enrichedActivities = activities.map { activity in
           ActivityConverter.enrichWithMetrics(activity, ftp: ftp)
       }

       // Calculate progressive CTL/ATL
       let calculator = TrainingLoadCalculator()
       let progressiveLoad = await calculator.calculateProgressiveTrainingLoad(enrichedActivities)

       // Add CTL/ATL to activities
       let activitiesWithLoad = enrichedActivities.compactMap { activity -> Activity? in
           guard let tss = activity.tss else { return nil }

           let activityDate = parseActivityDate(activity.startDateLocal)
           let day = Calendar.current.startOfDay(for: activityDate ?? Date())
           let load = progressiveLoad[day]

           return Activity(
               // ... copy all fields
               atl: load?.atl,
               ctl: load?.ctl,
               // ...
           )
       }

       // NOW filter for activities with CTL/ATL
       activitiesForLoad = activitiesWithLoad.filter { $0.ctl != nil && $0.atl != nil }

       // Rest of existing logic...
   }
   ```

3. **Test:**
   - Verify Trends page shows training load for last 7/30/60 days
   - Check CTL/ATL values match activity detail charts
   - Confirm no performance regression

4. **Commit:**
   - `fix(trends): Calculate CTL/ATL before filtering training load data`

---

### Phase 2: Training Load DetailViewModel (Priority: HIGH)
**Goal:** Create dedicated ViewModel for Training Load to match Recovery/Sleep pattern
**Time Estimate:** 2-3 hours
**Risk:** Medium - new component with existing dependencies

#### Tasks:

1. **Create TrainingLoadDetailViewModel.swift**
   - Location: `VeloReady/Features/Shared/ViewModels/`
   - Pattern: @Observable, @MainActor, similar to RecoveryDetailViewModel
   - Dependencies: UnifiedActivityService, TrainingLoadCalculator, AthleteProfileManager

2. **ViewModel Structure:**
   ```swift
   @MainActor
   @Observable
   final class TrainingLoadDetailViewModel {
       // MARK: - Published Properties
       @Published private(set) var loadTrendData: [TrendDataPoint] = []
       @Published private(set) var activitiesWithLoad: [Activity] = []
       @Published private(set) var isLoading = false

       // MARK: - Dependencies
       private let activityService: UnifiedActivityService
       private let calculator: TrainingLoadCalculator
       private let profileManager: AthleteProfileManager
       private let persistenceController: PersistenceController

       // MARK: - Initialization
       init(
           activityService: UnifiedActivityService = .shared,
           calculator: TrainingLoadCalculator = TrainingLoadCalculator(),
           profileManager: AthleteProfileManager = .shared,
           persistenceController: PersistenceController = .shared
       ) {
           self.activityService = activityService
           self.calculator = calculator
           self.profileManager = profileManager
           self.persistenceController = persistenceController
       }

       // MARK: - Public Methods
       func loadData() async {
           isLoading = true
           await loadTrainingLoadTrend()
           isLoading = false
       }

       func getHistoricalLoadData(for period: TrendPeriod) async -> [TrendDataPoint] {
           // Similar to RecoveryDetailViewModel.getHistoricalRecoveryData
       }

       // MARK: - Private Methods
       private func loadTrainingLoadTrend() async {
           // Move logic from TrainingLoadChart component
           // Calculate CTL/ATL for activities
       }
   }
   ```

3. **Refactor TrainingLoadChart.swift**
   - Remove inline state management (@State historicalActivities, etc.)
   - Accept TrainingLoadDetailViewModel as parameter
   - Become pure view component

4. **Create TrainingLoadDetailView.swift**
   - Location: `VeloReady/Features/Today/Views/DetailViews/`
   - Use new ViewModel
   - Follow RecoveryDetailView structure

5. **Test:**
   - Verify training load calculations match previous behavior
   - Check 21-day chart still works
   - Test offline fallback with Core Data

6. **Commit:**
   - `feat(training-load): Create TrainingLoadDetailViewModel following MVVM pattern`

---

### Phase 3: Base ViewModel & Shared Logic (Priority: MEDIUM)
**Goal:** Extract common trend-fetching logic into base class
**Time Estimate:** 2-3 hours
**Risk:** Medium - affects multiple ViewModels

#### Tasks:

1. **Create BaseDetailViewModel.swift**
   - Location: `VeloReady/Features/Shared/ViewModels/`
   - Generic trend fetching from Core Data
   - Shared caching logic
   - Period selector state management

2. **Base ViewModel Structure:**
   ```swift
   @MainActor
   class BaseDetailViewModel: ObservableObject {
       // MARK: - Shared State
       @Published var selectedPeriod: TrendPeriod = .days30
       @Published var isLoading = false

       // MARK: - Dependencies
       let persistenceController: PersistenceController

       init(persistenceController: PersistenceController = .shared) {
           self.persistenceController = persistenceController
       }

       // MARK: - Shared Methods
       func fetchTrendData<T: NSManagedObject>(
           entityName: String,
           keyPath: String,
           period: TrendPeriod,
           transform: (T) -> TrendDataPoint?
       ) async -> [TrendDataPoint] {
           // Generic Core Data fetch with deduplication
       }

       func deduplicate<T>(_ items: [T], by keyPath: KeyPath<T, Date>) -> [T] {
           // Shared deduplication logic
       }
   }
   ```

3. **Refactor ViewModels to Inherit:**
   - RecoveryDetailViewModel extends BaseDetailViewModel
   - SleepDetailViewModel extends BaseDetailViewModel
   - TrainingLoadDetailViewModel extends BaseDetailViewModel

4. **Remove Duplicate Code:**
   - Core Data fetch logic
   - Deduplication logic
   - Period filtering logic

5. **Test:**
   - Verify all three detail pages still work
   - Check trend data is identical to before refactor
   - Confirm no performance regression

6. **Commit:**
   - `refactor(viewmodels): Create BaseDetailViewModel with shared trend logic`

---

### Phase 4: Unified Components (Priority: MEDIUM)
**Goal:** Create reusable components following Today page atomic pattern
**Time Estimate:** 3-4 hours
**Risk:** Medium - UI changes require careful testing

#### Tasks:

1. **Create RingHeaderView.swift**
   - Location: `VeloReady/Features/Shared/Views/Components/`
   - Unified ring visualization for all detail pages
   - Configurable ring style (recovery, sleep, load)
   - Supports band descriptions, score text

2. **Component Structure:**
   ```swift
   struct RingHeaderView: View {
       let score: Double
       let maxScore: Double
       let band: ScoreBand
       let title: String
       let subtitle: String?
       let ringStyle: RingStyle

       enum RingStyle {
           case recovery
           case sleep
           case load
       }

       var body: some View {
           VStack(spacing: Spacing.lg) {
               // Ring visualization
               RingView(
                   score: score,
                   maxScore: maxScore,
                   color: band.color,
                   style: ringStyle
               )

               // Score text
               VStack(spacing: Spacing.xs) {
                   VRText(title, style: .largeTitle)
                   if let subtitle = subtitle {
                       VRText(subtitle, style: .body, color: Color.text.secondary)
                   }
               }

               // Band description
               BandDescriptionView(band: band)
           }
           .padding(Spacing.lg)
       }
   }
   ```

3. **Create DetailPageTemplate.swift**
   - Consistent structure for all detail pages
   - ScrollView with RefreshControl
   - Standard section spacing
   - Pro feature gate integration

4. **Template Structure:**
   ```swift
   struct DetailPageTemplate<Header: View, Content: View>: View {
       let title: String
       let header: () -> Header
       let content: () -> Content
       let onRefresh: () async -> Void

       var body: some View {
           ScrollView {
               VStack(spacing: Spacing.xl) {
                   // Header section (ring)
                   header()

                   // Content sections
                   content()
               }
               .padding(Spacing.md)
           }
           .navigationTitle(title)
           .refreshable {
               await onRefresh()
           }
       }
   }
   ```

5. **Extract Section Components:**
   - `MetricGridSection` - 2x2 or 4-column metric layout
   - `TrendChartSection` - Reusable trend chart with period selector
   - `CandlestickChartSection` - HRV/RHR chart wrapper
   - `DebtSection` - Sleep/recovery debt card
   - `RecommendationsSection` - Dynamic recommendations list

6. **Refactor RecoveryHeaderSection:**
   - Use new RingHeaderView
   - Remove duplicate code
   - Keep recovery-specific logic

7. **Refactor SleepHeaderSection:**
   - Use new RingHeaderView
   - Remove duplicate code
   - Keep sleep-specific logic

8. **Test:**
   - Visual regression testing on all detail pages
   - Check dark mode support
   - Verify accessibility (VoiceOver)

9. **Commit:**
   - `refactor(components): Create unified RingHeaderView and DetailPageTemplate`

---

### Phase 5: View Refactoring (Priority: LOW)
**Goal:** Break down monolithic views into smaller, composable sections
**Time Estimate:** 4-5 hours
**Risk:** High - extensive changes to view hierarchy

#### Tasks:

1. **Refactor RecoveryDetailView (612 lines → ~300 lines)**
   - Extract inline sections into separate files
   - Use DetailPageTemplate
   - Use RingHeaderView for header
   - Extract:
     - `RecoveryFactorsSection.swift`
     - `RecoverySubScoresSection.swift`
     - `RecoveryDebtSection.swift`
     - `RecoveryReadinessSection.swift`
     - `RecoveryResilienceSection.swift`
     - `AppleHealthMetricsSection.swift`

2. **Refactor SleepDetailView (871 lines → ~350 lines)**
   - Extract inline sections into separate files
   - Use DetailPageTemplate
   - Use RingHeaderView for header
   - Extract:
     - `SleepScoreBreakdownSection.swift`
     - `SleepHypnogramSection.swift`
     - `SleepMetricsGridSection.swift`
     - `SleepStagesSection.swift`
     - `SleepDebtSection.swift`
     - `SleepConsistencySection.swift`
     - `SleepRecommendationsSection.swift`

3. **Create TrainingLoadDetailView (new, ~250 lines)**
   - Use DetailPageTemplate
   - Header: Current CTL/ATL/TSB metrics
   - Sections:
     - `TrainingLoadSummarySection.swift` - CTL/ATL/TSB cards
     - `TrainingLoadTrendSection.swift` - 7/30/60 day chart
     - `TrainingLoad21DaySection.swift` - Detailed 21-day projection
     - `TrainingPhaseSection.swift` - Current phase detection
     - `OvertrainingRiskSection.swift` - Risk assessment

4. **Standardize Section Pattern:**
   ```swift
   struct [Page][Feature]Section: View {
       let data: SectionData

       var body: some View {
           VStack(alignment: .leading, spacing: Spacing.md) {
               // Section header
               SectionHeader(title: "Section Title")

               // Section content
               StandardCard {
                   // Content using atomic components
               }
           }
       }
   }
   ```

5. **Test:**
   - Full regression testing on all three pages
   - Check scroll performance
   - Verify section visibility
   - Test Pro feature gates

6. **Commit (3 separate commits):**
   - `refactor(recovery): Extract RecoveryDetailView sections into components`
   - `refactor(sleep): Extract SleepDetailView sections into components`
   - `feat(training-load): Create TrainingLoadDetailView with section components`

---

### Phase 6: Standardize Mini-Charts (Priority: LOW)
**Goal:** Replace inline mini-charts with TrendChart component
**Time Estimate:** 1-2 hours
**Risk:** Low - cosmetic improvements

#### Tasks:

1. **Replace Sleep Debt Mini-Chart**
   - Current: Inline bar chart in SleepDetailView
   - Replace with: TrendChart component (bar style, 7-day period)
   - Benefits: Consistent styling, reusable code

2. **Replace Sleep Consistency Mini-Chart**
   - Current: Inline bar chart in SleepDetailView
   - Replace with: TrendChart component (bar style, 7-day period)

3. **Standardize TrendChart API:**
   - Ensure consistent period selector behavior
   - Standardize data format (TrendDataPoint)
   - Add 7-day option if missing

4. **Test:**
   - Verify visual consistency
   - Check animation behavior
   - Test period switching

5. **Commit:**
   - `refactor(charts): Replace inline mini-charts with TrendChart component`

---

## Testing Strategy

### Unit Tests
- **TrainingLoadDetailViewModel**
  - Test CTL/ATL calculation accuracy
  - Test progressive load calculations
  - Test error handling for missing data

- **BaseDetailViewModel**
  - Test generic fetch logic
  - Test deduplication
  - Test period filtering

### Integration Tests
- **TrendsViewModel Bug Fix**
  - Test with 0, 7, 30, 60, 90 days of activities
  - Verify CTL/ATL values match TrainingLoadChart
  - Test offline fallback

### UI Tests
- **Detail Pages**
  - Test navigation to/from Today page
  - Test pull-to-refresh
  - Test period selector changes
  - Test Pro feature gates

### Performance Tests
- **Load Times**
  - Measure initial page load (target: <500ms)
  - Measure data refresh (target: <1s)
  - Check memory usage with large datasets

### Regression Tests
- **Visual Regression**
  - Screenshot comparison for all detail pages
  - Check light/dark mode
  - Verify layout on different screen sizes

---

## Execution Plan

### Recommended Approach: Phased Execution

**Tonight (Before Morning):**
1. ✅ Complete Phase 1 (Critical Bug Fix) - ~1-2 hours
2. ✅ Complete Phase 2 (TrainingLoadDetailViewModel) - ~2-3 hours
3. ✅ Test and commit both phases
4. 📝 Document remaining phases for future work

**Future Work (Next Session):**
1. Phase 3 (Base ViewModel) - ~2-3 hours
2. Phase 4 (Unified Components) - ~3-4 hours
3. Phase 5 (View Refactoring) - ~4-5 hours
4. Phase 6 (Mini-Charts) - ~1-2 hours

**Total Time Estimate:** 13-19 hours (full refactor)

### Risk Mitigation

**Rollback Plan:**
- Each phase is a separate commit
- Can revert individual phases without losing work
- Branch can be merged incrementally

**Testing Between Phases:**
- Run quick-test after each phase
- Manually test affected pages
- Check for compilation errors

**Code Review Checkpoints:**
- After Phase 1 (critical fix)
- After Phase 2 (new ViewModel)
- After Phase 4 (UI changes)

---

## Success Criteria

### Phase 1 Complete When:
- ✅ Training load data appears in Trends page for last 7/30/60 days
- ✅ CTL/ATL values match activity detail charts
- ✅ Tests pass
- ✅ No performance regression

### Phase 2 Complete When:
- ✅ TrainingLoadDetailViewModel matches Recovery/Sleep pattern
- ✅ TrainingLoadChart uses new ViewModel
- ✅ Tests pass
- ✅ Behavior identical to before refactor

### Full Refactor Complete When:
- ✅ All three detail pages use consistent architecture
- ✅ Code duplication reduced by 50%+
- ✅ Component reuse increased
- ✅ All tests passing
- ✅ No visual regressions
- ✅ Performance maintained or improved

---

## Dependencies & Blockers

### External Dependencies:
- None - all work is internal refactoring

### Internal Dependencies:
- Phase 2 can start immediately after Phase 1
- Phase 3 should wait for Phase 2 completion
- Phase 4 can run parallel to Phase 3
- Phase 5 requires Phase 4 completion
- Phase 6 requires Phase 5 completion

### Potential Blockers:
- TrainingLoadCalculator performance issues (if dataset is large)
- Core Data schema changes (if required for new features)
- Pro feature gate changes (if business logic changes)

---

## Documentation Updates

### Code Documentation:
- Add header comments to all new ViewModels
- Document BaseDetailViewModel inheritance pattern
- Add examples for DetailPageTemplate usage
- Document RingHeaderView customization options

### Architecture Documentation:
- Update MASTER_ARCHITECTURE_PLAN.md
- Create DETAIL_PAGES_ARCHITECTURE.md
- Document component hierarchy
- Add sequence diagrams for data flow

### User-Facing Documentation:
- None required - internal refactor only

---

## Future Enhancements (Out of Scope)

1. **Training Load Forecasting**
   - Predict future CTL/ATL based on planned workouts
   - Show "what-if" scenarios

2. **Cross-Page Correlations**
   - Recovery vs Training Load
   - Sleep vs Performance
   - HRV vs Strain

3. **Advanced Analytics**
   - Training stress balance zones
   - Optimal TSB ranges per athlete
   - Periodization recommendations

4. **Offline Mode Improvements**
   - Pre-cache trend data
   - Smarter offline fallbacks
   - Background sync

---

## Appendix

### File Inventory

**Views to Refactor:**
- RecoveryDetailView.swift (612 lines)
- SleepDetailView.swift (871 lines)

**Views to Create:**
- TrainingLoadDetailView.swift (new)

**ViewModels to Create:**
- TrainingLoadDetailViewModel.swift (new)
- BaseDetailViewModel.swift (new)

**ViewModels to Refactor:**
- RecoveryDetailViewModel.swift
- SleepDetailViewModel.swift
- TrendsViewModel.swift (bug fix)

**Components to Create:**
- RingHeaderView.swift (new)
- DetailPageTemplate.swift (new)
- Various section components (10+ files)

**Components to Refactor:**
- TrainingLoadChart.swift
- RecoveryHeaderSection.swift
- SleepHeaderSection.swift

### Estimated Line Count Changes

| File | Before | After | Delta |
|------|--------|-------|-------|
| RecoveryDetailView.swift | 612 | ~300 | -312 |
| SleepDetailView.swift | 871 | ~350 | -521 |
| TrainingLoadChart.swift | 482 | ~200 | -282 |
| New components | 0 | ~2000 | +2000 |
| **Net Change** | **1965** | **2850** | **+885** |

*Net increase due to better organization and reusability, not code duplication*

---

## Approval & Sign-Off

**Prepared By:** Claude Code
**Date:** 2025-11-19
**Status:** Awaiting approval for execution

**Approval Required From:** Mark Boulton

**Decision:**
- [ ] A) Proceed with Phase 1 & 2 tonight (critical fix + ViewModel)
- [ ] B) Attempt full refactor tonight (high risk)
- [ ] C) Phase 1 only, defer rest

---

*This document will be updated as work progresses. Each phase completion will be marked with checkboxes and commit SHAs.*
