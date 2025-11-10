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
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "Network unavailable. Please check your connection."
            case .authenticationFailed:
                return "Authentication failed. Please sign in again."
            case .dataFetchFailed(let details):
                return "Failed to fetch data: \(details)"
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
            if shouldRefreshOnReappear() {
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
    /// 3. Calculate scores (2-3 seconds)
    /// 4. Fetch activities (background, non-blocking)
    /// 5. Set state to .ready
    private func loadInitial() async {
        let startTime = Date()
        Logger.info("🔄 [TodayCoordinator] ━━━ Starting loadInitial() ━━━")
        
        state = .loading
        error = nil
        
        do {
            // Phase 1: Fetch health data and calculate scores
            Logger.info("🔄 [TodayCoordinator] Phase 1: Calculating scores...")
            loadingStateManager.updateState(.fetchingHealthData)
            
            // Check if HealthKit is authorized
            let hasHealthKit = services.healthKitManager.isAuthorized
            loadingStateManager.updateState(.calculatingScores(hasHealthKit: hasHealthKit, hasSleepData: false))
            
            await scoresCoordinator.calculateAll()
            Logger.info("✅ [TodayCoordinator] Scores calculated")
            
            // Phase 2: Fetch activities (background, non-blocking)
            Logger.info("🔄 [TodayCoordinator] Phase 2: Fetching activities in background...")
            loadingStateManager.updateState(.contactingIntegrations(sources: [.strava, .appleHealth]))
            
            startBackgroundActivityFetch()
            
            // Mark as ready
            state = .ready
            lastLoadTime = Date()
            
            loadingStateManager.updateState(.complete)
            
            let duration = Date().timeIntervalSince(startTime)
            Logger.info("✅ [TodayCoordinator] ━━━ Initial load complete in \(String(format: "%.2f", duration))s ━━━")
            
        } catch {
            let errorMessage = "Failed to load initial data: \(error.localizedDescription)"
            state = .error(errorMessage)
            self.error = .dataFetchFailed(error.localizedDescription)
            loadingStateManager.updateState(.error(.unknown(error.localizedDescription)))
            Logger.error("❌ [TodayCoordinator] Initial load failed: \(error)")
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
            async let activitiesRefresh: Void = {
                let activities = await activitiesCoordinator.fetchRecent(days: 90)
                // Update with activity count if available
                if activities.count > 0 {
                    loadingStateManager.updateState(.downloadingActivities(count: activities.count, source: .strava))
                }
            }()
            
            // Wait for both to complete
            _ = await (scoresRefresh, activitiesRefresh)
            
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
        
        do {
            await activitiesCoordinator.fetchRecent(days: 90)
            Logger.info("✅ [TodayCoordinator] Activities refreshed")
        } catch {
            Logger.error("❌ [TodayCoordinator] Activities refresh failed: \(error)")
        }
    }
    
    // MARK: - Background Tasks
    
    /// Start fetching activities in background (non-blocking)
    private func startBackgroundActivityFetch() {
        let task = Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            Logger.info("📦 [TodayCoordinator] Background: Fetching activities...")
            await self.activitiesCoordinator.fetchRecent(days: 90)
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

