import Foundation
import HealthKit

/// Fetches raw health data from HealthKit without transformation
class HealthKitDataFetcher {
    
    private let healthStore: HKHealthStore
    private let cacheManager = UnifiedCacheManager.shared
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Generic Fetch Methods
    
    /// Fetch the latest quantity sample for a given type
    func fetchLatestQuantity(for type: HKQuantityType, unit: HKUnit) async -> (sample: HKQuantitySample?, value: Double?) {
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
    
    func fetchLatestQuantityWithPredicate(for type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> (sample: HKQuantitySample?, value: Double?) {
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
    func fetchSum(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    if (error as NSError).code != 11 {
                        Logger.error("HealthKit fetchSum error for \(type.identifier): \(error.localizedDescription)")
                    }
                    continuation.resume(returning: 0.0)
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
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
    
    // MARK: - Date Range Queries (Development Mode)
    
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
    
    // MARK: - Batch Historical Fetching
    
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
                
                var sessions: [(bedtime: Date, wakeTime: Date)] = []
                var currentSession: (bedtime: Date, wakeTime: Date)?
                
                for sample in categorySamples {
                    guard sample.value != HKCategoryValueSleepAnalysis.awake.rawValue,
                          sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue else {
                        continue
                    }
                    
                    if let session = currentSession {
                        if sample.startDate.timeIntervalSince(session.wakeTime) < 7200 {
                            currentSession = (bedtime: session.bedtime, wakeTime: max(session.wakeTime, sample.endDate))
                        } else {
                            sessions.append(session)
                            currentSession = (bedtime: sample.startDate, wakeTime: sample.endDate)
                        }
                    } else {
                        currentSession = (bedtime: sample.startDate, wakeTime: sample.endDate)
                    }
                }
                
                if let session = currentSession {
                    sessions.append(session)
                }
                
                continuation.resume(returning: sessions)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - HealthKit Error

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
    let firstSleepTime: Date?
    let sample: HKCategorySample?
}
