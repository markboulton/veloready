# VeloReady iOS - Refactor Phase Prompts
**Timeline:** 3 weeks | **Branch:** `large-refactor`

Copy and paste these prompts to Windsurf as you complete each phase.

---

## Phase 0: Comprehensive Audit (Days 1-2)

### Prompt 0.1 - Code Leanness Audit
```
Run a comprehensive code leanness audit for VeloReady iOS:

1. Generate baseline metrics (total lines, file count)
2. Find duplicate calculation logic (training load, baselines, etc.)
3. Identify commented code blocks (potential dead code)
4. Find small services (<250 lines) that could be merged
5. Identify unused/low-reference files
6. Find duplicate model structures

Create AUDIT_LEANNESS.md with:
- Specific files and line numbers
- Duplicate code examples
- Service merge candidates (include line counts)
- Estimated lines that can be deleted

Target: Identify 1500-2000 lines to DELETE
```

### Prompt 0.2 - Design System Audit
```
Audit design system compliance across VeloReady iOS, focusing on recent feature work:

1. Find hard-coded strings (should use CommonContent, TodayContent, etc.)
2. Find hard-coded spacing (should use Spacing.md, Spacing.xl, etc.)
3. Find hard-coded colors (should use ColorScale)
4. Calculate Text vs VRText usage ratio
5. List files modified in last 2 weeks for manual review
6. Check for external padding on cards (StandardCard issue)

Create AUDIT_DESIGN.md with:
- Count of violations by type
- Specific files and line numbers
- Recent files that may have violations
- VRText adoption percentage (target: 95%+)

Target: Identify 50-100 design violations to FIX
```

### Prompt 0.3 - Developer Velocity Baseline
```
Measure current developer velocity metrics for VeloReady iOS:

1. Test execution time (run ./Scripts/quick-test.sh)
2. Build time (clean build)
3. Codebase complexity (file count, line count, largest files)
4. Find the 10 largest files and their line counts

Create VELOCITY_BASELINE.md with:
- Current metrics
- Target metrics
- Pain points (e.g., "scrolling through 1669-line HealthKitManager")

This establishes before/after comparison for refactor success.
```

### Prompt 0.4 - Create Master Cleanup Checklist
```
Using the three audit reports (AUDIT_LEANNESS.md, AUDIT_DESIGN.md, VELOCITY_BASELINE.md), create a comprehensive CLEANUP_CHECKLIST.md with:

A. Code to DELETE (with line counts)
   - Redundant cache systems
   - Commented/dead code
   - Duplicate calculations
   
B. Services to MERGE (28 → 20 target)
   - List small services with merge destinations
   
C. Design System Violations to FIX
   - Categorized by type (strings, spacing, colors, VRText)
   
D. Models to CONSOLIDATE
   - Redundant data structures
   
E. TODOs to RESOLVE (48 → <10 target)

This becomes our roadmap for Phases 4-5.
```

---

## Phase 1: VeloReadyCore Extraction (Days 3-7)

### Prompt 1.1 - Setup VeloReadyCore Structure
```
Set up VeloReadyCore package structure for business logic extraction:

1. Create directory structure:
   - Sources/Calculations/
   - Tests/CalculationTests/
   
2. Create placeholder files:
   - RecoveryCalculations.swift
   - SleepCalculations.swift
   - StrainCalculations.swift
   - BaselineCalculations.swift
   - TrainingLoadCalculations.swift
   
3. Update Package.swift with proper configuration
   - iOS 17+ platform
   - Test target

4. Verify package builds: `cd VeloReadyCore && swift build`

Goal: Foundation ready for logic extraction
```

