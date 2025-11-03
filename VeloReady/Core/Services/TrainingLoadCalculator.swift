import Foundation
import HealthKit

/// Calculates Chronic Training Load (CTL) and Acute Training Load (ATL) from HealthKit workouts
/// CTL = 42-day exponentially weighted average (fitness)
/// ATL = 7-day exponentially weighted average (fatigue)
/// TSB = CTL - ATL (form/readiness)
class TrainingLoadCalculator {
    private let trimpCalculator = TRIMPCalculator()
    private let healthKitManager = HealthKitManager.shared
    
    // Cache training load for 1 hour (expensive calculation, changes slowly)
    private var cachedTrainingLoad: (ctl: Double, atl: Double)?
    private var cacheTimestamp: Date?
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    
    /// Calculate CTL and ATL from Strava activities using TSS
    /// - Parameter activities: Array of activities with TSS values
    /// - Returns: Tuple of (ctl, atl) for the most recent date
    func calculateTrainingLoadFromActivities(_ activities: [IntervalsActivity]) -> (ctl: Double, atl: Double) {
        Logger.data("📊 Calculating CTL/ATL from \(activities.count) activities...")
        
        // Group activities by date and sum TSS
        var dailyTSS: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for activity in activities {
            guard let tss = activity.tss, tss > 0 else { continue }
            guard let activityDate = parseActivityDate(activity.startDateLocal) else { continue }
            
            let day = calendar.startOfDay(for: activityDate)
            dailyTSS[day, default: 0] += tss
        }
        
        Logger.data("📊 Found \(dailyTSS.count) days with TSS data")
        
        // Create array of last 42 days with TSS values
        let today = calendar.startOfDay(for: Date())
        var dailyValues: [Double] = []
        
        for i in 0..<42 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let tss = dailyTSS[date] ?? 0
            dailyValues.insert(tss, at: 0) // Insert at beginning to maintain chronological order
        }
        
        let ctl = calculateCTL(from: dailyValues)
        let atl = calculateATL(from: dailyValues)
        let tsb = ctl - atl
        
        Logger.data("📊 Training Load from Activities:")
        Logger.data("   CTL (Chronic): \(String(format: "%.1f", ctl)) (42-day fitness)")
        Logger.data("   ATL (Acute): \(String(format: "%.1f", atl)) (7-day fatigue)")
        Logger.data("   TSB (Balance): \(String(format: "%.1f", tsb)) (form)")
        
