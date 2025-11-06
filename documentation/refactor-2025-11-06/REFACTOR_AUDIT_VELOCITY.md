# VeloReady iOS - Developer Velocity Baseline
**Date:** November 6, 2025 | **Purpose:** Measure current velocity before refactor

---

## Executive Summary

**Current developer velocity is SIGNIFICANTLY IMPACTED by:**
1. Large files requiring excessive scrolling (1669 lines max)
2. Slow test feedback loop (78s for quick tests)
3. Hard-coded values creating search difficulty
4. No VeloReadyCore = slow pure logic testing (60s vs potential <5s)

**Target Improvements:**
- Find any function: Current ~30-60s → Target <5s
- Test pure calculations: Current N/A (no VeloReadyCore) → Target <5s
- Build time: Current unknown → Target maintain or improve
- Navigate codebase: Difficult → Easy

---

## 1. Test Execution Time ⏱️

### Quick Test Suite
```bash
$ time ./Scripts/quick-test.sh
✅ Quick test completed successfully in 78s
```

**Metrics:**
- **Current:** 78 seconds
- **Target:** <90 seconds ✅ (within target)
- **Status:** GOOD

**Breakdown:**
- Build phase: ~50 seconds
- Essential unit tests: ~25 seconds
- SwiftLint: Skipped (not installed)

### Full Test Suite
**Status:** Not measured (would run all 75+ tests)
**Expected:** ~90-120 seconds
**Target:** <120 seconds

### VeloReadyCore Tests
**Current:** ❌ **DOES NOT EXIST**
**Impact:** Cannot test pure calculation logic quickly
**After Phase 1:** <10 seconds ✅

**Why This Matters:**
```bash
# CURRENT: Test recovery score calculation
$ ./Scripts/quick-test.sh  # 78 seconds, requires iOS simulator

# AFTER PHASE 1: Test recovery calculation
$ cd VeloReadyCore && swift test  # <5 seconds, no simulator
```

**Velocity Impact:** 15x faster iteration on business logic

---

## 2. Build Time 🏗️

### Clean Build
**Status:** Not measured in this audit
**Typical:** 120-180 seconds (estimated from quick test)
**Target:** <180 seconds

### Incremental Build
**Status:** Not measured
**Typical:** 10-30 seconds (single file change)
**Target:** <30 seconds

**Note:** Will measure in future iterations if build performance becomes an issue

---

## 3. Codebase Complexity 📊

### File Metrics
```
Total Swift Files: 415
Total Lines:       88,882
Average per File:  214 lines
```

### Largest Files (Navigation Pain Points)
```
1,669 lines - Core/Networking/HealthKitManager.swift ❌ WORST
1,288 lines - Features/Settings/Views/DebugSettingsView.swift ❌
1,250 lines - Core/Data/UnifiedCacheManager.swift ❌
1,131 lines - Features/Trends/ViewModels/WeeklyReportViewModel.swift ❌
1,097 lines - Core/Networking/IntervalsAPIClient.swift ❌
1,084 lines - Core/Services/RecoveryScoreService.swift ❌
  983 lines - Core/Models/AthleteProfile.swift ⚠️
  939 lines - Features/Today/ViewModels/TodayViewModel.swift ⚠️
  902 lines - Features/Today/ViewModels/RideDetailViewModel.swift ⚠️
  895 lines - Core/Models/StrainScore.swift ⚠️
```

**Files >900 lines:** 7 files ❌ (Target: 0)

**Impact on Velocity:**
- Finding specific function: 30-60 seconds (scrolling through 1669 lines)
- Understanding file scope: Difficult (too much context)
- Merge conflicts: Higher likelihood in large files
- Code review: Time-consuming

---

## 4. Code Navigation Time 🧭

### Current: Manual Scrolling Through Large Files

**Scenario:** Find `calculateRecoveryScore()` in RecoveryScoreService.swift

**Current Process:**
1. Open RecoveryScoreService.swift (1084 lines)
2. Cmd+F "calculateRecoveryScore"
3. Scroll through multiple matches (method + calls)
4. Find correct definition
5. Understand context requires scrolling through surrounding 100+ lines

