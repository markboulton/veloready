import Foundation
import HealthKit
import UIKit

/// HealthKit error types
enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case dataNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .dataNotAvailable:
            return "Requested health data is not available"
        }
    }
}

/// Clean, simple HealthKit manager built from scratch
class HealthKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = HealthKitManager()
    
    // MARK: - Published Properties
    @MainActor @Published var isAuthorized = false
    @MainActor @Published var authorizationState: AuthorizationState = .notDetermined
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private let cacheManager = UnifiedCacheManager.shared
    
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
        
        // Body temperature (for illness detection)
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
    private init() {
        // NON-BLOCKING initialization - defer authorization check
        Task { @MainActor in
            // Quick status check without heavy operations
            await checkAuthorizationStatusFast()
        }
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit authorization from the user
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit not available on this device")
            return
        }
        
        do {
            Logger.debug("🔐 Requesting HealthKit authorization...")
            Logger.debug("📋 Requesting permissions for: \(readTypes.map { $0.identifier })")
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            Logger.debug("✅ Authorization sheet completed")
            
            // Check status after authorization with delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await MainActor.run {
                checkAuthorizationStatus()
            }
            
        } catch {
            Logger.error("HealthKit authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh authorization status (alias for checking)
    func refreshAuthorizationStatus() async {
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    /// Request workout permissions specifically
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
            
            // Check status
            let status = healthStore.authorizationStatus(for: workoutType)
            Logger.data("Workout permission status: \(status.rawValue)")
            
        } catch {
            Logger.error("Workout authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Request workout route permissions (must request workout permission too)
    func requestWorkoutRoutePermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit not available on this device")
            return
        }
        
        do {
            Logger.debug("🔐 Requesting Workout + Route permissions...")
            let workoutType = HKObjectType.workoutType()
            let routeType = HKSeriesType.workoutRoute()
            
            // Must request both together
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType, routeType])
            Logger.debug("✅ Workout + Route authorization sheet completed")
            
            // Check status
            let workoutStatus = healthStore.authorizationStatus(for: workoutType)
            let routeStatus = healthStore.authorizationStatus(for: routeType)
            Logger.data("Workout permission status: \(workoutStatus.rawValue)")
            Logger.data("Route permission status: \(routeStatus.rawValue)")
            
        } catch {
            Logger.error("Workout Route authorization error: \(error.localizedDescription)")
        }
    }
    
    /// Check authorization after returning from Settings
    func checkAuthorizationAfterSettingsReturn() async {
        // Give iOS time to propagate changes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await MainActor.run {
            checkAuthorizationStatus()
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
        
        // Apply the same fix: rawValue 1 should be treated as authorized
        // This is needed because iOS Settings shows permissions as ON but rawValue 1 = .sharingDenied
        if status.rawValue == 1 && status == .sharingDenied {
            Logger.debug("🔧 Fixing authorization status: rawValue 1 treated as authorized for \(type.identifier)")
            return .sharingAuthorized
        }
        
        return status
    }
    
    /// Open iOS Settings app to HealthKit permissions
    @MainActor
    func openSettings() {
        // Apple doesn't officially support deep-linking to HealthKit permissions
        // So we open general app settings and provide clear instructions
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    /// FAST authorization check - non-blocking, no heavy operations
    func checkAuthorizationStatusFast() async {
        Logger.debug("⚡ Fast HealthKit authorization check")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.authorizationState = .notAvailable
                self.isAuthorized = false
            }
            return
        }
        
        // Quick status check without data queries
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        
        // Apply the same iOS rawValue bug fix as the main method
        let effectiveStatus: HKAuthorizationStatus
        if hrvStatus.rawValue == 1 && hrvStatus == .sharingDenied {
            Logger.debug("🔧 Fast check: rawValue 1 treated as authorized for \(hrvType.identifier)")
            effectiveStatus = .sharingAuthorized
        } else {
            effectiveStatus = hrvStatus
        }
        
        await MainActor.run {
            self.authorizationState = AuthorizationState.fromHKStatus(effectiveStatus)
            self.isAuthorized = effectiveStatus == .sharingAuthorized
        }
        
        Logger.debug("⚡ Fast HealthKit check completed: \(await authorizationState)")
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
    
    /// Async version of authorization status check
    private func checkAuthorizationStatusAsync() async {
        var authorizedCount = 0
        var deniedCount = 0
        var notDeterminedCount = 0
        
        for type in readTypes {
            let status = healthStore.authorizationStatus(for: type)
            
            // IMPROVED LOGIC: Handle the iOS rawValue bug more intelligently
            if status.rawValue == 1 {
                // This could be either the iOS bug OR actually denied
                // We need to distinguish by checking if we can actually access data
                if await canAccessHealthData(for: type) {
                    authorizedCount += 1
                } else {
                    deniedCount += 1
                }
            } else {
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
        }
        
        // Update state based on results - More practical approach
        await updateAuthorizationState(authorizedCount: authorizedCount, deniedCount: deniedCount, notDeterminedCount: notDeterminedCount)
    }
    
    /// Update authorization state on main actor
    @MainActor
    private func updateAuthorizationState(authorizedCount: Int, deniedCount: Int, notDeterminedCount: Int) {
        // Define critical types that are essential for the app to function
        let criticalTypes = [
            "HKQuantityTypeIdentifierHeartRate",
            "HKQuantityTypeIdentifierHeartRateVariabilitySDNN", 
            "HKCategoryTypeIdentifierSleepAnalysis",
            "HKQuantityTypeIdentifierStepCount",
            "HKQuantityTypeIdentifierActiveEnergyBurned"
        ]
        
        // Count how many critical types we have
        _ = readTypes.filter { criticalTypes.contains($0.identifier) }.count
        
        if authorizedCount == readTypes.count {
            authorizationState = .authorized
            isAuthorized = true
            Logger.debug("✅ HealthKit fully authorized")
        } else if deniedCount > 0 {
            // If ANY critical types are denied, treat as denied
            // This ensures we show the authorization prompt when permissions are off
            authorizationState = .denied
            isAuthorized = false
            Logger.warning("️ HealthKit denied - critical permissions missing (\(deniedCount) denied, \(authorizedCount) authorized)")
        } else if authorizedCount > 0 && deniedCount == 0 {
            // Only show partial if we have some permissions but no denials
            authorizationState = .partial
            isAuthorized = true
            Logger.debug("✅ HealthKit partially authorized (\(authorizedCount)/\(readTypes.count))")
        } else {
            // No permissions determined yet
            authorizationState = .notDetermined
            isAuthorized = false
            Logger.warning("️ HealthKit authorization not determined")
        }
    }
    
    /// Test if we can actually access health data for a specific type
    private func canAccessHealthData(for type: HKObjectType) async -> Bool {
        guard let sampleType = type as? HKSampleType else {
            // For non-sample types, just check authorization status
            let status = healthStore.authorizationStatus(for: type)
            return status == .sharingAuthorized || (status.rawValue == 1)
        }
        
        // Try a read-based test: attempt to query for recent data
        // This is more reliable than write tests since we only have read permissions
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now // Last 7 days
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 1, // Just check if we can get any data
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if error == nil {
                    // Check if we have actual data for critical types
                    let criticalTypes = [
                        "HKQuantityTypeIdentifierHeartRate",
                        "HKQuantityTypeIdentifierHeartRateVariabilitySDNN", 
                        "HKCategoryTypeIdentifierSleepAnalysis",
                        "HKQuantityTypeIdentifierStepCount",
                        "HKQuantityTypeIdentifierActiveEnergyBurned"
                    ]
                    
                    let hasData = (samples?.count ?? 0) > 0
                    
                    if criticalTypes.contains(type.identifier) && !hasData {
                        // For critical types, no data likely means no permission
                        continuation.resume(returning: false)
                    } else {
                        // For non-critical types or when we have data, consider it authorized
                        continuation.resume(returning: true)
                    }
                } else {
                    // If we get an error, check if it's an authorization error
                    let errorDescription = error?.localizedDescription.lowercased() ?? ""
                    if errorDescription.contains("not authorized") || errorDescription.contains("denied") {
                        continuation.resume(returning: false)
                    } else {
                        // Other errors (like no data) still mean we have access
                        continuation.resume(returning: true)
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetch detailed sleep data for last night (cached for 1 hour)
    func fetchDetailedSleepData() async -> HealthKitSleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let cacheKey = "healthkit:sleep:\(startOfToday.timeIntervalSince1970)"
        
        // Try cache first
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 3600) { // 1 hour cache
                return await self.fetchDetailedSleepDataInternal()
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchDetailedSleepDataInternal()
        }
    }
    
    /// Internal method to fetch sleep data from HealthKit
    private func fetchDetailedSleepDataInternal() async -> HealthKitSleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<HealthKitSleepData?, Never>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                guard error == nil, let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    Logger.error("No HealthKit sleep samples found: error=\(error?.localizedDescription ?? "none"), samplesCount=\(samples?.count ?? 0)")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Removed verbose sleep sample logging
                
                // Filter to most recent sleep session only
                
                // Group samples by sleep session (continuous sleep periods)
                var sleepSessions: [[HKCategorySample]] = []
                var currentSession: [HKCategorySample] = []
                let maxGapBetweenSessions: TimeInterval = 30 * 60 // 30 minutes gap = new session
                
                for i in 0..<sleepSamples.count {
                    currentSession.append(sleepSamples[i])
                    
                    if i + 1 < sleepSamples.count {
                        let timeGap = sleepSamples[i + 1].startDate.timeIntervalSince(sleepSamples[i].endDate)
                        if timeGap > maxGapBetweenSessions {
                            // End current session, start new one
                            sleepSessions.append(currentSession)
                            currentSession = []
                        }
                    }
                }
                
                // Add final session
                if !currentSession.isEmpty {
                    sleepSessions.append(currentSession)
                }
                
                // Removed verbose session logging
                
                guard let mostRecentSession = sleepSessions.last else {
                    Logger.error("No valid sleep sessions found")
                    continuation.resume(returning: nil)
                    return
                }
                
                Logger.debug("✅ Using most recent sleep session (\(mostRecentSession.count) samples)")
                
                // Parse sleep stages from most recent session only
                var deepSleep = 0.0
                var remSleep = 0.0
                var coreSleep = 0.0
                var awake = 0.0
                var inBed = 0.0
                var wakeCount = 0
                
                var earliestBedtime: Date?
                var latestWakeTime: Date?
                var firstSleepTime: Date? // Track first actual sleep stage for latency
                
                for sample in mostRecentSession {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Track bed and wake times
                    if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                        earliestBedtime = sample.startDate
                    }
                    if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                        latestWakeTime = sample.endDate
                    }
                    
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSleep += duration
                        if firstSleepTime == nil {
                            firstSleepTime = sample.startDate
                        }
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSleep += duration
                        if firstSleepTime == nil {
                            firstSleepTime = sample.startDate
                        }
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        coreSleep += duration
                        if firstSleepTime == nil {
                            firstSleepTime = sample.startDate
                        }
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awake += duration
                        wakeCount += 1
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        inBed += duration
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        coreSleep += duration // Treat unspecified as core
                        if firstSleepTime == nil {
                            firstSleepTime = sample.startDate
                        }
                    default:
                        break
                    }
                }
                
                let totalSleep = deepSleep + remSleep + coreSleep
                let timeInBed = earliestBedtime != nil && latestWakeTime != nil ?
                    latestWakeTime!.timeIntervalSince(earliestBedtime!) : totalSleep + awake
                
                // Simplified logging - only log summary
                Logger.debug("💤 Sleep: \(String(format: "%.1f", totalSleep/3600))h (Deep: \(String(format: "%.1f", deepSleep/3600))h, REM: \(String(format: "%.1f", remSleep/3600))h, Core: \(String(format: "%.1f", coreSleep/3600))h)")
                
                // Ensure we distinguish between actual sleep vs time in bed
                let actualSleepDuration = totalSleep // This should be actual sleep only
                let actualTimeInBed = timeInBed
                
                // TEMPORARY FIX: If sleep duration > 8 hours, it might be swapped with timeInBed
                var correctedSleepDuration = actualSleepDuration
                var correctedTimeInBed = actualTimeInBed
                
                if actualSleepDuration > 8*3600 && actualTimeInBed < actualSleepDuration {
                    Logger.warning("️ POTENTIAL VALUE SWAP DETECTED: Swapping sleepDuration and timeInBed")
                    correctedSleepDuration = actualTimeInBed
                    correctedTimeInBed = actualSleepDuration
                    Logger.debug("   Corrected Sleep Duration: \(String(format: "%.2f", correctedSleepDuration/3600)) hrs")
                    Logger.debug("   Corrected Time in Bed: \(String(format: "%.2f", correctedTimeInBed/3600)) hrs")
                }
                
                let sleepData = HealthKitSleepData(
                    sleepDuration: correctedSleepDuration,
                    timeInBed: correctedTimeInBed,
                    deepSleepDuration: deepSleep,
                    remSleepDuration: remSleep,
                    coreSleepDuration: coreSleep,
                    awakeDuration: awake,
                    wakeEvents: max(0, wakeCount - 1), // Don't count initial wake
                    bedtime: earliestBedtime,
                    wakeTime: latestWakeTime,
                    firstSleepTime: firstSleepTime,
                    sample: mostRecentSession.first
                )
                
                continuation.resume(returning: sleepData)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch latest sleep data (simplified for debug views)
    func fetchLatestSleepData() async -> (sample: HKCategorySample?, duration: TimeInterval?) {
        if let sleepData = await fetchDetailedSleepData() {
            return (sleepData.sample, sleepData.sleepDuration)
        }
        return (nil, nil)
    }
    
    /// Fetch historical sleep data for baseline calculations (cached for 1 hour)
    func fetchHistoricalSleepData(days: Int = 7) async -> [(bedtime: Date?, wakeTime: Date?)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cacheKey = "healthkit:sleep_history:\(days):\(today.timeIntervalSince1970)"
        
        // Try cache first
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 3600) { // 1 hour cache
                return await self.fetchHistoricalSleepDataInternal(days: days)
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchHistoricalSleepDataInternal(days: days)
        }
    }
    
    /// Internal method to fetch historical sleep data from HealthKit
    private func fetchHistoricalSleepDataInternal(days: Int) async -> [(bedtime: Date?, wakeTime: Date?)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                
                guard error == nil, let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    Logger.error("No historical sleep data found: error=\(error?.localizedDescription ?? "none"), samplesCount=\(samples?.count ?? 0)")
                    continuation.resume(returning: [])
                    return
                }
                
                Logger.debug("🔍 HISTORICAL SLEEP ANALYSIS:")
                Logger.data("Found \(sleepSamples.count) historical sleep samples over \(days) days")
                
                // Group samples by sleep session (continuous sleep periods)
                var allSleepSessions: [[HKCategorySample]] = []
                var currentSession: [HKCategorySample] = []
                let maxGapBetweenSessions: TimeInterval = 30 * 60 // 30 minutes gap = new session
                
                for i in 0..<sleepSamples.count {
                    currentSession.append(sleepSamples[i])
                    
                    if i + 1 < sleepSamples.count {
                        let timeGap = sleepSamples[i + 1].startDate.timeIntervalSince(sleepSamples[i].endDate)
                        if timeGap > maxGapBetweenSessions {
                            // End current session, start new one
                            allSleepSessions.append(currentSession)
                            currentSession = []
                        }
                    }
                }
                
                // Add final session
                if !currentSession.isEmpty {
                    allSleepSessions.append(currentSession)
                }
                
                Logger.debug("   Found \(allSleepSessions.count) total sleep sessions across \(days) days")
                
                // Extract bedtime and wake time for each session
                var sleepTimes: [(bedtime: Date?, wakeTime: Date?)] = []
                
                for (index, session) in allSleepSessions.enumerated() {
                    var earliestBedtime: Date?
                    var latestWakeTime: Date?
                    
                    for sample in session {
                        // Track bed and wake times
                        if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                            earliestBedtime = sample.startDate
                        }
                        if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                            latestWakeTime = sample.endDate
                        }
                    }
                    
                    sleepTimes.append((bedtime: earliestBedtime, wakeTime: latestWakeTime))
                    
                    Logger.debug("     Session \(index + 1): bedtime=\(earliestBedtime?.description ?? "nil"), wake=\(latestWakeTime?.description ?? "nil")")
                }
                
                continuation.resume(returning: sleepTimes)
            }
            healthStore.execute(query)
        }
    }

    /// Fetch latest HRV data (cached for 5 minutes)
    func fetchLatestHRVData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:hrv:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) { // 5 min cache
                return await self.fetchLatestQuantity(for: hrvType, unit: HKUnit.secondUnit(with: .milli))
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchLatestQuantity(for: hrvType, unit: HKUnit.secondUnit(with: .milli))
        }
    }
    
    /// Fetch overnight HRV data (for alcohol detection)
    /// Gets average/representative HRV from last night's sleep period
    /// - Parameters:
    ///   - bedtime: Optional actual bedtime from sleep session
    ///   - wakeTime: Optional actual wake time from sleep session
    func fetchOvernightHRVData(bedtime: Date? = nil, wakeTime: Date? = nil) async -> (sample: HKQuantitySample?, value: Double?) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return (nil, nil)
        }
        
        let calendar = Calendar.current
        let overnightStart: Date
        let overnightEnd: Date
        
        // Use actual sleep session times if available (PHYSIOLOGICALLY CORRECT)
        if let bedtime = bedtime, let wakeTime = wakeTime {
            overnightStart = bedtime
            overnightEnd = wakeTime
            Logger.debug("🍷 Using ACTUAL sleep session times for overnight HRV")
        } else {
            // Fallback to estimated sleep window (6 PM yesterday to 6 AM today)
            let now = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let startOfYesterday = calendar.startOfDay(for: yesterday)
            let endOfToday = calendar.startOfDay(for: now)
            overnightStart = calendar.date(byAdding: .hour, value: 18, to: startOfYesterday)!
            overnightEnd = calendar.date(byAdding: .hour, value: 6, to: endOfToday)!
            Logger.debug("🍷 Using ESTIMATED sleep window for overnight HRV (no sleep session data)")
        }
        
        Logger.debug("🍷 Fetching overnight HRV from \(overnightStart) to \(overnightEnd)")
        
        // Get ALL HRV samples from overnight period and calculate average
        let predicate = HKQuery.predicateForSamples(withStart: overnightStart, end: overnightEnd, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    Logger.debug("🍷 ⚠️ No overnight HRV samples found - alcohol detection will be limited")
                    continuation.resume(returning: (nil, nil))
                    return
                }
                
                // Calculate average of all overnight HRV samples
                let unit = HKUnit.secondUnit(with: .milli)
                let values = samples.map { $0.quantity.doubleValue(for: unit) }
                let average = values.reduce(0, +) / Double(values.count)
                
                Logger.debug("🍷 Found \(samples.count) overnight HRV samples")
                Logger.debug("🍷 Average overnight HRV: \(String(format: "%.2f", average)) ms (range: \(String(format: "%.2f", values.min() ?? 0))-\(String(format: "%.2f", values.max() ?? 0)))")
                
                // Return the first sample with the average value for consistency
                continuation.resume(returning: (samples.first, average))
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch latest resting heart rate (cached for 5 minutes)
    func fetchLatestRHRData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:rhr:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) { // 5 min cache
                return await self.fetchLatestQuantity(for: rhrType, unit: HKUnit(from: "count/min"))
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchLatestQuantity(for: rhrType, unit: HKUnit(from: "count/min"))
        }
    }
    
    /// Fetch latest respiratory rate (cached for 5 minutes)
    func fetchLatestRespiratoryRateData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let respType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:respiratory:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) { // 5 min cache
                return await self.fetchLatestQuantity(for: respType, unit: HKUnit(from: "count/min"))
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchLatestQuantity(for: respType, unit: HKUnit(from: "count/min"))
        }
    }
    
    /// Fetch daily steps (cached for 5 minutes)
    func fetchDailySteps() async -> Int? {
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:steps:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) { // 5 min cache
                return await self.fetchDailyStepsInternal()
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchDailyStepsInternal()
        }
    }
    
    private func fetchDailyStepsInternal() async -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: today,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let result = result, let steps = result.sumQuantity() {
                    let stepCount = Int(steps.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: stepCount > 0 ? stepCount : nil)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Fetch daily active calories (cached for 5 minutes)
    func fetchDailyActiveCalories() async -> Double? {
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:active_calories:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) { // 5 min cache
                return await self.fetchDailyActiveCaloriesInternal()
            }
        } catch {
            // If cache fails, fetch directly
            return await fetchDailyActiveCaloriesInternal()
        }
    }
    
    private func fetchDailyActiveCaloriesInternal() async -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: today,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let result = result, let calories = result.sumQuantity() {
                    let calorieCount = calories.doubleValue(for: HKUnit.kilocalorie())
                    continuation.resume(returning: calorieCount > 0 ? calorieCount : nil)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Fetch latest VO₂ Max
    func fetchLatestVO2MaxData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            return (nil, nil)
        }
        
        return await fetchLatestQuantity(for: vo2MaxType, unit: HKUnit(from: "mL/kg*min"))
    }
    
    /// Fetch latest blood oxygen saturation (SpO2)
    func fetchLatestOxygenSaturationData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            return (nil, nil)
        }
        
        return await fetchLatestQuantity(for: spo2Type, unit: HKUnit.percent())
    }
    
    /// Fetch latest body temperature
    func fetchLatestBodyTemperatureData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let tempType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else {
            return (nil, nil)
        }
        
        return await fetchLatestQuantity(for: tempType, unit: HKUnit.degreeFahrenheit())
    }
    
    /// Fetch today's activity data
    func fetchTodayActivity() async -> (steps: Int, activeCalories: Double, exerciseMinutes: Double, walkingDistance: Double) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let steps = await fetchSum(
            for: .quantityType(forIdentifier: .stepCount)!,
            predicate: predicate,
            unit: HKUnit.count()
        )
        
        let calories = await fetchSum(
            for: .quantityType(forIdentifier: .activeEnergyBurned)!,
            predicate: predicate,
            unit: HKUnit.kilocalorie()
        )
        
        let exercise = await fetchSum(
            for: .quantityType(forIdentifier: .appleExerciseTime)!,
            predicate: predicate,
            unit: HKUnit.minute()
        )
        
        let distance = await fetchSum(
            for: .quantityType(forIdentifier: .distanceWalkingRunning)!,
            predicate: predicate,
            unit: HKUnit.meterUnit(with: .kilo)
        )
        
        return (Int(steps), calories, exercise, distance)
    }
    
    /// Fetch hourly step counts for today (for sparkline visualization)
    /// Optimized to use HKStatisticsCollectionQuery for batch fetching
    func fetchTodayHourlySteps() async -> [Int] {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return Array(repeating: 0, count: 24)
        }
        
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            // Create interval components for 1 hour
            var interval = DateComponents()
            interval.hour = 1
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepsType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: startOfDay,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    Logger.error("HealthKit hourly steps error: \(error.localizedDescription)")
                    continuation.resume(returning: Array(repeating: 0, count: 24))
                    return
                }
                
                var hourlySteps = Array(repeating: 0, count: 24)
                
                results?.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                    let hour = calendar.component(.hour, from: statistics.startDate)
                    if hour < 24, let sum = statistics.sumQuantity() {
                        hourlySteps[hour] = Int(sum.doubleValue(for: .count()))
                    }
                }
                
                continuation.resume(returning: hourlySteps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert HKCategoryValueSleepAnalysis raw value to readable string
    private func sleepValueString(for rawValue: Int) -> String {
        switch rawValue {
        case 0:
            return "InBed"
        case 1:
            return "AsSleep"
        case 2:
            return "AsCoreSleep"
        case 3:
            return "AsDeepSleep"
        case 4:
            return "AsREM"
        case 5:
            return "AsAwake"
        default:
            return "Unknown(\(rawValue))"
        }
    }
    
    /// Fetch the latest quantity sample for a given type
    private func fetchLatestQuantity(for type: HKQuantityType, unit: HKUnit) async -> (sample: HKQuantitySample?, value: Double?) {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: (nil, nil))
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: (sample, value))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestQuantityWithPredicate(for type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> (sample: HKQuantitySample?, value: Double?) {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: (nil, nil))
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: (sample, value))
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch sum of quantities for a given type and predicate
    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    // Only log meaningful errors (not "no data" errors)
                    if (error as NSError).code != 11 { // HKError code 11 = no data
                        Logger.error("HealthKit fetchSum error for \(type.identifier): \(error.localizedDescription)")
                    }
                    continuation.resume(returning: 0.0)
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    // Silently return 0 for missing data (normal case)
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                Logger.debug("✅ Fetched \(type.identifier): \(value)")
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Development Mode Data Capture Methods
    
    /// Fetch steps data for a date range (for development mode)
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepsType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let stepsSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: stepsSamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch active energy data for a date range (for development mode)
    func fetchActiveEnergyData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: energyType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let energySamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: energySamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch HRV data for a date range (for development mode)
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let hrvSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: hrvSamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch resting heart rate data for a date range (for development mode)
    func fetchRestingHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: rhrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let rhrSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: rhrSamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch sleep data for a date range (for development mode)
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let sleepSamples = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: sleepSamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch heart rate data for a date range (for development mode)
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                let hrSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: hrSamples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch VO₂ Max data for a date range (for development mode and trends)
    func fetchVO2MaxData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: vo2MaxType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Error fetching VO₂ Max data: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let vo2Samples = samples as? [HKQuantitySample] ?? []
                Logger.data("Fetched \(vo2Samples.count) VO₂ Max samples")
                continuation.resume(returning: vo2Samples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch blood oxygen (SpO2) data for a date range (for development mode and trends)
    func fetchOxygenSaturationData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: spo2Type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Error fetching SpO2 data: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let spo2Samples = samples as? [HKQuantitySample] ?? []
                Logger.data("Fetched \(spo2Samples.count) SpO2 samples")
                continuation.resume(returning: spo2Samples)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch body temperature data for a date range (for illness detection)
    func fetchBodyTemperatureData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let tempType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: tempType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Error fetching body temperature data: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let tempSamples = samples as? [HKQuantitySample] ?? []
                Logger.data("Fetched \(tempSamples.count) body temperature samples")
                continuation.resume(returning: tempSamples)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Workouts
    
    /// Fetch recent workouts from Apple Health (filtered to strength and walking only)
    func fetchRecentWorkouts(limit: Int = 50, daysBack: Int = 30) async -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        
        // Date range: last N days (use start of day to include today)
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: startOfToday) else {
            return []
        }
        
        Logger.debug("🔍 Fetching workouts from \(startDate) to \(now)")
        
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )
        
        // Filter for strength, walking, and hiking workouts only
        let strengthPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
        let functionalStrengthPredicate = HKQuery.predicateForWorkouts(with: .functionalStrengthTraining)
        let walkingPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let hikingPredicate = HKQuery.predicateForWorkouts(with: .hiking)
        
        let typePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            strengthPredicate,
            functionalStrengthPredicate,
            walkingPredicate,
            hikingPredicate
        ])
        
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            datePredicate,
            typePredicate
        ])
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: combinedPredicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Failed to fetch workouts: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                Logger.debug("✅ Fetched \(workouts.count) strength/walking workouts from Apple Health")
                
                // Debug: Print details of each workout
                for (index, workout) in workouts.prefix(5).enumerated() {
                    let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                    
                    // Use new iOS 18+ API for active energy burned
                    let calories: Double
                    if #available(iOS 18.0, *),
                       let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                       let energyStatistics = workout.statistics(for: energyType),
                       let totalEnergy = energyStatistics.sumQuantity() {
                        calories = totalEnergy.doubleValue(for: .kilocalorie())
                    } else {
                        // Fallback for iOS < 18.0 - using deprecated API intentionally for compatibility
                        calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    }
                    
                    Logger.debug("   Workout \(index + 1): \(workout.workoutActivityType.name)")
                    Logger.debug("      Date: \(workout.startDate)")
                    Logger.debug("      Duration: \(Int(workout.duration / 60))m")
                    Logger.debug("      Distance: \(String(format: "%.1f", distance / 1000))km")
                    Logger.debug("      Calories: \(Int(calories)) kcal")
                }
                
                continuation.resume(returning: workouts)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Batch Historical Data Fetching
    
    /// Fetch all HRV samples in a date range for historical backfill
    func fetchHRVSamples(from startDate: Date, to endDate: Date) async -> [HKQuantitySample] {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    Logger.error("❌ Failed to fetch HRV samples: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let quantitySamples = (samples as? [HKQuantitySample]) ?? []
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch all RHR samples in a date range for historical backfill
    func fetchRHRSamples(from startDate: Date, to endDate: Date) async -> [HKQuantitySample] {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: rhrType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    Logger.error("❌ Failed to fetch RHR samples: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let quantitySamples = (samples as? [HKQuantitySample]) ?? []
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch all sleep sessions in a date range for historical backfill
    func fetchSleepSessions(from startDate: Date, to endDate: Date) async -> [(bedtime: Date, wakeTime: Date)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    Logger.error("❌ Failed to fetch sleep samples: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Group by sleep session (consecutive samples)
                var sessions: [(bedtime: Date, wakeTime: Date)] = []
                var currentSession: (bedtime: Date, wakeTime: Date)?
                
                for sample in categorySamples {
                    // Only count actual sleep stages (not awake/in bed)
                    guard sample.value != HKCategoryValueSleepAnalysis.awake.rawValue,
                          sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue else {
                        continue
                    }
                    
                    if let session = currentSession {
                        // If this sample is within 2 hours of the last wake time, extend the session
                        if sample.startDate.timeIntervalSince(session.wakeTime) < 7200 {
                            currentSession = (bedtime: session.bedtime, wakeTime: max(session.wakeTime, sample.endDate))
                        } else {
                            // New session
                            sessions.append(session)
                            currentSession = (bedtime: sample.startDate, wakeTime: sample.endDate)
                        }
                    } else {
                        // First session
                        currentSession = (bedtime: sample.startDate, wakeTime: sample.endDate)
                    }
                }
                
                // Add the last session
                if let session = currentSession {
                    sessions.append(session)
                }
                
                continuation.resume(returning: sessions)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .walking: return "Walking"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        default: return "Other"
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

// MARK: - Sleep Data

struct HealthKitSleepData {
    let sleepDuration: TimeInterval
    let timeInBed: TimeInterval
    let deepSleepDuration: TimeInterval
    let remSleepDuration: TimeInterval
    let coreSleepDuration: TimeInterval
    let awakeDuration: TimeInterval
    let wakeEvents: Int
    let bedtime: Date?
    let wakeTime: Date?
    let firstSleepTime: Date? // Time of first sleep stage (for latency calculation)
    let sample: HKCategorySample?
}
