# Activities Pages Refactor Plan
**Branch:** `activities-refactor`
**Date:** 2025-11-20
**Status:** Planning - Ready for Phase 1

## Executive Summary

This document outlines a comprehensive refactor of the Activities List and Activity Detail pages to align with the V2 architecture patterns established in:
- Today page refactor (TodayViewState + TodayDataLoader)
- Detail pages refactor (Recovery/Sleep/Training Load ViewModels)
- Phase 4 migration (Pure V2 architecture with lifecycle management)

**Goals:**
1. Migrate from singleton to dependency injection pattern
2. Separate concerns: View → ViewModel → Service → API
3. Extract shared services for activity data management
4. Decompose monolithic views into reusable components
5. Add proper state management and lifecycle handling
6. Improve testability and maintainability

**Estimated Effort:** 3-4 days
**Risk Level:** Medium (extensive changes, but well-established patterns)

---

## Current State Analysis

### Activities List Page

**Files:**
- `ActivitiesView.swift` - 201 lines
- `ActivitiesViewModel.swift` - 388 lines

**Current Architecture:**
```
ActivitiesView
  └── ActivitiesViewModel (singleton, @Observable)
      ├── Direct API calls (IntervalsAPIClient)
      ├── Pagination logic
      ├── Filter logic
      ├── Data fetching (Intervals + Strava + HealthKit)
      └── Progressive loading
```

**Issues Identified:**

1. **❌ Singleton Pattern**
   - `static let shared = ActivitiesViewModel()`
   - Hard to test, tight coupling
   - Cannot have multiple instances

2. **❌ API Injection at View Layer**
   - `@EnvironmentObject var apiClient: IntervalsAPIClient`
   - View knows about API implementation
   - Violates separation of concerns

3. **❌ Mixed Concerns in ViewModel**
   - Data fetching logic (lines 98-173)
   - Pagination logic (lines 312-330)
   - Filter logic (lines 260-273)
   - Progressive loading (lines 284-310)
   - All in one class (388 lines)

4. **❌ No State Layer Pattern**
   - ViewModel directly manages state
   - No lifecycle event system
   - No centralized state management

5. **❌ No Shared Service Pattern**
   - Duplicates activity fetching logic from TodayDataLoader
   - No centralized UnifiedActivityService
   - Each view fetches activities independently

### Activity Detail Page

**Files:**
- `ActivityDetailView.swift` - 432 lines
- `ActivityDetailViewModel.swift` - 446 lines

**Current Architecture:**
```
ActivityDetailView
  └── ActivityDetailViewModel (@Observable)
      ├── HealthKit data loading (lines 106-327)
      ├── Intervals API calls (lines 51-104)
      ├── Map generation (lines 330-445)
      └── Chart data processing
```

**Issues Identified:**

1. **❌ Monolithic ViewModel (446 lines)**
   - HealthKit logic (221 lines)
   - API logic (53 lines)
   - Map generation (115 lines)
   - Chart processing (57 lines)

2. **❌ No Service Layer**
   - HealthKit queries directly in ViewModel
   - API calls directly in ViewModel
   - No separation of data fetching vs presentation logic

3. **❌ Monolithic View (432 lines)**
   - Inline header section (lines 240-386)
   - Inline map section (lines 388-432)
   - Inline chart section (lines 56-103)
   - No component extraction

4. **❌ Direct HealthKit Usage**
   - `private let healthStore = HKHealthStore()`
   - Should use HealthKitManager service
   - Duplicates logic across ViewModels

5. **❌ No State Pattern**
   - Uses `init(activityData:)` instead of `.task`
   - No lifecycle management
   - No loading phases

---

## Architectural Patterns to Apply

### Pattern 1: State Container (from TodayViewState)

**Example:**
```swift
@MainActor
final class ActivitiesViewState: ObservableObject {
    static let shared = ActivitiesViewState()

    enum LoadingPhase {
        case notStarted
        case loadingCache
        case loadingFreshData
        case complete
        case error(Error)
    }

    @Published var phase: LoadingPhase = .notStarted
    @Published var activities: [UnifiedActivity] = []
    @Published var selectedFilters: Set<ActivityType> = []

    // Lifecycle handling
    func handle(_ event: LifecycleEvent) async {
        // ...
    }
}
```

