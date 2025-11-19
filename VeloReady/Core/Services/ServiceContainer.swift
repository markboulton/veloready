import Foundation
import Combine
import UIKit

/// Centralized service container for dependency injection
/// Provides singleton access to all app services
/// Improves testability and reduces boilerplate
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    // MARK: - Lifecycle
    
    private var cancellables = Set<AnyCancellable>()
    private(set) var isInitialized = false
    
    // MARK: - Core Services

    lazy var healthKitManager = HealthKitManager.shared
    lazy var cacheManager = DailyDataService.shared
    
    // MARK: - Data Services
    
    lazy var stravaDataService = StravaDataService.shared
    lazy var deduplicationService = ActivityDeduplicationService.shared
    
    // MARK: - Auth Services
    
    lazy var intervalsOAuthManager = IntervalsOAuthManager.shared
    lazy var stravaAuthService = StravaAuthService.shared
    
    // MARK: - API Clients
    
    lazy var intervalsAPIClient = IntervalsAPIClient(oauthManager: intervalsOAuthManager)
    lazy var stravaAPIClient = StravaAPIClient.shared
    
    // MARK: - Score Services
    
    lazy var recoveryScoreService = RecoveryScoreService.shared
    lazy var sleepScoreService = SleepScoreService.shared
    lazy var strainScoreService = StrainScoreService.shared
    lazy var wellnessDetectionService = WellnessDetectionService.shared
    
    // MARK: - Coordinators (NEW: Week 2-3)
    
    /// ScoresCoordinator - single source of truth for all score calculations
    /// Orchestrates recovery, sleep, and strain score services
    /// Part of: Today View Refactoring Plan - Week 2
    lazy var scoresCoordinator: ScoresCoordinator = {
        Logger.info("📦 [ServiceContainer] Creating ScoresCoordinator...")
        let coordinator = ScoresCoordinator(
            recoveryService: recoveryScoreService,
            sleepService: sleepScoreService,
            strainService: strainScoreService
        )
        Logger.info("📦 [ServiceContainer] ScoresCoordinator created successfully")
        return coordinator
    }()
    
    /// ActivitiesCoordinator - coordinates activity fetching from all sources
    /// Handles Intervals.icu, Strava, and Apple Health integration
    /// Part of: Today View Refactoring Plan - Week 3
    lazy var activitiesCoordinator: ActivitiesCoordinator = {
        Logger.info("📦 [ServiceContainer] Creating ActivitiesCoordinator...")
        let coordinator = ActivitiesCoordinator(services: self)
        Logger.info("📦 [ServiceContainer] ActivitiesCoordinator created successfully")
        return coordinator
    }()
    
    /// LoadingStateManager - manages loading state transitions for UI
    lazy var loadingStateManager: LoadingStateManager = {
        LoadingStateManager()
    }()
    
    // MARK: - ViewModels Registry
    
    private var viewModels: [String: Any] = [:]
    
    /// Register a ViewModel for reuse
    func register<T>(_ viewModel: T, for key: String) {
        viewModels[key] = viewModel
        Logger.debug("📝 ServiceContainer: Registered ViewModel '\(key)'")
    }
    
    /// Retrieve a registered ViewModel
    func retrieve<T>(_ type: T.Type, for key: String) -> T? {
        return viewModels[key] as? T
    }
    
    /// Remove a ViewModel from registry
    func unregister(for key: String) {
        viewModels.removeValue(forKey: key)
        Logger.debug("🗑️ ServiceContainer: Unregistered ViewModel '\(key)'")
    }
    
    /// Get all registered ViewModel keys
    var registeredViewModels: [String] {
        Array(viewModels.keys)
    }
    
    // MARK: - Initialization
    
    private init() {
        setupLifecycleObservers()
    }
    
    /// Initialize all critical services on app launch
    /// Call this from app init for optimal performance
    func initialize() {
        guard !isInitialized else { return }
        
        Logger.debug("📦 ServiceContainer: Initializing...")
        
        // Note: Legacy cache cleanup happens automatically via UnifiedCacheManager migration system
        
        // Initialize core services that need early setup
        _ = healthKitManager
        _ = intervalsOAuthManager
        
        isInitialized = true
        Logger.debug("✅ ServiceContainer: Initialized")
    }
    
    // MARK: - Lifecycle Management
    
    private func setupLifecycleObservers() {
        // Observe app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppBackground() {
        Logger.debug("📦 ServiceContainer: App entering background")
        
        // Flush caches to disk
        Task { @MainActor in
            await flushCaches()
        }
    }
    
    private func handleAppForeground() {
        Logger.debug("📦 ServiceContainer: App entering foreground")
        
        // Refresh stale data
        Task { @MainActor in
            await refreshStaleData()
        }
    }
    
    // MARK: - Cache Lifecycle
    
    /// Flush all caches to persistent storage
    private func flushCaches() async {
        Logger.debug("💾 ServiceContainer: Flushing caches to disk...")
        
        // Caches automatically persist via UserDefaults
        // This is a hook for future disk-based caching
        
        Logger.debug("✅ ServiceContainer: Caches flushed")
    }
    
    /// Refresh stale data when returning to foreground
    private func refreshStaleData() async {
        Logger.debug("🔄 ServiceContainer: Checking for stale data...")

        // Skip cache invalidation when offline to preserve synchronously-loaded cached scores
        guard NetworkMonitor.shared.isConnected else {
            Logger.debug("📡 ServiceContainer: Device offline - skipping cache invalidation to preserve cached data")
            return
        }

        // Invalidate sleep cache to catch late-arriving data from Apple Watch
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sleepCacheKey = "healthkit:sleep:\(startOfToday.timeIntervalSince1970)"
        await UnifiedCacheManager.shared.invalidate(key: sleepCacheKey)
        Logger.debug("🔄 Invalidated sleep cache - will re-fetch from HealthKit")

        // Individual services handle their own staleness checks
        // This is a hook for coordinated refresh logic

        Logger.debug("✅ ServiceContainer: Staleness check complete")
    }
    
    // MARK: - Service Management
    
    /// Reset all services (useful for testing or logout)
    func reset() {
        Logger.debug("📦 ServiceContainer: Resetting all services")
        
        // Clear all caches
        clearAllCaches()
        
        // Note: Auth state should be cleared separately via auth managers
        
        isInitialized = false
    }
    
    /// Clear all service caches
    func clearAllCaches() {
        Logger.debug("🗑️ ServiceContainer: Clearing all caches...")
        
        // IntervalsCache and HealthKitCache deleted - use CacheOrchestrator
        Task {
            await CacheOrchestrator.shared.invalidate(matching: ".*")
        }
        
        // Clear score service caches
        Task { await recoveryScoreService.clearBaselineCache() }
        
        Logger.debug("✅ ServiceContainer: All caches cleared")
    }
    
    /// Warm up critical services for optimal performance
    func warmUp() async {
        Logger.debug("🔥 ServiceContainer: Warming up services...")
        
        // Pre-load critical data
        if healthKitManager.isAuthorized {
            // HealthKitCache deleted - pre-load directly
            _ = await healthKitManager.fetchRecentWorkouts(daysBack: 90)
        }
        
        Logger.debug("✅ ServiceContainer: Services warmed up")
    }
    
    /// Check health of all services
    func healthCheck() -> ServiceHealth {
        ServiceHealth(
            healthKitAuthorized: healthKitManager.isAuthorized,
            intervalsConnected: intervalsOAuthManager.isAuthenticated,
            stravaConnected: stravaAuthService.connectionState.isConnected,
            cacheHealthy: true // Could add cache validation
        )
    }
}

// MARK: - Service Health

struct ServiceHealth {
    let healthKitAuthorized: Bool
    let intervalsConnected: Bool
    let stravaConnected: Bool
    let cacheHealthy: Bool
    
    var isHealthy: Bool {
        // At minimum, HealthKit should be authorized
        healthKitAuthorized && cacheHealthy
    }
    
    var connectedDataSources: Int {
        [healthKitAuthorized, intervalsConnected, stravaConnected].filter { $0 }.count
    }
}
