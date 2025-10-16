import Foundation
import HealthKit

/// Service for calculating daily strain scores using Whoop-like algorithm
@MainActor
class StrainScoreService: ObservableObject {
    static let shared = StrainScoreService()
    
    @Published var currentStrainScore: StrainScore?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private let intervalsAPIClient: IntervalsAPIClient
    private let intervalsCache = IntervalsCache.shared
    private let userSettings = UserSettings.shared
    private let sleepScoreService = SleepScoreService.shared
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    // Persistent caching
    private let userDefaults = UserDefaults.standard
    private let cachedStrainScoreKey = "cachedStrainScore"
    private let cachedStrainScoreDateKey = "cachedStrainScoreDate"
    
    init() {
        self.intervalsAPIClient = IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared)
        
        // Load cached strain score immediately for instant display
        loadCachedStrainScore()
    }
    
    /// Calculate today's strain score
    func calculateStrainScore() async {
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation()
        }
        
        await calculationTask?.value
    }
    
    private func performCalculation() async {
        Logger.debug("🔄 Starting strain score calculation")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            Logger.warning("️ Strain score calculation already in progress, skipping...")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Add timeout to prevent hanging
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
            throw CancellationError()
        }
        
        let calculationTask = Task {
            await performActualCalculation()
        }
        
        do {
            _ = try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await timeoutTask.value }
                group.addTask { await calculationTask.value }
                
                // Wait for first task to complete (either timeout or calculation)
                try await group.next()
                
                // Cancel the other task
                timeoutTask.cancel()
                calculationTask.cancel()
            }
            
            Logger.debug("✅ Strain score calculation completed successfully")
        } catch {
            if error is CancellationError {
                Logger.debug("⏰ Strain score calculation timed out after 15 seconds")
                errorMessage = "Calculation timed out. Please try again."
            } else {
                Logger.error("Strain score calculation error: \(error)")
                errorMessage = "Calculation failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func performActualCalculation() async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let stepStatus = healthKitManager.getAuthorizationStatus(for: stepType)
        
        if stepStatus == .sharingDenied {
            Logger.error("Strain permissions explicitly denied - skipping calculation")
            await MainActor.run {
                currentStrainScore = nil
                isLoading = false
            }
            return
        }
        
        // Use real data
        let realScore = await calculateRealStrainScore()
        currentStrainScore = realScore
        
        // Save to persistent cache for instant loading next time
        if let score = currentStrainScore {
            saveStrainScoreToCache(score)
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealStrainScore() async -> StrainScore? {
        // Ensure sleep score is calculated first for recovery modulation
        await sleepScoreService.calculateSleepScore()
        
        // Get health data
        async let steps = fetchDailySteps()
        async let activeCalories = fetchDailyActiveCalories()
        async let hrv = healthKitManager.fetchLatestHRVData()
        async let rhr = healthKitManager.fetchLatestRHRData()
        async let baselines = baselineCalculator.calculateAllBaselines()
        
        // Get training loads (from Intervals or HealthKit)
        async let trainingLoadData = fetchTrainingLoads()
        
        // Get today's workouts from ALL sources (HealthKit, Intervals.icu, Strava)
        async let todaysWorkouts = fetchTodaysWorkouts()
        async let todaysActivities = fetchTodaysUnifiedActivities()
        
        let (hrvValue, rhrValue) = await (hrv, rhr)
        let (stepsValue, activeCaloriesValue) = await (steps, activeCalories)
        let (hrvBaseline, rhrBaseline, _, _) = await baselines
        let trainingLoads = await trainingLoadData
        let workouts = await todaysWorkouts
        let unifiedActivities = await todaysActivities
        
        // Calculate TRIMP from today's HealthKit workouts + unified activities (Intervals/Strava)
        let healthKitTRIMP = await calculateTRIMPFromWorkouts(workouts: workouts)
        let unifiedTRIMP = calculateTRIMPFromStravaActivities(activities: unifiedActivities)
        let cardioTRIMP = healthKitTRIMP + unifiedTRIMP
        
        // BUG FIX: Include HealthKit AND unified activities (Intervals.icu + Strava)
        let healthKitDuration = workouts.reduce(0.0) { $0 + $1.duration }
        let unifiedDuration = unifiedActivities.reduce(0.0) { $0 + ($1.duration ?? 0) }
        let cardioDuration = healthKitDuration + unifiedDuration
        
        Logger.debug("   HealthKit Duration: \(Int(healthKitDuration/60))min")
        Logger.debug("   Intervals/Strava Duration: \(Int(unifiedDuration/60))min")
        Logger.debug("   Total Cardio Duration: \(Int(cardioDuration/60))min")
        
        let averageIF: Double? = nil // Not available from HealthKit alone
        
        // Collect workout types for activity differentiation
        let workoutTypes = workouts.map { workout -> String in
            switch workout.workoutActivityType {
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .swimming: return "Swimming"
            case .walking: return "Walking"
            case .hiking: return "Hiking"
            case .rowing: return "Rowing"
            default: return "Other"
            }
        }
        
        // Detect strength workouts and get RPE
        let strengthWorkouts = workouts.filter {
            $0.workoutActivityType == .traditionalStrengthTraining ||
            $0.workoutActivityType == .functionalStrengthTraining
        }
        let strengthDuration = strengthWorkouts.reduce(0.0) { $0 + $1.duration }
        
        // Get RPE and muscle groups from storage for strength workouts (use first if multiple)
        var strengthRPE: Double? = nil
        var muscleGroupsTrained: [MuscleGroup]? = nil
        if let firstStrength = strengthWorkouts.first {
            strengthRPE = WorkoutMetadataService.shared.getRPE(for: firstStrength)
            muscleGroupsTrained = WorkoutMetadataService.shared.getMuscleGroups(for: firstStrength)
        }
        
        Logger.debug("🔍 Strain Score Inputs:")
        Logger.debug("   Steps: \(stepsValue ?? 0)")
        Logger.debug("   Active Calories: \(activeCaloriesValue ?? 0)")
        Logger.debug("   Cardio TRIMP: \(cardioTRIMP)")
        Logger.debug("   Cardio Duration: \(cardioDuration)s")
        Logger.debug("   Workout Types: \(workoutTypes)")
        Logger.debug("   Strength Duration: \(strengthDuration / 60)min")
        Logger.debug("   Strength RPE: \(strengthRPE != nil ? String(format: "%.1f", strengthRPE!) : "nil (using default 6.5)")")
        if let muscleGroups = muscleGroupsTrained {
            Logger.debug("   Muscle Groups: \(muscleGroups.map { $0.rawValue }.joined(separator: ", "))")
        }
        Logger.debug("   Average IF: \(averageIF ?? 0.0)")
        Logger.debug("   Sleep Score: \(sleepScoreService.currentSleepScore?.score ?? -1)")
        if let hrvSample = hrvValue.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) {
            Logger.debug("   HRV: \(hrvSample) ms")
        } else {
            Logger.debug("   HRV: nil")
        }
        Logger.debug("   Recovery Factor: \((trainingLoads.atl, trainingLoads.ctl))")
        
        // Create inputs
        let inputs = StrainScore.StrainInputs(
            continuousHRData: nil, // TODO: Implement continuous HR data collection
            dailyTRIMP: nil, // TODO: Calculate from continuous HR data
            cardioDailyTRIMP: cardioTRIMP,
            cardioDurationMinutes: cardioDuration > 0 ? cardioDuration / 60 : nil,
            averageIntensityFactor: averageIF,
            workoutTypes: workoutTypes.isEmpty ? nil : workoutTypes,
            strengthSessionRPE: strengthRPE,
            strengthDurationMinutes: strengthDuration > 0 ? strengthDuration / 60 : nil,
            strengthVolume: nil,
            strengthSets: nil,
            muscleGroupsTrained: muscleGroupsTrained,
            isEccentricFocused: nil, // TODO: Add eccentric focus flag to UI
            dailySteps: stepsValue,
            activeEnergyCalories: activeCaloriesValue,
            nonWorkoutMETmin: nil,
            hrvOvernight: hrvValue.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
            hrvBaseline: hrvBaseline,
            rmrToday: rhrValue.sample?.quantity.doubleValue(for: HKUnit(from: "count/min")),
            rmrBaseline: rhrBaseline,
            sleepQuality: sleepScoreService.currentSleepScore?.score,
            userFTP: getUserFTP(),
            userMaxHR: getUserMaxHR(),
            userRestingHR: getUserRestingHR(),
            userBodyMass: getUserBodyMass()
        )
        
        let result = StrainScoreCalculator.calculate(inputs: inputs)
        Logger.debug("🔍 Strain Score Result:")
        Logger.debug("   Final Score: \(result.score)")
        Logger.debug("   Band: \(result.band.rawValue)")
        Logger.debug("   Sub-scores: Cardio=\(result.subScores.cardioLoad), Strength=\(result.subScores.strengthLoad), Activity=\(result.subScores.nonExerciseLoad)")
        Logger.debug("   Recovery Factor: \(String(format: "%.2f", result.subScores.recoveryFactor))")
        return result
    }
    
    // MARK: - Data Fetching
    
    private func fetchDailySteps() async -> Int? {
        guard healthKitManager.isAuthorized else { return nil }
        
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
            
            HKHealthStore().execute(query)
        }
    }
    
    private func fetchDailyActiveCalories() async -> Double? {
        guard healthKitManager.isAuthorized else { return nil }
        
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
            
            HKHealthStore().execute(query)
        }
    }
    
    /// Fetch training loads (CTL/ATL) from Intervals.icu or HealthKit
    private func fetchTrainingLoads() async -> (atl: Double?, ctl: Double?) {
        do {
            // Try Intervals.icu first (if available)
            let activities = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: false)
            
            if let latestActivity = activities.first {
                Logger.data("Using Intervals.icu training loads: ATL=\(latestActivity.atl?.description ?? "nil"), CTL=\(latestActivity.ctl?.description ?? "nil")")
                return (latestActivity.atl, latestActivity.ctl)
            } else {
                Logger.warning("️ No Intervals.icu data, calculating from HealthKit")
                return await calculateTrainingLoadsFromHealthKit()
            }
        } catch {
            Logger.error("Intervals.icu not available: \(error)")
            Logger.warning("️ Calculating training loads from HealthKit")
            return await calculateTrainingLoadsFromHealthKit()
        }
    }
    
    /// Fetch today's workouts from HealthKit
    private func fetchTodaysWorkouts() async -> [HKWorkout] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let workouts = await healthKitManager.fetchWorkouts(
            from: today,
            to: tomorrow,
            activityTypes: [.cycling, .running, .swimming, .walking, .functionalStrengthTraining, .traditionalStrengthTraining, .hiking, .rowing, .other]
        )
        
        Logger.debug("🔍 Found \(workouts.count) HealthKit workouts for today")
        return workouts
    }
    
    /// Fetch today's activities from unified service (Intervals.icu OR Strava)
    /// This ensures we get activities regardless of which service the user has connected
    private func fetchTodaysUnifiedActivities() async -> [IntervalsActivity] {
        do {
            // Use UnifiedActivityService to get today's activities from any source
            let activities = try await UnifiedActivityService.shared.fetchTodaysActivities()
            Logger.debug("🔍 Found \(activities.count) unified activities for today (Intervals.icu or Strava)")
            return activities
        } catch {
            Logger.warning("⚠️ Failed to fetch unified activities: \(error)")
            return []
        }
    }
    
    /// Calculate TRIMP from Strava activities
    private func calculateTRIMPFromStravaActivities(activities: [IntervalsActivity]) -> Double {
        var totalTRIMP: Double = 0
        
        for activity in activities {
            // Use TSS if available (best for cycling)
            if let tss = activity.tss {
                totalTRIMP += tss
                Logger.debug("   Strava Activity: \(activity.name ?? "Unknown") - TSS: \(String(format: "%.1f", tss))")
                continue
            }
            
            // Fallback: Estimate from power/HR
            if let avgPower = activity.averagePower,
               let duration = activity.duration,
               let ftp = getUserFTP() {
                let intensityFactor = avgPower / ftp
                let estimatedTSS = (duration / 3600) * intensityFactor * intensityFactor * 100
                totalTRIMP += estimatedTSS
                Logger.debug("   Strava Activity: \(activity.name ?? "Unknown") - Estimated TSS: \(String(format: "%.1f", estimatedTSS))")
                continue
            }
            
            // Last resort: Estimate from HR if available
            if let avgHR = activity.averageHeartRate,
               let duration = activity.duration,
               let maxHR = getUserMaxHR(),
               let restingHR = getUserRestingHR() {
                let hrReserve = maxHR - restingHR
                let workingHR = avgHR - restingHR
                let percentHRR = workingHR / hrReserve
                let trimp = (duration / 60) * percentHRR * 0.64 * exp(1.92 * percentHRR)
                totalTRIMP += trimp
                Logger.debug("   Strava Activity: \(activity.name ?? "Unknown") - HR-based TRIMP: \(String(format: "%.1f", trimp))")
            }
        }
        
        Logger.debug("🔍 Total TRIMP from \(activities.count) Strava activities: \(String(format: "%.1f", totalTRIMP))")
        return totalTRIMP
    }
    
    /// Calculate training loads from HealthKit (fallback)
    private func calculateTrainingLoadsFromHealthKit() async -> (atl: Double?, ctl: Double?) {
        let calculator = TrainingLoadCalculator()
        let (ctl, atl) = await calculator.calculateTrainingLoad()
        return (atl, ctl)
    }
    
    /// Calculate TRIMP from HealthKit workouts
    private func calculateTRIMPFromWorkouts(workouts: [HKWorkout]) async -> Double {
        let calculator = TRIMPCalculator()
        var totalTRIMP: Double = 0
        
        for workout in workouts {
            let trimp = await calculator.calculateTRIMP(for: workout)
            totalTRIMP += trimp
            
            let activityName: String
            switch workout.workoutActivityType {
            case .cycling: activityName = "Cycling"
            case .running: activityName = "Running"
            case .swimming: activityName = "Swimming"
            case .walking: activityName = "Walking"
            case .functionalStrengthTraining: activityName = "Strength"
            case .rowing: activityName = "Rowing"
            case .hiking: activityName = "Hiking"
            default: activityName = "Other"
            }
            
            Logger.debug("   Workout: \(activityName) - TRIMP: \(String(format: "%.1f", trimp))")
        }
        
        Logger.debug("🔍 Total TRIMP from \(workouts.count) workouts: \(String(format: "%.1f", totalTRIMP))")
        return totalTRIMP
    }
    
    // MARK: - TRIMP Calculation
    
    private func calculateTRIMPFromActivities(activities: [IntervalsActivity]) -> Double {
        var totalTRIMP: Double = 0
        
        for activity in activities {
            Logger.debug("🔍 Processing activity '\(activity.name ?? "Unknown")' for TRIMP:")
            
            // First try to use TSS (Training Stress Score) if available
            // TSS is a better metric for cycling and is directly comparable to TRIMP
            if let tss = activity.tss, tss > 0 {
                Logger.debug("   ✅ Using TSS: \(tss)")
                totalTRIMP += tss
                continue
            }
            
            // Fall back to HR-based TRIMP if TSS not available
            if let duration = activity.duration,
               let avgHR = activity.averageHeartRate,
               duration > 0 {
                
                // Simple TRIMP calculation based on average HR
                // This is a simplified version - ideally you'd have HR time series data
                let durationMinutes = duration / 60
                let hrReserve = calculateHeartRateReserve(averageHR: avgHR)
                let trimpForActivity = durationMinutes * hrReserve
                
                Logger.debug("   ✅ Using HR-based TRIMP: \(trimpForActivity) (duration: \(durationMinutes)m, avgHR: \(avgHR))")
                totalTRIMP += trimpForActivity
            } else {
                Logger.debug("   ⚠️ No TSS or HR data available, skipping activity")
            }
        }
        
        Logger.debug("🔍 Total TRIMP from activities: \(totalTRIMP)")
        return totalTRIMP
    }
    
    private func calculateHeartRateReserve(averageHR: Double) -> Double {
        let restingHR = getUserRestingHR() ?? 60
        let maxHR = getUserMaxHR() ?? 180
        
        guard maxHR > restingHR else { return 0 }
        
        let hrReserve = (averageHR - restingHR) / (maxHR - restingHR)
        return max(0, min(1, hrReserve))
    }
    
    private func calculateAverageIntensityFactor(activities: [IntervalsActivity]) -> Double? {
        let activitiesWithIF = activities.compactMap { activity in
            activity.intensityFactor
        }
        
        guard !activitiesWithIF.isEmpty else { return nil }
        
        return activitiesWithIF.reduce(0, +) / Double(activitiesWithIF.count)
    }
    
    // MARK: - Helper Methods
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 first (with timezone)
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try local format without timezone (2025-10-02T06:11:37)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    // MARK: - User Settings Helpers
    
    private func getUserFTP() -> Double? {
        // Default FTP for testing - should be configurable
        return 250.0
    }
    
    private func getUserMaxHR() -> Double? {
        // Default max HR for testing - should be configurable
        return 180.0
    }
    
    private func getUserRestingHR() -> Double? {
        // Default resting HR for testing - should be configurable
        return 55.0
    }
    
    private func getUserBodyMass() -> Double? {
        // Default body mass for testing - should be configurable
        return 75.0
    }
}