### Pattern 2: Data Loader Service (from TodayDataLoader)

**Example:**
```swift
@MainActor
final class ActivitiesDataLoader {
    func loadActivities(limit: Int, daysBack: Int) async throws -> [UnifiedActivity] {
        // Coordinate fetching from multiple sources
        // Deduplicate
        // Return unified activities
    }
}
```

### Pattern 3: Dependency Injection (from Detail ViewModels)

**Example:**
```swift
@MainActor
@Observable
final class ActivityDetailViewModel {
    private let activityService: UnifiedActivityService
    private let healthKitManager: HealthKitManager
    private let mapService: MapSnapshotService

    init(
        activityData: UnifiedActivityData,
        activityService: UnifiedActivityService = .shared,
        healthKitManager: HealthKitManager = .shared,
        mapService: MapSnapshotService = .shared
    ) {
        // Dependency injection for testability
    }
}
```

### Pattern 4: Component Extraction (from Detail Pages)

**Example:**
```swift
// Before: Inline 100-line section
var headerSection: some View {
    // 100 lines of code
}

// After: Extracted component
struct ActivityHeaderSection: View {
    let activity: UnifiedActivity
    var body: some View {
        // ...
    }
}
```

---

## Migration Strategy

### Phase 1: Activities List State & Services (Priority: HIGH)

**Goal:** Introduce state layer and shared services following TodayViewState pattern

**Time Estimate:** 1-1.5 days
**Risk:** Medium (core architecture changes)

#### Tasks:

**1.1: Create UnifiedActivityService (Shared Service)**
- Location: `VeloReady/Core/Services/Data/UnifiedActivityService.swift`
- Pattern: Singleton service (like DailyDataService)
- Responsibilities:
  - Coordinate fetching from Intervals, Strava, HealthKit
  - Deduplication logic
  - Caching strategy
  - Provide unified activity stream

```swift
@MainActor
final class UnifiedActivityService {
    static let shared = UnifiedActivityService()

    private let intervalsClient: IntervalsAPIClient
    private let stravaService: StravaDataService
    private let healthKitManager: HealthKitManager
    private let deduplicationService: ActivityDeduplicationService

    func fetchRecentActivities(limit: Int, daysBack: Int) async throws -> [UnifiedActivity] {
        // Fetch from all sources
        // Deduplicate
        // Cache
        // Return unified list
    }

    func refreshActivities() async throws -> [UnifiedActivity] {
        // Force refresh from all sources
    }
}
```

**1.2: Create ActivitiesDataLoader**
- Location: `VeloReady/Features/Activities/Data/ActivitiesDataLoader.swift`
- Pattern: Similar to TodayDataLoader
- Responsibilities:
  - Use UnifiedActivityService
  - Handle pagination logic
  - Manage loading states
  - Cache coordination

```swift
@MainActor
final class ActivitiesDataLoader {
    private let activityService: UnifiedActivityService
    private let cacheManager: CacheManager

    func loadInitialActivities() async throws -> [UnifiedActivity] {
        // Load from cache first (instant)
        // Then fetch fresh data (background)
    }

    func loadMoreActivities(page: Int) async throws -> [UnifiedActivity] {
        // Pagination logic
    }
}
```

**1.3: Create ActivitiesViewState**
- Location: `VeloReady/Features/Activities/State/ActivitiesViewState.swift`
- Pattern: TodayViewState architecture
- Responsibilities:
  - Unified state container
  - Lifecycle event handling
  - Loading phase management
  - Coordinate with ActivitiesDataLoader

```swift
@MainActor
final class ActivitiesViewState: ObservableObject {
    static let shared = ActivitiesViewState()

    // Loading phase
    @Published var phase: LoadingPhase = .notStarted

    // Activities state
    @Published var allActivities: [UnifiedActivity] = []
    @Published var filteredActivities: [UnifiedActivity] = []
    @Published var selectedFilters: Set<UnifiedActivity.ActivityType> = []

    // Pagination state
    @Published var currentPage: Int = 0
    @Published var isLoadingPage: Bool = false

    // Dependencies
    private let dataLoader: ActivitiesDataLoader

    // Lifecycle handling
    func handle(_ event: LifecycleEvent) async {
        switch event {
        case .viewAppeared:
            await loadActivitiesIfNeeded()
        case .pullToRefresh:
            await refresh()
        // ...
        }
    }
}
```