        return (ctl, atl)
    }
    
    /// Calculate progressive CTL/ATL values for each activity date
    /// - Parameter activities: Array of activities with TSS values
    /// - Returns: Dictionary mapping activity dates to (ctl, atl) tuples
    func calculateProgressiveTrainingLoad(_ activities: [IntervalsActivity]) -> [Date: (ctl: Double, atl: Double)] {
        Logger.data("📊 Calculating progressive CTL/ATL from \(activities.count) activities...")
        
        var result: [Date: (ctl: Double, atl: Double)] = [:]
        let calendar = Calendar.current
        
        // Group activities by date and sum TSS
        var dailyTSS: [Date: Double] = [:]
        for activity in activities {
            guard let tss = activity.tss, tss > 0 else { continue }
            guard let activityDate = parseActivityDate(activity.startDateLocal) else { continue }
            
            let day = calendar.startOfDay(for: activityDate)
            dailyTSS[day, default: 0] += tss
        }
        
        Logger.data("📊 Found \(dailyTSS.count) days with TSS data for progressive calculation")
        
        // Get sorted dates
        let sortedDates = dailyTSS.keys.sorted()
        guard !sortedDates.isEmpty else {
            Logger.data("📊 No TSS data found - returning empty progressive load")
            return result
        }
        
        Logger.data("📊 Date range with TSS: \(sortedDates.first!.description) to \(sortedDates.last!.description)")
        Logger.data("📊 Daily TSS values: \(dailyTSS.map { "\(calendar.startOfDay(for: $0.key)): \(String(format: "%.0f", $0.value))" }.sorted().joined(separator: ", "))")
        
        // Calculate CTL/ATL progressively using incremental EMA formula
        // EMA_today = (value_today × alpha) + (EMA_yesterday × (1 - alpha))
        // where alpha = 2 / (N + 1)
        
        let ctlAlpha = 2.0 / 43.0  // 42-day time constant
        let atlAlpha = 2.0 / 8.0   // 7-day time constant
        
        // Estimate starting CTL/ATL based on early training pattern
        // This prevents "cold start" problem where we reset fitness to zero
        
        // Look at first 2 weeks of activity to establish baseline
        let firstTwoWeeks = sortedDates.prefix(min(14, sortedDates.count))
        let totalTSS = firstTwoWeeks.compactMap { dailyTSS[$0] }.reduce(0.0, +)
        let activityCount = firstTwoWeeks.count
        
        // Calculate average TSS per activity day
        let avgTSSPerActivity = totalTSS / Double(max(1, activityCount))
        
        // Estimate CTL: assume training at this level for ~42 days
        // CTL represents accumulated fitness, so use a multiplier
        // At steady state with 3-4 activities/week: CTL ≈ avgTSS * ~0.7
        var currentCTL = avgTSSPerActivity * 0.7
        
        // ATL represents recent fatigue (7-day window)
        // Start lower than CTL since it's a shorter window
        var currentATL = avgTSSPerActivity * 0.4
        
        Logger.data("📊 Baseline estimate from \(activityCount) early activities (avg TSS=\(String(format: "%.1f", avgTSSPerActivity))): CTL=\(String(format: "%.1f", currentCTL)), ATL=\(String(format: "%.1f", currentATL))")
        
        // Start from earliest date in data
        let startDate = sortedDates.first!
        let today = calendar.startOfDay(for: Date())
        
        Logger.data("📊 Calculating from \(startDate) to \(today) (\(calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) days)")
        
        // Build progressive history using incremental EMA
        var currentDate = startDate
        
        while currentDate <= today {
            let tss = dailyTSS[currentDate] ?? 0
            
            // Incremental EMA update
            currentCTL = (tss * ctlAlpha) + (currentCTL * (1 - ctlAlpha))
            currentATL = (tss * atlAlpha) + (currentATL * (1 - atlAlpha))
            
            // Store for this date
            result[currentDate] = (currentCTL, currentATL)
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        Logger.data("📊 Progressive calculation complete: \(result.count) dates with CTL/ATL")
        
        // Log last 5 dates for verification
        let lastDates = result.keys.sorted().suffix(5)
        for date in lastDates {
            if let load = result[date] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                Logger.data("  \(dateFormatter.string(from: date)): CTL=\(String(format: "%.1f", load.ctl)), ATL=\(String(format: "%.1f", load.atl))")
            }
        }
        
        return result
    }
    
    /// Get daily TSS values from activities
    /// - Parameter activities: Array of activities with TSS values
    /// - Returns: Dictionary mapping dates to total TSS for that day
    func getDailyTSSFromActivities(_ activities: [IntervalsActivity]) -> [Date: Double] {
        var dailyTSS: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for activity in activities {
            guard let tss = activity.tss, tss > 0 else { continue }
            guard let activityDate = parseActivityDate(activity.startDateLocal) else { continue }
            
            let day = calendar.startOfDay(for: activityDate)
            dailyTSS[day, default: 0] += tss
        }
        
        return dailyTSS
    }
    
    /// Calculate progressive training load from HealthKit workouts
    /// Uses TRIMP as TSS equivalent for non-power activities
    /// - Returns: Dictionary mapping dates to (ctl, atl, tss) tuples
    func calculateProgressiveTrainingLoadFromHealthKit() async -> [Date: (ctl: Double, atl: Double, tss: Double)] {
        Logger.data("📊 Calculating progressive load from HealthKit workouts...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!
        
        // Fetch all workouts in range
        let workouts = await healthKitManager.fetchWorkouts(
            from: startDate,
            to: Date(),
            activityTypes: [.cycling, .running, .swimming, .walking, .functionalStrengthTraining, .traditionalStrengthTraining, .hiking, .rowing, .other]
        )
        
        Logger.data("📊 Found \(workouts.count) HealthKit workouts to analyze")
        
        // Calculate daily TRIMP (use as TSS equivalent)
        var dailyTRIMP: [Date: Double] = [:]
        
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.startDate)
            let trimp = await trimpCalculator.calculateTRIMP(for: workout)
            dailyTRIMP[day, default: 0] += trimp
        }
        
        Logger.data("📊 Found \(dailyTRIMP.count) days with TRIMP data")
        
        // Get sorted dates
        let sortedDates = dailyTRIMP.keys.sorted()
        guard !sortedDates.isEmpty else {
            Logger.data("📊 No TRIMP data found - returning empty progressive load")
            return [:]
        }
        
        // Calculate baseline from early activities
        let firstTwoWeeks = sortedDates.prefix(min(14, sortedDates.count))
        let totalTRIMP = firstTwoWeeks.compactMap { dailyTRIMP[$0] }.reduce(0.0, +)
        let activityCount = firstTwoWeeks.count
        let avgTRIMPPerActivity = totalTRIMP / Double(max(1, activityCount))
        
        var currentCTL = avgTRIMPPerActivity * 0.7
        var currentATL = avgTRIMPPerActivity * 0.4
        
        Logger.data("📊 Baseline from \(activityCount) activities (avg TRIMP=\(String(format: "%.1f", avgTRIMPPerActivity))): CTL=\(String(format: "%.1f", currentCTL)), ATL=\(String(format: "%.1f", currentATL))")
        
        // Progressive calculation
        let ctlAlpha = 2.0 / 43.0
        let atlAlpha = 2.0 / 8.0
        
        var result: [Date: (ctl: Double, atl: Double, tss: Double)] = [:]
        var currentDate = sortedDates.first!
        
        while currentDate <= today {
            let trimp = dailyTRIMP[currentDate] ?? 0
            
            // Incremental EMA update
            currentCTL = (trimp * ctlAlpha) + (currentCTL * (1 - ctlAlpha))
            currentATL = (trimp * atlAlpha) + (currentATL * (1 - atlAlpha))
            
            // Store with TRIMP as TSS equivalent
            result[currentDate] = (ctl: currentCTL, atl: currentATL, tss: trimp)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        Logger.data("📊 Progressive HealthKit calculation complete: \(result.count) dates")
        
        return result
    }
    
    /// Parse activity date string
    /// Handles both Intervals.icu format (no timezone) and Strava format (with 'Z')
    private func parseActivityDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
    
    /// Calculate current CTL and ATL from HealthKit workouts
    /// - Returns: Tuple of (ctl, atl) or nil if insufficient data
    func calculateTrainingLoad() async -> (ctl: Double, atl: Double) {
        // Check cache first (1 hour TTL)
        if let cached = cachedTrainingLoad,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpiryInterval {
            let age = Int(Date().timeIntervalSince(timestamp) / 60)
            Logger.debug("⚡ [Training Load] Using cached values (age: \(age)m) - CTL: \(String(format: "%.1f", cached.ctl)), ATL: \(String(format: "%.1f", cached.atl))")
            return cached
        }
        
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
        
        // Cache the result
        cachedTrainingLoad = (ctl, atl)
        cacheTimestamp = Date()
        Logger.debug("💾 [Training Load] Cached for 1 hour")
        
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
