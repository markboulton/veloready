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
    lazy var cacheManager = CacheManager.shared
    
    // MARK: - Data Services
    
    lazy var intervalsCache = IntervalsCache.shared
    lazy var healthKitCache = HealthKitCache.shared
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
    
    // MARK: - Initialization
    
    private init() {
        setupLifecycleObservers()
    }
    
    /// Initialize all critical services on app launch
    /// Call this from app init for optimal performance
    func initialize() {
        guard !isInitialized else { return }
        
        print("📦 ServiceContainer: Initializing...")
        
        // Initialize core services that need early setup
        _ = healthKitManager
        _ = intervalsOAuthManager
        
        isInitialized = true
        print("✅ ServiceContainer: Initialized")
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
        print("📦 ServiceContainer: App entering background")
        // Services can save state if needed
    }
    
    private func handleAppForeground() {
        print("📦 ServiceContainer: App entering foreground")
        // Services can refresh if needed
    }
    
    // MARK: - Service Management
    
    /// Reset all services (useful for testing or logout)
    func reset() {
        print("📦 ServiceContainer: Resetting all services")
        
        // Clear caches
        intervalsCache.clearAllCache()
        healthKitCache.clearCache()
        
        // Note: Auth state should be cleared separately via auth managers
        
        isInitialized = false
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
