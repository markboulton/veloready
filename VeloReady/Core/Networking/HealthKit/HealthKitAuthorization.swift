import Foundation
import HealthKit
import UIKit

/// Handles all HealthKit authorization and permission management
class HealthKitAuthorization: ObservableObject {
    
    // MARK: - Published Properties
    @MainActor @Published var isAuthorized: Bool = {
        let cached = UserDefaults.standard.bool(forKey: "healthKitAuthorized")
        return cached
    }()
    
    @MainActor @Published var authorizationState: AuthorizationState = {
        if let rawValue = UserDefaults.standard.string(forKey: "healthKitAuthState"),
           let state = AuthorizationState(rawValue: rawValue) {
            return state
        }
        return .notDetermined
    }()
    
    // MARK: - Private Properties
    private let healthStore: HKHealthStore
    
    // MARK: - Health Data Types
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        
        // Sleep
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        
        // Heart metrics
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrvType)
        }
        if let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(rhrType)
        }
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(hrType)
        }
        if let respType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respType)
        }
        
        // Fitness metrics
        if let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) {
            types.insert(vo2MaxType)
        }
        
        // Blood oxygen
        if let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(spo2Type)
        }
        
        // Body temperature
        if let tempType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(tempType)
        }
        
        // Activity
        if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepsType)
        }
        if let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(caloriesType)
        }
        if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseType)
        }
        if let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distanceType)
        }
        
        // Workouts and Routes
        types.insert(HKObjectType.workoutType())
        types.insert(HKSeriesType.workoutRoute())
        
        return types
    }()
    
    // MARK: - Initialization
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        
        Task { @MainActor in
            await checkAuthorizationStatusFast()
        }
    }
    
    // MARK: - Authorization Methods
    
    /// Request HealthKit authorization from the user
    func requestAuthorization() async {
        Logger.debug("==========================================")
        Logger.debug("🟠🟠🟠 AUTH requestAuthorization ENTRY")
        Logger.debug("==========================================")
        Logger.debug("🟠 [AUTH] requestAuthorization() called")
        Logger.debug("🟠 [AUTH] HKHealthStore.isHealthDataAvailable: \(HKHealthStore.isHealthDataAvailable())")
        print("🟠🟠🟠 [AUTH] PRINT: requestAuthorization() ENTRY")
        print("🟠 [AUTH] PRINT: HKHealthStore available: \(HKHealthStore.isHealthDataAvailable())")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🟠 [AUTH] ❌ HealthKit not available on this device")
            return
        }
        
        print("🟠 [AUTH] HealthKit is available, proceeding with request")
        print("🟠 [AUTH] readTypes count: \(readTypes.count)")
        
        do {
            print("🟠 [AUTH] 🔐 Requesting HealthKit authorization...")
            print("🟠 [AUTH] 📋 Requesting permissions for: \(readTypes.map { $0.identifier })")
            print("🟠 [AUTH] About to call healthStore.requestAuthorization()")
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            print("🟠 [AUTH] ✅ Authorization sheet completed (or bypassed by iOS)")
            print("🟠 [AUTH] Waiting 2 seconds for iOS to update authorization status...")
            
            // Check status after authorization with delay (iOS needs time to update)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            print("🟠 [AUTH] Now checking authorization status...")
            
            // iOS 26 BUG WORKAROUND: authorizationStatus() returns wrong value
            // Test actual data access instead
            print("🟠 [AUTH] Testing actual data access (iOS 26 workaround)...")
            let canAccessData = await testDataAccess()
            print("🟠 [AUTH] Data access test result: \(canAccessData)")
            
            if canAccessData {
                print("🟠 [AUTH] ✅ Can access data! Overriding iOS authorizationStatus() bug")
                await MainActor.run {
                    self.isAuthorized = true
                    self.authorizationState = .authorized
                    UserDefaults.standard.set(true, forKey: "healthKitAuthorized")
                    UserDefaults.standard.set(AuthorizationState.authorized.rawValue, forKey: "healthKitAuthState")
                }
            } else {
                await MainActor.run {
                    checkAuthorizationStatus()
                }
            }
            print("🟠 [AUTH] Authorization status check completed")
            
        } catch {
            Logger.error("HealthKit authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh authorization status
    func refreshAuthorizationStatus() async {
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    /// Request workout permissions
    func requestWorkoutPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit not available on this device")
            return
        }
        
        do {
            Logger.debug("🔐 Requesting Workout permissions...")
            let workoutType = HKObjectType.workoutType()
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
            Logger.debug("✅ Workout authorization sheet completed")
            
            let status = healthStore.authorizationStatus(for: workoutType)
            Logger.data("Workout permission status: \(status.rawValue)")
            
        } catch {
            Logger.error("Workout authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Request workout route permissions
    func requestWorkoutRoutePermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit not available on this device")
            return
        }
        
        do {
            Logger.debug("🔐 Requesting Workout + Route permissions...")
            let workoutType = HKObjectType.workoutType()
            let routeType = HKSeriesType.workoutRoute()
            
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType, routeType])
            Logger.debug("✅ Workout + Route authorization sheet completed")
            
            let workoutStatus = healthStore.authorizationStatus(for: workoutType)
            let routeStatus = healthStore.authorizationStatus(for: routeType)
            Logger.data("Workout permission status: \(workoutStatus.rawValue)")
            Logger.data("Route permission status: \(routeStatus.rawValue)")
            
        } catch {
            Logger.error("Workout Route authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Check authorization after returning from Settings (or on view appear)
    func checkAuthorizationAfterSettingsReturn() async {
        print("🟠 [AUTH] checkAuthorizationAfterSettingsReturn() called")
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // iOS 26 WORKAROUND: Test actual data access instead of trusting authorizationStatus()
        print("🟠 [AUTH] Testing actual data access...")
        let canAccessData = await testDataAccess()
        print("🟠 [AUTH] Data access test result: \(canAccessData)")
        
        if canAccessData {
            print("🟠 [AUTH] ✅ Can access data! Marking as authorized")
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationState = .authorized
                UserDefaults.standard.set(true, forKey: "healthKitAuthorized")
                UserDefaults.standard.set(AuthorizationState.authorized.rawValue, forKey: "healthKitAuthState")
            }
        } else {
            print("🟠 [AUTH] ❌ Cannot access data, checking authorizationStatus...")
            await MainActor.run {
                checkAuthorizationStatus()
            }
        }
    }
    
    /// Get detailed authorization info for debugging
    func getAuthorizationDetails() -> [String: String] {
        var details: [String: String] = [:]
        
        for type in readTypes {
            let typeName = type.identifier
            let status = healthStore.authorizationStatus(for: type)
            
            switch status {
            case .sharingAuthorized:
                details[typeName] = "Authorized"
            case .sharingDenied:
                details[typeName] = "Denied"
            case .notDetermined:
                details[typeName] = "Not Determined"
            @unknown default:
                details[typeName] = "Unknown"
            }
        }
        
        return details
    }
    
    /// Get authorization status for a specific type
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        let status = healthStore.authorizationStatus(for: type)
        
        // Return actual status - no workarounds!
        // .sharingDenied (rawValue 1) means user denied permissions
        // .sharingAuthorized (rawValue 2) means user granted permissions
        return status
    }
    
    /// Open iOS Settings app
    @MainActor
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    /// Fast authorization check - non-blocking
    func checkAuthorizationStatusFast() async {
        Logger.debug("⚡ Fast HealthKit authorization check")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            await updateAuthState(.notAvailable, false)
            return
        }
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        
        // Use actual status - no workarounds!
        await updateAuthState(
            AuthorizationState.fromHKStatus(hrvStatus),
            hrvStatus == .sharingAuthorized
        )
        
        Logger.debug("⚡ Fast HealthKit check completed: \(await authorizationState) (rawValue: \(hrvStatus.rawValue))")
    }
    
    /// Check current authorization status
    @MainActor
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .notAvailable
            isAuthorized = false
            return
        }
        
        Task {
            await checkAuthorizationStatusAsync()
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationStatusAsync() async {
        print("🟠 [AUTH] checkAuthorizationStatusAsync() starting...")
        var authorizedCount = 0
        var deniedCount = 0
        var notDeterminedCount = 0
        var statusDetails: [String] = []
        
        for type in readTypes {
            let status = healthStore.authorizationStatus(for: type)
            let statusStr: String
            
            // Use actual status - no special handling for rawValue 1
            switch status {
            case .notDetermined:
                notDeterminedCount += 1
                statusStr = "notDetermined"
            case .sharingDenied:
                deniedCount += 1
                statusStr = "DENIED"
            case .sharingAuthorized:
                authorizedCount += 1
                statusStr = "authorized"
            @unknown default:
                notDeterminedCount += 1
                statusStr = "unknown"
            }
            
            statusDetails.append("\(type.identifier): \(statusStr) (raw:\(status.rawValue))")
        }
        
        print("🟠 [AUTH] Authorization status for all \(readTypes.count) types:")
        for detail in statusDetails {
            print("🟠 [AUTH]   \(detail)")
        }
        print("🟠 [AUTH] Summary: authorized=\(authorizedCount), denied=\(deniedCount), notDetermined=\(notDeterminedCount)")
        
        await updateAuthorizationState(
            authorizedCount: authorizedCount,
            deniedCount: deniedCount,
            notDeterminedCount: notDeterminedCount
        )
    }
    
    @MainActor
    private func updateAuthorizationState(authorizedCount: Int, deniedCount: Int, notDeterminedCount: Int) {
        let criticalTypes = [
            "HKQuantityTypeIdentifierHeartRate",
            "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
            "HKCategoryTypeIdentifierSleepAnalysis",
            "HKQuantityTypeIdentifierStepCount",
            "HKQuantityTypeIdentifierActiveEnergyBurned"
        ]
        
        _ = readTypes.filter { criticalTypes.contains($0.identifier) }.count
        
        // FIXED: Check if we have ANY authorized permissions first
        if authorizedCount == readTypes.count {
            authorizationState = .authorized
            isAuthorized = true
            Logger.debug("✅ HealthKit fully authorized")
        } else if authorizedCount > 0 {
            // If we have SOME permissions, treat as partially authorized (usable!)
            authorizationState = .partial
            isAuthorized = true
            Logger.debug("✅ HealthKit partially authorized (\(authorizedCount)/\(readTypes.count), \(deniedCount) denied)")
        } else if deniedCount > 0 {
            // Only mark as denied if we have NO authorized permissions
            authorizationState = .denied
            isAuthorized = false
            Logger.warning("️ HealthKit denied - no permissions granted (\(deniedCount) denied, \(authorizedCount) authorized)")
        } else {
            authorizationState = .notDetermined
            isAuthorized = false
            Logger.warning("️ HealthKit authorization not determined")
        }
        
        UserDefaults.standard.set(isAuthorized, forKey: "healthKitAuthorized")
        UserDefaults.standard.set(authorizationState.rawValue, forKey: "healthKitAuthState")
    }
    
    private func canAccessHealthData(for type: HKObjectType) async -> Bool {
        guard let sampleType = type as? HKSampleType else {
            let status = healthStore.authorizationStatus(for: type)
            return status == .sharingAuthorized
        }
        
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if error == nil {
                    let criticalTypes = [
                        "HKQuantityTypeIdentifierHeartRate",
                        "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
                        "HKCategoryTypeIdentifierSleepAnalysis",
                        "HKQuantityTypeIdentifierStepCount",
                        "HKQuantityTypeIdentifierActiveEnergyBurned"
                    ]
                    
                    let hasData = (samples?.count ?? 0) > 0
                    
                    if criticalTypes.contains(type.identifier) && !hasData {
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                } else {
                    let errorDescription = error?.localizedDescription.lowercased() ?? ""
                    if errorDescription.contains("not authorized") || errorDescription.contains("denied") {
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// iOS 26 Workaround: Test actual data access
    private func testDataAccess() async -> Bool {
        print("🟠 [AUTH] testDataAccess: Attempting to fetch steps data...")
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("🟠 [AUTH] testDataAccess: Could not create steps type")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKSampleQuery(
                sampleType: stepsType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    let errorMsg = error.localizedDescription.lowercased()
                    print("🟠 [AUTH] testDataAccess: Query error: \(error.localizedDescription)")
                    if errorMsg.contains("not authorized") || errorMsg.contains("denied") {
                        print("🟠 [AUTH] testDataAccess: DENIED - no permission")
                        continuation.resume(returning: false)
                    } else {
                        print("🟠 [AUTH] testDataAccess: Non-permission error, assuming no data")
                        continuation.resume(returning: true)
                    }
                } else {
                    print("🟠 [AUTH] testDataAccess: SUCCESS - can access HealthKit!")
                    print("🟠 [AUTH] testDataAccess: Sample count: \(samples?.count ?? 0)")
                    continuation.resume(returning: true)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    @MainActor
    private func updateAuthState(_ state: AuthorizationState, _ authorized: Bool) {
        authorizationState = state
        isAuthorized = authorized
        UserDefaults.standard.set(isAuthorized, forKey: "healthKitAuthorized")
        UserDefaults.standard.set(authorizationState.rawValue, forKey: "healthKitAuthState")
    }
}

// MARK: - Authorization State

enum AuthorizationState: String {
    case notDetermined
    case authorized
    case denied
    case partial
    case notAvailable
    
    var description: String {
        switch self {
        case .notDetermined: return "Not Requested"
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .partial: return "Partially Authorized"
        case .notAvailable: return "Not Available"
        }
    }
    
    static func fromHKStatus(_ status: HKAuthorizationStatus) -> AuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingDenied:
            return .denied
        case .sharingAuthorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
}
