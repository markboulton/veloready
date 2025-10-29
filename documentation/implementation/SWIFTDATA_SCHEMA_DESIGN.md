# SwiftData Schema Design - V1

**Date:** October 25, 2025  
**Status:** DESIGN COMPLETE  
**Purpose:** Define SwiftData models with class inheritance for iOS 26+

---

## Overview

SwiftData schema replaces CoreData with modern Swift-native models. Key improvements:

- ✅ **Class inheritance** for hierarchical data (Workout → CardioWorkout, StrengthWorkout)
- ✅ **@Query macros** for reactive SwiftUI integration
- ✅ **Simpler API** (no NSManagedObject boilerplate)
- ✅ **Automatic CloudKit sync** (via @Model)
- ✅ **Schema versioning** for future migrations

---

## Base Models

### DailyMetric (Base Class)

```swift
import SwiftData
import Foundation

/// Base class for all daily metrics
@Model
final class DailyMetric {
    @Attribute(.unique) var date: Date
    var userId: String
    var athleteId: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date, userId: String, athleteId: Int) {
        self.date = date
        self.userId = userId
        self.athleteId = athleteId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**Purpose:** Common properties for all daily metrics  
**Unique Constraint:** `date` (one record per day per user)  
**CloudKit Sync:** ✅ Automatic

---

## Daily Metrics Models

### DailyScore

```swift
@Model
final class DailyScore: DailyMetric {
    var recoveryScore: Double?
    var recoveryBand: String? // "green", "amber", "red"
    var sleepScore: Double?
    var strainScore: Double?
    var effortTarget: Double?
    var aiBriefText: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var physio: DailyPhysio?
    @Relationship(deleteRule: .cascade) var load: DailyLoad?
    
    init(date: Date, userId: String, athleteId: Int) {
        super.init(date: date, userId: userId, athleteId: athleteId)
    }
}
```

**Migration from CoreData:**
```swift
// CoreData
let cdScore = DailyScores(context: context)
cdScore.date = date
cdScore.recoveryScore = 72.5

// SwiftData
let swiftDataScore = DailyScore(date: date, userId: userId, athleteId: athleteId)
swiftDataScore.recoveryScore = 72.5
modelContext.insert(swiftDataScore)
```

---

### DailyPhysio

```swift
@Model
final class DailyPhysio: DailyMetric {
    var hrv: Double?
    var hrvBaseline: Double?
    var rhr: Double?
    var rhrBaseline: Double?
    var sleepDuration: Double? // seconds
    var sleepBaseline: Double? // seconds
    
    init(date: Date, userId: String, athleteId: Int) {
        super.init(date: date, userId: userId, athleteId: athleteId)
    }
}
```

**Data Quality Helpers:**
```swift
extension DailyPhysio {
    var hrvDelta: Double? {
        guard let hrv = hrv, let baseline = hrvBaseline else { return nil }
        return hrv - baseline
    }
    
    var rhrDelta: Double? {
        guard let rhr = rhr, let baseline = rhrBaseline else { return nil }
        return rhr - baseline
    }
    
    var sleepDebtHours: Double? {
        guard let duration = sleepDuration, let baseline = sleepBaseline else { return nil }
        return (baseline - duration) / 3600
    }
}
```

---

### DailyLoad

```swift
@Model
final class DailyLoad: DailyMetric {
    var ctl: Double?
    var atl: Double?
    var tsb: Double?
    var tss: Double?
    var eftp: Double?
    var workoutId: String?
    var workoutName: String?
    var workoutType: String?
    
    init(date: Date, userId: String, athleteId: Int) {
        super.init(date: date, userId: userId, athleteId: athleteId)
    }
}
```

**Computed Properties:**
```swift
extension DailyLoad {
    var isFresh: Bool {
        guard let tsb = tsb else { return false }
        return tsb > 25 // Positive TSB indicates freshness
    }
    
    var isFatigued: Bool {
        guard let tsb = tsb else { return false }
        return tsb < -10 // Negative TSB indicates fatigue
    }
    
    var trainingStress: String {
        guard let tss = tss else { return "Rest" }
        switch tss {
        case 0..<50: return "Easy"
        case 50..<100: return "Moderate"
        case 100..<150: return "Hard"
        default: return "Very Hard"
        }
    }
}
```

---

### MLTrainingData

```swift
@Model
final class MLTrainingData: DailyMetric {
    @Attribute(.unique) var id: UUID
    
    // Feature vector (stored as JSON string)
    var featureVectorJSON: String?
    
    // Target values
    var targetRecoveryScore: Double
    var targetReadinessScore: Double
    
    // Predictions
    var actualRecoveryScore: Double
    var actualReadinessScore: Double
    var predictionError: Double
    var predictionConfidence: Double
    
    // Metadata
    var modelVersion: String?
    var trainingPhase: String? // "baseline", "weights", "lstm"
    var dataQualityScore: Double
    var isValidTrainingData: Bool
    
