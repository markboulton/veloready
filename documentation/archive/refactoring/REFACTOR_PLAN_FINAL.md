# VeloReady iOS - Architectural Refactor Plan (FINAL)
**Date:** November 6, 2025  
**Goal:** Super efficient, scalable, fast, performant, maintainable foundation  
**Timeline:** 2-3 weeks (proper foundation takes time)  
**Branch:** `large-refactor`

---

## What I Missed in V1 & V2

### V1 Missed:
- ❌ UnifiedCacheManager is 1250 lines because 300+ lines are encoding helpers (should be extracted)
- ❌ CachePersistenceLayer already exists (good separation, I ignored it)
- ❌ Real problem isn't multiple cache systems, it's **cache key chaos** and **no clear strategy**
- ❌ 42 services with @MainActor is a **critical performance killer** (not minor issue)

### V2 Missed:
- ❌ You explicitly said "cache needs to be fixed" - I made it optional
- ❌ Focused on developer convenience vs architectural quality
- ❌ Didn't address **service interdependencies** (RecoveryService → SleepService → BaselineCalculator)
- ❌ Didn't address **calculation duplication** (training load calculated in 4+ places)

---

## Real Architectural Problems

### 1. **Cache Architecture is SPLIT, Not Unified**

**Current Reality:**
```
UnifiedCacheManager (1250 lines)
├── Memory cache (NSCache logic)
├── Disk persistence (UserDefaults)
├── Type erasure (300+ lines of encoding)
├── Request deduplication
├── Offline fallback
├── TTL management
└── Migration logic

CachePersistenceLayer (234 lines) ← Separate actor for Core Data
CacheManager (769 lines) ← Legacy, still used for DailyScores
StreamCacheService (364 lines) ← Still used
IntervalsCache (243 lines) ← Still used
HealthKitCache (79 lines) ← Still used
```

**The Problem:**
- UnifiedCacheManager tries to be "unified" but ISN'T - other caches still exist
- It's doing too much (orchestration + implementation + encoding)
- No clear interface/protocol
- Cache keys are strings everywhere (inconsistent, typo-prone)

**The Solution - True Separation of Concerns:**
```
CacheOrchestrator (200 lines) ← NEW: Thin coordinator
├── Uses CacheKeyStrategy ← NEW: Type-safe keys
├── Delegates to layers:
    ├── MemoryCacheLayer ← Extract from UnifiedCache
    ├── DiskCacheLayer ← Extract from UnifiedCache  
    ├── CoreDataCacheLayer ← Use existing CachePersistenceLayer
└── Uses CacheEncodingHelper ← Extract 300 lines from UnifiedCache

Delete: StreamCacheService, IntervalsCache, HealthKitCache
Keep: CacheManager (only for DailyScores until SwiftData migration)
```

**Benefits:**
- Each layer <300 lines
- Clear responsibilities
- Easy to test
- Easy to swap implementations
- Type-safe keys
- Won't outgrow itself

---

### 2. **Business Logic Lives in Services (Wrong Layer)**

**Current Reality:**
```swift
@MainActor // ← BLOCKS UI!
class RecoveryScoreService: ObservableObject {
    func calculateRecoveryScore() async {
        // 1. Fetch data (good)
        let hrv = await healthKit.fetchHRV()
        
        // 2. Calculate score (WRONG - should be in VeloReadyCore)
        let score = calculateHRVComponent(hrv, baseline) // Complex math on main thread!
        
        // 3. Publish (good)
        self.currentRecoveryScore = score
    }
    
    // 400 lines of calculation logic that should be elsewhere
    private func calculateHRVComponent(...) -> Double { ... }
    private func calculateRHRComponent(...) -> Double { ... }
    private func applyAlcoholPenalty(...) -> Double { ... }
}
```

