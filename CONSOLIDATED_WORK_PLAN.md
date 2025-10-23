# Consolidated Work Plan: Complete MVVM + Atomic Design

**Date:** October 23, 2025, 8:00pm UTC+01:00  
**Goal:** Achieve 100% app-wide MVVM architecture + complete atomic design system  
**Estimated Total Time:** 4-6 hours

---

## 📊 Current Status

### ✅ What's Complete (78% Done)

**Phase 2/3: Atomic Components**
- ✅ 28 pure UI components created
- ✅ Trends section: 100% using ChartCard
- ✅ Today section cards: 100% using atomic wrappers
- ⚠️ Activity detail charts: NOT using ChartCard (5 charts)

**Phase 4: ViewModels**
- ✅ Today Cards: 4 ViewModels (~350 lines)
- ✅ Today Details: 7 ViewModels (~2,200 lines)
- ❌ Trends Cards: 0 ViewModels (11 needed)

**Overall Progress:** 78% complete

---

## 🎯 Remaining Work (22%)

### 1. Activity Detail Charts (Phase 2/3 Completion)
**5 charts, ~1,595 lines → ~1,270 lines after refactor**
- IntensityChart.swift
- TrainingLoadChart.swift
- ZonePieChartSection.swift
- WorkoutChartsSection
- HeartRateChart

### 2. Trends Card ViewModels (Phase 4D)
**11 cards, ~2,460 lines → extract ~800-1,000 lines to ViewModels**
- PerformanceOverviewCardV2
- RecoveryVsPowerCardV2
- TrainingPhaseCardV2
- OvertrainingRiskCardV2
- WeeklyTSSTrendCardV2
- RestingHRCardV2
- RecoveryTrendCardV2
- StressLevelCardV2
- TrainingLoadTrendCardV2
- FTPTrendCardV2
- HRVTrendCardV2

---

## 📋 Phased Work Plan

### **PHASE A: Activity Chart Refactoring** (1-2 hours)
**Priority:** HIGH - Completes Phase 2/3 atomic design  
**Impact:** UI consistency across entire app

#### A1: IntensityChart.swift (30 min)
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header (HStack + Text)
- [ ] Use design tokens (Spacing.md)
- [ ] Test with Pro/Free users
- [ ] Verify IF gauge still works
- [ ] Verify TSS display correct

**Before (239 lines):**
```swift
VStack(alignment: .leading, spacing: 16) {
    HStack(spacing: 8) {
        Text(TrainingLoadContent.Metrics.rideIntensity)
            .font(.headline)
            .fontWeight(.semibold)
        Spacer()
    }
    // Chart content...
}
```

**After (~190 lines):**
```swift
ChartCard(
    title: TrainingLoadContent.Metrics.rideIntensity,
    subtitle: "Intensity Factor and TSS analysis"
) {
    // Chart content only
}
```

#### A2: TrainingLoadChart.swift (30 min)
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header
- [ ] Use design tokens
- [ ] Ensure CTL/ATL/TSB legend works
- [ ] Test 21-day trend display
- [ ] Verify Pro gate

**Reduction:** 600 → ~520 lines

#### A3: ZonePieChartSection.swift (40 min)
- [ ] Split into two ChartCard instances
  - HR Zone ChartCard
  - Power Zone ChartCard
- [ ] Remove nested VStack layouts
- [ ] Use design tokens
- [ ] Test Pro upgrade CTA placement
- [ ] Test with/without power data
- [ ] Verify adaptive vs static zones

**Reduction:** 456 → ~340 lines

#### A4: WorkoutChartsSection (20 min)
- [ ] Wrap Power chart in ChartCard
- [ ] Wrap HR chart in ChartCard
- [ ] Wrap Speed chart in ChartCard
- [ ] Wrap Cadence chart in ChartCard
- [ ] Remove manual headers
- [ ] Use design tokens
- [ ] Test with various data combinations

**Reduction:** ~200 → ~150 lines

#### A5: HeartRateChart (WalkingDetailView) (20 min)
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header
- [ ] Use design tokens
- [ ] Test with walking workouts
- [ ] Verify heart rate zones display

**Reduction:** ~100 → ~70 lines

#### A6: Testing & Validation (20 min)
- [ ] Test RideDetailSheet with all charts
- [ ] Test WalkingDetailView
- [ ] Test WorkoutDetailView
- [ ] Verify Pro features still gated
- [ ] Check UI consistency with Trends section
- [ ] Build and run on device

**Total Phase A:** 2.5 hours  
**Code Reduction:** ~325 lines (20%)  
**Outcome:** 100% atomic design consistency

---

### **PHASE B: Trends Card ViewModels** (2-3 hours)
**Priority:** HIGH - Completes Phase 4 MVVM  
**Impact:** All business logic testable

#### B1: Top Priority Cards (1.5 hours)

