# VeloReady iOS - Large-Scale Refactor Plan
**Date:** November 6, 2025  
**Status:** 🔴 Planning Phase  
**Branch:** `large-refactor` (already created)  
**Estimated Duration:** 3-4 weeks  

---

## Executive Summary

The VeloReady iOS codebase has grown significantly over the past 2 weeks. This refactor addresses **5 critical areas**:

1. **Cache System Consolidation** - Eliminate 4 redundant cache implementations
2. **Code Efficiency & Architecture** - Break down monolithic files, optimize services
3. **Content & Design System Cleanup** - Ensure 100% adherence post-Phase 3 migration
4. **Debug Section Overhaul** - Complete reorganization and modernization
5. **Dead Code Elimination** - Remove unused files, TODOs, and technical debt

**Current Metrics:**
- **Total Lines:** 88,882 lines of Swift code
- **Services:** 28 separate service classes
- **Managers:** 13 manager classes
- **Cache Systems:** 5 different implementations (target: 1)
- **TODOs/FIXMEs:** 48 technical debt markers
- **Largest Files:** 7 files over 900 lines (HealthKitManager: 1669 lines)

---

## Critical Issues Identified

### 🔴 Priority 1: Cache System Chaos

**Problem:** 5 separate cache implementations with overlapping responsibilities:

| System | Lines | Purpose | Status |
|--------|-------|---------|--------|
| `UnifiedCacheManager` | 1250 | Actor-based unified cache | ✅ Best architecture |
| `CacheManager` | 769 | Legacy Core Data cache | ⚠️ Redundant |
| `StreamCacheService` | 364 | Strava/Intervals streams | ⚠️ Can be unified |
| `IntervalsCache` | 243 | Intervals.icu API cache | ⚠️ Can be unified |
| `HealthKitCache` | 79 | Apple Health cache | ⚠️ Can be unified |

**Impact:**
- Multiple cache key formats causing cache misses
- Inconsistent TTL strategies (1h, 4h, 7d)
- 3 different persistence layers (memory, UserDefaults, Core Data)
- ~40% of cache-related bugs traced to fragmentation

**Root Cause:** UnifiedCacheManager was created but old systems never removed.

---

### 🟡 Priority 2: Monolithic Files

**Problem:** 7 files exceed 900 lines:

| File | Lines | Issue |
|------|-------|-------|
| `HealthKitManager.swift` | 1669 | Too many responsibilities |
| `DebugSettingsView.swift` | 1288 | Massive debug file |
| `UnifiedCacheManager.swift` | 1250 | Could be split |
| `WeeklyReportViewModel.swift` | 1131 | Complex business logic |
| `IntervalsAPIClient.swift` | 1097 | All API calls in one file |
| `RecoveryScoreService.swift` | 1084 | Scoring + calculations |
| `TodayViewModel.swift` | 939 | Manages entire Today view |

**Impact:** Slow navigation, merge conflicts, hard to test

---

### 🟡 Priority 3: Debug Section Disaster

**Issues:**
- `DebugDashboardView.swift` is empty (0 bytes) - **dead file**
- `DebugSettingsView.swift` is 1288 lines - monolithic
- Not using design system (hard-coded strings)
- No clear organization by feature area

---

### 🟢 Priority 4: Technical Debt

48 TODO/FIXME markers across codebase:
- TrendsViewModel.swift (7 TODOs)
- RideSummaryService.swift (4 TODOs)  
- StrainScoreService.swift (3 TODOs)
- TodayView.swift (3 TODOs)

---

### ✅ Priority 5: Design System Adherence

**Status:** ✅ **GOOD** (Phase 3 complete)
- All 16 cards migrated to V2 with atomic components
- VRText, VRBadge, CardContainer properly used (658 usages)
- Content abstraction in place

**Remaining:** Debug section not using design system

---

## Refactor Phases

### Phase 1: Cache System Unification (Week 1, 3-4 days)
**Goal:** Consolidate 5 cache systems → 1 UnifiedCacheManager

