import Foundation
import HealthKit

/// Calculates Training Impulse (TRIMP) from heart rate data
/// TRIMP is a universal training load metric that works across all sports
/// Based on Edwards TRIMP (zone-based calculation)
/// Actor-isolated to run heavy calculations on background threads
actor TRIMPCalculator {
    private let healthKitManager = HealthKitManager.shared
    
    // Cache TRIMP per workout UUID (TRIMP for a workout never changes)
    private var trimpCache: [String: Double] = [:]
    private let cacheKey = "trimp_cache"
    
    init() {
        loadCache()
    }
    
    /// Calculate TRIMP for a specific workout
    /// - Parameter workout: The HKWorkout to calculate TRIMP for
    /// - Returns: TRIMP value (higher = more training stress)
    func calculateTRIMP(for workout: HKWorkout) async -> Double {
        let workoutId = workout.uuid.uuidString
        
        // Check cache first
        if let cached = trimpCache[workoutId] {
            Logger.debug("⚡ [TRIMP] Using cached value: \(String(format: "%.1f", cached))")
            return cached
        }
        // Get heart rate samples during workout
        let hrSamples = await getHeartRateSamples(
            from: workout.startDate,
            to: workout.endDate
        )
        
        guard !hrSamples.isEmpty else {
            Logger.warning("️ No HR data for workout, using estimate")
            // Fallback: estimate from calories/duration based on activity type
            return estimateTRIMPFromWorkout(workout)
        }
        
        // Get user's HR parameters
        let restingHR = getUserRestingHR() ?? 60
        let maxHR = getUserMaxHR() ?? 180
        
        // Removed verbose logging - only log summary at end
        
        // Calculate Edwards TRIMP (zone-based)
        let trimp = calculateEdwardsTRIMP(
            samples: hrSamples,
            restingHR: restingHR,
            maxHR: maxHR
        )
        
        Logger.debug("💓 TRIMP Result: \(String(format: "%.1f", trimp))")
        
        // Cache the result
        trimpCache[workoutId] = trimp
        saveCache()
        
        return trimp
    }
    
    /// Get average heart rate for a workout
    /// - Parameter workout: The HKWorkout to analyze
    /// - Returns: Average heart rate in BPM, or nil if no data
    func getAverageHeartRate(for workout: HKWorkout) async -> Double? {
        let hrSamples = await getHeartRateSamples(
            from: workout.startDate,
            to: workout.endDate
        )
        
        guard !hrSamples.isEmpty else { return nil }
        
        let sum = hrSamples.reduce(0.0) {
            $0 + $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
        return sum / Double(hrSamples.count)
    }
    
    // MARK: - Private Methods
    
    /// Get heart rate samples from HealthKit for a specific time range
    private func getHeartRateSamples(from start: Date, to end: Date) async -> [HKQuantitySample] {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Failed to fetch heart rate samples: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            
            HKHealthStore().execute(query)
        }
    }
    
    /// Calculate Edwards TRIMP using zone-based multipliers
    /// More accurate than simple HR reserve calculation
    private func calculateEdwardsTRIMP(samples: [HKQuantitySample], restingHR: Double, maxHR: Double) -> Double {
        var trimp: Double = 0
        let hrReserveRange = maxHR - restingHR
        
        guard hrReserveRange > 0 else {
            Logger.warning("️ Invalid HR range (maxHR=\(maxHR), restingHR=\(restingHR))")
            return 0
        }
        
        // Track time in each zone for debugging
        var timeInZones: [Int: Double] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for (index, sample) in samples.enumerated() {
            let hr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let hrReserve = (hr - restingHR) / hrReserveRange
            
            // Edwards TRIMP zone multipliers
            // Based on exponential relationship between HR and training stress
            let multiplier: Double
            let zone: Int
            switch hrReserve {
            case ..<0.5:
                multiplier = 1.0  // Zone 1-2 (Easy)
                zone = 1
            case 0.5..<0.6:
                multiplier = 2.0  // Zone 3 (Tempo)
                zone = 2
            case 0.6..<0.7:
                multiplier = 3.0  // Zone 4 (Threshold)
                zone = 3
            case 0.7..<0.8:
                multiplier = 4.0  // Zone 5 (VO2max)
                zone = 4
            default:
                multiplier = 5.0  // Zone 6-7 (Anaerobic)
                zone = 5
            }
            
            // Duration: time between this sample and next (or 1 minute if last sample)
            let nextSampleTime: Date
            if index < samples.count - 1 {
                nextSampleTime = samples[index + 1].startDate
            } else {
                nextSampleTime = sample.startDate.addingTimeInterval(60) // Assume 1 minute
            }
            let durationMinutes = nextSampleTime.timeIntervalSince(sample.startDate) / 60.0
            
            timeInZones[zone, default: 0] += durationMinutes
            trimp += durationMinutes * hrReserve * multiplier
        }
        
        // Removed verbose zone logging
        
        return trimp
    }
    
    /// Estimate TRIMP from workout when HR data is unavailable
    /// Uses different multipliers based on activity type
    private func estimateTRIMPFromWorkout(_ workout: HKWorkout) -> Double {
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        _ = workout.duration / 60.0
        
        // Different multipliers based on workout type
        // Strength training creates high muscular stress despite lower calorie burn
        let multiplier: Double
        let activityName: String
        
        switch workout.workoutActivityType {
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            // Strength training: higher multiplier (1.5x) to account for muscular stress
            multiplier = 1.5
            activityName = "Strength"
        case .cycling:
            multiplier = 0.8
            activityName = "Cycling"
        case .running:
            multiplier = 1.0
            activityName = "Running"
        case .swimming:
            multiplier = 0.9
            activityName = "Swimming"
        case .walking, .hiking:
            multiplier = 0.5
            activityName = "Walking/Hiking"
        default:
            multiplier = 0.7
            activityName = "Other"
        }
        
        let estimatedTRIMP = calories * multiplier
        
        Logger.debug("💓 Estimated TRIMP for \(activityName): \(Int(calories))kcal × \(multiplier) = \(String(format: "%.1f", estimatedTRIMP))")
        
        return estimatedTRIMP
    }
    
    /// Get user's resting heart rate from settings or HealthKit
    private func getUserRestingHR() -> Double? {
        return 60.0
    }
    
    /// Get user's max heart rate from settings or computed value
    private func getUserMaxHR() -> Double? {
        return 180.0
    }
    
    // MARK: - Cache Persistence
    
    /// Load TRIMP cache from UserDefaults
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cache = try? JSONDecoder().decode([String: Double].self, from: data) {
            trimpCache = cache
            Logger.debug("⚡ [TRIMP] Loaded \(cache.count) cached workouts")
        }
    }
    
    /// Save TRIMP cache to UserDefaults
    private func saveCache() {
        if let data = try? JSONEncoder().encode(trimpCache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