### Prompt 1.2 - Extract RecoveryCalculations
```
Extract RecoveryScore calculation logic from iOS service to VeloReadyCore:

1. Analyze RecoveryScoreService.swift to identify pure calculation methods
2. Create RecoveryCalculations struct in VeloReadyCore with:
   - calculateScore() - main calculation
   - calculateHRVComponent()
   - calculateRHRComponent()
   - calculateSleepComponent()
   - calculateRespiratoryComponent()
   - calculateFormComponent()
   - applyAlcoholPenalty()
   - All as public static methods
   
3. Create comprehensive tests in RecoveryCalculationsTests.swift:
   - Test each component calculation
   - Test full score calculation
   - Test edge cases (zero baseline, negative values)
   - Test illness detection skips alcohol penalty
   
4. Run tests: `cd VeloReadyCore && swift test`
   Target: <5 seconds

5. Update RecoveryScoreService to thin orchestrator that:
   - Fetches data (stays in iOS)
   - Calls RecoveryCalculations.calculateScore()
   - Publishes result (stays in iOS)
   - Target: <250 lines
   
6. Verify iOS tests still pass

DO NOT write any code in this response - implement it.
```

### Prompt 1.3 - Extract SleepCalculations
```
Extract SleepScore calculation logic to VeloReadyCore:

1. Create SleepCalculations struct in VeloReadyCore
2. Extract calculation logic from SleepScoreService
3. Create comprehensive tests
4. Update SleepScoreService to thin orchestrator (<250 lines)
5. Verify all tests pass

Follow the same pattern as RecoveryCalculations.
```

### Prompt 1.4 - Extract StrainCalculations
```
Extract StrainScore calculation logic to VeloReadyCore:

1. Create StrainCalculations struct in VeloReadyCore
2. Extract calculation logic from StrainScoreService
3. Create comprehensive tests
4. Update StrainScoreService to thin orchestrator (<250 lines)
5. Verify all tests pass

Follow the same pattern as RecoveryCalculations.
```

### Prompt 1.5 - Extract Baseline & TrainingLoad Calculations
```
Extract baseline and training load calculations to VeloReadyCore:

1. Create BaselineCalculations struct:
   - calculateHRVBaseline()
   - calculateRHRBaseline()
   - calculateSleepBaseline()
   
2. Create TrainingLoadCalculations struct:
   - CONSOLIDATE the 4 duplicate implementations found in audit
   - calculateCTLATL() as single source of truth
   
3. Create comprehensive tests for both

4. Update iOS services (BaselineCalculator, TrainingLoadCalculator) to use VeloReadyCore

5. Delete duplicate calculation code identified in AUDIT_LEANNESS.md

6. Run full test suite: ./Scripts/quick-test.sh

Verify: ~400 lines of duplicate code deleted
```

### Prompt 1.6 - Phase 1 Verification
```
Verify Phase 1 completion:

1. Run VeloReadyCore tests: `cd VeloReadyCore && swift test`
   - All tests pass
   - Execution time <10 seconds
   
2. Run iOS tests: `./Scripts/quick-test.sh`
   - All tests pass
   - Execution time ~60 seconds
   
3. Verify service file sizes:
   - RecoveryScoreService <250 lines
   - SleepScoreService <250 lines
   - StrainScoreService <250 lines
   
4. Commit Phase 1:
   git commit -m "refactor(phase1): extract business logic to VeloReadyCore

   - All calculation logic now in VeloReadyCore (testable in <10s)
   - iOS services are thin orchestrators (<250 lines each)
   - Deleted ~400 lines of duplicate calculations
   - Tests: VeloReadyCore <10s, iOS ~60s
   
   Benefits:
   - 10x faster tests
   - Logic reusable in backend/ML/widgets
   - Calculations run on background threads
   "

Create PHASE1_COMPLETE.md with metrics and next steps.
```

---

## Phase 2: Cache Architecture Redesign (Days 8-12)

### Prompt 2.1 - Create Type-Safe CacheKey
```
Create type-safe cache key system:

1. Create Core/Data/Cache/ directory structure

2. Create CacheKey.swift enum with cases for:
   - Activities (strava, intervals)
   - Streams (by source and activity ID)
   - Scores (recovery, sleep, strain by date)
   - Baselines (HRV, RHR, sleep)
   - HealthKit (steps, calories, workouts)
   - Wellness
   
3. Each case should have:
   - description property (string representation)
   - ttl property (time-to-live for that key type)
   
4. Include comprehensive documentation

DO NOT write code - implement it.

Goal: Eliminate string-based cache keys, compiler-enforced consistency
```