**B1.1: PerformanceOverviewCardViewModel (30 min)**
- [ ] Create ViewModel file
- [ ] Extract `generateInsight()` logic
- [ ] Extract trend calculation logic
- [ ] Move data processing from view
- [ ] Update PerformanceOverviewCardV2 to use ViewModel
- [ ] Test with 7/14/30 day ranges

**Logic to Extract:**
```swift
// From view to ViewModel
private func generateInsight() -> String {
    // Complex insight generation logic
}
private func calculateTrends() -> TrendData {
    // Trend calculation logic
}
```

**B1.2: RecoveryVsPowerCardViewModel (30 min)**
- [ ] Create ViewModel file
- [ ] Extract `calculateCorrelation()` logic
- [ ] Extract scatter plot data processing
- [ ] Move statistical calculations
- [ ] Update RecoveryVsPowerCardV2 to use ViewModel
- [ ] Test correlation calculations

**B1.3: TrainingPhaseCardViewModel (30 min)**
- [ ] Create ViewModel file
- [ ] Extract phase detection logic
- [ ] Extract TSB calculations
- [ ] Move phase recommendation logic
- [ ] Update TrainingPhaseCardV2 to use ViewModel
- [ ] Test phase transitions

**B1.4: OvertrainingRiskCardViewModel (30 min)**
- [ ] Create ViewModel file
- [ ] Extract risk calculation logic
- [ ] Extract multi-metric analysis
- [ ] Move warning threshold logic
- [ ] Update OvertrainingRiskCardV2 to use ViewModel
- [ ] Test risk levels

#### B2: Medium Priority Cards (1 hour)

**B2.1: WeeklyTSSTrendCardViewModel (15 min)**
- [ ] Create ViewModel file
- [ ] Extract TSS aggregation logic
- [ ] Extract weekly calculations
- [ ] Update WeeklyTSSTrendCardV2 to use ViewModel

**B2.2: RestingHRCardViewModel (15 min)**
- [ ] Create ViewModel file
- [ ] Extract RHR trend analysis
- [ ] Extract baseline calculations
- [ ] Update RestingHRCardV2 to use ViewModel

**B2.3: RecoveryTrendCardViewModel (15 min)**
- [ ] Create ViewModel file
- [ ] Extract recovery trend analysis
- [ ] Extract pattern detection
- [ ] Update RecoveryTrendCardV2 to use ViewModel

**B2.4: StressLevelCardViewModel (15 min)**
- [ ] Create ViewModel file
- [ ] Extract stress calculation logic
- [ ] Extract threshold analysis
- [ ] Update StressLevelCardV2 to use ViewModel

#### B3: Lower Priority Cards (30 min)

**B3.1: TrainingLoadTrendCardViewModel (10 min)**
- [ ] Create ViewModel file
- [ ] Extract load analysis logic
- [ ] Update TrainingLoadTrendCardV2 to use ViewModel

**B3.2: FTPTrendCardViewModel (10 min)**
- [ ] Create ViewModel file
- [ ] Extract FTP analysis logic
- [ ] Update FTPTrendCardV2 to use ViewModel

**B3.3: HRVTrendCardViewModel (10 min)**
- [ ] Create ViewModel file
- [ ] Extract HRV analysis logic
- [ ] Update HRVTrendCardV2 to use ViewModel

#### B4: Testing & Validation (30 min)
- [ ] Test all 11 Trends cards
- [ ] Verify data fetching works
- [ ] Check Pro feature gates
- [ ] Test time range switching
- [ ] Verify insights/calculations correct
- [ ] Build and run on device

**Total Phase B:** 3 hours  
**ViewModels Created:** 11  
**Logic Extracted:** ~800-1,000 lines  
**Outcome:** 100% MVVM coverage

---

### **PHASE C: Documentation & Cleanup** (30 min)
**Priority:** MEDIUM - Ensure maintainability

#### C1: Update Documentation (15 min)
- [ ] Update PHASE_2_3_4_COMPLETE_AUDIT.md
- [ ] Create PHASE_COMPLETE_SUMMARY.md
- [ ] Document all ViewModels created
- [ ] Document atomic component usage
- [ ] Update architecture diagrams

#### C2: Code Cleanup (15 min)
- [ ] Remove any commented-out code
- [ ] Verify all imports are used
- [ ] Check for any TODOs
- [ ] Ensure consistent formatting
- [ ] Run SwiftLint (if available)

**Total Phase C:** 30 min

---

## 📊 Detailed Breakdown by Priority

### Priority 1: Must Have (Critical Path)
1. **Activity Chart Refactoring** (Phase A) - 2.5 hours
   - Completes atomic design system
   - Achieves UI consistency
   - Required for professional polish

2. **Top 4 Trends ViewModels** (Phase B1) - 1.5 hours
   - PerformanceOverviewCardViewModel
   - RecoveryVsPowerCardViewModel
   - TrainingPhaseCardViewModel
   - OvertrainingRiskCardViewModel
   - These are the largest/most complex

### Priority 2: Should Have (High Value)
3. **Medium Trends ViewModels** (Phase B2) - 1 hour
   - WeeklyTSSTrendCardViewModel
   - RestingHRCardViewModel
   - RecoveryTrendCardViewModel
   - StressLevelCardViewModel