**Actions:**
1. Audit all cache system usages
2. Migrate services to UnifiedCacheManager pattern
3. Delete old cache files (StreamCache, IntervalsCache, HealthKitCache)
4. Standardize cache keys with CacheKeys enum
5. Test cache hit rates (target >80%)

**Files to Delete:**
- `StreamCacheService.swift` (364 lines)
- `IntervalsCache.swift` (243 lines)
- `HealthKitCache.swift` (79 lines)
- `StravaAthleteCache.swift`

**Lines Removed:** ~1,455 lines  
**Complexity:** 80% reduction (5 systems → 1)

---

### Phase 2: File Size Reduction (Week 1-2, 4-5 days)
**Goal:** Break down 7 monolithic files

#### HealthKitManager (1669 → 3 files)
```
Core/Networking/HealthKit/
├── HealthKitManager.swift (300 lines) - Coordinator
├── HealthKitMetrics.swift (400 lines) - HRV, RHR, Sleep
├── HealthKitWorkouts.swift (400 lines) - Workout queries
└── HealthKitBaselines.swift (300 lines) - Baselines
```

#### DebugSettingsView (1288 → 6 files)
```
Features/Debug/Views/
├── DebugSettingsView.swift (200 lines) - Navigation
├── DebugAuthSection.swift (150 lines)
├── DebugCacheSection.swift (200 lines)
├── DebugAPISection.swift (150 lines)
├── DebugFeaturesSection.swift (200 lines)
└── DebugMonitoringSection.swift (150 lines)
```

#### RecoveryScoreService (1084 → 3 files)
```
Core/Services/Recovery/
├── RecoveryScoreService.swift (400 lines)
├── RecoveryCalculations.swift (300 lines) - Move to VeloReadyCore
├── RecoveryMetrics.swift (200 lines)
```

**Total:** ~4,000 lines reorganized

---

### Phase 3: Debug Section Overhaul (Week 2, 2-3 days)
**Goal:** Modern, organized, design-system-compliant debug tools

**Actions:**
1. Delete `DebugDashboardView.swift` (dead file)
2. Create organized DebugHub with categories
3. Apply design system (VRText, VRBadge, tokens)
4. Add quick actions for common tasks

**New Structure:**
```
Features/Debug/
├── DebugHub.swift (TabView navigation)
├── Categories/
│   ├── DebugAuthView.swift
│   ├── DebugDataView.swift
│   ├── DebugFeaturesView.swift
│   ├── DebugNetworkView.swift
│   ├── DebugHealthView.swift
│   └── DebugMLView.swift
├── Dashboards/
│   ├── ServiceHealthDashboard.swift ✅
│   ├── TelemetryDashboard.swift ✅
│   └── CacheStatsDashboard.swift (New)
└── Galleries/
    ├── CardGalleryView.swift ✅
    └── ComponentGalleryView.swift (New)
```

---

### Phase 4: Performance Optimization (Week 2-3, 3-4 days)
**Goal:** <2s app startup, >80% cache hit rate

**Actions:**
1. Service consolidation (merge small services)
2. Reduce @MainActor overhead (use actors)
3. Optimize TodayViewModel startup (parallel loading)
4. Memory optimization (size-based cache eviction)

**Service Mergers:**
- `RecoverySleepCorrelationService` → `RecoveryScoreService`
- `SleepDebtService` → `SleepScoreService`
- `VO2MaxTrackingService` → `AthleteZoneService`

---

### Phase 5: Technical Debt Cleanup (Week 3, 2-3 days)
**Goal:** Resolve 48 TODO/FIXME markers

**Actions:**
1. Categorize TODOs (Resolve, Document, Delete)
2. Fix top priority files (TrendsVM, RideSummary, StrainScore)
3. Remove dead code (unused files/imports)
4. Clean up commented code

---

### Phase 6: Testing & Verification (Week 3-4, 2-3 days)
**Goal:** Ensure no regressions

