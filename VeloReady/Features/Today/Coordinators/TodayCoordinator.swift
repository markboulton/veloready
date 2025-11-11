import Foundation
import Combine

/// Coordinates the Today feature lifecycle and data fetching
/// 
/// **Responsibilities:**
/// - Manage app lifecycle (foreground/background, appear/disappear)
/// - Orchestrate data fetching (scores, activities, wellness)
/// - Manage loading states through state machine
/// - Coordinate background tasks
/// - Provide unified state to TodayViewModel
///
/// **Key Design Decisions:**
/// 1. State machine prevents invalid transitions
/// 2. Lifecycle events are explicit (no hidden side effects)
/// 3. Data fetching is coordinated (scores first, then activities)
/// 4. Comprehensive logging for debugging
/// 5. Error handling with specific error messages
///
/// Created: 2025-11-10
/// Part of: Today View Refactoring Plan - Phase 3 (Week 3-4)
@MainActor
class TodayCoordinator: ObservableObject {
    @Published private(set) var state: State = .initial
    @Published private(set) var error: TodayError?
    
    /// Coordinator state machine
    enum State: Equatable {
        case initial            // Never loaded (app just launched)
        case loading            // First load in progress
        case ready              // Loaded and ready, view active
        case background         // App in background
        case refreshing         // Pull-to-refresh or foreground refresh
        case error(String)      // Error occurred
        
        var description: String {
            switch self {
            case .initial: return "initial"
            case .loading: return "loading"
            case .ready: return "ready"
            case .background: return "background"
            case .refreshing: return "refreshing"
            case .error(let msg): return "error(\(msg))"
            }
        }
    }
    