// MARK: - Persistent Caching Extension

extension StrainScoreService {
    
    /// Load cached strain score for instant display
    private func loadCachedStrainScore() {
        guard let cachedData = userDefaults.data(forKey: cachedStrainScoreKey),
              let cachedDate = userDefaults.object(forKey: cachedStrainScoreDateKey) as? Date else {
            Logger.debug("📦 No cached strain score found")
            return
        }
        
        // Check if cache is from today
        let calendar = Calendar.current
        if calendar.isDate(cachedDate, inSameDayAs: Date()) {
            do {
                let decoder = JSONDecoder()
                let cachedScore = try decoder.decode(StrainScore.self, from: cachedData)
                currentStrainScore = cachedScore
                Logger.debug("⚡ Loaded cached strain score: \(cachedScore.score)")
            } catch {
                Logger.error("Failed to decode cached strain score: \(error)")
                Logger.warning("️ Clearing invalid cache - will recalculate")
                clearCachedStrainScore()
            }
        } else {
            Logger.debug("📦 Cached strain score is outdated, clearing cache")
            clearCachedStrainScore()
        }
    }
    
    /// Save strain score to persistent cache
    private func saveStrainScoreToCache(_ score: StrainScore) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(score)
            userDefaults.set(data, forKey: cachedStrainScoreKey)
            userDefaults.set(Date(), forKey: cachedStrainScoreDateKey)
            Logger.debug("💾 Saved strain score to cache: \(score.score)")
        } catch {
            Logger.error("Failed to save strain score to cache: \(error)")
        }
    }
    
    /// Clear cached strain score
    private func clearCachedStrainScore() {
        userDefaults.removeObject(forKey: cachedStrainScoreKey)
        userDefaults.removeObject(forKey: cachedStrainScoreDateKey)
    }
}