### Prompt 2.2 - Extract CacheEncodingHelper
```
Extract encoding logic from UnifiedCacheManager:

1. Create CacheEncodingHelper.swift actor (300 lines from UnifiedCache)

2. Move all encoding/decoding methods:
   - encode<T: Codable>()
   - decode<T: Codable>()
   - encodeComplex() - handles NSDictionary/NSArray
   - encodeDictionary()
   - encodeArray()
   - All NSNumber/NSCFBoolean handling
   
3. Update UnifiedCacheManager to use CacheEncodingHelper

4. Verify tests still pass

Result: UnifiedCacheManager reduced from 1250 → 950 lines
```

### Prompt 2.3 - Implement Cache Layers
```
Create layered cache architecture:

1. Create cache layer interfaces/protocols

2. Implement three layers:
   - MemoryCacheLayer.swift (150 lines)
     - NSCache-based
     - Request deduplication
     - Eviction policy
     
   - DiskCacheLayer.swift (200 lines)
     - UserDefaults for small data
     - FileManager for large data
     - Size-based storage decision
     
   - CoreDataCacheLayer.swift (100 lines)
     - Wraps existing CachePersistenceLayer
     - Provides consistent interface
     
3. Each layer should be independently testable

Goal: Clear separation, each layer <300 lines
```

### Prompt 2.4 - Create CacheOrchestrator
```
Create cache orchestrator to coordinate layers:

1. Create CacheOrchestrator.swift (200 lines) that:
   - Uses CacheKey (type-safe)
   - Uses CacheEncodingHelper
   - Coordinates three layers (Memory → Disk → CoreData)
   - Handles offline fallback
   - Implements fetchCacheFirst strategy
   
2. Provide same interface as old UnifiedCacheManager

3. Update a single service (UnifiedActivityService) to use new orchestrator as proof-of-concept

4. Verify cache works correctly

Goal: Thin orchestration layer with clear responsibilities
```

### Prompt 2.5 - Migrate All Services to New Cache
```
Migrate all services from old cache systems to CacheOrchestrator:

1. Update services one by one:
   - Replace StreamCacheService calls with CacheOrchestrator
   - Replace IntervalsCache calls with CacheOrchestrator
   - Replace HealthKitCache calls with CacheOrchestrator
   - Use CacheKey enum (no string keys)
   
2. Test each service after migration

3. Verify cache hit rates in debug tools

Pattern:
OLD: StreamCacheService.shared.getCachedStreams(activityId: id)
NEW: CacheOrchestrator.shared.fetch(key: .stream(source: .strava, activityId: id), ttl: .days(7)) { ... }
```

### Prompt 2.6 - Delete Legacy Cache Systems
```
Delete old cache implementations:

1. Delete files identified in AUDIT_LEANNESS.md:
   - StreamCacheService.swift (364 lines)
   - IntervalsCache.swift (243 lines)
   - HealthKitCache.swift (79 lines)
   - StravaAthleteCache.swift
   
2. Keep CacheManager.swift but document it's only for DailyScores until SwiftData migration

3. Run grep to ensure no references to deleted files remain

4. Run full test suite

5. Commit Phase 2:
   git commit -m "refactor(phase2): redesign cache architecture

   - Type-safe CacheKey enum (no more string typos)
   - Layered architecture (Memory/Disk/CoreData)
   - Each layer <300 lines with clear responsibility
   - Deleted 4 legacy cache systems (~1455 lines)
   
   Benefits:
   - Compiler-enforced cache key consistency
   - Easy to swap implementations
   - Clear separation of concerns
   - Won't outgrow itself
   "

Verify: 1455 lines deleted, cache hit rate >80%
```

---

## Phase 3: Performance Optimization (Days 11-12)

### Prompt 3.1 - Identify @MainActor Services
```
Audit services for @MainActor usage:

1. Find all services marked @MainActor
2. Categorize:
   - Must stay @MainActor (UI-heavy, ObservableObject needed)
   - Should become actor (calculation-heavy, can run background)
   
3. Create MAINACTOR_AUDIT.md with:
   - List of services to convert
   - Why each should/shouldn't convert
   - Priority order (calculation services first)
   
Target: Convert 20-25 calculation services to actors
```