**Actions:**
1. All automated tests pass (75+ tests, <90s)
2. Manual QA checklist (onboarding → scores → trends)
3. Performance benchmarks (startup, load times, memory)
4. Beta test with TestFlight users

---

## Git Strategy (RECOMMENDED)

### Branch Structure
```
main (production)
  ↓
large-refactor (base branch) ← You are here
  ↓
  ├── refactor/cache-unification (Phase 1)
  ├── refactor/file-splitting (Phase 2)
  ├── refactor/debug-overhaul (Phase 3)
  ├── refactor/performance (Phase 4)
  └── refactor/cleanup (Phase 5)
```

### Workflow: Feature Branch Per Phase
```bash
# Preserve current state
git checkout main
git tag -a v1.0-pre-refactor -m "State before refactor"
git push origin v1.0-pre-refactor

# Phase 1
git checkout large-refactor
git checkout -b refactor/cache-unification
# ... make changes ...
git commit -m "feat: consolidate cache systems"
git push origin refactor/cache-unification
# PR: refactor/cache-unification → large-refactor
# Merge after tests pass

# Phase 2
git checkout large-refactor
git pull
git checkout -b refactor/file-splitting
# ... repeat ...
```

### Final Merge to Main
```bash
git checkout main
git merge large-refactor --squash
git commit -m "refactor: large-scale architecture improvements

- Consolidated 5 cache systems into UnifiedCacheManager
- Split 7 monolithic files into logical modules
- Overhauled debug section with design system
- Optimized performance (2s startup, 80%+ cache hit)
- Resolved 48 TODOs and removed dead code
"
git push origin main
```

---

## Success Metrics

| Metric | Before | After (Target) | Improvement |
|--------|--------|----------------|-------------|
| Cache Systems | 5 | 1 | -80% complexity |
| Cache Hit Rate | ~60% | >80% | +33% |
| Largest File | 1669 lines | <900 lines | -46% |
| Files >900 lines | 7 | 0-2 | -70%+ |
| TODOs/FIXMEs | 48 | <10 | -79% |
| App Startup | 3-8s | <2s | -33% faster |
| Today View Load | 2-8s | <2s | -50% faster |
| Total Lines | 88,882 | ~84,000 | -5% |

---

## Timeline

### Week 1 (Nov 6-12)
- [x] Audit complete
- [ ] Phase 1: Cache Unification
- [ ] Phase 2: File Splitting (Part 1)

### Week 2 (Nov 13-19)
- [ ] Phase 2: File Splitting (Part 2)
- [ ] Phase 3: Debug Overhaul
- [ ] Phase 4: Performance (Part 1)

### Week 3 (Nov 20-26)
- [ ] Phase 4: Performance (Part 2)
- [ ] Phase 5: Technical Debt
- [ ] Phase 6: Testing

### Week 4 (Nov 27-Dec 3)
- [ ] Final testing & bug fixes
- [ ] Beta to TestFlight
- [ ] Merge to main

---

## Next Steps (Today)

1. ✅ Review this plan
2. [ ] Tag current state: `v1.0-pre-refactor`
3. [ ] Create Phase 1 branch: `refactor/cache-unification`
4. [ ] Review detailed implementation guide: `REFACTOR_IMPLEMENTATION_GUIDE.md`

---

## Risk Mitigation

**High Risk:**
- Cache changes (test comprehensively, keep old code commented for 1 release)
- Performance optimizations (benchmark before/after)

**Medium Risk:**
- File splits (use Xcode refactor tools)

**Low Risk:**
- Debug section changes (internal tooling only)

**Rollback Plan:**
```bash
git revert HEAD  # Revert merge
# Or nuclear option:
git reset --hard v1.0-pre-refactor
```

---

## Questions?

See `REFACTOR_IMPLEMENTATION_GUIDE.md` for:
- Detailed step-by-step instructions
- Code examples and patterns
- Cache key standardization reference
- Service consolidation details
- Testing checklists