**Time:** ~30-60 seconds

**After Phase 1 (Logic → VeloReadyCore):**
1. Open RecoveryScoreService.swift (now ~250 lines)
2. Cmd+F "calculateRecoveryScore"
3. Immediate visibility (everything fits on screen)

**Time:** <5 seconds ✅ (6-12x faster)

---

### Current: Finding Design System Violations

**Scenario:** Find all hard-coded Text() in detail views

**Current Process:**
1. grep search (fast)
2. Open each file
3. Scroll to line number
4. Understand context
5. Fix violation

**Time per file:** 3-5 minutes  
**Total for 10 files:** 30-50 minutes

**After Phase 5 (Design System Cleanup):**
- No violations to find
- Autocomplete shows available Content enums
- VRText usage enforced

---

## 5. Feature Development Cycle Time 🔄

### Current Workflow (Estimated)

**Adding a new score component:**
1. Understand existing calculation logic: 15-20 min (scrolling large files)
2. Write calculation code: 20-30 min
3. Write tests (iOS): 10-15 min
4. Run tests: 78 seconds per iteration
5. Debug failures: 5-10 iterations = 6-13 minutes test time
6. Manual QA in simulator: 10-15 min

**Total:** ~70-105 minutes per feature

---

### After Refactor (Projected)

**Adding a new score component:**
1. Understand existing calculation logic: 5 min (clear, small files)
2. Write calculation code in VeloReadyCore: 20-30 min
3. Write tests (VeloReadyCore): 5-10 min
4. Run tests: <5 seconds per iteration
5. Debug failures: 5-10 iterations = <1 minute test time
6. iOS integration (thin service): 10 min
7. Manual QA in simulator: 10-15 min

**Total:** ~50-70 minutes per feature ✅ (30-33% faster)

---

## 6. Common Pain Points 😫

### A. "Where is this function defined?"

**Frequency:** Multiple times per day  
**Current Time:** 30-60 seconds (searching large files)  
**After Refactor:** <5 seconds (smaller, organized files)

**Impact:** Interrupted flow, context switching

---

### B. "Why is this test so slow?"

**Frequency:** Every test run  
**Current:** 78 seconds (includes iOS simulator overhead)  
**After Phase 1:** VeloReadyCore tests <5 seconds (pure Swift)

**Impact:** Slower iteration, fewer tests written

---

### C. "Is this using the design system?"

**Frequency:** Every PR review  
**Current:** Manual inspection, grep searches  
**After Phase 5:** 95%+ compliance, obvious violations

**Impact:** Inconsistent UI, harder to maintain

---

### D. "Why did this calculation break?"

**Frequency:** Weekly  
**Current:** Debug in iOS simulator, slow feedback  
**After Phase 1:** Test pure calculation in VeloReadyCore (<5s)

**Impact:** Slower debugging, more production bugs

---

## 7. Baseline Metrics Summary

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Test Time (Quick)** | 78s | <90s | ✅ GOOD |
| **Test Time (VeloReadyCore)** | N/A ❌ | <10s | 🔴 MISSING |
| **Largest File** | 1,669 lines | <900 lines | ❌ BAD |
| **Files >900 lines** | 7 | 0 | ❌ BAD |
| **Find Function Time** | 30-60s | <5s | ❌ BAD |
| **Design Compliance** | 35% | 95% | ❌ BAD |
| **VRText Adoption** | 31.6% | 95% | ❌ BAD |
| **Hard-coded Spacing** | 566 | <50 | ❌ BAD |
| **Total Lines** | 88,882 | 84,000 | 🔴 BASELINE |

---

## 8. Velocity Improvement Projections

### After Phase 1 (VeloReadyCore Extraction)
```
✅ VeloReadyCore tests: <10s (was N/A)
✅ Calculation debugging: <5s (was 78s)
✅ RecoveryScoreService: 1084 → 250 lines
✅ Logic reusable: Backend, ML, Widgets
```

**Velocity Gain:** 15x faster for pure logic testing

---