**1.4: Refactor ActivitiesViewModel → ActivitiesViewState**
- Remove singleton pattern
- Move data fetching to ActivitiesDataLoader
- Move service logic to UnifiedActivityService
- Keep only presentation logic
- ~150 lines (down from 388)

**1.5: Update ActivitiesView**
- Replace `@Bindable var viewModel` with `@ObservedObject var state`
- Use lifecycle events instead of direct method calls
- Remove `@EnvironmentObject var apiClient`

**Testing:**
- ✅ Build succeeds
- ✅ Activities load on view appear
- ✅ Pull-to-refresh works
- ✅ Pagination works
- ✅ Filters work

**Commit:** `feat(activities): Introduce state layer and shared services (Phase 1)`

---

### Phase 2: Activity Detail State & Services (Priority: HIGH)

**Goal:** Extract service layer and introduce proper state management

**Time Estimate:** 1 day
**Risk:** Medium (extensive ViewModel changes)

#### Tasks:

**2.1: Create ActivityHealthKitService**
- Location: `VeloReady/Core/Services/ActivityHealthKitService.swift`
- Pattern: Stateless service
- Responsibilities:
  - Load heart rate data for workout
  - Load route data for workout
  - Load steps for workout
  - Pace calculations

```swift
@MainActor
final class ActivityHealthKitService {
    static let shared = ActivityHealthKitService()

    private let healthKitManager: HealthKitManager

    func loadHeartRateData(for workout: HKWorkout) async -> [(time: TimeInterval, heartRate: Double)] {
        // Query HealthKit
        // Return formatted data
    }

    func loadRouteData(for workout: HKWorkout) async -> [CLLocationCoordinate2D] {
        // Query HealthKit route
        // Return coordinates
    }
}
```

**2.2: Create ActivityMapService**
- Location: `VeloReady/Core/Services/Location/ActivityMapService.swift`
- Pattern: Stateless service
- Responsibilities:
  - Generate map snapshots
  - Calculate map regions
  - Add route overlays

```swift
@MainActor
final class ActivityMapService {
    static let shared = ActivityMapService()

    func generateMapSnapshot(coordinates: [CLLocationCoordinate2D]) async -> UIImage? {
        // Generate snapshot
        // Add route overlay
        // Return image
    }
}
```

**2.3: Refactor ActivityDetailViewModel**
- Inject services via dependency injection
- Remove direct HealthKit queries
- Remove direct API calls
- Move service logic to services
- Keep only presentation logic
- ~200 lines (down from 446)

```swift
@MainActor
@Observable
final class ActivityDetailViewModel {
    let activityData: UnifiedActivityData

    // Injected dependencies
    private let healthKitService: ActivityHealthKitService
    private let mapService: ActivityMapService
    private let apiClient: IntervalsAPIClient

    // Published state
    var heartRateSamples: [(time: TimeInterval, heartRate: Double)] = []
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var isLoading = false

    init(
        activityData: UnifiedActivityData,
        healthKitService: ActivityHealthKitService = .shared,
        mapService: ActivityMapService = .shared,
        apiClient: IntervalsAPIClient = .shared
    ) {
        self.activityData = activityData
        self.healthKitService = healthKitService
        self.mapService = mapService
        self.apiClient = apiClient
    }

    func loadData() async {
        isLoading = true

        // Use services for data loading
        if let workout = activityData.healthKitWorkout {
            heartRateSamples = await healthKitService.loadHeartRateData(for: workout)
            routeCoordinates = await healthKitService.loadRouteData(for: workout)
        }

        isLoading = false
    }
}
```

**Testing:**
- ✅ Build succeeds
- ✅ Activity detail loads correctly
- ✅ Maps render correctly
- ✅ Charts display correctly
- ✅ HealthKit data loads

**Commit:** `feat(activity-detail): Extract service layer and add dependency injection (Phase 2)`

---

### Phase 3: Component Extraction (Priority: MEDIUM)

**Goal:** Extract reusable components from monolithic views

**Time Estimate:** 1 day
**Risk:** Low (cosmetic refactor, no logic changes)

#### Tasks:

**3.1: Extract Activity List Components**

