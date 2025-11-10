import Foundation
import HealthKit
import UIKit

/// Lightweight coordinator for HealthKit operations
/// Uses HealthKitAuthorizationCoordinator for centralized, Apple-recommended authorization
/// Delegates to: HealthKitDataFetcher, HealthKitTransformer for data operations
class HealthKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = HealthKitManager()
    
    // MARK: - Components
    private let healthStore = HKHealthStore()
    
    // Centralized authorization coordinator (Apple's recommendations implemented)
    let authorizationCoordinator: HealthKitAuthorizationCoordinator
    
    let dataFetcher: HealthKitDataFetcher
    let transformer: HealthKitTransformer
    
    // MARK: - Published Properties (delegated from authorizationCoordinator)
    @Published var isAuthorized: Bool = false
    @Published var authorizationState: AuthorizationState = .notDetermined
    @Published var isRequesting: Bool = false
    
    // MARK: - Initialization
    private init() {
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
        self.transformer = HealthKitTransformer(healthStore: healthStore)
        
        // Initialize centralized coordinator
        let coordinator = HealthKitAuthorizationCoordinator(healthStore: healthStore)
        self.authorizationCoordinator = coordinator
        
        Logger.info("🔧 [HKMANAGER] Initialized with HealthKitAuthorizationCoordinator")
        
        // Sync published properties with coordinator
        Task { @MainActor in
            await self.syncWithCoordinator()
        }
    }
    
    // MARK: - Private Sync
    
    @MainActor
    private func syncWithCoordinator() async {
        // Observe coordinator state changes
        authorizationCoordinator.$isAuthorized
            .assign(to: &$isAuthorized)
        
        authorizationCoordinator.$authorizationState
            .assign(to: &$authorizationState)
        
        authorizationCoordinator.$isRequesting
            .assign(to: &$isRequesting)
        
        Logger.info("✅ [HKMANAGER] Synced with HealthKitAuthorizationCoordinator")
    }
    
    // MARK: - Authorization (NOW delegated to HealthKitAuthorizationCoordinator)
    
    /// Request HealthKit authorization - CENTRALIZED through coordinator
    func requestAuthorization() async {
        Logger.info("🔧 [HKMANAGER] requestAuthorization() - delegating to coordinator")
        await authorizationCoordinator.requestAuthorization()
        Logger.info("🔧 [HKMANAGER] requestAuthorization() complete - isAuthorized: \(isAuthorized)")
    }
    
    /// Check authorization after returning from Settings
    func checkAuthorizationAfterSettingsReturn() async {
        Logger.info("🔧 [HKMANAGER] checkAuthorizationAfterSettingsReturn() - delegating to coordinator")
        await authorizationCoordinator.checkAuthorizationAfterSettingsReturn()
    }
    
    /// Fast authorization check (for view appear)
    func checkAuthorizationStatusFast() async {
        await authorizationCoordinator.checkAuthorizationStatusFast()
    }
    
    /// Comprehensive authorization status check
    func checkAuthorizationStatus() async {
        await authorizationCoordinator.checkAuthorizationStatus()
    }
    
    /// Get detailed authorization info for debugging
    func getAuthorizationDetails() -> [String: String] {
        return authorizationCoordinator.getAuthorizationDetails()
    }
    
    /// Get authorization status for a specific type
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationCoordinator.getAuthorizationStatus(for: type)
    }
    
    /// Open iOS Settings app
    @MainActor
    func openSettings() {
        authorizationCoordinator.openSettings()
    }
    
    
    // MARK: - Data Fetching (delegated to HealthKitTransformer)
    
    func fetchDetailedSleepData() async -> HealthKitSleepData? {
        return await transformer.fetchDetailedSleepData()
    }
    
    func fetchLatestSleepData() async -> (sample: HKCategorySample?, duration: TimeInterval?) {
        return await transformer.fetchLatestSleepData()
    }
    
    func fetchHistoricalSleepData(days: Int = 7) async -> [(bedtime: Date?, wakeTime: Date?)] {
        return await transformer.fetchHistoricalSleepData(days: days)
    }
    
    func fetchLatestHRVData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestHRVData()
    }
    
    func fetchOvernightHRVData(bedtime: Date? = nil, wakeTime: Date? = nil) async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchOvernightHRVData(bedtime: bedtime, wakeTime: wakeTime)
    }
    
    func fetchLatestRHRData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestRHRData()
    }
    
    func fetchLatestRespiratoryRateData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestRespiratoryRateData()
    }
    
    func fetchDailySteps() async -> Int? {
        return await transformer.fetchDailySteps()
    }
    
    func fetchDailyActiveCalories() async -> Double? {
        return await transformer.fetchDailyActiveCalories()
    }
    
    func fetchLatestVO2MaxData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestVO2MaxData()
    }
    
    func fetchLatestOxygenSaturationData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestOxygenSaturationData()
    }
    
    func fetchLatestBodyTemperatureData() async -> (sample: HKQuantitySample?, value: Double?) {
        return await transformer.fetchLatestBodyTemperatureData()
    }
    
    func fetchTodayActivity() async -> (steps: Int, activeCalories: Double, exerciseMinutes: Double, walkingDistance: Double) {
        return await transformer.fetchTodayActivity()
    }
    
    func fetchTodayHourlySteps() async -> [Int] {
        return await transformer.fetchTodayHourlySteps()
    }
    
    // MARK: - Development Mode Data Capture (delegated to HealthKitDataFetcher)
    
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchStepsData(from: startDate, to: endDate)
    }
    
    func fetchActiveEnergyData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchActiveEnergyData(from: startDate, to: endDate)
    }
    
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchHRVData(from: startDate, to: endDate)
    }
    
    func fetchRestingHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchRestingHeartRateData(from: startDate, to: endDate)
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        return try await dataFetcher.fetchSleepData(from: startDate, to: endDate)
    }
    
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchHeartRateData(from: startDate, to: endDate)
    }
    
    func fetchVO2MaxData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchVO2MaxData(from: startDate, to: endDate)
    }
    
    func fetchOxygenSaturationData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchOxygenSaturationData(from: startDate, to: endDate)
    }
    
    func fetchBodyTemperatureData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await dataFetcher.fetchBodyTemperatureData(from: startDate, to: endDate)
    }
    
    // MARK: - Workouts (delegated to HealthKitTransformer)
    
    func fetchRecentWorkouts(limit: Int = 50, daysBack: Int = 30) async -> [HKWorkout] {
        return await transformer.fetchRecentWorkouts(limit: limit, daysBack: daysBack)
    }
    
    // MARK: - Batch Historical Data Fetching (delegated to HealthKitDataFetcher)
    
    func fetchHRVSamples(from startDate: Date, to endDate: Date) async -> [HKQuantitySample] {
        return await dataFetcher.fetchHRVSamples(from: startDate, to: endDate)
    }
    
    func fetchRHRSamples(from startDate: Date, to endDate: Date) async -> [HKQuantitySample] {
        return await dataFetcher.fetchRHRSamples(from: startDate, to: endDate)
    }
    
    func fetchSleepSessions(from startDate: Date, to endDate: Date) async -> [(bedtime: Date, wakeTime: Date)] {
        return await dataFetcher.fetchSleepSessions(from: startDate, to: endDate)
    }
}
