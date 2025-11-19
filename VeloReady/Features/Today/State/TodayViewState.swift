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

        var isLoading: Bool {
            switch self {
            case .loadingCache, .loadingFreshData:
                return true
            default:
                return false
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

    // MARK: - Initialization

    private init() {
        self.loader = TodayDataLoader()
        setupObservers()
    }

    // MARK: - Public API

    /// Load data with cache-first strategy (0ms to cached content)
    /// Should be called during 3-second branding animation for instant content after animation
    func load() async {
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
            Logger.info("✅ [TodayViewState] Load complete")
        } catch {
            Logger.error("❌ [TodayViewState] Load failed: \(error)")
            phase = .error(error)
        }
    }

    /// Refresh all data (pull-to-refresh)
    func refresh() async {
        Logger.info("🔄 [TodayViewState] Refreshing...")
        phase = .loadingFreshData

        do {
            try await PerformanceMonitor.shared.measure("TodayView.refresh") {
                try await loadFreshData()
            }
            phase = .complete
            lastUpdated = Date()
            animationTrigger = UUID() // Trigger ring animations
            Logger.info("✅ [TodayViewState] Refresh complete")
        } catch {
            Logger.error("❌ [TodayViewState] Refresh failed: \(error)")
            phase = .error(error)
        }
    }

    /// Invalidate caches (app foreground)
    func invalidateShortLivedCaches() async {
        await loader.invalidateHealthKitCaches()
        Logger.debug("🗑️ [TodayViewState] Invalidated short-lived caches")
    }

    // MARK: - Private Methods

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
