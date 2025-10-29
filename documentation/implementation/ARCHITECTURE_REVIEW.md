# VeloReady Architecture Review & Modernization Plan
**Date:** October 23, 2025  
**Status:** Analysis Complete - Action Plan Defined

---

## Executive Summary

VeloReady has **strong foundations** but shows signs of **organic growth without architectural refactoring**. The app has 24 services, 12 managers, 6 view models, and extensive duplication across API clients, caching layers, and UI components.

**Overall Grade: B+ (Good, but can be Great)**

### Strengths ✅
- **Excellent content architecture** - Centralized, localized content files
- **Modern SwiftUI** - Proper use of @ObservedObject, @StateObject, async/await
- **Component-based UI** - StandardCard, NavigationGradientMask reusable
- **Design system** - Color tokens, spacing, typography well-defined
- **Feature-based structure** - Clear separation (Today, Trends, Activities, etc.)

### Critical Issues ❌
1. **API Client Duplication** - 4 different HTTP clients with overlapping patterns
2. **Cache Fragmentation** - Multiple cache implementations (CacheManager, UnifiedCacheManager, StreamCacheService, AIBriefCache, RideSummaryCache)
3. **Service Explosion** - 24 services with unclear boundaries
4. **Implicit Dependencies** - Services calling services calling services
5. **No Repository Pattern** - Data layer mixed with business logic
6. **Hard-coded backgrounds** - Some components still bypass design system
7. **Component Duplication** - Many "Card" components with similar patterns

---

## 1. API & Networking Layer

### Current State
```
IntervalsAPIClient.swift      (856 lines) - Intervals.icu API
StravaAPIClient.swift         (217 lines) - Strava API  
VeloReadyAPIClient.swift      (129 lines) - VeloReady backend
AIBriefClient.swift           (104 lines) - AI Brief endpoint
RideSummaryClient.swift       (122 lines) - Ride Summary endpoint
StravaAuthService.swift       (337 lines) - OAuth + API calls
```

### Problems
- ❌ **6 different HTTP clients** - Each implements URLSession differently
- ❌ **Duplicate error handling** - Every client has its own error types
- ❌ **No centralized retry logic** - Some have it, some don't
- ❌ **Mixed responsibilities** - Auth + API calls in same files
- ❌ **No request/response interceptors** - Can't add logging/auth globally

### Solution: Unified Networking Layer
```swift
// Single, testable, composable networking layer
NetworkClient (generic HTTP client)
  ├─ RequestBuilder (fluent API for requests)
  ├─ ResponseHandler (unified error handling)
  ├─ RetryPolicy (configurable retry logic)
  ├─ AuthInterceptor (automatic token refresh)
  └─ CachePolicy (unified caching)

// API-specific clients become thin wrappers
IntervalsRepository: NetworkClient
StravaRepository: NetworkClient  
VeloReadyRepository: NetworkClient
```

**Benefits:**
- 80% code reduction in API clients
- Testable with mock NetworkClient
- Add features once (logging, metrics, auth) - benefits all APIs
- Clear separation: Networking vs Business Logic

---

## 2. Caching Strategy

### Current State
```
CacheManager.swift            - Generic cache
UnifiedCacheManager.swift     - Activity cache
StreamCacheService.swift      - Stream data cache
AIBriefCache (in AIBriefClient) - AI brief cache
RideSummaryCache (in RideSummaryClient) - Ride summary cache
IntervalsAPIClient - Has its own URLCache
```

### Problems
- ❌ **5 different caching implementations**
- ❌ **Inconsistent TTL strategies**
- ❌ **Memory vs disk cache mixed**
- ❌ **No cache invalidation strategy**
- ❌ **Cache stampede possible** (multiple requests for same data)

### Solution: Three-Tier Cache Architecture
```swift
// Layer 1: Memory Cache (instant access)
MemoryCache<Key, Value>
  - LRU eviction
  - Configurable size limits
  - Thread-safe

// Layer 2: Disk Cache (persistent)
DiskCache<Key, Value>
  - Codable support
  - TTL-based expiration
  - Size limits
  
// Layer 3: Repository Pattern (coordinates both)
Repository<Entity>
  ├─ MemoryCache (check first)
  ├─ DiskCache (check second)
  └─ NetworkClient (fetch if needed)
```

