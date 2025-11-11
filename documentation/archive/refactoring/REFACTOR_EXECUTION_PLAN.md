# VeloReady iOS - Step-by-Step Execution Plan
**Timeline:** 3 weeks | **Branch:** `large-refactor`

---

## Week 1: Audit + VeloReadyCore Extraction

### Days 1-2: COMPREHENSIVE AUDIT

**Day 1 Morning - Code Leanness Audit:**
```bash
# Run comprehensive audit scripts
./scripts/audit-leanness.sh > AUDIT_LEANNESS.md
# Find: Duplicate calculations, commented code, merge candidates
# Target: Identify 1500-2000 lines to DELETE
```

**Day 1 Afternoon - Design System Audit:**
```bash
# Audit design system violations
./scripts/audit-design-system.sh > AUDIT_DESIGN.md
# Find: Hard-coded strings, spacing, colors, Text vs VRText
# Target: Identify 50-100 violations to FIX
```

**Day 2 Morning - Velocity Baseline:**
```bash
# Measure current developer velocity
./scripts/measure-velocity.sh > VELOCITY_BASELINE.md
# Metrics: Test time, build time, navigation time
```

**Day 2 Afternoon - Create Checklists:**
- Consolidate findings into `CLEANUP_CHECKLIST.md`
- Prioritize: What blocks architecture vs what's polish

**Deliverables:** 4 audit reports, actionable checklist

---

### Days 3-7: VELOCREADYCORE EXTRACTION

**Day 3 - Setup Structure:**
```bash
cd VeloReadyCore
mkdir -p Sources/Calculations Tests/CalculationTests
# Create: Recovery, Sleep, Strain, Baseline, TrainingLoad calculation files
```

**Day 4-5 - Extract RecoveryCalculations:**
1. Move calculation logic from RecoveryScoreService → VeloReadyCore
2. Write comprehensive tests (target: <5s test time)
3. Update iOS service to thin orchestrator
4. Verify: All tests pass, RecoveryScoreService <250 lines

**Day 6-7 - Extract Remaining:**
1. SleepCalculations + tests
2. StrainCalculations + tests  
3. BaselineCalculations + tests
4. TrainingLoadCalculations + tests (**consolidate 4 duplicate implementations**)

**Week 1 Result:**
- ✅ All business logic in VeloReadyCore
- ✅ Tests run <10s (was 60-90s)
- ✅ Deleted ~400 lines duplicate calculations
- ✅ Services <250 lines each
- ✅ UI calculations on background threads

---

## Week 2: Cache Architecture + Performance

### Days 8-10: CACHE REDESIGN

**Day 8 - Foundation:**
1. Create `CacheKey.swift` enum (type-safe keys)
2. Extract `CacheEncodingHelper.swift` (300 lines from UnifiedCache)
3. Create cache layer interfaces

**Day 9 - Layer Implementation:**
```
Core/Data/Cache/
├── CacheOrchestrator.swift (200 lines) - Main interface
├── CacheKey.swift (150 lines) - Type-safe keys
├── CacheEncodingHelper.swift (300 lines) - Encoding logic
└── Layers/
    ├── MemoryCacheLayer.swift (150 lines)
    ├── DiskCacheLayer.swift (200 lines)
    └── CoreDataCacheLayer.swift (100 lines - wraps CachePersistenceLayer)
```

**Day 10 - Migration:**
1. Migrate UnifiedActivityService to new cache
2. Migrate StravaDataService
3. Migrate score services
4. Delete old cache files: StreamCache, IntervalsCache, HealthKitCache

**Result:** Delete 1455 lines, cache is layered and type-safe

---

### Days 11-12: @MAINACTOR CLEANUP

**Target:** Remove @MainActor from 20-25 calculation services

**Pattern:**
```swift
// BEFORE: @MainActor forces all work to main thread
@MainActor class RecoveryScoreService: ObservableObject {
    func calculate() async { /* blocks UI */ }
}

// AFTER: Actor with selective main thread access
actor RecoveryScoreService {
    @Published @MainActor var currentScore: RecoveryScore?
    nonisolated func calculate() async -> RecoveryScore {
        // Background calculation
        await MainActor.run { self.currentScore = score }
    }
}
```

**Services to convert:**
Recovery, Sleep, Strain, TrainingLoad, Baseline, Illness, Wellness, ML, Readiness, etc.

**Result:** App startup 8s → 2s, UI never blocks

---

## Week 3: Organization + Cleanup

### Days 13-15: FILE ORGANIZATION

**Day 13 - HealthKit Split:**
```
Core/Networking/HealthKit/
├── HealthKitManager.swift (200 lines) - Coordinator
├── HealthKitAuthorization.swift (100 lines)
├── HealthKitDataFetcher.swift (400 lines)
├── HealthKitTransformer.swift (200 lines)
└── HealthKitBaselines.swift (→ moved to VeloReadyCore)
```

**Day 14 - Debug Section:**
```
Features/Debug/
├── DebugHub.swift - TabView navigation
├── Categories/
│   ├── DebugAuthView.swift
│   ├── DebugDataView.swift
│   ├── DebugFeaturesView.swift
│   └── DebugNetworkView.swift
└── Dashboards/ (keep existing)
```
- Delete: DebugDashboardView.swift (0 bytes)
- Split: DebugSettingsView 1288 → 6 files of ~200 lines

**Day 15 - Service Organization:**
Organize services by domain:
```
Core/Services/
├── Scoring/
│   ├── RecoveryScoreService.swift
│   ├── SleepScoreService.swift
│   └── StrainScoreService.swift
├── Data/
│   ├── UnifiedActivityService.swift
│   ├── StravaDataService.swift
│   └── WorkoutMetadataService.swift
└── ML/
    └── (already organized)
```

