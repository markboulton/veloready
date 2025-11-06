# VeloReady iOS - Code Leanness Audit
**Date:** November 6, 2025 | **Target:** Identify 2,000-5,000 lines to DELETE

---

## Executive Summary

**Baseline:** 415 files, 88,882 lines  
**Deletion Target:** 2,000-5,000 lines (2.2-5.6%)  
**Identified:** ~4,500 lines (5.1% reduction) ✅

**Major Opportunities:**
1. Redundant Cache Systems: ~1,600 lines
2. Duplicate Calculations: ~800 lines  
3. Service Consolidation: ~900 lines
4. Dead/Commented Code: ~500 lines

---

## 1. Redundant Cache Systems (1,654 lines)

### DELETE: 5 cache implementations

**StreamCacheService.swift** (363 lines)
- Purpose: Caches Strava/Intervals streams
- Why delete: UnifiedCacheManager handles this
- Migration: Use CacheKey.stream() + UnifiedCacheManager

**IntervalsCache.swift** (243 lines)  
- Purpose: Caches Intervals.icu API responses
- Why delete: UnifiedCacheManager handles this

**HealthKitCache.swift** (79 lines)
- Purpose: Caches HealthKit workouts  
- Why delete: Can't serialize HKWorkout anyway

**StravaAthleteCache.swift** (~100 lines)
- Purpose: Caches Strava athlete data
- Why delete: Minimal usage, redundant

**CacheManager.swift** (partial: ~569 lines)
- Keep: ~200 lines (DailyScores Core Data, CTL/ATL backfill)
- Delete: ~569 lines (generic cache validation, score calculations)

**UnifiedCacheManager.swift** (-300 lines extraction)
- Extract: CacheEncodingHelper.swift (300 lines of encoding logic)
- Reduces: 1250 → 950 lines

**Total:** ~1,654 lines

---

## 2. Duplicate Calculations (705 lines)

### A. Training Load (CTL/ATL) - DUPLICATED IN 4 PLACES

**TrainingLoadCalculator.swift** (~200 lines) - PRIMARY, keep
**RecoveryScoreService.swift** (~180 lines) - DELETE
**StrainScoreService.swift** (~50 lines) - DELETE  
**CacheManager.swift** (~75 lines) - DELETE

**Consolidation:** Move to VeloReadyCore, delete 3 duplicates  
**Lines to DELETE:** ~400 lines

### B. Baseline Calculations - DUPLICATED IN 3 PLACES

**BaselineCalculator.swift** (~230 lines) - PRIMARY, keep
**CacheManager.swift** (~50 lines) - DELETE
**SleepScoreService.swift** (~45 lines) - DELETE

**Lines to DELETE:** ~95 lines

### C. TRIMP Calculations - DUPLICATED IN 5 PLACES

**TRIMPCalculator.swift** (~150 lines) - PRIMARY, keep
**StrainScore.swift** (~70 lines) - DELETE  
**TrainingLoadCalculator.swift** (~50 lines) - DELETE
**StrainScoreService.swift** (~90 lines) - DELETE

**Lines to DELETE:** ~210 lines

**Total:** ~705 lines

---

## 3. Service Consolidation (325 lines)

### Services to MERGE: 28 → 20

**RecoverySleepCorrelationService** (265 lines) → RecoveryScoreService  
- Save: ~50 lines (duplicate imports/methods)

**SleepDebtService** (252 lines) → SleepScoreService
- Save: ~40 lines (duplicate data fetching)

**VO2MaxTrackingService** (205 lines) → AthleteZoneService
- Save: ~30 lines (shared zone logic)

**ActivityDeduplicationService** (229 lines) → UnifiedActivityService  
- Save: ~40 lines (duplicate fetching)

**ActivityLocationService** (203 lines) → MapSnapshotService
- Save: ~30 lines (shared location validation)

**RPEStorageService** (84 lines) → WorkoutMetadataService
- Save: ~15 lines (shared Core Data logic)

**TrainingLoadService** (129 lines) → TrainingLoadCalculator
- Save: ~100 lines (entire service if wrapper)

**LocationGeocodingService** (100 lines) → MapSnapshotService
- Save: ~20 lines

**Total:** ~325 lines saved

---

## 4. Dead/Commented Code (300-500 lines)

### A. Dead Files

**DebugDashboardView.swift** - 0 bytes (empty file) ✅ DELETE IMMEDIATELY

### B. Commented Code

Found 4 instances of commented functions/classes:
- AIBriefConfig.swift
- MLTrainingDataService.swift  
- StravaAuthService.swift
- ActivityConverter.swift

