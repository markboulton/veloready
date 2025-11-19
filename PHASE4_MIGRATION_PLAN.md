# Phase 4: Complete Legacy Migration - Plan

## Executive Summary

Phase 4 will complete the migration to V2 architecture by:
1. Moving all TodayCoordinator functionality into TodayViewState
2. Removing TodayViewModel (bridge layer)
3. Updating TodayView to use TodayViewState directly
4. Deleting legacy files

**Current State:** Hybrid architecture with dual support (V2 + Phase 3 coordinators)
**Target State:** Pure V2 architecture (TodayViewState only)
**Estimated Effort:** 2-3 days
**Risk Level:** High (requires careful testing at each step)

---

## Current Architecture Analysis

### TodayViewModel (436 lines)
**Role:** Bridge layer between coordinators and view

**Responsibilities:**
1. **Observer Bridge** - Observes TodayViewState (V2) or TodayCoordinator (Phase 3)
2. **State Mapping** - Maps state to legacy view properties
3. **Legacy Compatibility** - Provides backwards-compatible properties
4. **Public API Delegation** - Delegates lifecycle calls to coordinator

**Dependencies:**
- TodayViewState (V2)
- TodayCoordinator (Phase 3)
- ScoresCoordinator
- ActivitiesCoordinator
- ServiceContainer
- LoadingStateManager

**Published Properties (used by TodayView):**
- `animationTrigger: UUID` - Triggers ring animations
- `isHealthKitAuthorized: Bool` - HealthKit auth state
- `errorMessage: String?` - Error display
- `isLoading: Bool` - Legacy loading state
- `isInitializing: Bool` - Initial load spinner
- `isDataLoaded: Bool` - Data ready flag
- `recentActivities: [Activity]` - Activity list
- `unifiedActivities: [UnifiedActivity]` - Unified activity list
- `wellnessData: [IntervalsWellness]` - Wellness data
- `loadingStateManager: LoadingStateManager` - Loading UI state

### TodayCoordinator (531 lines)
**Role:** Lifecycle orchestrator and data fetching coordinator

**Responsibilities:**
1. **Lifecycle State Machine** - Manages app lifecycle events
2. **Data Loading Orchestration** - Coordinates scores + activities
3. **Background Task Management** - Manages background tasks, cancellation
4. **Cache Invalidation** - Invalidates caches on pull-to-refresh
5. **Timeout Handling** - Wraps operations with timeouts
6. **Error Handling** - Structured error types and recovery

**Key State Machine:**
```
.initial → viewAppeared → loadInitial() → .ready
.ready → appForegrounded → refresh() (if >5 min)
.ready → pullToRefresh → refresh()
.ready → viewDisappeared → .background
```

**Lifecycle Events:**
- viewAppeared
- viewDisappeared
- appForegrounded
- healthKitAuthorized
- pullToRefresh
- intervalsAuthChanged

**Data Flow:**
1. loadInitial():
   - Load cached data (instant)
   - Calculate scores (2-3s) WITH TIMEOUT (20s)
   - Fetch activities (foreground for initial load)
   - Background backfill (60 days)

2. refresh():
   - Refresh scores and activities in parallel
   - Update loading states
   - Mark as ready

### TodayViewState (324 lines)
**Role:** V2 unified state container

**Current Capabilities:**
- Cache-first data loading
- Published state properties
- HealthKit observer
- Network observer
- Invalidate short-lived caches

**Missing Capabilities (need to add):**
- Lifecycle event handling
- Background task management
- Cache invalidation logic
- Timeout handling
- Loading state management
- Animation trigger coordination

---

## Migration Strategy

### Phase 4.1: Migrate TodayCoordinator → TodayViewState

**Goal:** Move all lifecycle and orchestration logic to TodayViewState

**Steps:**
1. Add lifecycle event enum to TodayViewState
2. Add state machine to TodayViewState
3. Move lifecycle handlers from TodayCoordinator
4. Move background task management
5. Move cache invalidation logic
6. Add timeout handling
7. Update load() and refresh() to match TodayCoordinator flow
8. Test with quick-test
9. Commit

**New Methods to Add to TodayViewState:**
```swift
// Lifecycle event handling
func handle(_ event: LifecycleEvent) async

// Background task management
private var backgroundTasks: [Task<Void, Never>]
private func cancelBackgroundTasks()

// Cache invalidation
func invalidateActivityCaches() async

// Timeout handling
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> TimeoutResult
```

**New State Machine:**
```swift
enum LoadingPhase {
    case notStarted      // Maps to .initial
    case loadingCache    // Maps to .loading (phase 1)
    case loadingFreshData // Maps to .loading (phase 2)
    case complete        // Maps to .ready
    case error(Error)    // Maps to .error
    case background      // NEW - view inactive
    case refreshing      // NEW - pull to refresh
}
```

### Phase 4.2: Remove TodayViewModel Bridge

**Goal:** Eliminate bridge layer by updating TodayView directly

**Steps:**
1. Read TodayView.swift to identify all TodayViewModel usage
2. Replace `@StateObject var viewModel = TodayViewModel.shared` with `@StateObject var state = TodayViewState.shared`
3. Update all property bindings to use TodayViewState directly
4. Update lifecycle calls (.onAppear, .onChange, etc.) to call TodayViewState
5. Test with quick-test
6. Commit

