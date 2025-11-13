import Foundation
import HealthKit

/// Actor for strain score data aggregation and calculation
/// Performs heavy data fetching and coordinates with existing StrainScoreCalculator
actor StrainDataCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private let trimpCalculator = TRIMPCalculator()
    private let trainingLoadCalculator = TrainingLoadCalculator()
    
    // MARK: - Main Calculation
    
    func calculateStrainScore(
        sleepScore: SleepScore?,
        ftp: Double?,
        maxHeartRate: Double?,
        restingHeartRate: Double?,
        bodyMass: Double?
    ) async -> StrainScore? {
        // Get health data (now cached in HealthKitManager)
        async let steps = healthKitManager.fetchDailySteps()
        async let activeCalories = healthKitManager.fetchDailyActiveCalories()
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
        let unifiedTRIMP = calculateTRIMPFromStravaActivities(activities: unifiedActivities, ftp: ftp, maxHR: maxHeartRate, restingHR: restingHeartRate)
        let cardioTRIMP = healthKitTRIMP + unifiedTRIMP
        
        // Include HealthKit AND unified activities (Intervals.icu + Strava)
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
            strengthRPE = await WorkoutMetadataService.shared.getRPE(for: firstStrength)
            muscleGroupsTrained = await WorkoutMetadataService.shared.getMuscleGroups(for: firstStrength)
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
        Logger.debug("   Sleep Score: \(sleepScore?.score ?? -1)")
        if let hrvSample = hrvValue.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) {
            Logger.debug("   HRV: \(hrvSample) ms")
        } else {
            Logger.debug("   HRV: nil")
        }
        Logger.debug("   Recovery Factor: \((trainingLoads.atl, trainingLoads.ctl))")
        
        // Create inputs
        let inputs = StrainScore.StrainInputs(
            continuousHRData: nil,
            dailyTRIMP: nil,
            cardioDailyTRIMP: cardioTRIMP,
            cardioDurationMinutes: cardioDuration > 0 ? cardioDuration / 60 : nil,
            averageIntensityFactor: averageIF,
            workoutTypes: workoutTypes.isEmpty ? nil : workoutTypes,
            strengthSessionRPE: strengthRPE,
            strengthDurationMinutes: strengthDuration > 0 ? strengthDuration / 60 : nil,
            strengthVolume: nil,
            strengthSets: nil,
            muscleGroupsTrained: muscleGroupsTrained,
            isEccentricFocused: nil,
            dailySteps: stepsValue,
            activeEnergyCalories: activeCaloriesValue,
            nonWorkoutMETmin: nil,
            hrvOvernight: hrvValue.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
            hrvBaseline: hrvBaseline,
            rmrToday: rhrValue.sample?.quantity.doubleValue(for: HKUnit(from: "count/min")),
            rmrBaseline: rhrBaseline,
            sleepQuality: sleepScore?.score,
            userFTP: ftp,
            userMaxHR: maxHeartRate,
            userRestingHR: restingHeartRate,
            userBodyMass: bodyMass
        )
        
        // Delegate to existing StrainScoreCalculator for final calculation
        let result = StrainScoreCalculator.calculate(inputs: inputs)
        Logger.debug("🔍 Strain Score Result:")
        Logger.debug("   Final Score: \(result.score)")
        Logger.debug("   Band: \(result.band.rawValue)")
        Logger.debug("   Sub-scores: Cardio=\(result.subScores.cardioLoad), Strength=\(result.subScores.strengthLoad), Activity=\(result.subScores.nonExerciseLoad)")
        Logger.debug("   Recovery Factor: \(String(format: "%.2f", result.subScores.recoveryFactor))")
        return result
    }
    
    // MARK: - Data Fetching
    
    private func fetchTrainingLoads() async -> (atl: Double?, ctl: Double?) {
        do {
            // Try Intervals.icu first (if available)
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
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
    
    private func fetchTodaysUnifiedActivities() async -> [Activity] {
        do {
            let activities = try await UnifiedActivityService.shared.fetchTodaysActivities()
            Logger.debug("🔍 Found \(activities.count) unified activities for today (Intervals.icu or Strava)")
            
            Logger.info("💓 [ENRICHMENT] Starting enrichment for \(activities.count) activities...")
            // Enrich activities with HR from streams if needed (30-day window only)
            let enriched = await enrichActivitiesWithHeartRate(activities)
            Logger.info("💓 [ENRICHMENT] Enrichment complete - returning \(enriched.count) activities")
            return enriched
        } catch {
            Logger.warning("⚠️ Failed to fetch unified activities: \(error)")
            return []
        }
    }
    
    /// Enrich activities with HR from streams when summary data is missing
    /// Only enriches activities from the last 30 days to limit API calls
    private func enrichActivitiesWithHeartRate(_ activities: [Activity]) async -> [Activity] {
        var enrichedActivities = activities
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        
        Logger.info("💓 [ENRICHMENT] Processing \(activities.count) activities (30-day window)")
        
        for (index, activity) in activities.enumerated() {
            Logger.debug("💓 [ENRICHMENT] Activity \(index + 1): '\(activity.name ?? "Unknown")' - avgHR: \(activity.averageHeartRate?.description ?? "nil"), enrichedHR: \(activity.enrichedAverageHeartRate?.description ?? "nil"), TSS: \(activity.tss?.description ?? "nil"), NP: \(activity.normalizedPower?.description ?? "nil")")
            
            // Skip if activity already has HR data (from summary or previous enrichment)
            if activity.averageHeartRate != nil || activity.enrichedAverageHeartRate != nil {
                Logger.debug("   ⏭️ Skipping '\(activity.name ?? "Unknown")' - already has HR")
                continue
            }
            
            // Skip if activity has TSS or power (don't need HR)
            if activity.tss != nil || activity.normalizedPower != nil {
                Logger.debug("   ⏭️ Skipping '\(activity.name ?? "Unknown")' - has TSS or power")
                continue
            }
            
            // Skip if activity doesn't have duration
            guard let duration = activity.duration, duration > 0 else {
                Logger.debug("   ⏭️ Skipping '\(activity.name ?? "Unknown")' - no duration")
                continue
            }
            
            // Only enrich recent activities (30-day window)
            guard let activityDate = parseActivityDate(activity.startDateLocal),
                  activityDate >= thirtyDaysAgo else {
                Logger.debug("   ⏭️ Skipping enrichment for '\(activity.name ?? "Unknown")' - older than 30 days")
                continue
            }
            
            Logger.info("💓 [ENRICHMENT] Fetching streams for '\(activity.name ?? "Unknown")' (ID: \(activity.id))...")
            // Fetch HR from streams
            if let avgHR = await fetchHeartRateFromStreams(activityId: activity.id, source: activity.source) {
                Logger.info("💓 Enriched '\(activity.name ?? "Unknown")' with HR from streams: \(Int(avgHR)) bpm")
                enrichedActivities[index].enrichedAverageHeartRate = avgHR
            } else {
                Logger.warning("   ⚠️ Could not enrich '\(activity.name ?? "Unknown")' - no HR data in streams")
            }
        }
        
        Logger.info("💓 [ENRICHMENT] Finished processing - \(enrichedActivities.filter { $0.enrichedAverageHeartRate != nil }.count) activities enriched")
        return enrichedActivities
    }
    
    /// Fetch heart rate data from activity streams and calculate average
    /// Returns nil if streams are unavailable or contain no HR data
    private func fetchHeartRateFromStreams(activityId: String, source: String?) async -> Double? {
        // Determine data source (default to Strava)
        let dataSource: APIDataSource = (source?.lowercased() == "intervals.icu") ? .intervals : .strava
        
        do {
            // Fetch streams from backend (cached for 7 days in Netlify Blobs)
            let streams = try await VeloReadyAPIClient.shared.fetchActivityStreams(
                activityId: activityId,
                source: dataSource
            )
            
            // Extract heartrate stream
            guard let hrStream = streams["heartrate"] else {
                Logger.debug("   ⚠️ No heartrate stream found for activity \(activityId)")
                return nil
            }
            
            // Extract HR values from StreamDataRaw enum
            let hrValues: [Double]
            switch hrStream.data {
            case .simple(let values):
                hrValues = values
            case .latlng:
                Logger.debug("   ⚠️ Unexpected latlng format for heartrate stream")
                return nil
            }
            
            guard !hrValues.isEmpty else {
                Logger.debug("   ⚠️ Heartrate stream is empty for activity \(activityId)")
                return nil
            }
            
            // Filter out invalid values (0 or negative)
            let validHRValues = hrValues.filter { $0 > 0 }
            
            guard !validHRValues.isEmpty else {
                Logger.debug("   ⚠️ No valid HR data in stream for activity \(activityId)")
                return nil
            }
            
            let averageHR = validHRValues.reduce(0, +) / Double(validHRValues.count)
            Logger.debug("   ✅ Calculated average HR from stream: \(Int(averageHR)) bpm (from \(validHRValues.count) samples)")
            
            return averageHR
        } catch {
            Logger.warning("⚠️ Failed to fetch streams for activity \(activityId): \(error)")
            return nil
        }
    }
    
    /// Parse activity date from ISO8601 string
    private func parseActivityDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }()
    }
    
    private func calculateTRIMPFromStravaActivities(activities: [Activity], ftp: Double?, maxHR: Double?, restingHR: Double?) -> Double {
        var totalTRIMP: Double = 0
        
        for activity in activities {
            // Priority 1: Use power data if available
            if let np = activity.normalizedPower,
               let duration = activity.duration,
               let ftpValue = ftp,
               np > 0, ftpValue > 0 {
                let intensityFactor = np / ftpValue
                let estimatedTSS = (duration / 3600) * intensityFactor * intensityFactor * 100
                totalTRIMP += estimatedTSS
                Logger.debug("   Activity: \(activity.name ?? "Unknown") - Power-based TSS: \(String(format: "%.1f", estimatedTSS))")
                continue
            }
            
            // Priority 2: Use pre-calculated TSS
            if let tss = activity.tss {
                totalTRIMP += tss
                Logger.debug("   Activity: \(activity.name ?? "Unknown") - Pre-calculated TSS: \(String(format: "%.1f", tss))")
                continue
            }
            
            // Priority 3: Estimate from HR (summary data)
            if let avgHR = activity.averageHeartRate,
               let duration = activity.duration,
               let maxHRValue = maxHR,
               let restingHRValue = restingHR {
                let hrReserve = maxHRValue - restingHRValue
                let workingHR = avgHR - restingHRValue
                let percentHRR = workingHR / hrReserve
                let trimp = (duration / 60) * percentHRR * 0.64 * exp(1.92 * percentHRR)
                totalTRIMP += trimp
                Logger.debug("   Activity: \(activity.name ?? "Unknown") - HR-based TRIMP (summary): \(String(format: "%.1f", trimp))")
            } else if let enrichedHR = activity.enrichedAverageHeartRate,
                      let duration = activity.duration,
                      let maxHRValue = maxHR,
                      let restingHRValue = restingHR {
                // Priority 3.5: Estimate from enriched HR (calculated from streams)
                let hrReserve = maxHRValue - restingHRValue
                let workingHR = enrichedHR - restingHRValue
                let percentHRR = workingHR / hrReserve
                let trimp = (duration / 60) * percentHRR * 0.64 * exp(1.92 * percentHRR)
                totalTRIMP += trimp
                Logger.info("   Activity: \(activity.name ?? "Unknown") - HR-based TRIMP (enriched from streams): \(String(format: "%.1f", trimp))")
            } else if let duration = activity.duration, duration > 0 {
                // Priority 4: FALLBACK - Estimate from duration alone (for activities without HR/power data)
                // This handles cases where stream enrichment failed or activity is older than 30 days
                // Use moderate intensity assumption (HR reserve ~0.6)
                let durationMinutes = duration / 60
                let estimatedHRReserve = 0.6  // Moderate intensity
                let estimatedTRIMP = durationMinutes * estimatedHRReserve
                totalTRIMP += estimatedTRIMP
                Logger.debug("   Activity: \(activity.name ?? "Unknown") - Duration-based estimate: \(String(format: "%.1f", estimatedTRIMP)) (duration: \(String(format: "%.1f", durationMinutes))m)")
            } else {
                Logger.debug("   Activity: \(activity.name ?? "Unknown") - NO DATA, skipping (duration: \(activity.duration == nil ? "nil" : "\(activity.duration!)s"), avgHR: \(activity.averageHeartRate == nil ? "nil" : "\(activity.averageHeartRate!)"))")
            }
        }
        
        Logger.debug("🔍 Total TRIMP from \(activities.count) unified activities: \(String(format: "%.1f", totalTRIMP))")
        return totalTRIMP
    }
    
    private func calculateTrainingLoadsFromHealthKit() async -> (atl: Double?, ctl: Double?) {
        let (ctl, atl) = await trainingLoadCalculator.calculateTrainingLoad()
        return (atl, ctl)
    }
    
    private func calculateTRIMPFromWorkouts(workouts: [HKWorkout]) async -> Double {
        var totalTRIMP: Double = 0
        
        for workout in workouts {
            let trimp = await trimpCalculator.calculateTRIMP(for: workout)
            totalTRIMP += trimp
        }
        
        Logger.debug("🔍 Total TRIMP from \(workouts.count) HealthKit workouts: \(String(format: "%.1f", totalTRIMP))")
        return totalTRIMP
    }
}