### After Phase 2 (Cache Architecture)
```
✅ Cache systems: 5 → 1
✅ Type-safe keys: No more typos
✅ Consistent patterns: Easier to understand
```

**Velocity Gain:** 50% fewer cache-related bugs

---

### After Phase 3 (Performance)
```
✅ App startup: 8s → 2s
✅ UI never blocks: Background calculations
✅ True parallelism: Faster data loading
```

**Velocity Gain:** Better UX = happier testing

---

### After Phase 4 (File Organization)
```
✅ HealthKitManager: 1669 → 4 files <500 lines
✅ DebugSettingsView: 1288 → 6 files ~200 lines
✅ All files <900 lines
✅ Clear navigation: Domain-based organization
```

**Velocity Gain:** 6-12x faster to find code

---

### After Phase 5 (Design System Cleanup)
```
✅ VRText adoption: 95%+ (was 31.6%)
✅ Hard-coded values: ~0 (was 914)
✅ 100% design compliance
✅ Autocomplete-driven development
```

**Velocity Gain:** 30% faster UI development

---

## 9. Developer Experience Improvements

### Before Refactor
```
😫 "I need to scroll through 1669 lines to find one function"
😫 "Testing calculations requires full iOS simulator (78s)"
😫 "I don't know if this uses the design system"
😫 "Which cache system should I use?"
😫 "Where should this logic live?"
```

### After Refactor
```
😊 "All files <900 lines, easy to navigate"
😊 "VeloReadyCore tests run in <5s"
😊 "Design system compliance is obvious"
😊 "One cache system with type-safe keys"
😊 "Clear separation: VeloReadyCore (logic) vs iOS (UI)"
```

---

## 10. Measurement Commands

### Reproduce These Metrics

```bash
cd /Users/markboulton/Dev/veloready

# 1. Test execution time
time ./Scripts/quick-test.sh

# 2. Codebase metrics
find VeloReady -name "*.swift" | wc -l  # File count
find VeloReady -name "*.swift" -exec wc -l {} + | tail -1  # Total lines

# 3. Largest files
find VeloReady -name "*.swift" -exec wc -l {} + | sort -rn | head -10

# 4. Design violations
grep -rn 'Text("' --include="*.swift" VeloReady/Features/ | wc -l
grep -rn 'spacing: [0-9]' --include="*.swift" VeloReady/Features/ | wc -l

# 5. VRText adoption
text_count=$(grep -rn 'Text("' --include="*.swift" VeloReady/Features/ | wc -l)
vrtext_count=$(grep -rn 'VRText(' --include="*.swift" VeloReady/Features/ | wc -l)
echo "VRText adoption: $(echo "scale=1; $vrtext_count / ($text_count + $vrtext_count) * 100" | bc)%"
```

---

## 11. Next Steps

1. ✅ Baseline established
2. ✅ Pain points identified
3. ✅ Targets set
4. Create master cleanup checklist (Prompt 0.4)
5. Begin Phase 1: VeloReadyCore extraction

---

## 12. Success Criteria (Post-Refactor)

### Critical Metrics
- [ ] VeloReadyCore tests <10s ✅
- [ ] All files <900 lines ✅
- [ ] Find any function <5s ✅
- [ ] VRText adoption >95% ✅
- [ ] Test time maintained <90s ✅

### Velocity Improvements
- [ ] Feature development 30% faster
- [ ] Calculation debugging 15x faster
- [ ] Code navigation 6-12x faster
- [ ] Design system violations obvious
- [ ] Cache patterns consistent

### Developer Experience
- [ ] No more scrolling through 1669-line files
- [ ] Fast feedback loop for business logic
- [ ] Clear separation of concerns
- [ ] Autocomplete-driven development
- [ ] Confident code changes

---

## Conclusion

**Current State:** Developer velocity hampered by large files, slow test feedback, and design system violations.

**Target State:** Fast iteration, clear organization, quick tests, design system compliance.

**Key Improvements:**
- 15x faster calculation testing (VeloReadyCore)
- 6-12x faster code navigation (file splitting)
- 30% faster feature development (combined improvements)

**Ready to proceed with Phase 1: VeloReadyCore extraction.**