**Mapping TodayViewModel → TodayViewState:**
```swift
// Animation
viewModel.animationTrigger → state.animationTrigger

// Loading states
viewModel.isLoading → state.phase.isLoading
viewModel.isInitializing → state.phase == .loadingCache
viewModel.isDataLoaded → state.phase == .complete

// HealthKit
viewModel.isHealthKitAuthorized → state.isHealthKitAuthorized

// Activities
viewModel.recentActivities → state.recentActivities
viewModel.unifiedActivities → state.recentActivities.map { UnifiedActivity(from: $0) }

// Lifecycle calls
viewModel.loadInitialUI() → state.handle(.viewAppeared)
viewModel.refreshData() → state.handle(.pullToRefresh)
viewModel.handleAppForeground() → state.handle(.appForegrounded)
```

### Phase 4.3: Activity Coordination Migration

**Goal:** Move activity coordination logic to TodayDataLoader

**Steps:**
1. Read ActivitiesCoordinator.swift to understand current logic
2. Add activity coordination methods to TodayDataLoader
3. Update loadFreshActivities() to include coordination logic
4. Test with quick-test
5. Commit

### Phase 4.4: Remove Legacy Files

**Goal:** Delete TodayViewModel and TodayCoordinator files

**Steps:**
1. Verify no references to TodayViewModel exist
2. Verify no references to TodayCoordinator exist
3. Delete TodayViewModel.swift
4. Delete TodayCoordinator.swift
5. Build to verify no compilation errors
6. Run full test suite
7. Commit

---

## Risk Mitigation

### High Risk Areas:
1. **Animation Timing** - Ring animations must still trigger correctly
2. **Loading States** - LoadingStateView must show correct states
3. **Background Tasks** - Backfill must not block UI or cause crashes
4. **HealthKit Authorization** - Must handle authorization changes correctly

### Testing Strategy:
1. **Quick-test after each step** - Catch regressions immediately
2. **Full-test before commits** - Comprehensive regression testing
3. **Manual testing scenarios:**
   - Cold start (first launch)
   - App foreground after >5 min
   - Pull to refresh
   - HealthKit authorization flow
   - Network offline/online
   - View disappear/reappear

### Rollback Plan:
- Commit after each major step
- If regression detected, git revert to previous commit
- Branch: `phase4-legacy-migration` (new branch from `refactor`)

---

## Testing Checklist

### Unit Tests:
- [ ] TodayViewState lifecycle event handling
- [ ] TodayViewState state machine transitions
- [ ] Background task management
- [ ] Timeout handling
- [ ] Cache invalidation

### Integration Tests:
- [ ] Initial load flow (cache → fresh → background)
- [ ] Pull to refresh flow
- [ ] App foreground flow
- [ ] HealthKit authorization flow
- [ ] Network connectivity changes

### UI Tests:
- [ ] Loading spinner shows/hides correctly
- [ ] Ring animations trigger on data load
- [ ] Error messages display correctly
- [ ] Pull to refresh works
- [ ] Activity list updates correctly

---

## Success Criteria

### Code Quality:
- [ ] All tests passing (quick-test + full-test)
- [ ] No compiler warnings
- [ ] Performance matches or improves Phase 3
- [ ] No memory leaks

### Architecture:
- [ ] Single state container (TodayViewState only)
- [ ] No coordinator pattern remnants
- [ ] Clear separation of concerns
- [ ] Comprehensive logging

### User Experience:
- [ ] 0ms to cached content (maintained)
- [ ] Smooth animations (no regressions)
- [ ] Correct loading states
- [ ] No UI freezes or stutters

---

## Timeline

**Day 1: TodayCoordinator Migration**
- Morning: Add lifecycle handlers to TodayViewState
- Afternoon: Add background task management, cache invalidation
- Evening: Test and commit

**Day 2: TodayViewModel Removal**
- Morning: Update TodayView to use TodayViewState directly
- Afternoon: Remove TodayViewModel bridge, test
- Evening: Activity coordination migration

**Day 3: Cleanup & Testing**
- Morning: Remove legacy files
- Afternoon: Full test suite, manual testing
- Evening: Documentation, final commit

---

## Files to Modify

### Core V2 Architecture:
- `/Users/markboulton/Dev/VeloReady/VeloReady/Features/Today/State/TodayViewState.swift` - Add lifecycle + coordination
- `/Users/markboulton/Dev/VeloReady/VeloReady/Features/Today/Data/TodayDataLoader.swift` - Add activity coordination

### Views:
- `/Users/markboulton/Dev/VeloReady/VeloReady/Features/Today/Views/Dashboard/TodayView.swift` - Remove TodayViewModel usage

### Files to Delete:
- `/Users/markboulton/Dev/VeloReady/VeloReady/Features/Today/ViewModels/TodayViewModel.swift`
- `/Users/markboulton/Dev/VeloReady/VeloReady/Features/Today/Coordinators/TodayCoordinator.swift`

### Documentation:
- `/Users/markboulton/Dev/VeloReady/PHASE4_COMPLETION.md` - Create completion report

---

*Migration plan created: 2025-11-19*
*Branch: phase4-legacy-migration*
*Ready to begin Phase 4.1*