### Priority 3: Nice to Have (Completeness)
4. **Remaining Trends ViewModels** (Phase B3) - 30 min
   - TrainingLoadTrendCardViewModel
   - FTPTrendCardViewModel
   - HRVTrendCardViewModel

5. **Documentation** (Phase C) - 30 min

---

## ⏱️ Time Estimates

### Minimum Viable (Priority 1 Only)
- Phase A: 2.5 hours
- Phase B1: 1.5 hours
- **Total:** 4 hours
- **Coverage:** 85%

### Recommended (Priority 1 + 2)
- Phase A: 2.5 hours
- Phase B1: 1.5 hours
- Phase B2: 1 hour
- **Total:** 5 hours
- **Coverage:** 95%

### Complete (All Priorities)
- Phase A: 2.5 hours
- Phase B: 3 hours
- Phase C: 30 min
- **Total:** 6 hours
- **Coverage:** 100%

---

## 🎯 Success Criteria

### Phase A Complete When:
- ✅ All 5 activity charts use ChartCard
- ✅ No manual VStack layouts in charts
- ✅ All using design tokens
- ✅ UI consistent with Trends section
- ✅ All tests pass
- ✅ Build succeeds

### Phase B Complete When:
- ✅ All 11 Trends cards have ViewModels
- ✅ All business logic extracted from views
- ✅ Views are pure UI
- ✅ All calculations testable
- ✅ All tests pass
- ✅ Build succeeds

### Overall Complete When:
- ✅ 100% atomic design consistency
- ✅ 100% MVVM coverage
- ✅ All business logic testable
- ✅ Documentation updated
- ✅ No regressions
- ✅ Professional code quality

---

## 📋 Execution Strategy

### Session 1: Activity Charts (2.5 hours)
**Focus:** Complete Phase A in one session
1. Start with IntensityChart (easiest)
2. Do TrainingLoadChart (most complex)
3. Do ZonePieChartSection (needs splitting)
4. Do WorkoutChartsSection (multiple charts)
5. Do HeartRateChart (simplest)
6. Test everything

**Commit after each chart:**
```
Phase A: IntensityChart migrated to ChartCard
Phase A: TrainingLoadChart migrated to ChartCard
Phase A: ZonePieChartSection migrated to ChartCard
Phase A: WorkoutChartsSection migrated to ChartCard
Phase A: HeartRateChart migrated to ChartCard
Phase A: COMPLETE - All activity charts use atomic wrappers
```

### Session 2: Trends ViewModels (3 hours)
**Focus:** Complete Phase B in one session
1. Do top 4 cards first (most complex)
2. Do medium 4 cards next
3. Do remaining 3 cards
4. Test everything

**Commit after each ViewModel:**
```
Phase B: PerformanceOverviewCardViewModel created
Phase B: RecoveryVsPowerCardViewModel created
... (continue for all 11)
Phase B: COMPLETE - All Trends cards have ViewModels
```

### Session 3: Documentation (30 min)
**Focus:** Complete Phase C
1. Update all documentation
2. Final cleanup
3. Create summary

**Final commit:**
```
Phase C: COMPLETE - Documentation and cleanup done
ARCHITECTURE COMPLETE: 100% MVVM + Atomic Design! 🎉
```

---

## 🚀 Let's Get Started!

### Immediate Next Steps

**Ready to start Phase A?**

I'll help you refactor the activity charts one by one:

1. **IntensityChart.swift** (30 min)
   - Simplest to start with
   - Good warm-up
   - Clear pattern to follow

2. **TrainingLoadChart.swift** (30 min)
   - Most complex
   - Good learning experience
   - Sets pattern for others

3. **Continue through remaining charts**

**Should we start with IntensityChart.swift?**

---

## 📊 Progress Tracking

### Phase A: Activity Charts
- [ ] IntensityChart.swift
- [ ] TrainingLoadChart.swift
- [ ] ZonePieChartSection.swift
- [ ] WorkoutChartsSection
- [ ] HeartRateChart
- [ ] Testing & Validation

### Phase B: Trends ViewModels
- [ ] PerformanceOverviewCardViewModel
- [ ] RecoveryVsPowerCardViewModel
- [ ] TrainingPhaseCardViewModel
- [ ] OvertrainingRiskCardViewModel
- [ ] WeeklyTSSTrendCardViewModel
- [ ] RestingHRCardViewModel
- [ ] RecoveryTrendCardViewModel
- [ ] StressLevelCardViewModel
- [ ] TrainingLoadTrendCardViewModel
- [ ] FTPTrendCardViewModel
- [ ] HRVTrendCardViewModel
- [ ] Testing & Validation

### Phase C: Documentation
- [ ] Update documentation
- [ ] Code cleanup
- [ ] Final summary

---

**Total Remaining:** 16 tasks  
**Estimated Time:** 4-6 hours  
**Let's do this! 🚀**