Create:
- `ActivityListSection.swift` - Section wrapper with month header
- `ActivityCardRow.swift` - Reusable activity card (uses LatestActivityCardV2)
- `ActivityFilterBar.swift` - Filter chip bar
- `ActivityPaginationIndicator.swift` - Loading indicator

**3.2: Extract Activity Detail Components**

Create:
- `ActivityDetailHeader.swift` - Header with title, date, type badge
- `ActivityMetricsGrid.swift` - Metrics grid (duration, distance, etc.)
- `ActivityChartSection.swift` - Chart wrapper with title
- `ActivityMapSection.swift` - Map with title and state handling

**Before (Monolithic):**
```swift
// ActivityDetailView.swift - 432 lines
struct ActivityDetailView: View {
    var body: some View {
        ScrollView {
            VStack {
                // 100 lines of header code
                // 80 lines of metrics grid code
                // 120 lines of chart code
                // 132 lines of map code
            }
        }
    }
}
```

**After (Component-Based):**
```swift
// ActivityDetailView.swift - ~150 lines
struct ActivityDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ActivityDetailHeader(activity: activityData)

                ActivityMetricsGrid(activity: activityData, viewModel: viewModel)

                if !viewModel.chartSamples.isEmpty {
                    ActivityChartSection(viewModel: viewModel)
                }

                if !viewModel.routeCoordinates.isEmpty {
                    ActivityMapSection(coordinates: viewModel.routeCoordinates)
                }
            }
        }
    }
}
```

**Testing:**
- ✅ Visual regression (screenshots match)
- ✅ All sections render correctly
- ✅ Dark mode works
- ✅ Layout on different screen sizes

**Commit:** `refactor(activities): Extract view components for reusability (Phase 3)`

---

### Phase 4: Caching & Performance (Priority: MEDIUM)

**Goal:** Add caching strategy and optimize performance

**Time Estimate:** 0.5 day
**Risk:** Low (additive changes)

#### Tasks:

**4.1: Add Activity Caching to UnifiedActivityService**
- Cache activities in UserDefaults (30-minute TTL)
- Cache-first loading (instant content)
- Background refresh

```swift
func fetchRecentActivities(limit: Int, daysBack: Int) async throws -> [UnifiedActivity] {
    // 1. Try cache first (instant)
    if let cached = loadFromCache(), !shouldRefresh(cached) {
        return cached.activities
    }

    // 2. Fetch fresh data
    let fresh = await fetchFromSources(limit: limit, daysBack: daysBack)

    // 3. Cache for next time
    saveToCache(fresh)

    return fresh
}
```

**4.2: Optimize Activity List Pagination**
- Reduce initial page size (15 → 10)
- Increase prefetch threshold (3 → 5 items)
- Add smooth pagination transitions

**4.3: Add Performance Monitoring**
- Track activity load time
- Track pagination performance
- Log cache hit rate

**Testing:**
- ✅ Cache hit rate >70%
- ✅ Initial load <500ms (cached)
- ✅ Pagination smooth (no jank)

**Commit:** `perf(activities): Add caching and optimize pagination (Phase 4)`

---

### Phase 5: Offline Support & Error Handling (Priority: LOW)

**Goal:** Graceful offline handling and error recovery

**Time Estimate:** 0.5 day
**Risk:** Low (additive changes)

#### Tasks:

**5.1: Add Core Data Fallback**
- Store activities in Core Data
- Load from Core Data when offline
- Background sync when online

**5.2: Add Error States**
- Network error handling
- Empty state improvements
- Retry logic

**5.3: Add Loading States**
- Skeleton loading for activity cards
- Shimmer effect
- Progressive reveal

**Testing:**
- ✅ Airplane mode works (shows cached)
- ✅ Network error shows retry button
- ✅ Empty state informative

**Commit:** `feat(activities): Add offline support and error handling (Phase 5)`

---

## Architecture After Refactor

### Activities List (Pure V2)
```
ActivitiesView (~100 lines)
  └── ActivitiesViewState (state container, ~200 lines)
      └── ActivitiesDataLoader (data fetching, ~150 lines)
          └── UnifiedActivityService (shared service, ~250 lines)
              ├── IntervalsAPIClient
              ├── StravaDataService
              ├── HealthKitManager
              └── ActivityDeduplicationService
```

