import Foundation

/// Centralized service container for dependency injection
/// Provides singleton access to all app services
/// Improves testability and reduces boilerplate
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
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
    
    private init() {}
    
    /// Reset all services (useful for testing or logout)
    func reset() {
        // Clear caches
        intervalsCache.clearAllCache()
        healthKitCache.clearCache()
        
        // Note: Auth state should be cleared separately via auth managers
    }
}
