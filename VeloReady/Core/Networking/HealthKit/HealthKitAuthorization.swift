import Foundation
import HealthKit
import UIKit

/// Handles all HealthKit authorization and permission management
class HealthKitAuthorization: ObservableObject {
    
    // MARK: - Published Properties
    // CRITICAL: No initial caching - always query HealthKit directly
    // This prevents drift between cached state and actual iOS Health permissions
    @MainActor @Published var isAuthorized: Bool = false
    
    @MainActor @Published var authorizationState: AuthorizationState = .notDetermined
    
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
    /// CRITICAL: This shows the iOS authorization sheet to the user
    func requestAuthorization() async {
        Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.info("🚀 [AUTH] requestAuthorization() ENTRY")
        Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.info("🔍 [AUTH] HKHealthStore.isHealthDataAvailable: \(HKHealthStore.isHealthDataAvailable())")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("❌ [AUTH] HealthKit not available on this device")
            await updateAuthState(.notAvailable, false)
            return
        }
        
        Logger.info("✅ [AUTH] HealthKit is available")
        Logger.info("📋 [AUTH] Requesting permissions for \(readTypes.count) data types")
        Logger.info("📋 [AUTH] Types: \(readTypes.map { $0.identifier }.prefix(5).joined(separator: ", "))...")
        
