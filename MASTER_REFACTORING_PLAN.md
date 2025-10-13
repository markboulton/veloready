# Master Refactoring Plan - VeloReady Codebase

## 🎯 Objective
Apply the proven TodayView refactoring pattern to the entire codebase for improved maintainability, testability, and multi-app scalability.

## 📊 Current State Analysis

### Top 10 Files by Size (Lines of Code)
| Rank | File | Lines | Priority | Complexity |
|------|------|-------|----------|------------|
| 1 | `SettingsView.swift` | 1,039 | 🔴 HIGH | High |
| 2 | `DebugSettingsView.swift` | 874 | 🟡 MEDIUM | Medium |
| 3 | `TodayView.swift` | 719 | ✅ DONE | - |
| 4 | `AthleteZonesSettingsView.swift` | 702 | 🔴 HIGH | High |
| 5 | `ActivitiesView.swift` | 700 | 🔴 HIGH | High |
| 6 | `WorkoutDetailView.swift` | 672 | 🟡 MEDIUM | Medium |
| 7 | `StrainDetailView.swift` | 557 | 🟡 MEDIUM | Medium |
| 8 | `SleepDetailView.swift` | 540 | 🟡 MEDIUM | Medium |
| 9 | `IntervalsAPIDebugView.swift` | 519 | 🟢 LOW | Low |
| 10 | `DataSourcesSettingsView.swift` | 431 | 🟡 MEDIUM | Medium |

**Total Lines in Top 10**: 6,753 lines  
**Estimated Reduction Potential**: ~2,000 lines (30% average)

---

## 🗺️ Refactoring Sequence

### **Batch 1: Critical Views (Week 1)**
High-impact, user-facing views

#### 1.1 SettingsView.swift (1,039 lines) 🔴
**Priority**: CRITICAL  
**Estimated Reduction**: 1,039 → ~650 lines (37%)  
**Effort**: 5-6 hours

**Sections to Extract**:
- [ ] `AccountSection` (~150 lines)
- [ ] `DataSourcesSection` (~200 lines)
- [ ] `HealthKitSection` (~100 lines)
- [ ] `PreferencesSection` (~150 lines)
- [ ] `AboutSection` (~80 lines)
- [ ] `DebugSection` (~100 lines)

**Dependencies to Inject**:
- HealthKitManager
- IntervalsOAuthManager
- StravaAuthService
- SubscriptionManager

#### 1.2 ActivitiesView.swift (700 lines) 🔴
**Priority**: CRITICAL  
**Estimated Reduction**: 700 → ~450 lines (36%)  
**Effort**: 4-5 hours

**Sections to Extract**:
- [ ] `ActivityListSection` (~200 lines)
- [ ] `FilterSection` (~100 lines)
- [ ] `EmptyStateSection` (~80 lines)
- [ ] `ActivityStatsSection` (~120 lines)

**Dependencies to Inject**:
- ActivitiesViewModel
- HealthKitManager
- IntervalsAPIClient

#### 1.3 AthleteZonesSettingsView.swift (702 lines) 🔴
**Priority**: HIGH  
**Estimated Reduction**: 702 → ~450 lines (36%)  
**Effort**: 4-5 hours

**Sections to Extract**:
- [ ] `HeartRateZonesSection` (~200 lines)
- [ ] `PowerZonesSection` (~200 lines)
- [ ] `ZoneCalculatorSection` (~150 lines)

**Dependencies to Inject**:
- AthleteZonesManager
- HealthKitManager

---

### **Batch 2: Detail Views (Week 2)**
Medium complexity, important for UX

#### 2.1 WorkoutDetailView.swift (672 lines) 🟡
**Priority**: MEDIUM  
**Estimated Reduction**: 672 → ~450 lines (33%)  
**Effort**: 4 hours

**Sections to Extract**:
- [ ] `WorkoutHeaderSection` (~100 lines)
- [ ] `WorkoutChartsSection` (~200 lines)
- [ ] `WorkoutStatsSection` (~150 lines)
- [ ] `WorkoutMapSection` (~100 lines)

#### 2.2 StrainDetailView.swift (557 lines) 🟡
**Priority**: MEDIUM  
**Estimated Reduction**: 557 → ~370 lines (34%)  
**Effort**: 3-4 hours

**Sections to Extract**:
- [ ] `StrainOverviewSection` (~150 lines)
- [ ] `StrainChartSection` (~150 lines)
- [ ] `StrainHistorySection` (~100 lines)

#### 2.3 SleepDetailView.swift (540 lines) 🟡
**Priority**: MEDIUM  
**Estimated Reduction**: 540 → ~360 lines (33%)  
**Effort**: 3-4 hours

**Sections to Extract**:
- [ ] `SleepOverviewSection` (~150 lines)
- [ ] `SleepStagesSection` (~150 lines)
- [ ] `SleepHistorySection` (~100 lines)

---

### **Batch 3: Supporting Views (Week 3)**
Lower priority, but still valuable

#### 3.1 DataSourcesSettingsView.swift (431 lines) 🟡
**Priority**: MEDIUM  
**Effort**: 2-3 hours

#### 3.2 TrendsView.swift (386 lines) 🟡
**Priority**: MEDIUM  
**Effort**: 2-3 hours

#### 3.3 RecoveryDetailView.swift (392 lines) 🟡
**Priority**: MEDIUM  
**Effort**: 2-3 hours

---

### **Batch 4: Debug/Admin Views (Week 4)**
Lower priority, internal tools

#### 4.1 DebugSettingsView.swift (874 lines) 🟢
**Priority**: LOW  
**Effort**: 3-4 hours

