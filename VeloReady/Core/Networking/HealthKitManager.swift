import Foundation
import HealthKit
import UIKit

/// Lightweight coordinator for HealthKit operations
/// Delegates to specialized components: HealthKitAuthorization, HealthKitDataFetcher, HealthKitTransformer
class HealthKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = HealthKitManager()
    
    // MARK: - Components
    private let healthStore = HKHealthStore()
    let authorization: HealthKitAuthorization
    let dataFetcher: HealthKitDataFetcher
    let transformer: HealthKitTransformer
    
    // MARK: - Published Properties (delegated from authorization)
    @Published var isAuthorized: Bool = false
    @Published var authorizationState: AuthorizationState = .notDetermined
    
    // MARK: - Initialization
    private init() {
        self.authorization = HealthKitAuthorization(healthStore: healthStore)
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
        self.transformer = HealthKitTransformer(healthStore: healthStore)
        
        // Sync published properties with authorization component
        Task { @MainActor in
            self.isAuthorized = await authorization.isAuthorized
            self.authorizationState = await authorization.authorizationState
        }
    }
    
    // MARK: - Authorization (delegated to HealthKitAuthorization)
    
    func requestAuthorization() async {
        await authorization.requestAuthorization()
        await syncAuth()
    }
    
    func refreshAuthorizationStatus() async {
        await authorization.refreshAuthorizationStatus()
        await syncAuth()
    }
    
    func requestWorkoutPermissions() async {
        await authorization.requestWorkoutPermissions()
        await syncAuth()
    }
    
    func requestWorkoutRoutePermissions() async {
        await authorization.requestWorkoutRoutePermissions()
        await syncAuth()
    }
    
    func checkAuthorizationAfterSettingsReturn() async {
        await authorization.checkAuthorizationAfterSettingsReturn()
        await syncAuth()
    }
    
    func getAuthorizationDetails() -> [String: String] {
        return authorization.getAuthorizationDetails()
    }
    
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authorization.getAuthorizationStatus(for: type)
    }
    
    @MainActor
    func openSettings() {
        authorization.openSettings()
    }
    
    func checkAuthorizationStatusFast() async {
        await authorization.checkAuthorizationStatusFast()
        await syncAuth()
    }
    
    @MainActor
    func checkAuthorizationStatus() {
        authorization.checkAuthorizationStatus()
        Task {
            await syncAuth()
        }
    }
    
    @MainActor
    private func syncAuth() async {
        self.isAuthorized = await authorization.isAuthorized
        self.authorizationState = await authorization.authorizationState
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