**Result:** All files <900 lines, clear organization

---

### Days 16-18: LEANNESS CLEANUP

**Day 16 - Delete Dead Code:**
Using `CLEANUP_CHECKLIST.md`:
1. Delete 4 cache systems (1455 lines)
2. Remove commented code blocks (~500 lines)
3. Delete duplicate calculations (~400 lines)

**Day 17 - Service Consolidation:**
Merge small services:
- RecoverySleepCorrelation → Recovery
- SleepDebt → Sleep
- VO2MaxTracking → AthleteZone
- ActivityDeduplication → UnifiedActivity
- ActivityLocation → MapSnapshot

**Result:** 28 → 20 services, delete ~900 lines

**Day 18 - Design System Fixes:**
Using `AUDIT_DESIGN.md`, fix violations:
1. Hard-coded strings → Content enums
2. Hard-coded spacing → Spacing tokens
3. Hard-coded colors → ColorScale
4. Text → VRText (target: 95% usage)

**Result:** 100% design system compliance

---

### Days 19-21: TESTING + POLISH

**Day 19 - Resolve TODOs:**
- Fix high-priority: TrendsViewModel, RideSummaryService, StrainScoreService
- Document or delete remaining: 48 → <10 TODOs

**Day 20 - Comprehensive Testing:**
```bash
# Run all tests
./Scripts/quick-test.sh

# VeloReadyCore tests
cd VeloReadyCore && swift test

# Manual QA
# - Fresh install flow
# - All scores calculate
# - Cache works
# - Offline mode
# - Performance feels faster
```

**Day 21 - Documentation + Metrics:**
Create `REFACTOR_SUMMARY.md`:
- Before/after metrics
- Architecture diagrams
- Migration notes
- Known issues

---

## Success Metrics

### Code Quality
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Total Lines | 88,882 | ~84,000 | -5% minimum |
| Services | 28 | 20 | -30% |
| Cache Systems | 5 | 1 | -80% |
| Files >900 lines | 7 | 0 | 100% reduction |
| TODOs | 48 | <10 | -80% |

### Performance
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| App Startup | 3-8s | <2s | -50% |
| Test Time (Core) | N/A | <10s | New capability |
| Test Time (iOS) | 62s | 60s | Maintain |
| Cache Hit Rate | ~60% | >85% | +40% |

### Design System
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| VRText Usage | ~60% | >95% | 100% compliance |
| Hard-coded Values | 50+ | 0 | Zero tolerance |
| Design Violations | Many | 0 | 100% compliance |

### Developer Velocity
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Find Function | Scroll 1669 lines | <5s | 10x faster |
| Add Feature | Measure | Measure | 30% faster |
| Test Calculation | 60s simulator | 5s CLI | 12x faster |

---

## Audit Scripts to Create

### `scripts/audit-leanness.sh`
```bash
#!/bin/bash
# Find duplicate code, commented blocks, merge candidates
echo "=== CODE LEANNESS AUDIT ==="
# 1. Baseline metrics
# 2. Find commented code
# 3. Find duplicate calculations
# 4. Find small services (<250 lines)
# 5. Find unused files
```

### `scripts/audit-design-system.sh`
```bash
#!/bin/bash
# Find design system violations
echo "=== DESIGN SYSTEM AUDIT ==="
# 1. Hard-coded strings
# 2. Hard-coded spacing
# 3. Hard-coded colors
# 4. Text vs VRText ratio
# 5. Files modified in last 2 weeks
```

### `scripts/measure-velocity.sh`
```bash
#!/bin/bash
# Measure developer velocity metrics
echo "=== VELOCITY BASELINE ==="
# 1. Test execution time
# 2. Build time
# 3. Xcode indexing (file count)
# 4. Code navigation (largest files)
```

---

## Daily Commit Pattern

```bash
# Morning: Start day with pull
git checkout large-refactor
git pull origin large-refactor

# Work: Commit frequently
git add <files>
git commit -m "refactor(core): extract RecoveryCalculations to VeloReadyCore"

# Evening: Push daily progress
git push origin large-refactor
```

---

## Final Merge

```bash
# Tag pre-refactor state
git checkout main
git tag -a v1.0-pre-refactor -m "State before large refactor"
git push origin v1.0-pre-refactor

# Merge refactor
git checkout main
git merge large-refactor --squash
git commit -m "refactor: establish scalable architectural foundation

See REFACTOR_SUMMARY.md for complete details.

Key Changes:
- Extract business logic to VeloReadyCore (testable in 5s)
- Redesign cache with type-safe keys and layered architecture
- Remove @MainActor from calculation services (UI never blocks)
- Organize files by concern (all <900 lines)
- Delete 2500+ lines (dead code, duplicates, old caches)
- Consolidate 28 → 20 services
- 100% design system compliance

Performance:
- App startup: 8s → 2s
- VeloReadyCore tests: <10s
- Cache hit rate: 60% → 85%

Ready for features, ML, backend integration, SwiftData migration.
"

git push origin main
```

---

## Questions Before Starting

1. **Audit scripts:** Create them or run commands manually?
2. **VeloReadyCore:** Package already set up or need to configure?
3. **Testing:** Run tests after each change or batch at end of phase?
4. **Risk tolerance:** Stop if tests fail or push through with fixes?
5. **Timeline:** 3 weeks realistic or need buffer?

**This plan fully addresses all requirements. Ready to execute?**