        do {
            Logger.info("🔐 [AUTH] Calling healthStore.requestAuthorization()...")
            Logger.info("⏳ [AUTH] iOS will now show authorization sheet to user...")
            
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            
            Logger.info("✅ [AUTH] Authorization sheet completed (user made selection)")
            Logger.info("⏳ [AUTH] Waiting 2 seconds for iOS to process authorization...")
            
            // iOS needs time to process authorization
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            Logger.info("🔍 [AUTH] Testing actual data access (iOS 26 workaround)...")
            let canAccessData = await testDataAccess()
            Logger.info("🔍 [AUTH] Data access test result: \(canAccessData)")
            
            if canAccessData {
                Logger.info("✅ [AUTH] SUCCESS! User granted HealthKit permissions")
                await updateAuthState(.authorized, true)
            } else {
                Logger.info("❌ [AUTH] Data access denied - checking authorization status...")
                await MainActor.run {
                    checkAuthorizationStatus()
                }
            }
            
            Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Logger.info("🏁 [AUTH] requestAuthorization() EXIT - isAuthorized: \(await isAuthorized)")
            Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
        } catch {
            Logger.error("❌ [AUTH] HealthKit authorization error: \(error.localizedDescription)")
            await updateAuthState(.denied, false)
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
    /// CRITICAL: This now PROACTIVELY requests authorization if not determined
    func checkAuthorizationAfterSettingsReturn() async {
        Logger.info("🔍 [AUTH] checkAuthorizationAfterSettingsReturn() called")
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("❌ [AUTH] HealthKit not available on device")
            await updateAuthState(.notAvailable, false)
            return
        }
        
        // Step 1: Check actual data access
        Logger.info("🔍 [AUTH] Testing actual data access...")
        let canAccessData = await testDataAccess()
        Logger.info("🔍 [AUTH] Data access test result: \(canAccessData)")
        
        if canAccessData {
            Logger.info("✅ [AUTH] Can access data! User has granted permissions.")
            await updateAuthState(.authorized, true)
        } else {
            // Step 2: Cannot access data - check if it's "not determined" vs "denied"
            Logger.info("❌ [AUTH] Cannot access data - checking authorization status...")
            
            // Check the actual authorization status
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            let status = healthStore.authorizationStatus(for: hrvType)
            Logger.info("🔍 [AUTH] HRV authorization status: \(status.rawValue) (\(AuthorizationState.fromHKStatus(status).description))")
            
            if status == .notDetermined {
                // CRITICAL FIX: Authorization has NEVER been requested - request it now!
                Logger.info("🚀 [AUTH] Authorization not determined - REQUESTING NOW")
                await requestAuthorization()
            } else if status == .sharingDenied {
                Logger.info("❌ [AUTH] Authorization explicitly denied by user")
                await updateAuthState(.denied, false)
            } else {
                // Fallback: check all types
                Logger.info("⚠️ [AUTH] Status unclear - performing full check...")
                await MainActor.run {
                    checkAuthorizationStatus()
                }
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
        Logger.info("🔍 [AUTH] checkAuthorizationStatusAsync() starting...")
        Logger.info("📊 [AUTH] Checking authorization for \(readTypes.count) data types...")
        
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
        
        Logger.info("📊 [AUTH] Authorization status for all \(readTypes.count) types:")
        for detail in statusDetails {
            Logger.debug("   \(detail)")
        }
        Logger.info("📊 [AUTH] Summary: ✅ \(authorizedCount) authorized, ❌ \(deniedCount) denied, ⏳ \(notDeterminedCount) pending")
        
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
        
        let oldState = authorizationState
        let oldAuthorized = isAuthorized
        
        // FIXED: Check if we have ANY authorized permissions first
        if authorizedCount == readTypes.count {
            authorizationState = .authorized
            isAuthorized = true
            Logger.info("✅ [AUTH] HealthKit fully authorized (\(authorizedCount)/\(readTypes.count))")
        } else if authorizedCount > 0 {
            // If we have SOME permissions, treat as partially authorized (usable!)
            authorizationState = .partial
            isAuthorized = true
            Logger.info("✅ [AUTH] HealthKit partially authorized (\(authorizedCount)/\(readTypes.count), \(deniedCount) denied)")
        } else if deniedCount > 0 {
            // Only mark as denied if we have NO authorized permissions
            authorizationState = .denied
            isAuthorized = false
            Logger.warning("❌ [AUTH] HealthKit denied - no permissions granted (\(deniedCount) denied)")
        } else {
            authorizationState = .notDetermined
            isAuthorized = false
            Logger.warning("⚠️ [AUTH] HealthKit authorization not determined (\(notDeterminedCount) pending)")
        }
        
        // Log state transitions
        if oldState != authorizationState || oldAuthorized != isAuthorized {
            Logger.info("🔄 [AUTH] State transition: \(oldState.description) → \(authorizationState.description)")
        }
        
        // REMOVED: UserDefaults caching to prevent drift from actual iOS Health permissions
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
    /// CRITICAL: This is the definitive way to check authorization on iOS 26+
    private func testDataAccess() async -> Bool {
        Logger.info("🔍 [AUTH] testDataAccess: Attempting to fetch steps data...")
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            Logger.info("❌ [AUTH] testDataAccess: Could not create steps type")
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
                    Logger.info("❌ [AUTH] testDataAccess: Query error: \(error.localizedDescription)")
                    
                    // CRITICAL FIX: "Authorization not determined" is a PERMISSION ERROR!
                    // It means the user has NEVER been asked for permission.
                    // OLD BUG: This was incorrectly treated as "no data available"
                    if errorMsg.contains("authorization not determined") ||
                       errorMsg.contains("not determined") ||
                       errorMsg.contains("not authorized") || 
                       errorMsg.contains("denied") {
                        Logger.info("❌ [AUTH] testDataAccess: PERMISSION ERROR - authorization required")
                        continuation.resume(returning: false)
                    } else {
                        // Other errors (network, data unavailable, etc) - assume no data but authorized
                        Logger.info("⚠️ [AUTH] testDataAccess: Non-permission error (network/data issue)")
                        continuation.resume(returning: true)
                    }
                } else {
                    Logger.info("✅ [AUTH] testDataAccess: SUCCESS - can access HealthKit!")
                    Logger.info("✅ [AUTH] testDataAccess: Sample count: \(samples?.count ?? 0)")
                    continuation.resume(returning: true)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    @MainActor
    private func updateAuthState(_ state: AuthorizationState, _ authorized: Bool) {
        let oldState = authorizationState
        let oldAuthorized = isAuthorized
        
        authorizationState = state
        isAuthorized = authorized
        
        // Log state transitions for debugging
        if oldState != state || oldAuthorized != authorized {
            Logger.info("🔄 [AUTH] State transition: \(oldState.description) → \(state.description), isAuthorized: \(oldAuthorized) → \(authorized)")
        }
        
        // REMOVED: UserDefaults caching to prevent drift from actual iOS Health permissions
        // The app now always queries HealthKit directly for authoritative state
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
