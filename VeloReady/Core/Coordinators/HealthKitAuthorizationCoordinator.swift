import Foundation
import HealthKit
import UIKit
import Combine

/// Centralized coordinator for HealthKit authorization
/// Implements Apple's recommendations:
/// - Centralized permission requests (not scattered across views)
/// - Duplicate request protection
/// - App lifecycle observation for Settings return
/// - Asynchronous authorization handling
@MainActor
class HealthKitAuthorizationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current authorization state (single source of truth)
    @Published private(set) var authorizationState: AuthorizationState = .notDetermined
    
    /// Whether the app is authorized to access HealthKit data
    @Published private(set) var isAuthorized: Bool = false
    
    /// Whether an authorization request is currently in progress
    @Published private(set) var isRequesting: Bool = false
    
    /// Whether the initial authorization check has completed (prevents UI flash)
    @Published private(set) var hasCompletedInitialCheck: Bool = false
    
    // MARK: - Private Properties
    
    private let healthStore: HKHealthStore
    private var cancellables = Set<AnyCancellable>()
    private var lastAuthorizationCheck: Date?
    
    // Minimum time between authorization checks (prevents excessive polling)
    private let minCheckInterval: TimeInterval = 1.0
    
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
    
    nonisolated init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        
        Logger.info("🎯 [AUTH COORDINATOR] Initialized")
        
        // Setup app lifecycle observers on MainActor
        Task { @MainActor in
            self.setupLifecycleObservers()
            
            // Initial authorization check (PASSIVE - does not request)
            // Only checks status, never triggers authorization sheet
            await self.checkAuthorizationStatusFast()
        }
    }
    
    // MARK: - Public Methods
    
    /// Request HealthKit authorization from the user
    /// CRITICAL: This is the SINGLE centralized method for requesting authorization
    /// - Prevents duplicate requests with isRequesting guard
    /// - Uses 2-second delay for iOS to process authorization
    /// - Tests actual data access to verify authorization
    func requestAuthorization() async {
        // PROTECTION: Prevent duplicate authorization requests
        guard !isRequesting else {
            Logger.info("⚠️ [AUTH COORDINATOR] Authorization request already in progress, skipping duplicate")
            return
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("❌ [AUTH COORDINATOR] HealthKit not available on this device")
            await updateState(.notAvailable, false)
            return
        }
        
        Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.info("🚀 [AUTH COORDINATOR] requestAuthorization() ENTRY")
        Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        isRequesting = true
        defer { isRequesting = false }
        
        do {
            Logger.info("📋 [AUTH COORDINATOR] Requesting permissions for \(readTypes.count) data types")
            Logger.info("🔐 [AUTH COORDINATOR] Calling healthStore.requestAuthorization()...")
            Logger.info("⏳ [AUTH COORDINATOR] iOS will now show authorization sheet to user...")
            
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            
            Logger.info("✅ [AUTH COORDINATOR] Authorization sheet completed (user made selection)")
            Logger.info("⏳ [AUTH COORDINATOR] Waiting 2 seconds for iOS to process authorization...")
            
            // Apple's Recommendation: Delayed check after authorization
            // iOS needs time to update authorization status internally
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            Logger.info("🔍 [AUTH COORDINATOR] Testing actual data access (iOS 26 workaround)...")
            let canAccessData = await testDataAccess()
            Logger.info("🔍 [AUTH COORDINATOR] Data access test result: \(canAccessData)")
            
            if canAccessData {
                Logger.info("✅ [AUTH COORDINATOR] SUCCESS! User granted HealthKit permissions")
                await updateState(.authorized, true)
            } else {
                Logger.info("❌ [AUTH COORDINATOR] Data access denied - checking authorization status...")
                await checkAuthorizationStatus()
            }
            
            Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Logger.info("🏁 [AUTH COORDINATOR] requestAuthorization() EXIT - isAuthorized: \(isAuthorized)")
            Logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
        } catch {
            Logger.error("❌ [AUTH COORDINATOR] HealthKit authorization error: \(error.localizedDescription)")
            await updateState(.denied, false)
        }
    }
    
    /// Check authorization status after returning from Settings
    /// PASSIVE: Only checks status, NEVER automatically requests authorization
    /// Authorization must be explicitly requested via requestAuthorization()
    func checkAuthorizationAfterSettingsReturn() async {
        Logger.info("🔍 [AUTH COORDINATOR] checkAuthorizationAfterSettingsReturn() called")
        
        // Throttle checks to prevent excessive polling
        if let lastCheck = lastAuthorizationCheck,
           Date().timeIntervalSince(lastCheck) < minCheckInterval {
            Logger.info("⚠️ [AUTH COORDINATOR] Throttling check (last check was \(Date().timeIntervalSince(lastCheck))s ago)")
            return
        }
        lastAuthorizationCheck = Date()
        
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s delay
        
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("❌ [AUTH COORDINATOR] HealthKit not available on device")
            await updateState(.notAvailable, false)
            return
        }
        
        // Step 1: Check actual data access
        Logger.info("🔍 [AUTH COORDINATOR] Testing actual data access...")
        let canAccessData = await testDataAccess()
        Logger.info("🔍 [AUTH COORDINATOR] Data access test result: \(canAccessData)")
        
        if canAccessData {
            Logger.info("✅ [AUTH COORDINATOR] Can access data! User has granted permissions.")
            await updateState(.authorized, true)
            hasCompletedInitialCheck = true // Mark initial check complete
        } else {
            // Step 2: Cannot access data - check if it's "not determined" vs "denied"
            Logger.info("❌ [AUTH COORDINATOR] Cannot access data - checking authorization status...")
            
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            let status = healthStore.authorizationStatus(for: hrvType)
            Logger.info("🔍 [AUTH COORDINATOR] HRV authorization status: \(status.rawValue) (\(AuthorizationState.fromHKStatus(status).description))")
            
            hasCompletedInitialCheck = true // Mark initial check complete (even if denied)
            
            if status == .notDetermined {
                // CHANGED: Do NOT automatically request authorization
                // User must explicitly tap "Grant Access" button
                Logger.info("⏸️ [AUTH COORDINATOR] Authorization not determined - waiting for user action")
                await updateState(.notDetermined, false)
            } else if status == .sharingDenied {
                Logger.info("❌ [AUTH COORDINATOR] Authorization explicitly denied by user")
                await updateState(.denied, false)
            } else {
                // Fallback: check all types
                Logger.info("⚠️ [AUTH COORDINATOR] Status unclear - performing full check...")
                await checkAuthorizationStatus()
            }
        }
    }
    
    /// Fast authorization check - non-blocking
    /// Use this for initial checks (e.g., view appear)
    func checkAuthorizationStatusFast() async {
        Logger.info("⚡ [AUTH COORDINATOR] Fast authorization check")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            await updateState(.notAvailable, false)
            return
        }
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        
        await updateState(
            AuthorizationState.fromHKStatus(hrvStatus),
            hrvStatus == .sharingAuthorized
        )
        
        Logger.info("⚡ [AUTH COORDINATOR] Fast check completed: \(authorizationState) (rawValue: \(hrvStatus.rawValue))")
    }
    
    /// Check current authorization status (comprehensive check of all types)
    func checkAuthorizationStatus() async {
        Logger.info("🔍 [AUTH COORDINATOR] Comprehensive authorization check starting...")
        Logger.info("📊 [AUTH COORDINATOR] Checking authorization for \(readTypes.count) data types...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            await updateState(.notAvailable, false)
            return
        }
        
        var authorizedCount = 0
        var deniedCount = 0
        var notDeterminedCount = 0
        
        for type in readTypes {
            let status = healthStore.authorizationStatus(for: type)
            
            switch status {
            case .notDetermined:
                notDeterminedCount += 1
            case .sharingDenied:
                deniedCount += 1
            case .sharingAuthorized:
                authorizedCount += 1
            @unknown default:
                notDeterminedCount += 1
            }
        }
        
        Logger.info("📊 [AUTH COORDINATOR] Summary: ✅ \(authorizedCount) authorized, ❌ \(deniedCount) denied, ⏳ \(notDeterminedCount) pending")
        
        // Update state based on counts
        if authorizedCount == readTypes.count {
            await updateState(.authorized, true)
            Logger.info("✅ [AUTH COORDINATOR] HealthKit fully authorized (\(authorizedCount)/\(readTypes.count))")
        } else if authorizedCount > 0 {
            await updateState(.partial, true)
            Logger.info("✅ [AUTH COORDINATOR] HealthKit partially authorized (\(authorizedCount)/\(readTypes.count), \(deniedCount) denied)")
        } else if deniedCount > 0 {
            await updateState(.denied, false)
            Logger.warning("❌ [AUTH COORDINATOR] HealthKit denied - no permissions granted (\(deniedCount) denied)")
        } else {
            await updateState(.notDetermined, false)
            Logger.warning("⚠️ [AUTH COORDINATOR] HealthKit authorization not determined (\(notDeterminedCount) pending)")
        }
    }
    
    /// Open iOS Settings app
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        Logger.info("⚙️ [AUTH COORDINATOR] Opening Settings app")
    }
    
    /// Get authorization status for a specific type
    nonisolated func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    /// Get detailed authorization info for debugging
    nonisolated func getAuthorizationDetails() -> [String: String] {
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
    
    // MARK: - Private Methods
    
    /// Setup app lifecycle observers
    /// Apple's Recommendation: Observe app lifecycle to detect Settings return
    private func setupLifecycleObservers() {
        Logger.info("👁️ [AUTH COORDINATOR] Setting up app lifecycle observers")
        
        // Observe app becoming active (user returns from Settings)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Logger.info("👁️ [AUTH COORDINATOR] App became active - checking authorization status")
                Task { @MainActor [weak self] in
                    await self?.checkAuthorizationAfterSettingsReturn()
                }
            }
            .store(in: &cancellables)
        
        // Observe scene phase changes
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .sink { [weak self] _ in
                Logger.info("👁️ [AUTH COORDINATOR] Scene activated - checking authorization status")
                Task { @MainActor [weak self] in
                    await self?.checkAuthorizationAfterSettingsReturn()
                }
            }
            .store(in: &cancellables)
        
        Logger.info("✅ [AUTH COORDINATOR] Lifecycle observers setup complete")
    }
    
    /// Test actual data access (iOS 26 workaround)
    /// CRITICAL: This is the definitive way to check authorization on iOS 26+
    private func testDataAccess() async -> Bool {
        Logger.info("🔍 [AUTH COORDINATOR] testDataAccess: Attempting to fetch steps data...")
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            Logger.info("❌ [AUTH COORDINATOR] testDataAccess: Could not create steps type")
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
                    Logger.info("❌ [AUTH COORDINATOR] testDataAccess: Query error: \(error.localizedDescription)")
                    
                    // CRITICAL FIX: "Authorization not determined" is a PERMISSION ERROR!
                    // It means the user has NEVER been asked for permission.
                    if errorMsg.contains("authorization not determined") ||
                       errorMsg.contains("not determined") ||
                       errorMsg.contains("not authorized") || 
                       errorMsg.contains("denied") {
                        Logger.info("❌ [AUTH COORDINATOR] testDataAccess: PERMISSION ERROR - authorization required")
                        continuation.resume(returning: false)
                    } else {
                        // Other errors (network, data unavailable, etc) - assume no data but authorized
                        Logger.info("⚠️ [AUTH COORDINATOR] testDataAccess: Non-permission error (network/data issue)")
                        continuation.resume(returning: true)
                    }
                } else {
                    Logger.info("✅ [AUTH COORDINATOR] testDataAccess: SUCCESS - can access HealthKit!")
                    Logger.info("✅ [AUTH COORDINATOR] testDataAccess: Sample count: \(samples?.count ?? 0)")
                    continuation.resume(returning: true)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Update authorization state
    private func updateState(_ state: AuthorizationState, _ authorized: Bool) {
        let oldState = authorizationState
        let oldAuthorized = isAuthorized
        
        authorizationState = state
        isAuthorized = authorized
        
        // Log state transitions for debugging
        if oldState != state || oldAuthorized != authorized {
            Logger.info("🔄 [AUTH COORDINATOR] State transition: \(oldState.description) → \(state.description), isAuthorized: \(oldAuthorized) → \(authorized)")
        }
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