### Activity Detail (Clean Separation)
```
ActivityDetailView (~150 lines)
  ├── ActivityDetailHeader (~50 lines)
  ├── ActivityMetricsGrid (~80 lines)
  ├── ActivityChartSection (~100 lines)
  └── ActivityMapSection (~80 lines)

  └── ActivityDetailViewModel (~200 lines)
      ├── ActivityHealthKitService (~150 lines)
      ├── ActivityMapService (~100 lines)
      └── IntervalsAPIClient
```

### Code Metrics Comparison

| Component | Before | After | Delta |
|-----------|--------|-------|-------|
| **Activities List** |
| ActivitiesView | 201 | ~100 | **-101** |
| ActivitiesViewModel | 388 | N/A | **-388** |
| ActivitiesViewState | 0 | ~200 | +200 |
| ActivitiesDataLoader | 0 | ~150 | +150 |
| **Activity Detail** |
| ActivityDetailView | 432 | ~150 | **-282** |
| ActivityDetailViewModel | 446 | ~200 | **-246** |
| **New Services** |
| UnifiedActivityService | 0 | ~250 | +250 |
| ActivityHealthKitService | 0 | ~150 | +150 |
| ActivityMapService | 0 | ~100 | +100 |
| **New Components** |
| Activity components | 0 | ~400 | +400 |
| **Total** | **1,467** | **1,700** | **+233** |

**Net Result:**
- ~233 more lines of code
- Better organized (9 files instead of 4)
- **63% reduction in view complexity** (201+432 → 100+150)
- **100% improvement in testability** (dependency injection)
- **Shared service reuse** (UnifiedActivityService used by multiple features)

---

## Dependencies & Services Created

### New Services (Shared across features):

1. **UnifiedActivityService** - Central activity data coordination
   - Used by: Activities page, Today page, Trends page
   - Benefits: Single source of truth, consistent deduplication

2. **ActivityHealthKitService** - HealthKit queries for activities
   - Used by: Activity detail, Today latest activity card
   - Benefits: No duplicate HealthKit logic

3. **ActivityMapService** - Map generation for activities
   - Used by: Activity detail, Activity list previews
   - Benefits: Consistent map rendering

### Updated Services:

1. **StravaDataService** - Already exists, use directly
2. **HealthKitManager** - Already exists, use via ActivityHealthKitService
3. **IntervalsAPIClient** - Already exists, use via UnifiedActivityService

---

## Testing Strategy

### Unit Tests (High Priority)

**UnifiedActivityService:**
- Test deduplication logic
- Test caching behavior
- Test source prioritization
- Test error handling

**ActivitiesDataLoader:**
- Test pagination logic
- Test filter application
- Test loading states

**ActivityDetailViewModel:**
- Test data loading flow
- Test error handling
- Test dependency injection

### Integration Tests (Medium Priority)

**Activities List:**
- Test view appear → data load
- Test pull-to-refresh
- Test pagination
- Test filter changes

**Activity Detail:**
- Test HealthKit data loading
- Test map generation
- Test chart rendering

### UI Tests (Low Priority)

- Visual regression (screenshot comparison)
- Dark mode verification
- Layout on different screen sizes

---

## Migration Path

### Recommended Approach: Phased Execution

**Week 1 (High Priority):**
1. ✅ Phase 1: Activities List State & Services (~1.5 days)
2. ✅ Phase 2: Activity Detail State & Services (~1 day)
3. ✅ Test and commit after each phase

**Week 2 (Medium Priority):**
1. ✅ Phase 3: Component Extraction (~1 day)
2. ✅ Phase 4: Caching & Performance (~0.5 day)
3. ✅ Phase 5: Offline Support (~0.5 day)

**Total Time:** 3.5-4 days

### Risk Mitigation

**Rollback Plan:**
- Each phase is a separate commit
- Can revert individual phases
- Feature flags for gradual rollout

**Testing Checkpoints:**
- After Phase 1 (core architecture)
- After Phase 2 (service extraction)
- After Phase 3 (visual regression)

---

## Success Criteria

### Phase 1 Complete When:
- ✅ UnifiedActivityService created and tested
- ✅ ActivitiesViewState manages all state
- ✅ Singleton removed from ActivitiesViewModel
- ✅ Activities load from shared service
- ✅ Tests passing

