# VeloReady iOS - Refactor Plan (REVISED)
**Date:** November 6, 2025  
**Status:** 🟢 Ready to Execute  
**Timeline:** 1.5-2 weeks MAX (not 3-4 weeks)  
**Branch:** `large-refactor` (work directly here, no sub-branches)

---

## Why This Revision?

**Original plan had priorities backwards:**
- Put cache consolidation first (HIGH RISK, doesn't fix daily pain)
- 3-4 week timeline (too long to be heads-down on refactoring)
- Too formal Git process for solo developer

**What you ACTUALLY need:**
- Navigate code faster (split massive files)
- Find debug tools faster (organize debug section)
- Reduce cognitive load (clean TODOs)
- Improve performance (fix @MainActor overuse)
- Cache cleanup... if time permits (not critical)

---

## REVISED Priorities

### 🟢 Priority 1: File Splitting (Days 1-3)
**Why First:** LOW RISK, IMMEDIATE velocity improvement  
**Impact:** Stop wasting time scrolling through 1669-line files

**Target Files:**
1. HealthKitManager (1669 → 4 files of ~400 lines)
2. DebugSettingsView (1288 → 6 files of ~200 lines)
3. RecoveryScoreService (1084 → 3 files)
4. WeeklyReportViewModel (1131 → 2-3 files)
5. IntervalsAPIClient (1097 → 3 files)

**Effort:** 2-3 days  
**Risk:** ⭐ LOW (just moving code)  
**Velocity Gain:** ⭐⭐⭐⭐⭐ IMMEDIATE

---

### 🟢 Priority 2: Debug Section Overhaul (Days 3-4)
**Why Second:** ZERO RISK, huge quality-of-life improvement

**Actions:**
1. Delete `DebugDashboardView.swift` (0 bytes - dead file)
2. Split DebugSettingsView into organized sections
3. Apply design system (VRText, VRBadge, tokens)
4. Add quick-action buttons for common tasks
5. Create DebugHub with tab navigation

**Effort:** 1-2 days  
**Risk:** ⭐ NONE (internal tooling)  
**Velocity Gain:** ⭐⭐⭐⭐ HIGH (testing/debugging faster)

---

### 🟡 Priority 3: @MainActor Massacre (Days 4-5)
**Why Third:** Hidden performance killer I underestimated

**Problem:** 42 services marked `@MainActor` forcing work to main thread
- RecoveryScoreService calculations block UI
- TrainingLoadCalculator blocks UI  
- BaselineCalculator blocks UI
- Sleep/Strain calculations block UI

**Solution:**
```swift
// ❌ BEFORE - ALL work on main thread
@MainActor
class RecoveryScoreService: ObservableObject {
    func calculate() async -> RecoveryScore {
        // Heavy math blocks UI
    }
}

// ✅ AFTER - Only UI updates on main thread
actor RecoveryScoreService {
    nonisolated func calculate() async -> RecoveryScore {
        // Math runs on background
    }
    
    @MainActor
    func publishScore(_ score: RecoveryScore) {
        // Only this on main thread
    }
}
```

**Target:** 15-20 services can lose @MainActor  
**Effort:** 1-2 days  
**Risk:** ⭐⭐ MEDIUM (need testing)  
**Performance Gain:** ⭐⭐⭐⭐⭐ MASSIVE

---

### 🟡 Priority 4: Technical Debt Blitz (Days 5-7)
**Why Fourth:** Clean mental clutter

**Actions:**
1. **Resolve High-Value TODOs** (TrendsViewModel: 7, RideSummaryService: 4)
2. **Delete Low-Value TODOs** (outdated comments)
3. **Document Complex TODOs** (if can't fix now)
4. **Remove Dead Code** (unused files, commented blocks)

**Target:** 48 → <10 TODOs  
**Effort:** 2-3 days  
**Risk:** ⭐ LOW  
**Mental Load:** ⭐⭐⭐⭐ Reduced significantly

---

### 🔴 Priority 5: Selective Cache Fixes (Days 8-10, IF TIME)
**Why Last:** Works mostly fine, HIGH RISK to change

**REVISED APPROACH - Don't consolidate everything:**

**Do This:**
1. ✅ Create `CacheKeys.swift` enum (standardize keys)
2. ✅ Fix specific cache bugs (if you've hit any)
3. ✅ Migrate 1-2 services as proof-of-concept
4. ❌ **DON'T** delete all old cache systems yet
5. ❌ **DON'T** force full migration

**Rationale:**
- Cache consolidation can be gradual
- Don't need to do it all at once
- Low ROI vs risk right now
- Can finish later if needed

**Effort:** 1-2 days (partial only)  
**Risk:** ⭐⭐⭐ HIGH (if doing full migration)  
**Risk:** ⭐ LOW (if doing selective fixes)

---

## Week-by-Week Breakdown

### Week 1: Quick Wins (Days 1-5)
**Monday-Tuesday:** File splitting (HealthKitManager, DebugSettings)  
**Wednesday:** Debug section overhaul  
**Thursday-Friday:** @MainActor cleanup (score services)

**Goal:** By Friday, development velocity noticeably better

### Week 2: Polish & Optimize (Days 6-10)
**Monday-Tuesday:** Technical debt cleanup (TODOs, dead code)  
**Wednesday:** Remaining file splits (ViewModels, API client)  
**Thursday:** Selective cache fixes (CacheKeys, 1-2 migrations)  
**Friday:** Testing, documentation, merge

**Goal:** Refactor complete, ready to build features again

---

## Simplified Git Workflow

**NO sub-branches** (you're solo developer):

```bash
# Work directly on large-refactor
git checkout large-refactor

# Commit frequently with clear messages
git commit -m "refactor: split HealthKitManager into modules"
git commit -m "refactor: organize debug settings into sections"
git commit -m "perf: remove @MainActor from calculation services"

# Push daily
git push origin large-refactor

# When done (end of week 2)
git checkout main
git merge large-refactor --squash
git commit -m "refactor: improve developer velocity and performance"
git push origin main
```

---

## Success Metrics (Revised)

### Developer Velocity (Primary Goal)
- [ ] Find code in <10 seconds (vs scrolling through 1669 lines)
- [ ] Debug tools organized and discoverable
- [ ] Mental load reduced (<10 TODOs vs 48)

### Performance (Secondary Goal)
- [ ] App startup <2s (currently 3-8s)
- [ ] Score calculations don't block UI
- [ ] Memory usage stable

### Code Health (Tertiary Goal)
- [ ] All files <900 lines (was: 7 files over 900)
- [ ] Cache keys standardized (CacheKeys enum)
- [ ] All tests passing (75+ tests)

---

## What Changed From V1?

### Priorities Reordered
1. ~~Cache consolidation~~ → **File splitting** (LOW RISK, HIGH IMPACT)
2. ~~Code efficiency~~ → **Debug overhaul** (ZERO RISK, HIGH QoL)
3. ~~Content cleanup~~ → **@MainActor fixes** (MEDIUM RISK, HUGE PERF)
4. ~~Debug section~~ → **Tech debt** (LOW RISK, CLEAN MENTAL)
5. ~~Tech debt~~ → **Selective cache** (HIGH RISK → Optional)

### Timeline Shortened
- Was: 3-4 weeks
- Now: 1.5-2 weeks MAX
- Reason: Stay focused, get back to features faster

### Git Strategy Simplified
- Was: Feature branch per phase
- Now: Work directly on large-refactor
- Reason: You're solo developer, don't need overhead

### Cache Approach Changed
- Was: Full migration, delete all old systems
- Now: Selective fixes, gradual migration
- Reason: HIGH RISK, works mostly fine, not worth forcing

---

## Day 1 Action Plan (Tomorrow)

### Morning (2-3 hours)
```bash
cd /Users/markboulton/Dev/veloready
git checkout large-refactor

# 1. Split HealthKitManager
mkdir -p VeloReady/Core/Networking/HealthKit

# 2. Create structure files
touch VeloReady/Core/Networking/HealthKit/HealthKitMetrics.swift
touch VeloReady/Core/Networking/HealthKit/HealthKitWorkouts.swift
touch VeloReady/Core/Networking/HealthKit/HealthKitBaselines.swift

# 3. Move code (use Xcode refactor tools)
# - Cut HRV/RHR/Sleep methods → HealthKitMetrics
# - Cut workout methods → HealthKitWorkouts
# - Cut baseline methods → HealthKitBaselines

# 4. Update HealthKitManager to coordinator pattern
```

### Afternoon (2-3 hours)
```bash
# 5. Update all callers
# Find: HealthKitManager.shared.fetchLatestHRV
# Replace: HealthKitManager.shared.metrics.fetchLatestHRV

# 6. Run tests
./Scripts/quick-test.sh

# 7. Commit
git add VeloReady/Core/Networking/HealthKit/
git commit -m "refactor: split HealthKitManager into metric modules

Reduces main file from 1669 → 300 lines
Organized into:
- HealthKitMetrics (HRV, RHR, Sleep)
- HealthKitWorkouts (Workout queries)
- HealthKitBaselines (7-day calculations)

All tests passing ✅
"
git push origin large-refactor
```

**By end of Day 1:** HealthKitManager split, code easier to navigate

---

## Critical Differences from V1

### ✅ What's Better Now

1. **Velocity First** - Focus on making YOUR work faster
2. **Low Risk First** - Start with file moves, not risky cache changes
3. **Realistic Timeline** - 2 weeks vs 4 weeks
4. **Pragmatic** - Don't force cache consolidation if it works
5. **Simple Process** - No complex branching strategy

### ⚠️ What We're NOT Doing (Yet)

1. **Full cache consolidation** - Too risky, works mostly fine
2. **Service consolidation** - Can do later if needed
3. **VeloReadyCore migration** - Not urgent
4. **Formal sub-branches** - Unnecessary overhead

### 🎯 Clear Success Criteria

**Week 1 Friday Check:**
- Can I find code faster? ✅ YES → Continue
- Are debug tools better? ✅ YES → Continue
- Is app more responsive? ✅ YES → Continue

**Week 2 Friday Check:**
- TODOs reduced? ✅ YES → Merge
- Tests passing? ✅ YES → Merge
- Ready to build features? ✅ YES → Merge

If NO on any → Stop, reassess, don't force it

---

## Questions for You

1. **Timeline:** Does 1.5-2 weeks feel right? Or still too long?

2. **Cache:** Agree to make it optional/selective vs full migration?

3. **@MainActor:** Want to prioritize this higher? (42 services is a LOT)

4. **First target:** Start with HealthKitManager split tomorrow?

5. **Git:** Comfortable working directly on large-refactor branch?

---

## Bottom Line

**V1 Plan:** Safe but slow, optimizes for "perfection"  
**V2 Plan:** Fast and pragmatic, optimizes for "velocity"

You're frustrated that development is slow. V2 fixes that in 2 weeks, not 4.

**Start tomorrow with low-risk file splitting. See immediate improvement. Build momentum.**

Does this feel better?