**Benefits:**
- Single cache strategy across app
- Automatic cache coordination
- Prevents duplicate network requests
- Clear cache invalidation

---

## 3. Service Layer

### Current State
**24 Services** with overlapping responsibilities:

```
RecoveryScoreService.swift         - Calculates recovery
SleepScoreService.swift            - Calculates sleep  
StrainScoreService.swift           - Calculates strain
IllnessDetectionService.swift      - Detects illness
WellnessDetectionService.swift     - Detects wellness
ReadinessForecastService.swift     - Forecasts readiness
RecoverySleepCorrelationService.swift - Correlates recovery/sleep
SleepDebtService.swift             - Calculates sleep debt
LiveActivityService.swift          - Live activity updates
UnifiedActivityService.swift       - Activity unification
ActivityDeduplicationService.swift - Deduplicates activities
WorkoutMetadataService.swift       - Workout metadata
StravaDataService.swift            - Strava data
AIBriefService.swift               - AI brief
RideSummaryService.swift           - Ride summaries
... (9 more)
```

### Problems
- ❌ **Unclear boundaries** - Which service does what?
- ❌ **Circular dependencies** - Service A calls Service B calls Service C calls Service A
- ❌ **God objects** - Some services do too much
- ❌ **Singletons everywhere** - Hard to test, global state
- ❌ **Mixed concerns** - Data fetching + business logic + caching + UI state

### Solution: Domain-Driven Design
```swift
// Domain: Health Metrics
HealthMetricsRepository
  ├─ RecoveryScoreCalculator (pure logic)
  ├─ SleepScoreCalculator (pure logic)
  └─ StrainScoreCalculator (pure logic)

// Domain: Activity Management  
ActivityRepository
  ├─ ActivityDeduplicator (pure logic)
  ├─ ActivityUnifier (pure logic)
  └─ MetadataEnricher (pure logic)

// Domain: Wellness Detection
WellnessRepository
  ├─ IllnessDetector (pure logic)
  ├─ WellnessAnalyzer (pure logic)
  └─ ForecastEngine (pure logic)

// Pure business logic - no side effects
Calculators/Analyzers/Detectors
  - Input → Output
  - 100% testable
  - No dependencies
```

**Benefits:**
- Clear separation of concerns
- Testable business logic (no mocks needed)
- Repositories handle data, Calculators handle logic
- Dependency injection instead of singletons

---

## 4. Design System

### Current State ✅ **GOOD**
```
ColorScale.swift       - System colors
ColorPalette.swift     - Semantic colors
Colors.swift           - Organized tokens
Typography.swift       - Type scale
Spacing.swift          - Spacing scale
Icons.swift            - Icon catalog
```

### Remaining Issues
- ⚠️ Some hard-coded colors still exist (found AIBriefView earlier)
- ⚠️ No component library documentation
- ⚠️ Spacing inconsistencies (some use .padding(16), some use Spacing.md)

### Action Items
- [x] Audit all hard-coded Color.primary.opacity()
- [ ] Create Figma design system (sync with code)
- [ ] Enforce spacing tokens via SwiftLint
- [ ] Document all design tokens

---

## 5. Component Architecture

### Current State
**~40 Card components** with similar patterns:

```
StandardCard ✅ (Good - reusable)
HealthWarningsCard ✅ (Uses StandardCard)
StepsCard ✅ (Uses StandardCard)
CaloriesCard ✅ (Uses StandardCard)

But also:
HRVTrendCard
RecoveryTrendCard  
TrainingLoadTrendCard
FTPTrendCard
WeeklyTSSTrendCard
RestingHRCard
... (many more)
```

### Problems
- ❌ **Pattern duplication** - Many cards have same structure (header, chart, footer)
- ❌ **No composition** - Each card is monolithic
- ❌ **Hard to test** - Cards tightly coupled to data