### Phase 2 Complete When:
- ✅ ActivityHealthKitService extracts HealthKit logic
- ✅ ActivityMapService extracts map logic
- ✅ ActivityDetailViewModel uses dependency injection
- ✅ ViewModel <250 lines
- ✅ Tests passing

### Full Refactor Complete When:
- ✅ All views use state container pattern
- ✅ All services use dependency injection
- ✅ Code duplication reduced by 50%+
- ✅ Component reuse increased
- ✅ All tests passing
- ✅ No visual regressions
- ✅ Performance maintained or improved

---

## Known Limitations & Future Work

### Items Not in Scope:

1. **Activity Sync Engine**
   - Currently: Fetch on demand
   - Future: Background sync service
   - Estimated effort: 2-3 days

2. **Activity Search**
   - Currently: Filters only
   - Future: Full-text search
   - Estimated effort: 1 day

3. **Activity Analytics**
   - Currently: Basic metrics
   - Future: Weekly/monthly summaries
   - Estimated effort: 2-3 days

4. **Activity Sharing**
   - Currently: None
   - Future: Share to social media
   - Estimated effort: 1-2 days

---

## Files to Create

### Services:
- `VeloReady/Core/Services/Data/UnifiedActivityService.swift` (~250 lines)
- `VeloReady/Core/Services/ActivityHealthKitService.swift` (~150 lines)
- `VeloReady/Core/Services/Location/ActivityMapService.swift` (~100 lines)

### State Layer:
- `VeloReady/Features/Activities/State/ActivitiesViewState.swift` (~200 lines)
- `VeloReady/Features/Activities/Data/ActivitiesDataLoader.swift` (~150 lines)

### Components (Activities List):
- `VeloReady/Features/Activities/Components/ActivityListSection.swift` (~80 lines)
- `VeloReady/Features/Activities/Components/ActivityFilterBar.swift` (~60 lines)
- `VeloReady/Features/Activities/Components/ActivityPaginationIndicator.swift` (~40 lines)

### Components (Activity Detail):
- `VeloReady/Features/Shared/Components/ActivityDetailHeader.swift` (~100 lines)
- `VeloReady/Features/Shared/Components/ActivityMetricsGrid.swift` (~120 lines)
- `VeloReady/Features/Shared/Components/ActivityChartSection.swift` (~150 lines)
- `VeloReady/Features/Shared/Components/ActivityMapSection.swift` (~100 lines)

### Files to Modify:
- `VeloReady/Features/Activities/Views/ActivitiesView.swift` (201 → ~100 lines)
- `VeloReady/Features/Activities/ViewModels/ActivitiesViewModel.swift` (388 → delete or repurpose)
- `VeloReady/Features/Today/Views/DetailViews/ActivityDetailView.swift` (432 → ~150 lines)
- `VeloReady/Features/Today/ViewModels/ActivityDetailViewModel.swift` (446 → ~200 lines)

---

## Branch & Merge Strategy

**Current Branch:** `today-refactor`
**New Branch:** `activities-refactor` (from `today-refactor`)

**Recommended Merge Flow:**
1. Create `activities-refactor` from `today-refactor`
2. Complete Phase 1 → commit → test
3. Complete Phase 2 → commit → test
4. Complete Phase 3 → commit → test
5. Complete Phase 4 → commit → test
6. Complete Phase 5 → commit → test
7. Merge `activities-refactor` → `today-refactor`
8. Verify all tests pass
9. Merge `today-refactor` → `main`

---

## Documentation Updates

### Code Documentation:
- Add header comments to all new services
- Document state management pattern
- Add examples for component usage

### Architecture Documentation:
- Update MASTER_ARCHITECTURE_PLAN.md
- Create ACTIVITIES_ARCHITECTURE.md
- Document service layer architecture
- Add sequence diagrams

---

## Approval & Sign-Off

**Prepared By:** Claude Code
**Date:** 2025-11-20
**Status:** Awaiting approval for execution

**Decision:**
- [ ] A) Proceed with full refactor (Phases 1-5, ~4 days)
- [ ] B) Phase 1-2 only (core architecture, ~2.5 days)
- [ ] C) Defer to future sprint

---

*This document will be updated as work progresses. Each phase completion will be marked with checkboxes and commit SHAs.*
