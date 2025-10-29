# SwiftData Migration Plan - iOS 26 Minimum

**Status:** APPROVED - Option A (iOS 26 Minimum)  
**Decision Date:** October 25, 2025  
**Launch Date:** January 26, 2026  
**Timeline:** Q1 2026 (8-10 weeks post-launch)

---

## Executive Summary

VeloReady is transitioning from CoreData to SwiftData with iOS 26 as the minimum deployment target. This enables:

- **SwiftData class inheritance** for hierarchical workout models (Workout → StrengthWorkout, CardioWorkout, IntervalWorkout)
- **Simpler persistence layer** (no dual CoreData/SwiftData code)
- **MLX on-device AI integration** (Priority #1 per ops report)
- **Better SwiftUI integration** with @Query macros and reactive updates

---

## Phase 1: Pre-Migration (Weeks 1-2, Post-Launch)

### 1.1 Audit Existing CoreData Models

**Objective:** Understand current data structure before migration

**Tasks:**
- [ ] Identify all CoreData entities (DailyScores, DailyPhysio, MLTrainingData, etc.)
- [ ] Document relationships and constraints
- [ ] Export sample data for testing
- [ ] Create migration test fixtures

**Deliverable:** `COREDATA_AUDIT.md` with entity diagrams

### 1.2 Design SwiftData Schema V1

**Objective:** Design new SwiftData models with class inheritance

**Models to Create:**

```swift
// Base model with common properties
@Model
final class DailyMetric {
    @Attribute(.unique) var date: Date
    var userId: String
    var athleteId: Int
    var createdAt: Date
    var updatedAt: Date
}

// Specific metric types
@Model
final class DailyScore: DailyMetric {
    var recoveryScore: Double?
    var sleepScore: Double?
    var strainScore: Double?
    var hrv: Double?
    var rhr: Int?
}

@Model
final class DailyPhysio: DailyMetric {
    var activeCalories: Double?
    var totalCalories: Double?
    var steps: Int?
    var respiratoryRate: Double?
}

@Model
final class MLTrainingData: DailyMetric {
    var ctl: Double?
    var atl: Double?
    var tss: Double?
    var np: Double?
    var ifValue: Double?
}

// Hierarchical workout models
@Model
final class Workout {
    @Attribute(.unique) var id: String
    var userId: String
    var athleteId: Int
    var startDate: Date
    var duration: TimeInterval
    var type: WorkoutType
    var distance: Double?
    var elevation: Double?
}

@Model
final class CardioWorkout: Workout {
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var avgPower: Double?
    var normalizedPower: Double?
    var tss: Double?
}

@Model
final class StrengthWorkout: Workout {
    var exercises: [Exercise]?
    var totalReps: Int?
    var totalSets: Int?
}
```

**Deliverable:** `SwiftDataModels.swift` with all model definitions

### 1.3 Create Schema Versioning Strategy

**Objective:** Plan for future schema changes

**Implementation:**
```swift
enum SchemaVersion: Int {
    case v1 = 1  // Initial SwiftData migration
    case v2 = 2  // Future: Add new fields
}

// In app initialization:
let schema = Schema([DailyScore.self, DailyPhysio.self, MLTrainingData.self, Workout.self])
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
```

**Deliverable:** Schema versioning documentation

---

## Phase 2: Data Migration (Weeks 3-4)

### 2.1 Build Migration Tool

**Objective:** Transform CoreData → SwiftData without data loss

**Tasks:**
- [ ] Create `CoreDataToSwiftDataMigrator.swift`
- [ ] Implement batch migration (process in chunks to avoid memory spikes)
- [ ] Add progress tracking and logging
- [ ] Create rollback mechanism

**Pseudocode:**
```swift
class CoreDataToSwiftDataMigrator {
    func migrate() async throws {
        // 1. Read all CoreData entities
        let coreDataScores = try fetchAllCoreDataScores()
        
        // 2. Transform to SwiftData models
        let swiftDataScores = coreDataScores.map { coreDataScore in
            DailyScore(
                date: coreDataScore.date,
                userId: coreDataScore.userId,
                athleteId: coreDataScore.athleteId,
                recoveryScore: coreDataScore.recoveryScore,
                sleepScore: coreDataScore.sleepScore,
                strainScore: coreDataScore.strainScore
            )
        }
        
        // 3. Insert into SwiftData in batches
        for batch in swiftDataScores.chunked(into: 100) {
            modelContext.insert(contentsOf: batch)
            try modelContext.save()
        }
        
        // 4. Verify migration
        let migratedCount = try fetchAllSwiftDataScores().count
        assert(migratedCount == coreDataScores.count, "Migration count mismatch")
    }
}
```

**Deliverable:** Migration tool + test suite

### 2.2 Test Migration Path

**Objective:** Validate data integrity

**Tests:**
- [ ] Unit tests: Each model type migrates correctly
- [ ] Integration tests: Full migration on test device
- [ ] Data integrity: Count, checksums, date ranges
- [ ] Performance: Migration completes in <30 seconds
- [ ] Rollback: Can restore from backup

**Deliverable:** `MigrationTests.swift` with 100% coverage

### 2.3 Backup Strategy

**Objective:** Protect user data during migration

**Implementation:**
- [ ] Create backup of CoreData before migration
- [ ] Store backup in app sandbox
- [ ] Provide manual restore option
- [ ] Auto-delete backup after 7 days

---

## Phase 3: Implementation (Weeks 5-6)

### 3.1 Update ViewModels to Use SwiftData

**Objective:** Replace CoreData queries with SwiftData @Query

**Before (CoreData):**
```swift
@FetchRequest(
    entity: DailyScore.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \DailyScore.date, ascending: false)]
)
var scores: FetchedResults<DailyScore>
```

**After (SwiftData):**
```swift
@Query(sort: \.date, order: .reverse)
var scores: [DailyScore]
```

**Files to Update:**
- [ ] TodayViewModel.swift
- [ ] TrendsViewModel.swift
- [ ] RecoveryDetailViewModel.swift
- [ ] SleepDetailViewModel.swift
- [ ] StrainDetailViewModel.swift

**Deliverable:** Updated ViewModels with @Query macros

### 3.2 Implement Workout Class Hierarchy

**Objective:** Enable polymorphic workout queries

**Implementation:**
```swift
// Query all workouts (base type)
@Query
var allWorkouts: [Workout]

// Query specific types
@Query(where: \CardioWorkout.tss > 50)
var highTSSWorkouts: [CardioWorkout]

// Type-safe filtering
func cardioWorkouts() -> [CardioWorkout] {
    allWorkouts.compactMap { $0 as? CardioWorkout }
}
```

**Deliverable:** Workout hierarchy with polymorphic queries

### 3.3 Add Reactive Updates

**Objective:** Leverage SwiftData's reactive capabilities

**Implementation:**
```swift
@Observable
class RecoveryScoreService {
    @ObservationIgnored
    @Query(sort: \.date, order: .reverse)
    var dailyScores: [DailyScore]
    
    var latestScore: Double? {
        dailyScores.first?.recoveryScore
    }
}

// In View:
@State var recoveryService = RecoveryScoreService()

var body: some View {
    Text("Recovery: \(recoveryService.latestScore ?? 0)")
        // Automatically updates when dailyScores changes
}
```

**Deliverable:** Reactive service layer

---

## Phase 4: Testing & QA (Weeks 7-8)

### 4.1 Unit Tests

**Objective:** Verify model behavior

- [ ] Model initialization
- [ ] Relationships and constraints
- [ ] Query predicates
- [ ] Schema versioning

**Coverage Target:** >90%

### 4.2 Integration Tests

**Objective:** Verify end-to-end data flow

- [ ] Migration from CoreData
- [ ] CRUD operations
- [ ] Complex queries
- [ ] Performance benchmarks

### 4.3 User Acceptance Testing

**Objective:** Real-world validation

- [ ] Beta testers migrate their data
- [ ] No data loss
- [ ] App performance acceptable
- [ ] No crashes

**Deliverable:** UAT report + sign-off

---

## Phase 5: Rollout (Week 9)

### 5.1 Pre-Launch Checklist

- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Documentation complete
- [ ] Backup strategy tested
- [ ] Rollback plan documented

### 5.2 Staged Rollout

**Stage 1 (Day 1):** Internal testers (10 users)  
**Stage 2 (Day 2-3):** Beta testers (100 users)  
**Stage 3 (Day 4+):** General release

### 5.3 Monitoring

- [ ] Crash rate <0.1%
- [ ] Migration success rate >99%
- [ ] App startup time <2s
- [ ] Query performance <100ms

---

## Technical Decisions

### Why SwiftData over CoreData?

| Aspect | SwiftData | CoreData |
|--------|-----------|----------|
| API | Modern, Swift-native | Legacy, Objective-C |
| SwiftUI Integration | Native @Query macros | Requires @FetchRequest |
| Class Inheritance | ✅ Supported | ❌ Not supported |
| Code Complexity | Simpler | More boilerplate |
| Learning Curve | Easier | Steeper |

### Why iOS 26 Minimum?

- SwiftData class inheritance requires iOS 26+
- January 26 launch allows 6+ months for iOS 25 users to upgrade
- MLX integration (Priority #1) requires iOS 26 anyway
- Market precedent: Most apps drop support after 1-2 iOS versions

### Why Not Parallel CoreData/SwiftData?

**Rejected because:**
- 2x persistence code = 2x maintenance burden
- Dual query paths = testing complexity
- Sync logic between stores = potential data inconsistency
- No user-facing benefit (iOS 25 users will upgrade anyway)

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Data loss during migration | Low | Critical | Backup before migration, test on 1000+ records |
| Performance regression | Medium | High | Benchmark queries, add indexes |
| Migration timeout | Low | High | Batch processing, progress tracking |
| User confusion | Medium | Medium | In-app messaging, documentation |

---

## Success Criteria

✅ **Technical:**
- All CoreData data migrated to SwiftData
- Zero data loss
- Query performance within 10% of CoreData
- App startup time <2s
- Crash rate <0.1%

✅ **User Experience:**
- Seamless migration (no manual action required)
- No visible performance degradation
- New features enabled (MLX integration)

✅ **Business:**
- >99% migration success rate
- <1% rollback rate
- Positive user feedback

---

## Timeline Summary

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Pre-Migration | 2 weeks | Jan 27 | Feb 9 |
| Data Migration | 2 weeks | Feb 10 | Feb 23 |
| Implementation | 2 weeks | Feb 24 | Mar 9 |
| Testing & QA | 2 weeks | Mar 10 | Mar 23 |
| Rollout | 1 week | Mar 24 | Mar 30 |
| **Total** | **~9 weeks** | Jan 27 | Mar 30 |

---

## Next Steps

1. ✅ Update deployment target to iOS 26.0 (DONE)
2. ⏳ Audit existing CoreData models (Week 1)
3. ⏳ Design SwiftData schema (Week 1)
4. ⏳ Build migration tool (Week 2-3)
5. ⏳ Update ViewModels (Week 5-6)
6. ⏳ Comprehensive testing (Week 7-8)
7. ⏳ Staged rollout (Week 9)

---

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftData WWDC 2023 Session](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes)
- [VeloReady Ops Report](./ops/reports/initial-cycle.md) - MLX Priority #1

---

**Document Version:** 1.0  
**Last Updated:** October 25, 2025  
**Owner:** Mark Boulton  
**Status:** APPROVED
