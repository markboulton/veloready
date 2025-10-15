import Foundation
import HealthKit

/// Calculates Chronic Training Load (CTL) and Acute Training Load (ATL) from HealthKit workouts
/// CTL = 42-day exponentially weighted average (fitness)
/// ATL = 7-day exponentially weighted average (fatigue)
/// TSB = CTL - ATL (form/readiness)
class TrainingLoadCalculator {
    private let trimpCalculator = TRIMPCalculator()
    private let healthKitManager = HealthKitManager.shared
    
    /// Calculate current CTL and ATL from HealthKit workouts
    /// - Returns: Tuple of (ctl, atl) or nil if insufficient data
    func calculateTrainingLoad() async -> (ctl: Double, atl: Double) {
        Logger.data("Calculating training load from HealthKit workouts...")
        
        // Get last 42 days of TRIMP values
        let dailyTRIMP = await getDailyTRIMP(days: 42)
        
        // Need at least 7 days of data for meaningful calculation
        let nonZeroDays = dailyTRIMP.filter { $0 > 0 }.count
        Logger.data("Found \(nonZeroDays) days with workout data in last 42 days")
        
        let ctl = calculateCTL(from: dailyTRIMP)
        let atl = calculateATL(from: dailyTRIMP)
        
        let tsb = ctl - atl
        
        Logger.data("Training Load Results:")
        Logger.debug("   CTL (Chronic): \(String(format: "%.1f", ctl)) (42-day fitness)")
        Logger.debug("   ATL (Acute): \(String(format: "%.1f", atl)) (7-day fatigue)")
        Logger.debug("   TSB (Balance): \(String(format: "%.1f", tsb)) (form)")
        
        return (ctl, atl)
    }
    
    /// Get TRIMP for a specific date range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Total TRIMP for the period
    func getTRIMPForPeriod(from start: Date, to end: Date) async -> Double {
        let workouts = await healthKitManager.fetchWorkouts(
            from: start,
            to: end,
            activityTypes: [.cycling, .running, .swimming, .walking, .functionalStrengthTraining, .traditionalStrengthTraining, .hiking, .rowing]
        )
        
        var totalTRIMP: Double = 0
        for workout in workouts {
            let trimp = await trimpCalculator.calculateTRIMP(for: workout)
            totalTRIMP += trimp
        }
        
        return totalTRIMP
    }
    
    // MARK: - Private Methods
    
    /// Get daily TRIMP values for the last N days
    private func getDailyTRIMP(days: Int) async -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        
        Logger.data("Fetching workouts from \(startDate) to \(Date())")
        
        // Get all workouts in range
        let workouts = await healthKitManager.fetchWorkouts(
            from: startDate,
            to: Date(),
            activityTypes: [.cycling, .running, .swimming, .walking, .functionalStrengthTraining, .traditionalStrengthTraining, .hiking, .rowing, .other]
        )
        
        Logger.data("Found \(workouts.count) workouts to analyze")
        
        // Group by day and calculate TRIMP
        var dailyTRIMP: [Date: Double] = [:]
        
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.startDate)
            let trimp = await trimpCalculator.calculateTRIMP(for: workout)
            dailyTRIMP[day, default: 0] += trimp
            
            Logger.debug("   Workout on \(day): +\(String(format: "%.1f", trimp)) TRIMP")
        }
        
        // Create array with 0 for days with no workouts (maintains exponential weighting)
        var result: [Double] = []
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let trimp = dailyTRIMP[date] ?? 0
            result.insert(trimp, at: 0)
        }
        
        return result
    }
    
    /// Calculate CTL (Chronic Training Load) - 42-day exponentially weighted average
    /// This represents your fitness/training capacity
    private func calculateCTL(from dailyValues: [Double]) -> Double {
        return calculateExponentialAverage(values: dailyValues, days: 42)
    }
    
    /// Calculate ATL (Acute Training Load) - 7-day exponentially weighted average
    /// This represents your recent fatigue/training stress
    private func calculateATL(from dailyValues: [Double]) -> Double {
        let last7Days = Array(dailyValues.suffix(7))
        return calculateExponentialAverage(values: last7Days, days: 7)
    }
    
    /// Calculate exponentially weighted average
    /// Recent values have more weight than older values
    /// - Parameters:
    ///   - values: Array of daily values
    ///   - days: Time constant for the exponential average
    /// - Returns: Exponentially weighted average
    private func calculateExponentialAverage(values: [Double], days: Int) -> Double {
        guard !values.isEmpty else { return 0 }
        
        // Lambda (smoothing factor) = 2 / (N + 1)
        // This gives more weight to recent values
        let lambda = 2.0 / (Double(days) + 1.0)
        
        // Start with first value
        var ewa = values.first!
        
        // Apply exponential weighting to subsequent values
        for value in values.dropFirst() {
            ewa = (value * lambda) + (ewa * (1 - lambda))
        }
        
        return ewa
    }
}

// MARK: - HealthKitManager Extension

extension HealthKitManager {
    /// Fetch workouts from HealthKit for a specific date range and activity types
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    ///   - activityTypes: Array of HKWorkoutActivityType to include
    /// - Returns: Array of HKWorkout objects
    func fetchWorkouts(from start: Date, to end: Date, activityTypes: [HKWorkoutActivityType]) async -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        
        // Create compound predicate for activity types
        let typePredicates = activityTypes.map {
            HKQuery.predicateForWorkouts(with: $0)
        }
        let compoundPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: typePredicates
        )
        
        let finalPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [predicate, compoundPredicate]
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: finalPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Failed to fetch workouts: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                Logger.debug("✅ Fetched \(workouts.count) workouts from HealthKit")
                continuation.resume(returning: workouts)
            }
            
            HKHealthStore().execute(query)
        }
    }
}