**The Problem:**
- Calculation logic is in iOS services (can't test without simulator)
- @MainActor forces calculations on main thread (UI blocks for 2-8s!)
- Logic is duplicated (training load calculated in 4 places)
- Can't reuse logic in backend/ML/widgets

**The Solution - Proper Layering:**
```swift
// VeloReadyCore (pure Swift, no iOS deps)
public struct RecoveryCalculations {
    public static func calculateScore(
        hrv: Double, 
        hrvBaseline: Double,
        rhr: Double,
        rhrBaseline: Double,
        sleep: SleepData
    ) -> RecoveryScore {
        // All calculation logic here
        // Can test in milliseconds
        // Can run on any thread
        // Can reuse in backend/ML
    }
}

// iOS Service (thin orchestrator)
actor RecoveryScoreService { // ← Actor, not @MainActor
    nonisolated func calculateRecoveryScore() async -> RecoveryScore {
        // 1. Fetch data (background thread)
        let hrv = await healthKit.fetchHRV()
        let rhr = await healthKit.fetchRHR()
        let sleep = await sleepService.getCurrentSleep()
        
        // 2. Calculate (background thread, using VeloReadyCore)
        let score = RecoveryCalculations.calculateScore(
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            rhr: rhr,
            rhrBaseline: rhrBaseline,
            sleep: sleep
        )
        
        // 3. Publish (main thread only when updating UI)
        await MainActor.run {
            self.currentRecoveryScore = score
        }
        
        return score
    }
}
```

**Benefits:**
- Calculations run on background threads (UI never blocks)
- VeloReadyCore tests run in 5s (not 60s)
- Logic is reusable (backend, ML, widgets)
- Services are thin (<200 lines)
- Clear separation

---

### 3. **Service Interdependencies Create Race Conditions**

**Current Reality:**
```
TodayViewModel
    ↓ (parallel)
    ├─→ RecoveryScoreService
    │       ↓ (needs sleep first)
    │       └─→ SleepScoreService ← RACE CONDITION
    │               ↓
    │               └─→ HealthKitManager
    │
    └─→ SleepScoreService (also started in parallel!)
            ↓ (already running)
            └─→ Returns immediately, no data
```

You've ALREADY fixed one race condition (the "Limited Data" bug), but the **root cause remains** - services depend on each other but run in parallel.

**The Solution - Dependency Injection + Clear Sequencing:**
```swift
// 1. Extract data fetching from calculation
actor DataFetchingService {
    func fetchTodayData() async -> TodayData {
        // Fetch everything ONCE, in order
        async let hrv = healthKit.fetchHRV()
        async let rhr = healthKit.fetchRHR()
        async let sleep = healthKit.fetchSleep()
        async let activities = activityService.fetch()
        
        return TodayData(
            hrv: await hrv,
            rhr: await rhr,
            sleep: await sleep,
            activities: await activities
        )
    }
}

// 2. Services receive data, don't fetch
actor RecoveryScoreService {
    func calculateScore(from data: TodayData) -> RecoveryScore {
        // No dependencies, just calculation
        return RecoveryCalculations.calculateScore(
            hrv: data.hrv,
            rhr: data.rhr,
            sleep: data.sleep
        )
    }
}

// 3. ViewModel orchestrates clearly
class TodayViewModel {
    func loadData() async {
        // Phase 1: Fetch data ONCE
        let data = await dataFetchingService.fetchTodayData()
        
        // Phase 2: Calculate scores in parallel (no dependencies now)
        async let recovery = recoveryService.calculateScore(from: data)
        async let sleep = sleepService.calculateScore(from: data.sleep)
        async let strain = strainService.calculateScore(from: data)
        
        // Phase 3: Update UI
        let scores = await (recovery, sleep, strain)
        self.recoveryScore = scores.0
        self.sleepScore = scores.1
        self.strainScore = scores.2
    }
}
```

**Benefits:**
- No race conditions (data fetched once)
- True parallelism (calculations don't depend on each other)
- Clear data flow
- Easy to test
- Easy to cache at data layer

---

### 4. **File Size is a SYMPTOM, Not the Disease**

**V1 said:** "HealthKitManager is 1669 lines - split it"

**But WHY is it 1669 lines?**
- It does fetching (HRV, RHR, Sleep, Workouts)
- It does calculations (baselines, TRIMP)
- It does caching
- It does authorization
- It does data transformation

**The Real Problem:** Mixing concerns

**The Solution:** Extract by CONCERN, not by file size
```
HealthKit/
├── HealthKitAuthorization.swift (100 lines) - Request permissions
├── HealthKitDataFetcher.swift (400 lines) - Fetch raw HK samples
├── HealthKitTransformer.swift (200 lines) - Transform HKSample → app models
└── HealthKitManager.swift (200 lines) - Coordinate above

Calculations/ (Move to VeloReadyCore)
├── BaselineCalculations.swift - HRV/RHR/Sleep baselines
├── TRIMPCalculations.swift - Training impulse from workouts
└── TrainingLoadCalculations.swift - CTL/ATL/TSB

Caching/ (Handled by cache layer)
```

**Benefits:**
- Clear boundaries
- Easy to test each piece
- Easy to replace implementations
- Won't grow uncontrollably

---

## The Proper Refactor Plan

### Phase 1: Extract Business Logic to VeloReadyCore (Week 1)

**Goal:** Move ALL calculation logic out of iOS services

**What Moves to VeloReadyCore:**
```
VeloReadyCore/Sources/
├── Calculations/
│   ├── RecoveryCalculations.swift
│   ├── SleepCalculations.swift
│   ├── StrainCalculations.swift
│   ├── BaselineCalculations.swift
│   ├── TrainingLoadCalculations.swift
│   └── TRIMPCalculations.swift
├── Models/ (already exists)
│   ├── RecoveryScore.swift
│   ├── SleepScore.swift
│   └── StrainScore.swift
└── Utilities/
    ├── DateHelpers.swift
    └── MathHelpers.swift
```

**iOS Services Become Thin:**
```swift
// BEFORE: 1084 lines
@MainActor
class RecoveryScoreService: ObservableObject {
    // 400+ lines of calculation logic
}

// AFTER: 200 lines
actor RecoveryScoreService {
    nonisolated func calculate(from data: HealthData) -> RecoveryScore {
        // Delegate to VeloReadyCore
        return RecoveryCalculations.calculateScore(from: data)
    }
}
```

**Testing Benefits:**
```bash
# BEFORE: Run iOS simulator, takes 60-90s
./Scripts/quick-test.sh

# AFTER: VeloReadyCore tests run in 5s (no simulator)
cd VeloReadyCore && swift test  # 5 seconds!

# iOS tests now only test orchestration, not calculations
./Scripts/quick-test.sh  # Still 60s, but fewer tests
```

**Effort:** 5-7 days  
**Risk:** ⭐⭐ Medium (but high value)  
**Benefits:**
- ⭐⭐⭐⭐⭐ 10x faster tests
- ⭐⭐⭐⭐⭐ Logic reusable in backend/ML
- ⭐⭐⭐⭐⭐ Can run on background threads

---

### Phase 2: Fix Cache Architecture (Week 2)

**Goal:** Proper separation of concerns, type-safe keys

#### Step 2.1: Create CacheKeyStrategy (Day 1)

```swift
// VeloReady/Core/Data/Cache/CacheKeyStrategy.swift
enum CacheKey: Hashable {
    case stravaActivities(days: Int)
    case intervalsActivities(days: Int)
    case stream(source: String, activityId: String)
    case recoveryScore(date: Date)
    case sleepScore(date: Date)
    case hrvBaseline
    case rhrBaseline
    
    var stringValue: String {
        switch self {
        case .stravaActivities(let days):
            return "strava:activities:\(days)"
        case .stream(let source, let id):
            return "stream:\(source)_\(id)"
        case .recoveryScore(let date):
            return "score:recovery:\(date.ISO8601Format())"
        // ... etc
        }
    }
}
```

**Benefits:**
- Type-safe (no typos)
- Compiler-enforced consistency
- Easy to refactor
- Discoverable (autocomplete shows all keys)

#### Step 2.2: Extract CacheEncodingHelper (Day 1-2)

```swift
// VeloReady/Core/Data/Cache/CacheEncodingHelper.swift (300 lines)
// Move ALL encoding logic from UnifiedCacheManager here
actor CacheEncodingHelper {
    func encode<T: Codable>(_ value: T) throws -> Data { ... }
    func decode<T: Codable>(_ data: Data, as type: T.Type) throws -> T { ... }
    
    // All the NSDictionary/NSArray handling
    private func encodeDictionary(...) { ... }
    private func encodeArray(...) { ... }
}
```

#### Step 2.3: Create Layered Cache Architecture (Day 2-4)

```swift
// VeloReady/Core/Data/Cache/CacheOrchestrator.swift (200 lines)
actor CacheOrchestrator {
    private let memoryLayer: MemoryCacheLayer
    private let diskLayer: DiskCacheLayer
    private let coreDataLayer: CoreDataCacheLayer
    private let encodingHelper: CacheEncodingHelper
    
    func fetch<T: Codable>(
        key: CacheKey,
        ttl: TimeInterval,
        fetchOperation: () async throws -> T
    ) async throws -> T {
        // 1. Try memory
        if let cached = await memoryLayer.get(key) {
            return cached
        }
        
        // 2. Try disk
        if let cached = await diskLayer.get(key) {
            await memoryLayer.set(key, value: cached)
            return cached
        }
        
        // 3. Try Core Data
        if let cached = await coreDataLayer.get(key) {
            await memoryLayer.set(key, value: cached)
            return cached
        }
        
        // 4. Fetch and cache
        let fresh = try await fetchOperation()
        await saveToAllLayers(key, value: fresh, ttl: ttl)
        return fresh
    }
}

// VeloReady/Core/Data/Cache/Layers/MemoryCacheLayer.swift (150 lines)
actor MemoryCacheLayer {
    private var cache: [CacheKey: CachedValue] = [:]
    private var inflightRequests: [CacheKey: Task<Any, Error>] = [:]
    
    func get<T>(_ key: CacheKey) -> T? { ... }
    func set<T>(_ key: CacheKey, value: T) { ... }
    func invalidate(_ key: CacheKey) { ... }
}

// VeloReady/Core/Data/Cache/Layers/DiskCacheLayer.swift (200 lines)
actor DiskCacheLayer {
    // UserDefaults for small data, FileManager for large
    func get<T: Codable>(_ key: CacheKey) async -> T? { ... }
    func set<T: Codable>(_ key: CacheKey, value: T) async { ... }
}

// VeloReady/Core/Data/Cache/Layers/CoreDataCacheLayer.swift (100 lines)
actor CoreDataCacheLayer {
    private let persistenceLayer: CachePersistenceLayer
    
    func get<T: Codable>(_ key: CacheKey) async -> T? {
        await persistenceLayer.loadFromCoreData(
            key: key.stringValue,
            as: T.self
        )?.value
    }
    
    func set<T: Codable>(_ key: CacheKey, value: T, ttl: TimeInterval) async {
        await persistenceLayer.saveToCoreData(
            key: key.stringValue,
            value: value,
            ttl: ttl
        )
    }
}
```

#### Step 2.4: Migrate Services to New Cache (Day 4-5)

```swift
// BEFORE
let cached = StreamCacheService.shared.getCachedStreams(activityId: id)
if cached == nil {
    let fresh = await fetchStreams(id)
    StreamCacheService.shared.cacheStreams(fresh, activityId: id)
}

// AFTER
let streams = try await CacheOrchestrator.shared.fetch(
    key: .stream(source: "strava", activityId: id),
    ttl: .days(7),
    fetchOperation: { await self.fetchStreams(id) }
)
```

#### Step 2.5: Delete Old Cache Systems (Day 5)

```bash
git rm VeloReady/Core/Services/StreamCacheService.swift
git rm VeloReady/Core/Services/IntervalsCache.swift
git rm VeloReady/Core/Services/HealthKitCache.swift
git rm VeloReady/Core/Services/StravaAthleteCache.swift
# Keep CacheManager for now (DailyScores until SwiftData)
```

**Effort:** 5 days  
**Risk:** ⭐⭐⭐ Medium-High  
**Benefits:**
- ⭐⭐⭐⭐⭐ Type-safe keys
- ⭐⭐⭐⭐ Clear separation
- ⭐⭐⭐⭐ Each layer <300 lines
- ⭐⭐⭐⭐ Easy to test
- ⭐⭐⭐⭐⭐ Won't outgrow itself

---

### Phase 3: Remove @MainActor from Calculation Services (Week 2-3)

**Goal:** Stop blocking UI with heavy calculations

**Target Services:** (20-25 services)
- RecoveryScoreService
- SleepScoreService
- StrainScoreService
- TrainingLoadCalculator
- BaselineCalculator
- IllnessDetectionService
- WellnessDetectionService
- MLPredictionService
- ReadinessForecastService

**Pattern:**
```swift
// BEFORE: Blocks UI for 2-8s
@MainActor
class RecoveryScoreService: ObservableObject {
    @Published var currentScore: RecoveryScore?
    
    func calculateRecoveryScore() async {
        // Heavy calculation on main thread
        let score = complexCalculation()
        self.currentScore = score
    }
}

// AFTER: Background calculation, UI never blocks
actor RecoveryScoreService {
    @Published @MainActor var currentScore: RecoveryScore?
    
    nonisolated func calculateRecoveryScore() async -> RecoveryScore {
        // Heavy calculation on background thread
        let score = RecoveryCalculations.calculateScore(...)
        
        // Only touch UI on main thread
        await MainActor.run {
            self.currentScore = score
        }
        
        return score
    }
}
```

**Effort:** 3-4 days  
**Risk:** ⭐⭐ Medium (need testing)  
**Benefits:**
- ⭐⭐⭐⭐⭐ UI never blocks
- ⭐⭐⭐⭐⭐ App startup <2s (from 3-8s)
- ⭐⭐⭐⭐ True parallelism

---

### Phase 4: File Splitting & Organization (Week 3)

**Now that concerns are separated, file splits are OBVIOUS:**

```
Core/Data/Cache/
├── CacheOrchestrator.swift (200 lines) ← Main interface
├── CacheKeyStrategy.swift (100 lines) ← Type-safe keys
├── CacheEncodingHelper.swift (300 lines) ← Encoding logic
└── Layers/
    ├── MemoryCacheLayer.swift (150 lines)
    ├── DiskCacheLayer.swift (200 lines)
    └── CoreDataCacheLayer.swift (100 lines)

Core/Networking/HealthKit/
├── HealthKitManager.swift (200 lines) ← Coordinator
├── HealthKitAuthorization.swift (100 lines) ← Permissions
├── HealthKitDataFetcher.swift (400 lines) ← Fetch raw data
└── HealthKitTransformer.swift (200 lines) ← Transform data

Core/Services/Scoring/
├── RecoveryScoreService.swift (200 lines) ← Thin orchestrator
├── SleepScoreService.swift (200 lines)
└── StrainScoreService.swift (200 lines)

VeloReadyCore/Sources/Calculations/
├── RecoveryCalculations.swift (300 lines) ← Pure logic
├── SleepCalculations.swift (200 lines)
├── StrainCalculations.swift (250 lines)
├── BaselineCalculations.swift (150 lines)
└── TrainingLoadCalculations.swift (200 lines)
```

**Effort:** 3-4 days  
**Risk:** ⭐ Low (just moving code)  
**Benefits:**
- ⭐⭐⭐⭐ Easy to navigate
- ⭐⭐⭐⭐ Clear boundaries
- ⭐⭐⭐⭐ Won't grow uncontrollably

---

### Phase 5: Debug Section & Tech Debt (Week 3)

**Quick wins after architecture is solid:**

1. **Delete dead file:** DebugDashboardView.swift (0 bytes)
2. **Split DebugSettingsView:** 1288 → 6 files of ~200 lines
3. **Apply design system:** Use VRText, VRBadge, tokens
4. **Resolve 48 TODOs:** Delete outdated, fix high-value
5. **Remove dead code:** Unused imports, commented blocks

**Effort:** 2-3 days  
**Risk:** ⭐ None  
**Benefits:** Clean mental model

---

## Success Metrics

### Performance (Primary)
- [ ] App startup <2s (currently 3-8s)
- [ ] Score calculations never block UI
- [ ] Cache hit rate >85% (currently ~60%)
- [ ] VeloReadyCore tests <10s (currently N/A)

### Architecture (Primary)
- [ ] All calculation logic in VeloReadyCore (testable, reusable)
- [ ] All services <300 lines (thin orchestrators)
- [ ] Cache has clear layers, type-safe keys
- [ ] No @MainActor on calculation services

### Maintainability (Secondary)
- [ ] All files <900 lines
- [ ] Clear separation of concerns
- [ ] Easy to add new features
- [ ] Won't outgrow itself in weeks

---

## Why This Plan is Right

### It Addresses Root Causes
- ✅ Cache is properly layered (won't outgrow itself)
- ✅ Business logic extracted (testable, reusable, fast)
- ✅ Services are thin (easy to maintain)
- ✅ Type-safe keys (no bugs from typos)
- ✅ Clear boundaries (easy to extend)

### It's Future-Proof
- ✅ VeloReadyCore logic can be used in backend/ML/widgets
- ✅ Cache layers can be swapped (e.g., Redis instead of UserDefaults)
- ✅ Easy to add new data sources (just implement interface)
- ✅ Ready for SwiftData migration (clean Core Data boundary)

### It Solves Your Pain Points
- ✅ "Time consuming" → VeloReadyCore tests run in seconds
- ✅ "Cumbersome" → Clear file organization, easy to find code
- ✅ "Cache needs fixing" → Proper architecture, not band-aids
- ✅ "Super efficient" → No UI blocking, parallel execution
- ✅ "Scalable" → Layers can grow independently
- ✅ "Fast" → Background calculations, smart caching
- ✅ "Performant" → Actor-based, no @MainActor overhead
- ✅ "Easy to build on" → Clear interfaces, separated concerns
- ✅ "Won't outgrow itself" → Proper architecture from start

---

## Git Strategy

```bash
# Work on large-refactor
git checkout large-refactor

# Phase 1: VeloReadyCore extraction (Week 1)
git commit -m "refactor(core): extract RecoveryCalculations to VeloReadyCore"
git commit -m "refactor(core): extract SleepCalculations to VeloReadyCore"
# ... etc

# Phase 2: Cache architecture (Week 2)  
git commit -m "refactor(cache): create CacheKeyStrategy with type-safe keys"
git commit -m "refactor(cache): extract CacheEncodingHelper (300 lines)"
git commit -m "refactor(cache): implement layered cache architecture"
git commit -m "refactor(cache): migrate services to CacheOrchestrator"
git commit -m "refactor(cache): delete legacy cache systems"

# Phase 3: @MainActor cleanup (Week 2-3)
git commit -m "perf: remove @MainActor from calculation services"

# Phase 4: File organization (Week 3)
git commit -m "refactor: organize files by concern, not size"

# Phase 5: Polish (Week 3)
git commit -m "chore: clean debug section and tech debt"

# Final merge
git checkout main
git merge large-refactor --squash
git commit -m "refactor: establish scalable architectural foundation

Phase 1: Extract business logic to VeloReadyCore
- All calculation logic testable in seconds
- Logic reusable in backend/ML/widgets
- Services become thin orchestrators

Phase 2: Implement proper cache architecture
- Type-safe CacheKey enum
- Layered architecture (Memory/Disk/CoreData)
- Each layer <300 lines
- Deleted 4 redundant cache systems

Phase 3: Remove @MainActor from calculations
- UI never blocks (2s startup vs 8s)
- True parallel execution
- Background calculations

Phase 4: Organize by concern
- Clear boundaries
- Easy to navigate
- Won't outgrow itself

Metrics:
- App startup: 8s → 2s (75% faster)
- VeloReadyCore tests: N/A → 5s
- Cache hit rate: 60% → 85%
- Largest file: 1669 → 400 lines
- Services: Fat → Thin orchestrators

Ready for features, ML, backend integration, SwiftData migration.
"
```

---

## Next Steps

### Today
1. Review this plan - does it address your concerns?
2. Confirm cache architecture approach
3. Confirm VeloReadyCore extraction approach
4. Tag current state: `git tag v1.0-pre-refactor`

### Tomorrow (Day 1)
Start with VeloReadyCore extraction (highest value):
1. Extract RecoveryCalculations.swift
2. Add tests (run in 5s!)
3. Update RecoveryScoreService to use it
4. Commit

Build momentum with quick wins, proper architecture.

---

## Questions

1. **VeloReadyCore extraction:** Agree this is the right first phase?
2. **Cache layering:** Does the 3-layer approach make sense?
3. **Type-safe keys:** Prefer enum or protocol?
4. **Timeline:** 2-3 weeks realistic for proper architecture?
5. **Risk tolerance:** Comfortable with medium-risk, high-value changes?

This is a **foundation** for the next 6-12 months. Worth doing right.
