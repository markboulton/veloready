import SwiftUI
import Combine

/// Unified state container for Today view (Phase 1 - V2 Architecture)
/// Replaces 10 @ObservedObject properties with a single source of truth
@MainActor
final class TodayViewState: ObservableObject {
    static let shared = TodayViewState()

    // MARK: - Loading Phase

    enum LoadingPhase {
        case notStarted
        case loadingCache          // 0ms - Show cached data
        case loadingFreshData      // Background refresh
        case complete
        case error(Error)
        case background            // View inactive (backgrounded or navigated away)
        case refreshing            // Pull-to-refresh in progress

        var isLoading: Bool {
            switch self {
            case .loadingCache, .loadingFreshData, .refreshing:
                return true
            default:
                return false
            }
        }

        var description: String {
            switch self {
            case .notStarted: return "notStarted"
            case .loadingCache: return "loadingCache"
            case .loadingFreshData: return "loadingFreshData"
            case .complete: return "complete"
            case .error(let error): return "error(\(error.localizedDescription))"
            case .background: return "background"
            case .refreshing: return "refreshing"
            }
        }
    }

    // MARK: - Lifecycle Events

    /// Lifecycle events that can occur in Today view
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

    // MARK: - Published State

    @Published var phase: LoadingPhase = .notStarted
    @Published var lastUpdated: Date?

    // MARK: - Core Scores State

    @Published var recoveryScore: Double?
    @Published var sleepScore: Double?
    @Published var strainScore: Double?
    @Published var recoveryPhase: RecoveryPhaseType = .calculating

    // MARK: - Physio State

    @Published var hrv: Double?
    @Published var hrvBaseline: Double?
    @Published var rhr: Double?
    @Published var rhrBaseline: Double?

    // MARK: - Sleep State

    @Published var sleepDuration: TimeInterval?
    @Published var sleepBaseline: TimeInterval?

    // MARK: - Training Load State

    @Published var ctl: Double?
    @Published var atl: Double?
    @Published var tsb: Double?
    @Published var todayTSS: Double?
    @Published var trainingLoadHistory: [TrainingLoadDataPoint] = []

    // MARK: - Activities State

    @Published var latestActivity: Activity?
    @Published var recentActivities: [Activity] = []

    // MARK: - Live Activity State

    @Published var todaySteps: Int?
    @Published var stepGoal: Int?
    @Published var todayCalories: Double?
    @Published var calorieGoal: Double?
    @Published var todayDistance: Double?

    // MARK: - Performance Metrics State

    @Published var currentFTP: Double?
    @Published var ftpTrend: TrendDirection = .stable
    @Published var currentVO2Max: Double?
    @Published var vo2MaxTrend: TrendDirection = .stable

    // MARK: - Alert State

    @Published var activeAlerts: [TodayAlert] = []

    // MARK: - Health Kit State

    @Published var isHealthKitAuthorized: Bool = false
    @Published var hasCompletedInitialAuthCheck: Bool = false

    // MARK: - Network State

    @Published var isConnected: Bool = true
    @Published var hasStravaConnection: Bool = false
    @Published var hasIntervalsConnection: Bool = false

    // MARK: - Animation State

    @Published var animationTrigger: UUID = UUID()

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let loader: TodayDataLoader

    // Lifecycle tracking
    private var hasLoadedOnce = false
    private var isViewActive = false
    private var lastLoadTime: Date?

    // Background task management
    private var backgroundTasks: [Task<Void, Never>] = []

    // MARK: - Initialization

    private init() {
        self.loader = TodayDataLoader()
        setupObservers()
    }

    // MARK: - Public API