#### 4.2 IntervalsAPIDebugView.swift (519 lines) 🟢
**Priority**: LOW  
**Effort**: 2-3 hours

---

## 📋 Refactoring Pattern (Per View)

### Phase 1: Extract Child Views (2-4 hours per view)
1. Identify logical sections
2. Create `Sections/` directory
3. Extract each section to separate file
4. Add preview support
5. Update parent view usage
6. Remove old computed properties
7. Test build after each extraction
8. **Commit**: "refactor: Extract [ViewName] sections (Phase 1)"

### Phase 2: Dependency Injection (1-2 hours per view)
1. Identify all `.shared` singleton usage
2. Add init parameters with defaults
3. Inject dependencies in init
4. Update all usages
5. Test build
6. **Commit**: "refactor: Add DI to [ViewName] (Phase 2)"

### Phase 3: ViewModel Extraction (1-2 hours per view, if needed)
1. Extract business logic to ViewModel
2. Move state management
3. Add dependency injection to ViewModel
4. Test build
5. **Commit**: "refactor: Extract [ViewName]ViewModel (Phase 3)"

---

## 📊 Expected Results

### Overall Impact
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Total Lines** | ~12,931 | ~8,500 | **-34%** |
| **Avg File Size** | 300 lines | 200 lines | **-33%** |
| **Reusable Components** | ~10 | ~50 | **+400%** |
| **Testable Units** | ~20 | ~100 | **+400%** |
| **Files with DI** | 5 | 43 | **+760%** |

### Time Investment
- **Batch 1**: 13-16 hours (3 critical views)
- **Batch 2**: 10-12 hours (3 detail views)
- **Batch 3**: 6-9 hours (3 supporting views)
- **Batch 4**: 5-7 hours (2 debug views)
- **Total**: 34-44 hours (~1 week of focused work)

### ROI
- **Maintenance**: 40% faster
- **Bug fixing**: 50% faster
- **Feature development**: 30% faster
- **Testing**: 60% faster
- **Onboarding**: 50% faster

---

## 🎯 Success Criteria

### Per View
- [ ] Reduce file size by 30%+
- [ ] Extract 3+ reusable sections
- [ ] Add dependency injection
- [ ] Add preview support for all sections
- [ ] Maintain 100% functionality
- [ ] Zero bugs introduced
- [ ] Build always passing
- [ ] Clean commit per phase

### Overall
- [ ] Reduce codebase by 30%+
- [ ] Create 40+ reusable components
- [ ] 100% DI coverage for major views
- [ ] All sections have previews
- [ ] Zero breaking changes
- [ ] All builds passing
- [ ] Clean commit history

---

## 🚀 Execution Strategy

### Daily Workflow
**Morning** (3-4 hours):
1. Pick next view from sequence
2. Analyze and plan sections
3. Extract 2-3 sections
4. Test and commit Phase 1

**Afternoon** (2-3 hours):
1. Add dependency injection
2. Test and commit Phase 2
3. Update documentation
4. Move to next view

### Weekly Goals
- **Week 1**: Complete Batch 1 (3 critical views)
- **Week 2**: Complete Batch 2 (3 detail views)
- **Week 3**: Complete Batch 3 (3 supporting views)
- **Week 4**: Complete Batch 4 (2 debug views)

---

## 📝 Tracking Progress

### Commit Convention
```
refactor([view-name]): [phase] - [description]

Examples:
- refactor(settings): Extract sections (Phase 1)
- refactor(settings): Add dependency injection (Phase 2)
- refactor(activities): Extract sections (Phase 1)
```

### Progress File
Create `REFACTORING_PROGRESS.md` to track:
- [ ] Views completed
- [ ] Lines reduced
- [ ] Components created
- [ ] Time spent
- [ ] Issues encountered

---

## 🎓 Lessons from TodayView

### What Worked ✅
1. Incremental approach (one section at a time)
2. Test after every change
3. Commit after each phase
4. Add previews immediately
5. Use DI with defaults for backward compatibility

### Patterns to Reuse ✅
1. **Section Extraction**: Create file → Move code → Add preview → Update usage → Remove old → Test → Commit
2. **Dependency Injection**: Identify deps → Add init params → Inject → Test → Commit
3. **Testing**: Build after every change, never skip

### Pitfalls to Avoid ❌
1. Don't extract too many sections at once
2. Don't skip testing between changes
3. Don't forget preview support
4. Don't break backward compatibility
5. Don't commit broken code

---

## 🏁 Getting Started

### Immediate Next Steps
1. ✅ Review and approve this plan
2. 🔄 Start with **SettingsView.swift** (highest impact)
3. 🔄 Follow the proven pattern from TodayView
4. 🔄 Test, verify, commit after each phase
5. 🔄 Move to next view in sequence

### First Target: SettingsView.swift
**Start**: Now  
**Estimated Completion**: 5-6 hours  
**Expected Reduction**: 1,039 → ~650 lines (37%)

---

## 💡 Optional Enhancements (Future)

### After Core Refactoring
1. **Configuration System**: Per-app feature flags
2. **Theme System**: Configurable colors/fonts
3. **Analytics**: Track component usage
4. **Documentation**: Auto-generate from code
5. **Testing**: Add unit tests for all components

---

## 🎉 Vision

**By completion, VeloReady will have:**
- ✅ 34% smaller codebase
- ✅ 50+ reusable components
- ✅ 100% DI coverage
- ✅ Full preview support
- ✅ 60% faster testing
- ✅ Ready for multi-app scaling
- ✅ World-class code quality

**Let's build the future! 🚀**