### Prompt 3.2 - Convert Calculation Services to Actors
```
Remove @MainActor from calculation services:

Convert these services from @MainActor class to actor:
- RecoveryScoreService
- SleepScoreService
- StrainScoreService
- TrainingLoadCalculator
- BaselineCalculator
- IllnessDetectionService
- WellnessDetectionService

Pattern for each:
1. Change from @MainActor class to actor
2. Mark calculation methods as nonisolated (run on background)
3. Keep @Published properties with @MainActor
4. Only touch main thread for UI updates via MainActor.run {}
5. Test after each conversion

Goal: Heavy calculations never block UI
```

### Prompt 3.3 - Optimize TodayViewModel Startup
```
Optimize TodayViewModel to reduce startup time:

1. Implement 3-phase loading:
   - Phase 1: Show cached scores immediately (<100ms)
   - Phase 2: Update critical scores in parallel (200ms-2s)
   - Phase 3: Background load non-critical data
   
2. Use withTaskGroup for parallel execution

3. Ensure calculations use background threads (actor services)

4. Measure startup time before/after

Target: 8s → <2s startup time
```

### Prompt 3.4 - Phase 3 Verification
```
Verify Phase 3 performance improvements:

1. Measure app startup time (use Instruments or manual timing)
2. Verify UI never blocks during score calculations
3. Test on device: iPhone 14, 15 Pro
4. Run full test suite

5. Commit Phase 3:
   git commit -m "perf(phase3): remove @MainActor from calculation services

   - Converted 20+ services to actors
   - Calculations run on background threads
   - Optimized TodayViewModel with parallel loading
   
   Performance:
   - App startup: 8s → 2s (75% faster)
   - UI never blocks during calculations
   - True parallel execution
   "

Create PHASE3_COMPLETE.md with before/after metrics.
```

---

## Phase 4: File Organization (Days 13-15)

### Prompt 4.1 - Split HealthKitManager
```
Split HealthKitManager (1669 lines) by concern:

1. Create Core/Networking/HealthKit/ directory

2. Split into 4 files:
   - HealthKitManager.swift (200 lines) - Coordinator
   - HealthKitAuthorization.swift (100 lines) - Permissions
   - HealthKitDataFetcher.swift (400 lines) - Fetch raw HK samples
   - HealthKitTransformer.swift (200 lines) - Transform to app models
   
3. Update HealthKitManager to use sub-components

4. Update all callers:
   OLD: HealthKitManager.shared.fetchLatestHRV()
   NEW: HealthKitManager.shared.dataFetcher.fetchLatestHRV()
   
5. Run tests after each change

Goal: Clear separation of concerns, each file <500 lines
```

### Prompt 4.2 - Reorganize Debug Section
```
Overhaul debug section for usability:

1. Delete DebugDashboardView.swift (0 bytes - dead file)

2. Split DebugSettingsView (1288 lines) into:
   - DebugHub.swift (100 lines) - TabView navigation
   - DebugAuthView.swift (150 lines) - Auth, OAuth
   - DebugDataView.swift (200 lines) - Cache, Core Data
   - DebugFeaturesView.swift (200 lines) - Pro features
   - DebugNetworkView.swift (150 lines) - API debugging
   - DebugHealthView.swift (150 lines) - HealthKit, scores
   
3. Keep existing dashboards:
   - ServiceHealthDashboard.swift
   - TelemetryDashboard.swift
   - CardGalleryView.swift
   
4. Apply design system to all debug views:
   - Use VRText, VRBadge
   - Use Spacing tokens
   - Use ColorScale
   - Abstract strings to DebugContent

Goal: Organized by task, design system compliant
```