    init(date: Date, userId: String, athleteId: Int) {
        self.id = UUID()
        super.init(date: date, userId: userId, athleteId: athleteId)
        self.targetRecoveryScore = 0
        self.targetReadinessScore = 0
        self.actualRecoveryScore = 0
        self.actualReadinessScore = 0
        self.predictionError = 0
        self.predictionConfidence = 0
        self.dataQualityScore = 0
        self.isValidTrainingData = false
    }
}
```

**Feature Vector Helpers:**
```swift
extension MLTrainingData {
    struct FeatureVector: Codable {
        var hrv: Double?
        var hrv_baseline: Double?
        var hrv_delta: Double?
        var rhr: Double?
        var rhr_baseline: Double?
        var rhr_delta: Double?
        var sleep_duration: Double?
        var sleep_baseline: Double?
        var sleep_delta: Double?
        var yesterday_strain: Double?
        var yesterday_tss: Double?
        var ctl: Double?
        var atl: Double?
        var tsb: Double?
        var day_of_week: Int?
        var recovery_trend_7d: Double?
    }
    
    var featureVector: FeatureVector? {
        guard let json = featureVectorJSON else { return nil }
        return try? JSONDecoder().decode(FeatureVector.self, from: json.data(using: .utf8) ?? Data())
    }
    
    func setFeatureVector(_ features: FeatureVector) {
        featureVectorJSON = try? String(data: JSONEncoder().encode(features), encoding: .utf8)
    }
}
```

---

## Hierarchical Workout Models

### Workout (Base Class)

```swift
@Model
final class Workout {
    @Attribute(.unique) var id: String
    var userId: String
    var athleteId: Int
    var startDate: Date
    var duration: TimeInterval // seconds
    var type: WorkoutType
    var distance: Double? // meters
    var elevation: Double? // meters
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, userId: String, athleteId: Int, startDate: Date, type: WorkoutType) {
        self.id = id
        self.userId = userId
        self.athleteId = athleteId
        self.startDate = startDate
        self.type = type
        self.duration = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum WorkoutType: String, Codable {
    case ride = "Ride"
    case run = "Run"
    case strength = "Strength"
    case swim = "Swim"
    case other = "Other"
}
```

---

### CardioWorkout

```swift
@Model
final class CardioWorkout: Workout {
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var avgPower: Double? // watts
    var normalizedPower: Double? // watts
    var tss: Double? // Training Stress Score
    var ifValue: Double? // Intensity Factor
    var variabilityIndex: Double? // Power variability %
    
    init(id: String, userId: String, athleteId: Int, startDate: Date) {
        super.init(id: id, userId: userId, athleteId: athleteId, startDate: startDate, type: .ride)
    }
}
```

**Computed Properties:**
```swift
extension CardioWorkout {
    var avgHeartRateZone: Int? {
        guard let avgHR = avgHeartRate else { return nil }
        // Zones: 1=<60%, 2=60-70%, 3=70-80%, 4=80-90%, 5=90-100%
        let maxHR = 178 // User's max HR
        let percentage = Double(avgHR) / Double(maxHR) * 100
        return Int(percentage / 20) + 1
    }
    
    var powerZoneDistribution: [Int: Double]? {
        // Would require stream data (not in base model)
        return nil
    }
}
```

---

### StrengthWorkout

```swift
@Model
final class StrengthWorkout: Workout {
    var exercises: [Exercise]?
    var totalReps: Int?
    var totalSets: Int?
    var totalWeight: Double? // kg
    var avgRPE: Double? // Rate of Perceived Exertion (1-10)
    
    init(id: String, userId: String, athleteId: Int, startDate: Date) {
        super.init(id: id, userId: userId, athleteId: athleteId, startDate: startDate, type: .strength)
    }
}

@Model
final class Exercise {
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double? // kg
    var rpe: Double? // Rate of Perceived Exertion
    
    init(name: String, sets: Int, reps: Int) {
        self.name = name
        self.sets = sets
        self.reps = reps
    }
}
```

---

## Schema Container Configuration

```swift
import SwiftData

struct SwiftDataConfig {
    static func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            // Daily metrics
            DailyScore.self,
            DailyPhysio.self,
            DailyLoad.self,
            MLTrainingData.self,
            // Workouts
            Workout.self,
            CardioWorkout.self,
            StrengthWorkout.self,
            Exercise.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowUndefinedAttributes: false
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
```

---

## Query Examples

### Using @Query Macro

```swift
// Fetch today's scores
@Query(sort: \.date, order: .reverse)
var dailyScores: [DailyScore]

// Fetch last 7 days
@Query(where: #Predicate { score in
    score.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
}, sort: \.date, order: .reverse)
var last7Days: [DailyScore]

// Fetch with filter
@Query(where: #Predicate { score in
    score.recoveryScore ?? 0 > 70
}, sort: \.date, order: .reverse)
var goodRecoveryDays: [DailyScore]

// Fetch CardioWorkouts with high TSS
@Query(where: #Predicate { workout in
    (workout as? CardioWorkout)?.tss ?? 0 > 100
}, sort: \.startDate, order: .reverse)
var hardWorkouts: [CardioWorkout]
```

### Manual Queries (if needed)

```swift
@Environment(\.modelContext) var modelContext