    /// Errors that can occur in Today feature
    enum TodayError: Error, LocalizedError {
        case networkUnavailable
        case authenticationFailed
        case dataFetchFailed(String)
        case scoreCalculationTimeout
        case scoreCalculationFailed
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "Network unavailable. Please check your connection."
            case .authenticationFailed:
                return "Authentication failed. Please sign in again."
            case .dataFetchFailed(let details):
                return "Failed to fetch data: \(details)"
            case .scoreCalculationTimeout:
                return "Score calculation timed out. Pull to refresh to try again."
            case .scoreCalculationFailed:
                return "Score calculation failed. Pull to refresh to try again."
            case .unknown(let details):
                return "An error occurred: \(details)"
            }
        }
    }
    
    // Dependencies
    private let scoresCoordinator: ScoresCoordinator
    private let activitiesCoordinator: ActivitiesCoordinator
    private let services: ServiceContainer
    private let loadingStateManager: LoadingStateManager
    
    // Lifecycle tracking
    private var hasLoadedOnce = false
    private var isViewActive = false
    private var lastLoadTime: Date?
    
    // Background task management
    private var backgroundTasks: [Task<Void, Never>] = []
    
    // MARK: - Initialization
    
    init(
        scoresCoordinator: ScoresCoordinator,
        activitiesCoordinator: ActivitiesCoordinator,
        services: ServiceContainer = .shared,
        loadingStateManager: LoadingStateManager
    ) {
        self.scoresCoordinator = scoresCoordinator
        self.activitiesCoordinator = activitiesCoordinator
        self.services = services
        self.loadingStateManager = loadingStateManager
        
        Logger.info("🎯 [TodayCoordinator] Initialized")
    }
    
    // MARK: - Lifecycle Events
    
    /// Handle lifecycle events through state machine
    /// 
    /// **State Machine Rules:**
    /// - .initial + viewAppeared → loadInitial()
    /// - .ready + viewAppeared → (no-op, already loaded)
    /// - .ready + appForegrounded → refresh() (if > 5 mins since last load)
    /// - .ready + viewDisappeared → .background
    /// - .ready + pullToRefresh → refresh()
    /// - .ready + healthKitAuthorized → refresh()
    ///
    /// - Parameter event: The lifecycle event to handle
    func handle(_ event: LifecycleEvent) async {
        Logger.info("🔄 [TodayCoordinator] Handling event: \(event) - current state: \(state.description)")
        
        switch (event, state) {
        case (.viewAppeared, .initial):
            // First time view appears - load everything
            isViewActive = true
            await loadInitial()
            hasLoadedOnce = true
            
        case (.viewAppeared, .background):
            // View reappeared after backgrounding
            isViewActive = true
            if shouldRefreshOnReappear() {
                await refresh()
            } else {
                state = .ready
                Logger.info("✅ [TodayCoordinator] View reappeared - data still fresh, no refresh needed")
            }
            
        case (.viewAppeared, _):
            // Subsequent appears (e.g., navigating back from detail)
            isViewActive = true
            Logger.info("✅ [TodayCoordinator] View appeared - state: \(state.description), no action needed")
            
        case (.viewDisappeared, _):
            // View disappeared (navigated away or backgrounded)
            isViewActive = false
            cancelBackgroundTasks()
            if state != .initial {
                state = .background
            }
            Logger.info("✅ [TodayCoordinator] View disappeared - transitioned to background, tasks cancelled")
            
        case (.appForegrounded, _) where isViewActive:
            // App came to foreground while view is active
            // Safety check: If we're in .ready state but scores are still loading, something is wrong
            let scoresStillLoading = scoresCoordinator.state.phase == .loading || 
                                     scoresCoordinator.state.phase == .initial
            
            if scoresStillLoading {
                Logger.warning("⚠️ [TodayCoordinator] Inconsistent state: coordinator \(state.description) but scores \(scoresCoordinator.state.phase) - forcing refresh")
                await refresh()
            } else if shouldRefreshOnReappear() {
                await refresh()
            } else {
                Logger.info("✅ [TodayCoordinator] App foregrounded - data still fresh, no refresh needed")
            }
            
        case (.healthKitAuthorized, .ready):
            // HealthKit was just authorized - refresh to get new data
            Logger.info("🔄 [TodayCoordinator] HealthKit authorized - refreshing data")
            await refresh()
            
        case (.pullToRefresh, .ready), (.pullToRefresh, .background):
            // User explicitly triggered pull-to-refresh
            await refresh()
            
        case (.intervalsAuthChanged, .ready):
            // Intervals.icu auth changed - refresh activities
            Logger.info("🔄 [TodayCoordinator] Intervals auth changed - refreshing activities")
            await refreshActivitiesOnly()
            
        default:
            Logger.debug("⏭️ [TodayCoordinator] Ignoring event: \(event) in state: \(state.description)")
        }
    }
    
    /// Lifecycle events that can occur
    enum LifecycleEvent: CustomStringConvertible {
        case viewAppeared
        case viewDisappeared
        case appForegrounded
        case healthKitAuthorized
        case pullToRefresh
        case intervalsAuthChanged
        
        var description: String {
            switch self {
            case .viewAppeared: return "viewAppeared"
            case .viewDisappeared: return "viewDisappeared"
            case .appForegrounded: return "appForegrounded"
            case .healthKitAuthorized: return "healthKitAuthorized"
            case .pullToRefresh: return "pullToRefresh"
            case .intervalsAuthChanged: return "intervalsAuthChanged"
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load initial data (first load only)
    ///
    /// **Flow:**
    /// 1. Set state to .loading
    /// 2. Load cached data (instant)
    /// 3. Calculate scores (2-3 seconds) WITH TIMEOUT
    /// 4. Fetch activities (background, non-blocking)
    /// 5. Set state to .ready (ONLY if scores succeeded)
    private func loadInitial() async {
        let startTime = Date()
        Logger.info("🔄 [TodayCoordinator] ━━━ Starting loadInitial() ━━━")
        
        state = .loading
        error = nil
        
        do {
            // Phase 1: Fetch health data and calculate scores WITH TIMEOUT
            // NOTE: HealthKit authorization check is GUARANTEED to be complete at this point
            // RootView.onAppear blocks UI rendering until checkAuthorizationAfterSettingsReturn() finishes
            Logger.info("🔄 [TodayCoordinator] Phase 1: Calculating scores...")
            loadingStateManager.updateState(.fetchingHealthData)
            
            // Start score calculation in background, but show status updates in foreground
            let scoreTask = Task {
                await scoresCoordinator.calculateAll()
            }
            
            // Wait a bit, then transition to "calculating" state
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
            
            let hasHealthKit = services.healthKitManager.isAuthorized
            loadingStateManager.updateState(.calculatingScores(hasHealthKit: hasHealthKit, hasSleepData: false))
            
            // Wait for scores to complete WITH TIMEOUT (20 seconds - generous for slow HealthKit)
            let scoreResult = await withTimeout(seconds: 20) {
                await scoreTask.value
            }
            
            // CRITICAL: Verify scores actually completed successfully
            guard scoreResult == .completed else {
                Logger.error("❌ [TodayCoordinator] Score calculation timed out after 20s!")
                // DON'T set lastLoadTime - this allows retry on next foreground (>5 min)
                state = .error("Score calculation timed out")
                self.error = .scoreCalculationTimeout
                loadingStateManager.updateState(.error(.unknown("Score calculation timed out")))
                return
            }
            
            // Verify scores coordinator reached .ready phase
            guard scoresCoordinator.state.phase == .ready else {
                Logger.error("❌ [TodayCoordinator] Score calculation completed but phase is \(scoresCoordinator.state.phase), not .ready!")
                // DON'T set lastLoadTime - this allows retry on next foreground (>5 min)
                state = .error("Score calculation failed")
                self.error = .scoreCalculationFailed
                loadingStateManager.updateState(.error(.unknown("Score calculation failed")))
                return
            }
            
            Logger.info("✅ [TodayCoordinator] Scores calculated successfully")
            
            // Phase 2: Fetch activities (foreground for initial load to show all states)
            Logger.info("🔄 [TodayCoordinator] Phase 2: Fetching activities...")
            loadingStateManager.updateState(.contactingIntegrations(sources: [.strava, .appleHealth]))
            
            // Start activity fetch, show "contacting" for a bit
            let activityTask = Task {
                await activitiesCoordinator.fetchRecent(days: 90)
            }
            
            // Wait a bit before transitioning to "downloading"
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            let activities = await activityTask.value
            
            if activities.count > 0 {
                loadingStateManager.updateState(.downloadingActivities(count: activities.count, source: .strava))
            }
            
            // Phase 3: Processing and saving
            loadingStateManager.updateState(.processingData)
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            loadingStateManager.updateState(.savingToICloud)
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            
            // CRITICAL: Only mark as ready and set lastLoadTime if we got here
            // (scores verified, activities fetched - everything succeeded)
            state = .ready
            lastLoadTime = Date()
            
            // Show "Updated just now" persistently (not .complete which hides immediately)
            loadingStateManager.updateState(.updated(Date()))
            
            let duration = Date().timeIntervalSince(startTime)
            Logger.info("✅ [TodayCoordinator] ━━━ Initial load complete in \(String(format: "%.2f", duration))s ━━━")
            
        } catch {
            // CRITICAL: DON'T set lastLoadTime on error
            // This allows automatic retry on next foreground (>5 min)
            let errorMessage = "Failed to load initial data: \(error.localizedDescription)"
            state = .error(errorMessage)
            self.error = .dataFetchFailed(error.localizedDescription)
            loadingStateManager.updateState(.error(.unknown(error.localizedDescription)))
            Logger.error("❌ [TodayCoordinator] Initial load failed: \(error) - will retry on next foreground")
        }
    }
    
    /// Refresh data (when app reopened or user pulls to refresh)
    ///
    /// **Flow:**
    /// 1. Set state to .refreshing (keeps existing data visible)
    /// 2. Refresh scores
    /// 3. Refresh activities
    /// 4. Set state to .ready
    private func refresh() async {
        let startTime = Date()
        Logger.info("🔄 [TodayCoordinator] ━━━ Starting refresh() ━━━")
        
        let oldState = state
        state = .refreshing
        error = nil
        
        do {
            // Show "Contacting..." status (NOT "Calculating scores" since scores already visible)
            loadingStateManager.updateState(.contactingIntegrations(sources: [.strava, .appleHealth]))
            
            // Refresh scores and activities in parallel
            Logger.info("🔄 [TodayCoordinator] Refreshing scores and activities...")
            
            async let scoresRefresh = scoresCoordinator.refresh()
            
            // Fetch activities and update loading state with count
            let activities = await activitiesCoordinator.fetchRecent(days: 90)
            if activities.count > 0 {
                loadingStateManager.updateState(.downloadingActivities(count: activities.count, source: .strava))
            }
            
            // Wait for scores to complete
            await scoresRefresh
            
            // Processing and syncing states
            loadingStateManager.updateState(.processingData)
            loadingStateManager.updateState(.savingToICloud)
            
            // Mark as ready
            state = .ready
            lastLoadTime = Date()
            
            loadingStateManager.updateState(.updated(Date()))
            
            let duration = Date().timeIntervalSince(startTime)
            Logger.info("✅ [TodayCoordinator] ━━━ Refresh complete in \(String(format: "%.2f", duration))s ━━━")
            
        } catch {
            let errorMessage = "Failed to refresh data: \(error.localizedDescription)"
            state = oldState // Revert to previous state on error
            self.error = .dataFetchFailed(error.localizedDescription)
            loadingStateManager.updateState(.error(.unknown(error.localizedDescription)))
            Logger.error("❌ [TodayCoordinator] Refresh failed: \(error)")
        }
    }
    
    /// Refresh activities only (when Intervals auth changes)
    private func refreshActivitiesOnly() async {
        Logger.info("🔄 [TodayCoordinator] Refreshing activities only...")
        
        let _ = await activitiesCoordinator.fetchRecent(days: 90)
        Logger.info("✅ [TodayCoordinator] Activities refreshed")
    }
    
    // MARK: - Background Tasks
    
    /// Start fetching activities in background (non-blocking)
    private func startBackgroundActivityFetch() {
        let task = Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            Logger.info("📦 [TodayCoordinator] Background: Fetching activities...")
            let _ = await self.activitiesCoordinator.fetchRecent(days: 90)
            Logger.info("✅ [TodayCoordinator] Background: Activities fetched")
        }
        
        backgroundTasks.append(task)
    }
    
    /// Cancel all background tasks
    private func cancelBackgroundTasks() {
        guard !backgroundTasks.isEmpty else { return }
        
        Logger.info("🛑 [TodayCoordinator] Cancelling \(backgroundTasks.count) background tasks")
        backgroundTasks.forEach { $0.cancel() }
        backgroundTasks.removeAll()
    }
    
    // MARK: - Helper Methods
    
    /// Determine if data should be refreshed when view reappears
    /// - Returns: True if data is stale (> 5 minutes old)
    private func shouldRefreshOnReappear() -> Bool {
        guard hasLoadedOnce else { return true }
        
        guard let lastLoadTime = lastLoadTime else { return true }
        
        let timeSinceLastLoad = Date().timeIntervalSince(lastLoadTime)
        let shouldRefresh = timeSinceLastLoad > 300 // 5 minutes
        
        Logger.info("⏰ [TodayCoordinator] Time since last load: \(String(format: "%.0f", timeSinceLastLoad))s - shouldRefresh: \(shouldRefresh)")
        
        return shouldRefresh
    }
    
    /// Execute an async operation with a timeout
    /// - Parameters:
    ///   - seconds: Timeout duration in seconds
    ///   - operation: The async operation to execute
    /// - Returns: `.completed` if operation finished in time, `.timedOut` otherwise
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> TimeoutResult {
        await withTaskGroup(of: TimeoutResult.self) { group in
            // Task 1: Run the actual operation
            group.addTask {
                _ = await operation()
                return .completed
            }
            
            // Task 2: Timeout timer
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .timedOut
            }
            
            // Return whichever completes first
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Result of a timeout operation
    private enum TimeoutResult {
        case completed
        case timedOut
    }
    
    // MARK: - Public API for Manual Control
    
    /// Force refresh (bypassing time checks)
    func forceRefresh() async {
        Logger.info("🔄 [TodayCoordinator] Force refresh requested")
        await refresh()
    }
    
    /// Force refresh scores only (bypassing daily limits)
    func forceRefreshScores() async {
        Logger.info("🔄 [TodayCoordinator] Force refresh scores requested")
        await scoresCoordinator.calculateAll(forceRefresh: true)
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension TodayCoordinator {
    /// Log current state for debugging
    func logCurrentState() {
        Logger.debug("📊 [TodayCoordinator] Current State:")
        Logger.debug("  state: \(state.description)")
        Logger.debug("  hasLoadedOnce: \(hasLoadedOnce)")
        Logger.debug("  isViewActive: \(isViewActive)")
        Logger.debug("  lastLoadTime: \(lastLoadTime?.description ?? "nil")")
        Logger.debug("  backgroundTasks: \(backgroundTasks.count)")
    }
}
#endif