### Prompt 4.3 - Organize Services by Domain
```
Organize services into domain-based directories:

1. Create structure:
   Core/Services/
   ├── Scoring/
   │   ├── RecoveryScoreService.swift
   │   ├── SleepScoreService.swift
   │   └── StrainScoreService.swift
   ├── Data/
   │   ├── UnifiedActivityService.swift
   │   ├── StravaDataService.swift
   │   └── WorkoutMetadataService.swift
   ├── Location/
   │   ├── LocationGeocodingService.swift
   │   └── MapSnapshotService.swift
   └── ML/
       └── (already organized)
       
2. Move files to appropriate directories

3. Update imports across codebase

4. Verify build succeeds

Goal: Services discoverable by domain
```

### Prompt 4.4 - Phase 4 Verification
```
Verify Phase 4 file organization:

1. Check no files >900 lines
2. Verify clear directory structure
3. Run full test suite
4. Verify debug section is organized and usable

5. Commit Phase 4:
   git commit -m "refactor(phase4): organize files by concern

   - Split HealthKitManager: 1669 → 4 files of <500 lines
   - Reorganized debug section: 1288 → 6 organized files
   - Organized services by domain (Scoring, Data, Location, ML)
   
   Results:
   - All files <900 lines
   - Clear navigation
   - Easy to find code
   "
```

---

## Phase 5: Leanness Cleanup (Days 16-18)

### Prompt 5.1 - Delete Dead and Duplicate Code
```
Delete dead and duplicate code identified in AUDIT_LEANNESS.md:

1. Delete commented code blocks (use audit report)
2. Delete duplicate calculation implementations (already consolidated in Phase 1)
3. Remove unused imports
4. Remove unused variables/functions flagged by Xcode

5. Run SwiftLint with aggressive rules to find more cleanup opportunities

Target: Delete 500-1000 additional lines
```

### Prompt 5.2 - Service Consolidation
```
Merge small services identified in AUDIT_LEANNESS.md:

Services to merge:
- RecoverySleepCorrelationService → RecoveryScoreService
- SleepDebtService → SleepScoreService
- VO2MaxTrackingService → AthleteZoneService
- ActivityDeduplicationService → UnifiedActivityService
- ActivityLocationService → MapSnapshotService

For each:
1. Move methods to parent service
2. Delete merged service file
3. Update references
4. Test

Target: 28 → 20 services, delete ~900 lines
```

### Prompt 5.3 - Fix Design System Violations
```
Fix all design system violations from AUDIT_DESIGN.md:

1. Hard-coded strings → Content enums:
   Replace Text("...") with VRText(CommonContent.xxx)
   
2. Hard-coded spacing → Spacing tokens:
   Replace .padding(12) with .padding(Spacing.md)
   
3. Hard-coded colors → ColorScale:
   Replace Color.blue with ColorScale.blueAccent
   
4. Text → VRText migration:
   Convert remaining Text() to VRText()
   Target: 95%+ VRText usage
   
5. Fix StandardCard external padding issue (from memory)

Work through violations file by file, test after each.
```

### Prompt 5.4 - Resolve TODOs
```
Clean up technical debt markers:

1. Review all 48 TODOs/FIXMEs from audit

2. Categorize and handle:
   - High priority (15-20): Fix now
   - Document (10-15): Add explanation why deferred
   - Delete (15-20): Outdated, no longer relevant
   
3. Focus on high-value files:
   - TrendsViewModel (7 TODOs)
   - RideSummaryService (4 TODOs)
   - StrainScoreService (3 TODOs)
   
Target: 48 → <10 TODOs remaining
```

### Prompt 5.5 - Phase 5 Verification
```
Verify Phase 5 leanness cleanup:

1. Count total lines: should be ~84,000 (was 88,882)
2. Count services: should be ~20 (was 28)
3. Count cache systems: should be 1 (was 5)
4. Count TODOs: should be <10 (was 48)
5. Design system compliance: should be 100%

6. Run full test suite

7. Commit Phase 5:
   git commit -m "refactor(phase5): comprehensive leanness cleanup

   - Deleted 2500+ lines (dead code, duplicates, old caches)
   - Consolidated 28 → 20 services
   - Fixed 50+ design system violations
   - Resolved 40+ TODOs
   
   Results:
   - Codebase: 88,882 → 84,000 lines (-5%)
   - 100% design system compliance
   - Clean, maintainable foundation
   "
```