    /// Load data with cache-first strategy (0ms to cached content)
    /// Should be called during 3-second branding animation for instant content after animation
    func load() async {
        let startTime = Date()
        Logger.info("📦 [TodayViewState] Starting load...")

        // Phase 1: Load cached data (0ms)
        phase = .loadingCache
        await PerformanceMonitor.shared.measure("TodayView.loadCache") {
            await loadCachedData()
        }

        // Phase 2: Refresh with fresh data (background)
        phase = .loadingFreshData
        do {
            try await PerformanceMonitor.shared.measure("TodayView.loadFresh") {
                try await loadFreshData()
            }
            phase = .complete
            lastUpdated = Date()
            lastLoadTime = Date() // Track for auto-refresh logic

            let duration = Date().timeIntervalSince(startTime)
            Logger.info("✅ [TodayViewState] Load complete in \(String(format: "%.2f", duration))s")

            // Phase 3: Background backfill of historical data (non-blocking)
            let backfillTask = Task(priority: .background) {
                Logger.info("🔄 [TodayViewState] Starting background backfill...")

                // Clean up corrupt data
                await DailyDataService.shared.cleanupCorruptTrainingLoadData()

                // Backfill all historical data
                await BackfillService.shared.backfillAll(days: 60, forceRefresh: true)

                Logger.info("✅ [TodayViewState] Background backfill complete")
            }
            backgroundTasks.append(backfillTask)

        } catch {
            Logger.error("❌ [TodayViewState] Load failed: \(error)")
            phase = .error(error)
            // Don't set lastLoadTime on error - allows retry
        }
    }

    /// Refresh all data (pull-to-refresh)
    func refresh() async {
        let startTime = Date()
        Logger.info("🔄 [TodayViewState] Refreshing...")

        let oldPhase = phase
        phase = .refreshing

        do {
            try await PerformanceMonitor.shared.measure("TodayView.refresh") {
                try await loadFreshData()
            }
            phase = .complete
            lastUpdated = Date()
            lastLoadTime = Date() // Track for auto-refresh logic
            animationTrigger = UUID() // Trigger ring animations

            let duration = Date().timeIntervalSince(startTime)
            Logger.info("✅ [TodayViewState] Refresh complete in \(String(format: "%.2f", duration))s")
        } catch {
            Logger.error("❌ [TodayViewState] Refresh failed: \(error)")
            phase = oldPhase // Revert to previous phase on error
            // Don't set lastLoadTime on error - allows retry
        }
    }

    /// Invalidate caches (app foreground)
    func invalidateShortLivedCaches() async {
        await loader.invalidateHealthKitCaches()
        Logger.debug("🗑️ [TodayViewState] Invalidated short-lived caches")
    }

    /// Handle lifecycle events through state machine
    ///
    /// **State Machine Rules:**
    /// - .notStarted + viewAppeared → load()
    /// - .complete + viewAppeared → (no-op, already loaded)
    /// - .complete + appForegrounded → refresh() (if > 5 mins since last load)
    /// - .complete + viewDisappeared → .background
    /// - .complete + pullToRefresh → refresh()
    /// - .complete + healthKitAuthorized → refresh()
    func handle(_ event: LifecycleEvent) async {
        Logger.info("🔄 [TodayViewState] Handling event: \(event) - current phase: \(phase.description)")

        switch (event, phase) {
        case (.viewAppeared, .notStarted):
            // First time view appears - load everything
            isViewActive = true
            await load()
            hasLoadedOnce = true

        case (.viewAppeared, .background):
            // View reappeared after backgrounding
            isViewActive = true
            if shouldAutoRefresh {
                await refresh()
            } else {
                phase = .complete
                Logger.info("✅ [TodayViewState] View reappeared - data still fresh")
            }

        case (.viewAppeared, _):
            // Subsequent appears (e.g., navigating back from detail)
            isViewActive = true
            Logger.info("✅ [TodayViewState] View appeared - phase: \(phase.description), no action needed")

        case (.viewDisappeared, _):
            // View disappeared (navigated away or backgrounded)
            isViewActive = false
            cancelBackgroundTasks()
            // Only transition to background if we've started loading
            switch phase {
            case .notStarted:
                break // Don't change phase if never started
            default:
                phase = .background
            }
            Logger.info("✅ [TodayViewState] View disappeared - transitioned to background, tasks cancelled")

        case (.appForegrounded, _) where isViewActive:
            // App came to foreground while view is active
            if shouldAutoRefresh {
                await refresh()
            } else {
                Logger.info("✅ [TodayViewState] App foregrounded - data still fresh, no refresh needed")
            }

        case (.healthKitAuthorized, .loadingCache), (.healthKitAuthorized, .loadingFreshData):
            // HealthKit authorized during initial load - will be picked up automatically
            Logger.info("🔄 [TodayViewState] HealthKit authorized during loading - will refresh after current load")

        case (.healthKitAuthorized, .complete):
            // HealthKit was just authorized - refresh to get new data
            Logger.info("🔄 [TodayViewState] HealthKit authorized - refreshing data")
            await refresh()

        case (.pullToRefresh, .complete), (.pullToRefresh, .background):
            // User explicitly triggered pull-to-refresh - invalidate caches first
            await invalidateActivityCaches()
            await refresh()

        case (.intervalsAuthChanged, .complete):
            // Intervals.icu auth changed - refresh activities
            Logger.info("🔄 [TodayViewState] Intervals auth changed - refreshing data")
            await refresh()

        default:
            Logger.debug("⏭️ [TodayViewState] Ignoring event: \(event) in phase: \(phase.description)")
        }
    }

