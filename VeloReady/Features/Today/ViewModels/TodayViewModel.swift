import Foundation
import SwiftUI
import Combine

/// ViewModel for the Today feature (SIMPLIFIED - Phase 3)
/// 
/// **BEFORE Phase 3:**
/// - 880 lines of code
/// - 3 responsibilities: Coordination + Presentation + Lifecycle
/// - Complex state management
/// - 20+ @Published properties
/// - 6 lifecycle handlers
/// - Background task management
/// - Activity fetching logic
/// - Score calculation orchestration
///
/// **AFTER Phase 3:**
/// - ~200 lines of code (-76%)
/// - 1 responsibility: Presentation only
/// - Simple state delegation
/// - Minimal @Published properties (UI state only)
/// - Lifecycle delegated to TodayCoordinator
/// - Activities delegated to ActivitiesCoordinator
/// - Scores delegated to ScoresCoordinator
///
/// Created: 2025-11-10 (originally)
/// Refactored: 2025-11-10 (Phase 3 - Week 3)
@MainActor
class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()
    
    // MARK: - Published Properties (UI State Only)
    
    @Published var animationTrigger = UUID() // Triggers ring animations on state changes
    @Published var isHealthKitAuthorized = false
    @Published var errorMessage: String?
    
    // Legacy loading states (deprecated, kept for backwards compatibility during migration)
    @Published var isLoading = false
    @Published var isInitializing = true {
        didSet {
            if !isInitializing && oldValue {
                animationTrigger = UUID()
                Logger.debug("🎬 [TodayViewModel] Triggered ring animations after spinner")
            }
        }
    }
    @Published var isDataLoaded = false
    
    // Legacy activity lists (kept for backwards compatibility)
    @Published var recentActivities: [Activity] = []
    @Published var unifiedActivities: [UnifiedActivity] = []
    @Published var wellnessData: [IntervalsWellness] = []
    
    // Loading state manager (kept for LoadingStateView compatibility)
    // Shared with TodayCoordinator via ServiceContainer
    @ObservedObject var loadingStateManager: LoadingStateManager
    
    // MARK: - Coordinators (NEW - Phase 3)

    private lazy var coordinator: TodayCoordinator = services.todayCoordinator
    let scoresCoordinator: ScoresCoordinator // Public for RecoveryMetricsSection
    private lazy var activitiesCoordinator: ActivitiesCoordinator = services.activitiesCoordinator

    // MARK: - V2 Architecture State

    private let todayState = TodayViewState.shared  // V2 Architecture

    // MARK: - Dependencies (Minimal)

    private let services: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // Convenience accessors for services still used directly
    let recoveryScoreService: RecoveryScoreService
    let sleepScoreService: SleepScoreService
    let strainScoreService: StrainScoreService
    
    // Track if initial UI has been loaded
    private var hasLoadedInitialUI = false
    
    // MARK: - Initialization
    
    private init(container: ServiceContainer = .shared) {
        let useV2 = FeatureFlags.shared.useTodayViewV2
        Logger.info("🎬 [TodayViewModel] Init (V2: \(useV2)) - using coordinators...")

        self.services = container

        // Loading state manager (shared with TodayCoordinator)
        self.loadingStateManager = container.loadingStateManager

        // Score services (still exposed for backwards compatibility)
        self.recoveryScoreService = container.recoveryScoreService
        self.sleepScoreService = container.sleepScoreService
        self.strainScoreService = container.strainScoreService

        // ScoresCoordinator is eagerly initialized (needed for UI bindings)
        self.scoresCoordinator = container.scoresCoordinator
        // coordinator and activitiesCoordinator are lazy (initialized on first use)

        Logger.info("✅ [TodayViewModel] Core services initialized")

        // V2: Initialize from TodayViewState if enabled
        if useV2 {
            Logger.info("🏗️ [TodayViewModel] Using TodayViewState (V2)")
            initializeFromTodayState()
        }

        // Setup observers
        setupCoordinatorObservers()
        setupHealthKitObserver()
        setupNetworkObserver()

        Logger.info("✅ [TodayViewModel] Init complete")
    }

    private func initializeFromTodayState() {
        // Initialize activity lists from TodayViewState
        let state = todayState
        self.recentActivities = state.recentActivities
        self.unifiedActivities = state.recentActivities.map { UnifiedActivity(from: $0) }

        // Initialize loading state based on phase
        switch state.phase {
        case .notStarted:
            self.isInitializing = true
            self.isLoading = false
            self.isDataLoaded = false

        case .loadingCache:
            self.isInitializing = true
            self.isLoading = true
            self.isDataLoaded = false

        case .loadingFreshData:
            self.isInitializing = false
            self.isLoading = true
            self.isDataLoaded = true

        case .complete:
            self.isInitializing = false
            self.isLoading = false
            self.isDataLoaded = true

        case .error:
            self.isInitializing = false
            self.isLoading = false
        }

        Logger.info("🔍 [INIT] V2 Activities - recent: \(recentActivities.count), unified: \(unifiedActivities.count)")
    }
    
    // MARK: - Observer Setup

    private func setupCoordinatorObservers() {
        let useV2 = FeatureFlags.shared.useTodayViewV2
        Logger.info("🔄 [TodayViewModel] Setting up observers (V2: \(useV2))")

        if useV2 {
            setupV2Observers()
        } else {
            setupPhase3Observers()
        }
    }

    private func setupV2Observers() {
        Logger.info("🔄 [TodayViewModel] Setting up V2 observers (TodayViewState)")

        // Observe TodayViewState loading phase
        todayState.$phase
            .sink { [weak self] phase in
                guard let self = self else { return }

                switch phase {
                case .notStarted:
                    self.isInitializing = true
                    self.isLoading = false
                    self.isDataLoaded = false

                case .loadingCache:
                    self.isInitializing = true
                    self.isLoading = true
                    self.isDataLoaded = false

                case .loadingFreshData:
                    self.isInitializing = false
                    self.isLoading = true
                    self.isDataLoaded = true

                case .complete:
                    self.isInitializing = false
                    self.isLoading = false
                    self.isDataLoaded = true
                    self.animationTrigger = UUID()

                case .error(let error):
                    self.isInitializing = false
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    Logger.error("❌ [TodayViewModel] V2 error: \(error)")
                }

                Logger.debug("🔄 [TodayViewModel] V2 phase: \(phase) - isInitializing: \(self.isInitializing)")
            }
            .store(in: &cancellables)

        // Observe TodayViewState activities
        todayState.$recentActivities
            .sink { [weak self] activities in
                guard let self = self else { return }
                self.recentActivities = activities
                self.unifiedActivities = activities.map { UnifiedActivity(from: $0) }
                Logger.debug("📦 [TodayViewModel] V2 Activities updated: \(activities.count)")
            }
            .store(in: &cancellables)

        // Observe animation trigger from TodayViewState
        todayState.$animationTrigger
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.animationTrigger = UUID()
                Logger.debug("🎬 [TodayViewModel] V2 animation trigger updated")
            }
            .store(in: &cancellables)
    }

    private func setupPhase3Observers() {
        Logger.info("🔄 [TodayViewModel] Setting up Phase 3 observers (Coordinators)")

        // Observe TodayCoordinator state for loading indicators
        coordinator.$state
            .sink { [weak self] state in
                guard let self = self else { return }

                // Map coordinator state to legacy properties
                switch state {
                case .initial:
                    self.isInitializing = true
                    self.isLoading = false
                    self.isDataLoaded = false

                case .loading:
                    self.isInitializing = true
                    self.isLoading = true
                    self.isDataLoaded = false

                case .ready:
                    self.isInitializing = false
                    self.isLoading = false
                    self.isDataLoaded = true
                    self.animationTrigger = UUID()

                case .refreshing:
                    self.isInitializing = false
                    self.isLoading = true
                    self.isDataLoaded = true

                case .background:
                    self.isLoading = false

                case .error(let message):
                    self.isInitializing = false
                    self.isLoading = false
                    self.errorMessage = message
                    Logger.error("❌ [TodayViewModel] Coordinator error: \(message)")
                }

                Logger.debug("🔄 [TodayViewModel] Coordinator state: \(state.description) - isInitializing: \(self.isInitializing)")
            }
            .store(in: &cancellables)

        // Observe ActivitiesCoordinator for activity updates
        activitiesCoordinator.$activities
            .sink { [weak self] activities in
                guard let self = self else { return }
                self.unifiedActivities = activities
                Logger.debug("📦 [TodayViewModel] Activities updated: \(activities.count)")
            }
            .store(in: &cancellables)
    }
    
    private func setupHealthKitObserver() {
        services.healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.isHealthKitAuthorized = isAuthorized
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkObserver() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                Task { @MainActor [weak self] in
                    if !isConnected {
                        self?.loadingStateManager.forceState(.offline)
                    } else if self?.isInitializing == false {
                        self?.loadingStateManager.forceState(.complete)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API (Simplified - delegates to coordinators)
    
    /// Load initial UI (called from TodayView.onAppear)
    func loadInitialUI() async {
        guard !hasLoadedInitialUI else {
            Logger.info("⏭️ [TodayViewModel] Initial UI already loaded - skipping")
            return
        }
        hasLoadedInitialUI = true
        
        Logger.info("🔄 [TodayViewModel] loadInitialUI() - delegating to coordinator")
        await coordinator.handle(.viewAppeared)
    }
    
    /// Refresh data (pull-to-refresh)
    func refreshData(forceRecoveryRecalculation: Bool = false) async {
        Logger.info("🔄 [TodayViewModel] refreshData(force: \(forceRecoveryRecalculation))")
        
        if forceRecoveryRecalculation {
            await coordinator.forceRefreshScores()
        } else {
            await coordinator.handle(.pullToRefresh)
        }
        
        animationTrigger = UUID()
    }
    
    /// Handle app foreground (called from TodayView)
    func handleAppForeground() async {
        Logger.info("🔄 [TodayViewModel] handleAppForeground() - delegating to coordinator")
        await coordinator.handle(.appForegrounded)
    }
    
    /// Handle view disappeared
    func handleViewDisappeared() async {
        Logger.info("🔄 [TodayViewModel] handleViewDisappeared() - delegating to coordinator")
        await coordinator.handle(.viewDisappeared)
    }
    
    /// Handle HealthKit authorization change
    func handleHealthKitAuth() async {
        Logger.info("🔄 [TodayViewModel] handleHealthKitAuth() - delegating to coordinator")
        await coordinator.handle(.healthKitAuthorized)
    }
    
    /// Handle Intervals auth change
    func handleIntervalsAuthChange() async {
        Logger.info("🔄 [TodayViewModel] handleIntervalsAuthChange() - delegating to coordinator")
        await coordinator.handle(.intervalsAuthChanged)
    }
    
    // MARK: - Debug & Utility Methods
    
    /// Clear baseline cache (force fresh calculation)
    func clearBaselineCache() {
        Task { await recoveryScoreService.clearBaselineCache() }
        Logger.debug("🗑️ [TodayViewModel] Cleared baseline cache")
    }
    
    /// Force refresh HealthKit workouts
    func forceRefreshHealthKitWorkouts() async {
        Logger.debug("🔄 [TodayViewModel] Force refreshing HealthKit workouts...")
        await refreshData()
    }
    
    /// Force refresh recovery score (bypassing daily limits)
    func forceRefreshData() async {
        Logger.info("🔄 [TodayViewModel] forceRefreshData() - forcing score recalculation")
        await refreshData(forceRecoveryRecalculation: true)
    }
    
    /// Load initial data fast (legacy, now delegates to coordinator)
    func loadInitialDataFast() {
        Logger.info("🔄 [TodayViewModel] loadInitialDataFast() - no-op (coordinator handles this)")
        // No-op - coordinator handles initial loading via viewAppeared event
    }
    
    /// Retry loading after error
    func retryLoading() {
        Logger.info("🔄 [TodayViewModel] retryLoading() - delegating to coordinator")
        Task {
            await coordinator.forceRefresh()
        }
    }
    
    /// Cancel background tasks (legacy compatibility)
    func cancelBackgroundTasks() {
        Logger.debug("🛑 [TodayViewModel] cancelBackgroundTasks() - delegating to coordinator")
        Task {
            await coordinator.handle(.viewDisappeared)
        }
    }
}

// MARK: - Computed Properties (Presentation Layer)

extension TodayViewModel {
    /// Whether Today view is in loading state
    var isTodayLoading: Bool {
        coordinator.state == .loading || coordinator.state == .refreshing
    }
    
    /// Whether we're in the initial loading state
    var isTodayInitializing: Bool {
        coordinator.state == .initial || coordinator.state == .loading
    }
    
    /// Current coordinator state for debugging
    var coordinatorState: TodayCoordinator.State {
        coordinator.state
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension TodayViewModel {
    /// Log current state for debugging
    func logCurrentState() {
        Logger.debug("📊 [TodayViewModel] Current State:")
        Logger.debug("  isInitializing: \(isInitializing)")
        Logger.debug("  isLoading: \(isLoading)")
        Logger.debug("  isDataLoaded: \(isDataLoaded)")
        Logger.debug("  activities: \(unifiedActivities.count)")
        Logger.debug("  coordinator state: \(coordinator.state.description)")
        coordinator.logCurrentState()
    }
}
#endif