func fetchTodayScores() throws -> [DailyScore] {
    let today = Calendar.current.startOfDay(for: Date())
    var descriptor = FetchDescriptor<DailyScore>(
        predicate: #Predicate { $0.date == today }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor)
}
```

---

## Migration Mapping

### CoreData → SwiftData

| CoreData | SwiftData | Notes |
|----------|-----------|-------|
| NSManagedObject | @Model class | Direct mapping |
| @NSManaged var | var (property) | Direct mapping |
| NSFetchRequest | @Query macro | Reactive queries |
| NSPredicate | #Predicate | Type-safe predicates |
| Relationships | @Relationship | Automatic cascade |
| CloudKit sync | Automatic | @Model syncs to CloudKit |

### Data Type Conversions

| CoreData | SwiftData | Conversion |
|----------|-----------|-----------|
| Date | Date | Direct |
| Double | Double | Direct |
| String | String | Direct |
| Bool | Bool | Direct |
| UUID | UUID | Direct |
| Data (JSON) | String (JSON) | Encode/decode |
| NSManagedObject | @Model | Rewrite as class |

---

## Validation Rules

### DailyScore

```swift
extension DailyScore {
    var isValid: Bool {
        guard let recovery = recoveryScore else { return false }
        return recovery >= 0 && recovery <= 100
    }
    
    func validate() throws {
        guard isValid else {
            throw ValidationError.invalidRecoveryScore
        }
    }
}

enum ValidationError: Error {
    case invalidRecoveryScore
    case invalidSleepScore
    case invalidStrainScore
}
```

### Workout

```swift
extension Workout {
    var isValid: Bool {
        return duration > 0 && !id.isEmpty
    }
}

extension CardioWorkout {
    var isValid: Bool {
        guard super.isValid else { return false }
        if let avgHR = avgHeartRate {
            return avgHR > 0 && avgHR < 220
        }
        return true
    }
}
```

---

## Performance Considerations

### Indexing Strategy

```swift
@Model
final class DailyScore: DailyMetric {
    @Attribute(.unique) var date: Date // Indexed for queries
    @Attribute(.indexed) var userId: String // Indexed for filtering
    var recoveryScore: Double?
    // Other properties...
}
```

### Query Performance Targets

| Query | Target | Notes |
|-------|--------|-------|
| Fetch today's score | <5ms | Indexed on date |
| Fetch 30 days | <15ms | Range query |
| Fetch with relationships | <20ms | Prefetch enabled |
| Save single record | <10ms | Background context |
| Batch save (100) | <50ms | Batch operation |

---

## Schema Versioning

### Version 1 (Current)

```swift
enum SchemaVersion: Int {
    case v1 = 1 // Initial SwiftData migration
    case v2 = 2 // Future: Add new fields
}
```

### Migration Strategy

```swift
// In app initialization
let schema = Schema([DailyScore.self, DailyPhysio.self, ...])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowUndefinedAttributes: false // Strict schema
)
```

### Future Migrations (V2+)

```swift
// Example: Adding new field to DailyScore
@Model
final class DailyScore: DailyMetric {
    // ... existing fields ...
    var illnessIndicator: String? // NEW in V2
}

// Migration plan:
// 1. Add field with default value
// 2. Increment schema version
// 3. Update migration logic
// 4. Test on sample data
```

---

## CloudKit Sync

### Automatic Configuration

SwiftData automatically syncs @Model classes to CloudKit if:
- Container is created with default configuration
- iCloud is enabled on device
- App has CloudKit entitlements

### Manual Configuration (if needed)

```swift
let config = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .private // or .public, .shared
)
```

---

## Testing Strategy

### Unit Tests

```swift
@MainActor
class DailyScoreTests: XCTestCase {
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyScore.self, configurations: [config])
        modelContext = ModelContext(container)
    }
    
    func testDailyScoreCreation() throws {
        let score = DailyScore(date: Date(), userId: "user1", athleteId: 123)
        score.recoveryScore = 75.0
        
        modelContext.insert(score)
        try modelContext.save()
        
        let fetched = try modelContext.fetch(FetchDescriptor<DailyScore>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].recoveryScore, 75.0)
    }
}
```

---

## Next Steps

1. ✅ **CoreData Audit** (COREDATA_AUDIT.md)
2. ✅ **SwiftData Schema Design** (this document)
3. ⏳ **Build Migration Tool** (Phase 2.1)
4. ⏳ **Create Test Fixtures** (Phase 2.2)
5. ⏳ **Test Migration** (Phase 2.3)

---

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftData WWDC 2023](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [Model Macro](https://developer.apple.com/documentation/swiftdata/model())
- [Query Macro](https://developer.apple.com/documentation/swiftdata/query())

---

**Document Version:** 1.0  
**Created:** October 25, 2025  
**Status:** DESIGN COMPLETE  
**Owner:** Mark Boulton