    // MARK: - Private Methods

    /// Whether data should be auto-refreshed (> 5 minutes since last load)
    private var shouldAutoRefresh: Bool {
        guard let lastLoad = lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) > 300 // 5 minutes
    }

    /// Cancel all background tasks
    private func cancelBackgroundTasks() {
        guard !backgroundTasks.isEmpty else { return }

        Logger.info("🛑 [TodayViewState] Cancelling \(backgroundTasks.count) background tasks")
        backgroundTasks.forEach { $0.cancel() }
        backgroundTasks.removeAll()
    }

    /// Invalidate activity caches (for pull-to-refresh)
    /// Forces fresh fetch from Strava/Intervals on next request
    private func invalidateActivityCaches() async {
        Logger.info("🗑️ [TodayViewState] Invalidating activity caches for pull-to-refresh")

        let cacheManager = UnifiedCacheManager.shared

        // Invalidate Strava activity caches (all time ranges)
        await cacheManager.invalidate(key: "strava:activities:7")
        await cacheManager.invalidate(key: "strava:activities:30")
        await cacheManager.invalidate(key: "strava:activities:90")
        await cacheManager.invalidate(key: "strava:activities:365")

        // Invalidate Intervals activity caches
        await cacheManager.invalidate(key: "intervals:activities:7")
        await cacheManager.invalidate(key: "intervals:activities:30")
        await cacheManager.invalidate(key: "intervals:activities:90")
        await cacheManager.invalidate(key: "intervals:activities:120")

        Logger.debug("✅ [TodayViewState] Activity caches invalidated")
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

    private func setupObservers() {
        // Observe HealthKit authorization changes
        HealthKitManager.shared.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$isHealthKitAuthorized)

        HealthKitManager.shared.authorizationCoordinator.$hasCompletedInitialCheck
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasCompletedInitialAuthCheck)

        // Observe network connectivity
        NetworkMonitor.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        // TODO: Fix data source connection observations
        // Need to understand proper APIs for StravaAuthService and IntervalsOAuthManager
        // StravaAuthService.shared.connectionState.$isConnected
        //     .receive(on: DispatchQueue.main)
        //     .assign(to: &$hasStravaConnection)

        IntervalsOAuthManager.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasIntervalsConnection)
    }

    private func loadCachedData() async {
        Logger.debug("💾 [TodayViewState] Loading cached data...")

        // Load cached scores (instant)
        if let cachedScores = await loader.loadCachedScores() {
            self.recoveryScore = cachedScores.recovery
            self.sleepScore = cachedScores.sleep
            self.strainScore = cachedScores.strain
            self.recoveryPhase = cachedScores.phase
            Logger.debug("✅ [TodayViewState] Loaded cached scores")
        }

        // Load cached physio (instant)
        if let cachedPhysio = await loader.loadCachedPhysio() {
            self.hrv = cachedPhysio.hrv
            self.hrvBaseline = cachedPhysio.hrvBaseline
            self.rhr = cachedPhysio.rhr
            self.rhrBaseline = cachedPhysio.rhrBaseline
            Logger.debug("✅ [TodayViewState] Loaded cached physio")
        }

        // Load cached sleep (instant)
        if let cachedSleep = await loader.loadCachedSleep() {
            self.sleepDuration = cachedSleep.duration
            self.sleepBaseline = cachedSleep.baseline
            Logger.debug("✅ [TodayViewState] Loaded cached sleep")
        }

        // Load cached training load (instant)
        if let cachedLoad = await loader.loadCachedTrainingLoad() {
            self.ctl = cachedLoad.ctl
            self.atl = cachedLoad.atl
            self.tsb = cachedLoad.tsb
            self.todayTSS = cachedLoad.todayTSS
            self.trainingLoadHistory = cachedLoad.history
            Logger.debug("✅ [TodayViewState] Loaded cached training load")
        }

        // Load cached activities (instant)
        if let cachedActivities = await loader.loadCachedActivities() {
            self.latestActivity = cachedActivities.latest
            self.recentActivities = cachedActivities.recent
            Logger.debug("✅ [TodayViewState] Loaded cached activities")
        }

        // Load cached live activity (instant)
        if let cachedLive = await loader.loadCachedLiveActivity() {
            self.todaySteps = cachedLive.steps
            self.stepGoal = cachedLive.stepGoal
            self.todayCalories = cachedLive.calories
            self.calorieGoal = cachedLive.calorieGoal
            self.todayDistance = cachedLive.distance
            Logger.debug("✅ [TodayViewState] Loaded cached live activity")
        }

        // Load cached performance (instant)
        if let cachedPerformance = await loader.loadCachedPerformance() {
            self.currentFTP = cachedPerformance.ftp
            self.ftpTrend = cachedPerformance.ftpTrend
            self.currentVO2Max = cachedPerformance.vo2Max
            self.vo2MaxTrend = cachedPerformance.vo2MaxTrend
            Logger.debug("✅ [TodayViewState] Loaded cached performance")
        }
    }

    private func loadFreshData() async throws {
        Logger.debug("🌐 [TodayViewState] Loading fresh data...")

        // Load all data in parallel (2-3s total)
        async let freshScores = loader.loadFreshScores()
        async let freshPhysio = loader.loadFreshPhysio()
        async let freshSleep = loader.loadFreshSleep()
        async let freshLoad = loader.loadFreshTrainingLoad()
        async let freshActivities = loader.loadFreshActivities()
        async let freshLive = loader.loadFreshLiveActivity()
        async let freshPerformance = loader.loadFreshPerformance()
        async let alerts = loader.loadAlerts()

        // Await all results
        let (scores, physio, sleep, load, activities, live, performance, alertList) = try await (
            freshScores, freshPhysio, freshSleep, freshLoad,
            freshActivities, freshLive, freshPerformance, alerts
        )

        // Update state with fresh data
        if let scores = scores {
            self.recoveryScore = scores.recovery
            self.sleepScore = scores.sleep
            self.strainScore = scores.strain
            self.recoveryPhase = scores.phase
        }

        if let physio = physio {
            self.hrv = physio.hrv
            self.hrvBaseline = physio.hrvBaseline
            self.rhr = physio.rhr
            self.rhrBaseline = physio.rhrBaseline
        }

        if let sleep = sleep {
            self.sleepDuration = sleep.duration
            self.sleepBaseline = sleep.baseline
        }

        if let load = load {
            self.ctl = load.ctl
            self.atl = load.atl
            self.tsb = load.tsb
            self.todayTSS = load.todayTSS
            self.trainingLoadHistory = load.history
        }

        self.latestActivity = activities.latest
        self.recentActivities = activities.recent

        self.todaySteps = live.steps
        self.stepGoal = live.stepGoal
        self.todayCalories = live.calories
        self.calorieGoal = live.calorieGoal
        self.todayDistance = live.distance

        self.currentFTP = performance.ftp
        self.ftpTrend = performance.ftpTrend
        self.currentVO2Max = performance.vo2Max
        self.vo2MaxTrend = performance.vo2MaxTrend

        self.activeAlerts = alertList

        Logger.debug("✅ [TodayViewState] Fresh data loaded")
    }
}

// MARK: - Supporting Types

enum TrendDirection {
    case up, down, stable
}

enum RecoveryPhaseType {
    case calculating
    case ready
    case fatigued
    case recovering
    case optimal
    case overreaching
}