---

## Phase 6: Final Verification & Documentation (Days 19-21)

### Prompt 6.1 - Comprehensive Testing
```
Run comprehensive test suite:

1. VeloReadyCore tests:
   cd VeloReadyCore && swift test
   Verify: <10 seconds, all pass
   
2. iOS tests:
   ./Scripts/quick-test.sh
   Verify: ~60 seconds, all pass
   
3. Manual QA checklist:
   - Fresh install → onboarding flow
   - Connect Strava → activities load
   - All scores calculate correctly
   - Cache works (clear → refetch → cache hit)
   - Offline mode works (airplane mode)
   - Debug section organized and functional
   
4. Performance testing:
   - Measure app startup time (<2s target)
   - Verify UI never blocks
   - Check memory usage in Instruments
   
Document any issues found for fixing.
```

### Prompt 6.2 - Create Success Metrics Report
```
Create REFACTOR_SUMMARY.md documenting complete refactor:

Include before/after metrics for:

1. Code Quality:
   - Total lines (88,882 → ~84,000)
   - Services count (28 → 20)
   - Cache systems (5 → 1)
   - Largest file (1669 → <900)
   - TODOs (48 → <10)
   
2. Performance:
   - App startup (8s → 2s)
   - VeloReadyCore tests (N/A → <10s)
   - iOS tests (62s → 60s)
   - Cache hit rate (60% → 85%)
   
3. Design System:
   - VRText usage (60% → 95%)
   - Hard-coded values (50+ → 0)
   - Violations (many → 0)
   
4. Developer Velocity:
   - Find function (scroll 1669 lines → <5s)
   - Test calculations (60s → 5s)
   
Include architecture diagrams showing new structure.
```

### Prompt 6.3 - Update Documentation
```
Update all documentation to reflect refactor:

1. Update README.md with new architecture
2. Update TESTING_GUIDE.md with VeloReadyCore instructions
3. Document cache architecture in CACHE_ARCHITECTURE.md
4. Update .windsurfrules with any new patterns

Ensure documentation is accurate for next developer.
```

### Prompt 6.4 - Final Commit & Merge
```
Prepare final merge to main:

1. Review all commits on large-refactor branch
2. Ensure all tests pass
3. Create comprehensive commit message

4. Tag pre-refactor state (if not done):
   git checkout main
   git tag -a v1.0-pre-refactor -m "State before large refactor"
   git push origin v1.0-pre-refactor

5. Merge with squash:
   git checkout main
   git merge large-refactor --squash
   
6. Create final commit message:
   git commit -m "refactor: establish scalable architectural foundation

   [Include comprehensive summary from REFACTOR_SUMMARY.md]
   
   See REFACTOR_SUMMARY.md for complete metrics and details.
   "

7. Push to main:
   git push origin main

8. Create GitHub release with refactor summary

Refactor complete! 🎉
```

---

## How to Use This Document

1. **Work through phases sequentially** - each builds on previous
2. **Copy/paste prompts verbatim** - they're designed to be self-contained
3. **Review output before moving to next prompt** - ensure quality
4. **Run tests after each prompt** - catch issues early
5. **Commit frequently** - use suggested commit messages

## Estimated Timeline

- **Phase 0:** 2 days (audit)
- **Phase 1:** 5 days (VeloReadyCore)
- **Phase 2:** 5 days (cache)
- **Phase 3:** 2 days (performance)
- **Phase 4:** 3 days (organization)
- **Phase 5:** 3 days (cleanup)
- **Phase 6:** 1 day (verification)

**Total:** ~21 days (3 weeks)

## Success Criteria

After completing all phases:
- ✅ All tests pass (VeloReadyCore <10s, iOS ~60s)
- ✅ App startup <2s (was 3-8s)
- ✅ All files <900 lines
- ✅ Cache hit rate >85%
- ✅ 100% design system compliance
- ✅ Clean, scalable foundation for next 6-12 months