### Solution: Composable Card System
```swift
// Base components
CardContainer (handles styling, background, padding)
CardHeader (icon, title, subtitle, chevron)
CardBody (generic content)
CardFooter (actions, links)

// Specialized components
ChartCard<ChartType> (composes CardContainer + CardHeader + Chart)
MetricCard (composes CardContainer + large number + subtitle)
ListCard (composes CardContainer + list items)

// Usage
ChartCard(
  title: "HRV Trend",
  chart: LineChart(data: hrvData)
)

MetricCard(
  icon: "heart",
  title: "Recovery",
  value: 82,
  unit: "%"
)
```

**Benefits:**
- 70% code reduction in card components
- Consistent styling automatically
- Easy to add new card types
- Testable in isolation

---

## 6. View Construction

### Current State
```swift
// Typical view has:
- 5-10 @ObservedObject properties
- Massive body with inline logic
- Private helper methods for formatting
- Mixed business logic and presentation
```

Example:
```swift
struct TodayView: View {
  @StateObject private var viewModel = TodayViewModel()
  @ObservedObject var healthKitManager = HealthKitManager.shared
  @ObservedObject var proConfig = ProFeatureConfig.shared
  @ObservedObject var stravaAuth = StravaOAuthService.shared
  @ObservedObject var intervalsAuth = IntervalsOAuthManager.shared
  @State private var showInitialSpinner = true
  @State private var missingSleepBannerDismissed = false
  // ... 10 more properties
  
  var body: some View {
    // 800+ lines
  }
}
```

### Problems
- ❌ **Tight coupling** - Views depend on 5+ services
- ❌ **God views** - TodayView.swift is 814 lines
- ❌ **Hard to test** - Can't test view logic without full app
- ❌ **State management chaos** - @State, @StateObject, @ObservedObject mixed

### Solution: MVVM + Composition
```swift
// Slim view
struct TodayView: View {
  @StateObject private var viewModel = TodayViewModel()
  
  var body: some View {
    ScrollView {
      ForEach(viewModel.sections) { section in
        SectionView(section: section)
      }
    }
  }
}

// Fat view model (testable)
class TodayViewModel: ObservableObject {
  @Published var sections: [Section] = []
  
  private let healthRepository: HealthRepository
  private let activityRepository: ActivityRepository
  
  init(
    healthRepository: HealthRepository = .shared,
    activityRepository: ActivityRepository = .shared
  ) {
    // Dependency injection for testing
  }
  
  func loadData() async {
    // All business logic here
    // Pure Swift - testable without SwiftUI
  }
}
```

**Benefits:**
- Views become 80% smaller
- Business logic 100% testable
- Easy to mock dependencies
- State management clear

---

## 7. Content Management

### Current State ✅ **EXCELLENT**
```
Well-organized content files:
- CommonContent.swift
- Feature-specific content files
- Localization-ready structure
```

### Minor Improvements
- [ ] Extract hard-coded strings still in views
- [ ] Add pluralization support
- [ ] Generate documentation from content files

---

## Implementation Plan

### Phase 1: Foundation (Week 1-2) 🔥 **HIGH PRIORITY**

**Goal:** Unified networking and caching

1. **Create NetworkClient**
   - [ ] Generic HTTP client with async/await
   - [ ] Request/Response interceptors
   - [ ] Retry policy
   - [ ] Error handling

2. **Create Cache Layer**
   - [ ] MemoryCache<Key, Value>
   - [ ] DiskCache<Key, Value>
   - [ ] CachePolicy configuration

3. **Create Repository Pattern**
   - [ ] BaseRepository protocol
   - [ ] HealthMetricsRepository
   - [ ] ActivityRepository

**Success Metrics:**
- All API calls go through NetworkClient
- All caching goes through Cache layer
- Delete 5 duplicate cache implementations

---

### Phase 2: Service Consolidation (Week 3-4)

**Goal:** Reduce 24 services to 8 repositories

1. **Extract Pure Logic**
   - [ ] Move calculations to pure functions
   - [ ] Create Calculator protocols
   - [ ] Unit tests for all calculators

2. **Create Domain Repositories**
   - [ ] HealthMetricsRepository
   - [ ] ActivityRepository
   - [ ] WellnessRepository
   - [ ] TrainingRepository