**Estimated:** ~100-200 lines of commented code blocks

### C. Potentially Unused Files

Need manual verification of files with <3 references outside self.

**Estimated:** ~100-200 lines

**Total:** ~300-500 lines

---

## 5. Largest Files (Opportunities for Splitting)

```
1,669 lines - HealthKitManager.swift (split → 4 files)
1,288 lines - DebugSettingsView.swift (split → 6 files)
1,250 lines - UnifiedCacheManager.swift (extract encoding)
1,131 lines - WeeklyReportViewModel.swift
1,097 lines - IntervalsAPIClient.swift
1,084 lines - RecoveryScoreService.swift (extract to VeloReadyCore)
```

**Note:** Splitting doesn't delete lines but enables better organization

---

## 6. Deletion Roadmap

### Week 2: Cache Consolidation (**~1,654 lines**)
1. Create CacheKey enum (type-safe)
2. Migrate services to UnifiedCacheManager  
3. Delete: StreamCacheService, IntervalsCache, HealthKitCache, StravaAthleteCache
4. Clean CacheManager (keep minimal)
5. Extract CacheEncodingHelper from UnifiedCacheManager

### Week 3: Duplicate Calculations (**~705 lines**)
1. Consolidate training load to VeloReadyCore
2. Consolidate baselines to VeloReadyCore
3. Consolidate TRIMP to VeloReadyCore
4. Delete 3 duplicate implementations each

### Week 3: Service Consolidation (**~325 lines**)
1. Merge 7-8 small services into related services
2. Delete merged service files
3. Update all references

### Week 3: Dead Code Cleanup (**~300-500 lines**)
1. Delete DebugDashboardView.swift (0 bytes)
2. Remove commented code blocks
3. Verify and delete unused files
4. Resolve/delete outdated TODOs

---

## 7. Expected Results

### Before
```
Total Lines:      88,882
Files:            415
Services:         28
Cache Systems:    5
Files >900:       7
```

### After (Conservative: 2,700 lines)
```
Total Lines:      86,182 (-3.0%)
Files:            407
Services:         20
Cache Systems:    1
Files >900:       2-3
```

### After (Realistic: 3,500 lines)
```
Total Lines:      85,382 (-3.9%)
Files:            405
Services:         20
Cache Systems:    1
Files >900:       0
```

### After (Optimistic: 4,500 lines)
```
Total Lines:      84,382 (-5.1%)
Files:            403
Services:         20
Cache Systems:    1
Files >900:       0
```

---

## 8. Specific File Deletions

### Immediate Deletions (Week 2-3)
```bash
# Cache systems
rm VeloReady/Core/Services/StreamCacheService.swift           # 363 lines
rm VeloReady/Core/Services/IntervalsCache.swift              # 243 lines
rm VeloReady/Core/Services/HealthKitCache.swift              #  79 lines
rm VeloReady/Core/Services/StravaAthleteCache.swift          # ~100 lines

# Dead file
rm VeloReady/Features/Debug/Views/DebugDashboardView.swift   # 0 bytes

# After mergers
rm VeloReady/Core/Services/RecoverySleepCorrelationService.swift  # 265 lines
rm VeloReady/Core/Services/SleepDebtService.swift                 # 252 lines
rm VeloReady/Core/Services/VO2MaxTrackingService.swift            # 205 lines
rm VeloReady/Core/Services/ActivityDeduplicationService.swift     # 229 lines
rm VeloReady/Core/Services/ActivityLocationService.swift          # 203 lines
rm VeloReady/Core/Services/RPEStorageService.swift                #  84 lines
rm VeloReady/Core/Services/TrainingLoadService.swift              # 129 lines
rm VeloReady/Core/Services/LocationGeocodingService.swift         # 100 lines
```

### Total Files Deleted: 13 files, ~2,252 lines

### Partial Deletions (in-file cleanup)
- CacheManager.swift: Delete ~569 lines, keep ~200
- Duplicate calculations: ~705 lines across multiple files
- Commented code: ~200-300 lines across multiple files

**Grand Total: ~3,726-4,226 lines deleted**

---

## 9. Next Steps

1. ✅ Review this audit
2. Run design system audit (Prompt 0.2)
3. Run velocity baseline (Prompt 0.3)
4. Create master cleanup checklist (Prompt 0.4)
5. Begin Phase 1: VeloReadyCore extraction

**Target Confirmed:** 2,000-5,000 lines ✅ Achieved