**Success Metrics:**
- 70% reduction in service files
- 100% test coverage on calculators
- Clear dependency graph

---

### Phase 3: Component System (Week 5-6)

**Goal:** Composable, reusable components

1. **Create Base Components**
   - [ ] CardContainer
   - [ ] CardHeader
   - [ ] CardBody
   - [ ] CardFooter

2. **Refactor Card Components**
   - [ ] Migrate to composition
   - [ ] Delete duplicate code
   - [ ] Add component tests

**Success Metrics:**
- 50% reduction in component files
- All cards use composition
- Component library documented

---

### Phase 4: View Architecture (Week 7-8)

**Goal:** Slim views, fat view models

1. **Refactor Major Views**
   - [ ] TodayView → TodayViewModel
   - [ ] TrendsView → TrendsViewModel
   - [ ] ActivitiesView → ActivitiesViewModel

2. **Add Tests**
   - [ ] View model unit tests
   - [ ] Business logic tests
   - [ ] Integration tests

**Success Metrics:**
- Views < 200 lines
- 80% code coverage on view models
- All business logic testable

---

### Phase 5: Design System Enforcement (Week 9)

**Goal:** Zero hard-coded values

1. **Audit & Fix**
   - [ ] Find all hard-coded colors
   - [ ] Find all hard-coded spacing
   - [ ] Replace with tokens

2. **Documentation**
   - [ ] Component library docs
   - [ ] Design token catalog
   - [ ] Usage guidelines

**Success Metrics:**
- 100% design token usage
- SwiftLint rules enforce tokens
- Figma sync automated

---

## Expected Outcomes

### Code Reduction
- **-40%** API client code (6 clients → 3 repositories)
- **-70%** service code (24 services → 8 repositories)
- **-50%** component code (better composition)
- **-30%** view code (move logic to view models)

### Quality Improvements
- **+500%** test coverage (10% → 60%)
- **-80%** dependency coupling
- **+100%** build time improvement (fewer files)
- **Zero** hard-coded design values

### Developer Experience
- **Clearer architecture** - Know where code belongs
- **Faster feature development** - Reusable components
- **Easier testing** - Dependency injection
- **Better onboarding** - Self-documenting code

---

## Quick Wins (Do These First) 🚀

### This Week
1. ✅ **Consolidate AIBriefView + DailyBriefCard** (DONE!)
2. [ ] Create NetworkClient base class
3. [ ] Create MemoryCache + DiskCache
4. [ ] Extract one calculator (e.g., RecoveryScoreCalculator)

### Next Week  
5. [ ] Refactor IntervalsAPIClient to use NetworkClient
6. [ ] Create HealthMetricsRepository
7. [ ] Migrate one service to repository pattern
8. [ ] Add tests for pure calculators

---

## Recommendations

### Must Do (Critical) 🔴
1. **Implement NetworkClient** - Stop the API client duplication
2. **Create Repository Pattern** - Separate data from business logic
3. **Extract Pure Logic** - Make calculators testable
4. **Slim Down Views** - Move logic to view models

### Should Do (High Value) 🟡
5. **Consolidate Caching** - One cache strategy
6. **Component Composition** - Reduce card duplication
7. **Add Tests** - 60% coverage target
8. **Design Token Enforcement** - SwiftLint rules

### Nice to Have (Future) 🟢
9. **Figma Sync** - Auto-generate design tokens
10. **Analytics Layer** - Track usage patterns
11. **Feature Flags** - A/B testing capability
12. **Modular Architecture** - Swift Packages per feature

---

## Conclusion

**VeloReady is well-built but has organic growth debt.** The architecture is sound, but needs **consolidation and abstraction** to scale efficiently.

**Priority:** Start with networking/caching (Phase 1) - this gives immediate benefits and enables faster feature development.

**Timeline:** 9 weeks to complete all phases, but you'll see benefits after each phase.

**Risk:** Low - All changes are refactoring, not rewriting. Features remain unchanged.

---

**Next Step:** Review this document, prioritize phases, and let's start with Phase 1!
