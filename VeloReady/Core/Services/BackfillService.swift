import Foundation
import CoreData
import HealthKit

/// Manages historical data backfilling operations
/// Coordinates between Core Data, HealthKit, and scoring services
/// 
/// **Single Responsibility**: All backfilling logic lives here, not in CacheManager
/// 
/// **Usage**:
/// ```swift
/// // Backfill everything
/// await BackfillService.shared.backfillAll()
///
/// // Individual backfills
/// await BackfillService.shared.backfillStrainScores()
/// ```
final class BackfillService {
    // MARK: - Singleton
    
    static let shared = BackfillService()
    
    // MARK: - Dependencies
    
    private let persistence = PersistenceController.shared
    private let healthKit = HealthKitManager.shared
    private let trainingLoadCalculator = TrainingLoadCalculator()
    
    // MARK: - Initialization
    
    private init() {
        Logger.info("🎯 [BackfillService] Initialized")
    }
    
    // MARK: - Public API
    
    /// Backfill all historical data (physio, training load, scores)
    /// - Parameters:
    ///   - days: Number of days to backfill (default 60)
    ///   - forceRefresh: Bypass throttling and force refresh (default false)
    func backfillAll(days: Int = 60, forceRefresh: Bool = false) async {
        Logger.info("🔄 [BACKFILL] ✅ FUNCTION CALLED - Starting comprehensive backfill for \(days) days...")
        Logger.info("🔄 [BACKFILL] forceRefresh: \(forceRefresh)")
        Logger.info("🔄 [BACKFILL] Current thread: \(Thread.current)")
        
        // Run in sequence for data dependencies
        Logger.info("🔄 [BACKFILL] Step 1/3: backfillHistoricalPhysioData...")
        await backfillHistoricalPhysioData(days: days)  // 1. Raw HealthKit data
        Logger.info("🔄 [BACKFILL] ✅ Step 1/3 complete")
        
        Logger.info("🔄 [BACKFILL] Step 2/3: backfillTrainingLoad...")
        await backfillTrainingLoad(days: days, forceRefresh: forceRefresh)  // 2. CTL/ATL/TSS
        Logger.info("🔄 [BACKFILL] ✅ Step 2/3 complete")
        
        Logger.info("🔄 [BACKFILL] Step 3/3: backfillScores...")
        await backfillScores(days: days, forceRefresh: forceRefresh)  // 3. Scores from raw data
        Logger.info("🔄 [BACKFILL] ✅ Step 3/3 complete")
        
        Logger.info("✅ [BACKFILL] Complete!")
    }
    
    /// Backfill all score types in parallel (recovery, sleep, strain)
    /// - Parameters:
    ///   - days: Number of days to backfill
    ///   - forceRefresh: Bypass throttling
    func backfillScores(days: Int = 60, forceRefresh: Bool = false) async {
        Logger.info("🔄 [BACKFILL] Starting score backfills (parallel)...")
        
        async let recovery = backfillHistoricalRecoveryScores(days: days, forceRefresh: forceRefresh)
        async let sleep = backfillSleepScores(days: days, forceRefresh: forceRefresh)
        async let strain = backfillStrainScores(daysBack: days, forceRefresh: forceRefresh)
        
        await (recovery, sleep, strain)
        
        Logger.info("✅ [BACKFILL] All scores complete")
    }
    
    // MARK: - Training Load Backfill
    
    /// Backfill training load data (CTL/ATL/TSS)
    /// Called when Intervals.icu doesn't provide CTL/ATL data
    /// Optimized to backfill last 42 days and save TSS values
    /// Smart caching: Only runs once per day to avoid redundant calculations
    func backfillTrainingLoad(days: Int = 42, forceRefresh: Bool = false) async {
        await throttledBackfill(
            key: "lastCTLBackfill",
            logPrefix: "CTL/ATL BACKFILL",
            forceRefresh: forceRefresh
        ) {
            Logger.data("📊 [CTL/ATL BACKFILL] Starting calculation for last \(days) days...")
        
        let calculator = TrainingLoadCalculator()
        var progressiveLoad: [Date: (ctl: Double, atl: Double, tss: Double)] = [:]
        
        // Try Intervals.icu first
        Logger.data("📊 [CTL/ATL BACKFILL] Step 1: Checking Intervals.icu...")
        let intervalsActivities = (try? await IntervalsAPIClient.shared.fetchRecentActivities(limit: 200, daysBack: 60)) ?? []
        
        if !intervalsActivities.isEmpty {
            let activitiesWithTSS = intervalsActivities.filter { ($0.tss ?? 0) > 0 }
            Logger.data("📊 [CTL/ATL BACKFILL] Found \(activitiesWithTSS.count) Intervals activities with TSS")
            
            for activity in activitiesWithTSS {
                guard let tss = activity.tss, tss > 0 else { continue }
                
                // Parse startDateLocal string to Date
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                formatter.timeZone = TimeZone.current
                
                guard let startDate = formatter.date(from: activity.startDateLocal) else { continue }
                
                let date = Calendar.current.startOfDay(for: startDate)
                
                // Progressive CTL/ATL calculation using exponential decay
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                let priorLoad = progressiveLoad[yesterday] ?? (ctl: 0, atl: 0, tss: 0)
                
                // CTL: 42-day exponential moving average
                let ctlDecay = exp(-1.0 / 42.0)
                let newCTL = priorLoad.ctl * ctlDecay + tss * (1.0 - ctlDecay)
                
                // ATL: 7-day exponential moving average
                let atlDecay = exp(-1.0 / 7.0)
                let newATL = priorLoad.atl * atlDecay + tss * (1.0 - atlDecay)
                
                progressiveLoad[date] = (ctl: newCTL, atl: newATL, tss: tss)
            }
        }
        
        // If no Intervals data, fetch from Strava
        if progressiveLoad.isEmpty {
            Logger.data("📊 [CTL/ATL BACKFILL] Step 2: Fetching Strava activities...")
            
            do {
                let stravaActivities = try await VeloReadyAPIClient.shared.fetchActivities(daysBack: days, limit: 200)
                let activities = ActivityConverter.stravaToActivity(stravaActivities)
                Logger.data("📊 [CTL/ATL BACKFILL] Found \(activities.count) Strava activities")
                
                // Get FTP for TSS calculation
                let athleteProfile = AthleteProfileManager.shared.profile
                let ftp = athleteProfile.ftp ?? 200.0
                let maxHR = athleteProfile.maxHR ?? 180.0
                let restingHR = athleteProfile.restingHR ?? 60.0
                
                // Sort activities by date (oldest first for progressive calculation)
                // Parse startDateLocal string to Date
                let dateFormatter = ISO8601DateFormatter()
                let sortedActivities = activities.sorted(by: { 
                    guard let date1 = dateFormatter.date(from: $0.startDateLocal),
                          let date2 = dateFormatter.date(from: $1.startDateLocal) else {
                        return false
                    }
                    return date1 < date2
                })
                
                for activity in sortedActivities {
                    guard let activityDate = dateFormatter.date(from: activity.startDateLocal) else {
                        continue
                    }
                    let date = Calendar.current.startOfDay(for: activityDate)
                    
                    // Calculate TSS for this activity
                    var tss: Double = 0
                    
                    // 1. Try power-based TSS (most accurate)
                    if let np = activity.normalizedPower,
                       let duration = activity.duration,
                       np > 0, ftp > 0 {
                        let intensityFactor = np / ftp
                        tss = (duration / 3600) * intensityFactor * intensityFactor * 100
                        Logger.debug("   \(activity.name ?? "Unknown"): Power-based TSS: \(String(format: "%.1f", tss))")
                    }
                    // 2. Fall back to HR-based TRIMP
                    else if let avgHR = activity.averageHeartRate,
                            let duration = activity.duration,
                            duration > 0, avgHR > 0 {
                        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
                        let trimp = (duration / 60) * hrReserve * 0.64 * exp(1.92 * hrReserve)
                        tss = trimp
                        Logger.debug("   \(activity.name ?? "Unknown"): HR-based TRIMP: \(String(format: "%.1f", tss))")
                    }
                    // 3. Estimate from duration and activity type
                    else if let duration = activity.duration {
                        tss = (duration / 3600) * 50 // Assume moderate intensity
                        Logger.debug("   \(activity.name ?? "Unknown"): Estimated TSS from duration: \(String(format: "%.1f", tss))")
                    }
                    
                    if tss > 0 {
                        // Progressive CTL/ATL calculation
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                        let priorLoad = progressiveLoad[yesterday] ?? (ctl: 0, atl: 0, tss: 0)
                        
                        let ctlDecay = exp(-1.0 / 42.0)
                        let newCTL = priorLoad.ctl * ctlDecay + tss * (1.0 - ctlDecay)
                        
                        let atlDecay = exp(-1.0 / 7.0)
                        let newATL = priorLoad.atl * atlDecay + tss * (1.0 - atlDecay)
                        
                        // Accumulate TSS if multiple activities on same day
                        let existingTSS = progressiveLoad[date]?.tss ?? 0
                        progressiveLoad[date] = (ctl: newCTL, atl: newATL, tss: tss + existingTSS)
                    }
                }
                
                Logger.data("📊 [CTL/ATL BACKFILL] Calculated load for \(progressiveLoad.count) days from Strava")
            } catch {
                Logger.error("❌ [CTL/ATL BACKFILL] Strava fetch failed: \(error)")
            }
        }
        
        // If still empty, try HealthKit workouts
        if progressiveLoad.isEmpty {
            Logger.data("📊 [CTL/ATL BACKFILL] Step 3: Falling back to HealthKit workouts...")
            progressiveLoad = await calculator.calculateProgressiveTrainingLoadFromHealthKit()
            Logger.data("📊 [CTL/ATL BACKFILL] Calculated load for \(progressiveLoad.count) days from HealthKit")
        }
        
        if progressiveLoad.isEmpty {
            Logger.data("📊 [CTL/ATL BACKFILL] No activities found to backfill from any source")
            return
        }
        
        Logger.data("📊 [CTL/ATL BACKFILL] Saving \(progressiveLoad.count) days to Core Data...")
        
        // Batch update DailyLoad entities for performance
            await self.updateDailyLoadBatch(progressiveLoad)
            
            Logger.data("✅ [CTL/ATL BACKFILL] Complete! (Next run allowed in 24h)")
        }
    }
    
    /// Batch update DailyLoad entities for performance
    private func updateDailyLoadBatch(_ progressiveLoad: [Date: (ctl: Double, atl: Double, tss: Double)]) async {
        let context = persistence.newBackgroundContext()
        let calendar = Calendar.current
        
        Logger.data("📊 [BATCH UPDATE] Processing \(progressiveLoad.count) days...")
        
        await context.perform {
            var updatedCount = 0
            var skippedCount = 0
            var createdCount = 0
            
            for (date, load) in progressiveLoad {
                let startOfDay = calendar.startOfDay(for: date)
                
                // Fetch or create DailyLoad
                let loadRequest = DailyLoad.fetchRequest()
                loadRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
                loadRequest.fetchLimit = 1
                
                let dailyLoad: DailyLoad
                if let existing = try? context.fetch(loadRequest).first {
                    dailyLoad = existing
                    updatedCount += 1
                } else {
                    dailyLoad = DailyLoad(context: context)
                    dailyLoad.date = startOfDay
                    createdCount += 1
                }
                
                // Update values
                dailyLoad.ctl = load.ctl
                dailyLoad.atl = load.atl
                dailyLoad.tss = load.tss
                dailyLoad.lastUpdated = Date()
                
                // CRITICAL FIX: Link DailyLoad to DailyScores (was missing!)
                let scoresRequest = DailyScores.fetchRequest()
                scoresRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
                scoresRequest.fetchLimit = 1
                
                if let scores = try? context.fetch(scoresRequest).first {
                    scores.load = dailyLoad
                } else {
                    skippedCount += 1
                }
            }
            
            // Save
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.data("✅ [BATCH UPDATE] Created \(createdCount), updated \(updatedCount), skipped \(skippedCount) entries")
                } catch {
                    Logger.error("❌ [BATCH UPDATE] Failed to save: \(error)")
                }
            } else {
                Logger.data("📊 [BATCH UPDATE] No changes to save (\(skippedCount) entries skipped)")
            }
        }
    }
    
    // MARK: - Score Backfills
    
    /// Backfill historical recovery scores from existing physio data
    /// This calculates recovery scores for days that have HRV/RHR/sleep data but placeholder recovery scores (50)
    func backfillHistoricalRecoveryScores(days: Int = 60, forceRefresh: Bool = false) async {
        await throttledBackfill(
            key: "lastRecoveryBackfill",
            logPrefix: "RECOVERY BACKFILL",
            forceRefresh: forceRefresh
        ) {
            Logger.data("📊 [RECOVERY BACKFILL] Starting backfill for last \(days) days...")
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
            
            await self.performBatchInBackground(logPrefix: "RECOVERY BACKFILL") { context in
                // Fetch all DailyScores in the period (bulk fetch for efficiency)
                let request = DailyScores.fetchRequest()
                request.predicate = NSPredicate(
                    format: "date >= %@ AND date < %@",
                    startDate as NSDate,
                    today as NSDate
                )
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
                
                let allScores = try context.fetch(request)
                
                guard !allScores.isEmpty else {
                    Logger.data("📊 [RECOVERY BACKFILL] No DailyScores found in period")
                    return (updated: 0, skipped: 0)
                }
                
                Logger.data("📊 [RECOVERY BACKFILL] Found \(allScores.count) days to process")
                
                var updatedCount = 0
                var skippedCount = 0
                
                for scores in allScores {
                    guard let date = scores.date else { continue }
                    
                    // Skip if already has a realistic recovery score (> 80 means properly calculated)
                    // Old simplified formula produced 40-70 range, new formula produces 0-100 with proper distribution
                    if !forceRefresh && scores.recoveryScore > 80 {
                        skippedCount += 1
                        continue
                    }
                    
                    // Check if we have physio data
                    guard let physio = scores.physio else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Only calculate if we have at least HRV and RHR
                    guard physio.hrv > 0, physio.rhr > 0 else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Build inputs from historical data
                    let inputs = RecoveryScore.RecoveryInputs(
                        hrv: physio.hrv > 0 ? physio.hrv : nil,
                        overnightHrv: physio.hrv > 0 ? physio.hrv : nil,
                        hrvBaseline: physio.hrvBaseline > 0 ? physio.hrvBaseline : nil,
                        rhr: physio.rhr > 0 ? physio.rhr : nil,
                        rhrBaseline: physio.rhrBaseline > 0 ? physio.rhrBaseline : nil,
                        sleepDuration: physio.sleepDuration > 0 ? physio.sleepDuration : nil,
                        sleepBaseline: physio.sleepBaseline > 0 ? physio.sleepBaseline : nil,
                        respiratoryRate: nil, // Not available historically
                        respiratoryBaseline: nil,
                        atl: nil, // Not available historically
                        ctl: nil,
                        recentStrain: nil,
                        sleepScore: nil // SleepScore structure too complex for backfill - use sleep duration instead
                    )
                    
                    // Use the SAME calculation as real-time (RecoveryScoreCalculator)
                    // Uses synchronous overload (rule-based) for backfill
                    let result = RecoveryScoreCalculator.calculate(inputs: inputs, illnessIndicator: nil)
                    
                    // Update the score
                    scores.recoveryScore = Double(result.score)
                    scores.recoveryBand = result.band.color
                    scores.lastUpdated = Date()
                    updatedCount += 1
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd"
                    Logger.data("  ✅ \(formatter.string(from: date)): Calculated recovery=\(result.score) (was \(Int(scores.recoveryScore)), HRV=\(physio.hrv), RHR=\(physio.rhr), Band=\(result.band.rawValue))")
                }
                
                return (updated: updatedCount, skipped: skippedCount)
            }
        }
    }
    
    /// Backfill sleep scores for the last 60 days from existing DailyPhysio sleep data
    /// This ensures historical days show accurate sleep scores instead of placeholder (50)
    /// Uses the same algorithm as today's sleep calculation
    func backfillSleepScores(days: Int = 60, forceRefresh: Bool = false) async {
        await throttledBackfill(
            key: "lastSleepBackfill",
            logPrefix: "SLEEP BACKFILL",
            forceRefresh: forceRefresh
        ) {
            Logger.debug("🔄 [SLEEP BACKFILL] Starting backfill for last \(days) days...")
            
            await self.performBatchInBackground(logPrefix: "SLEEP BACKFILL") { context in
                var updatedCount = 0
                var skippedCount = 0
                
                for date in self.historicalDates(daysBack: days) {
                    // Fetch DailyScores for this day
                    let scoresRequest = DailyScores.fetchRequest()
                    scoresRequest.predicate = NSPredicate(format: "date == %@", date as NSDate)
                    scoresRequest.fetchLimit = 1
                    
                    guard let scores = try context.fetch(scoresRequest).first else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Skip if already has a realistic sleep score (> 80 means properly calculated)
                    // Old simplified formula produced 50-90 range, new formula produces proper 0-100 distribution
                    if !forceRefresh && scores.sleepScore > 80 {
                        skippedCount += 1
                        continue
                    }
                    
                    // Fetch DailyPhysio for sleep data
                    guard let physio = scores.physio else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Only calculate if we have sleep duration
                    guard physio.sleepDuration > 0 else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Build inputs from historical data (use what's available)
                    let inputs = SleepScore.SleepInputs(
                        sleepDuration: physio.sleepDuration,
                        timeInBed: nil, // Not available historically
                        sleepNeed: 25200, // Standard 7 hours (same as real-time calc)
                        deepSleepDuration: nil, // Not available historically
                        remSleepDuration: nil,
                        coreSleepDuration: nil,
                        awakeDuration: nil,
                        wakeEvents: nil,
                        bedtime: nil,
                        wakeTime: nil,
                        baselineBedtime: nil,
                        baselineWakeTime: nil,
                        hrvOvernight: physio.hrv > 0 ? physio.hrv : nil,
                        hrvBaseline: physio.hrvBaseline > 0 ? physio.hrvBaseline : nil,
                        sleepLatency: nil
                    )
                    
                    // Use the SAME calculation as real-time (SleepScoreCalculator)
                    let result = SleepScoreCalculator.calculate(inputs: inputs, illnessIndicator: nil)
                    
                    scores.sleepScore = Double(result.score)
                    scores.lastUpdated = Date()
                    updatedCount += 1
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM dd"
                    let sleepHours = physio.sleepDuration / 3600.0
                    Logger.debug("📊 [SLEEP BACKFILL]   \(dateFormatter.string(from: date)): \(result.score) (was \(Int(scores.sleepScore)), \(String(format: "%.1f", sleepHours))h sleep, Band=\(result.band.rawValue))")
                }
                
                return (updated: updatedCount, skipped: skippedCount)
            }
        }
    }
    
    /// Backfill strain scores for the last 60 days from existing DailyLoad (TSS) data
    /// This ensures historical days show accurate strain scores instead of 0
    /// Uses the same algorithm as today's strain calculation but from historical TSS
    func backfillStrainScores(daysBack: Int = 60, forceRefresh: Bool = false) async {
        await throttledBackfill(
            key: "lastStrainBackfill",
            logPrefix: "STRAIN BACKFILL",
            forceRefresh: forceRefresh
        ) {
            Logger.debug("🔄 [STRAIN BACKFILL] Starting backfill for last \(daysBack) days...")
            
            // Fetch athlete profile once before batch operation (avoid await inside closure)
            let athleteProfile = await AthleteProfileManager.shared.profile
            
            await self.performBatchInBackground(logPrefix: "STRAIN BACKFILL") { context in
                var updatedCount = 0
                var skippedCount = 0
                
                for date in self.historicalDates(daysBack: daysBack) {
                    // Fetch DailyScores for this day
                    let scoresRequest = DailyScores.fetchRequest()
                    scoresRequest.predicate = NSPredicate(format: "date == %@", date as NSDate)
                    scoresRequest.fetchLimit = 1
                    
                    guard let scores = try context.fetch(scoresRequest).first else {
                        skippedCount += 1
                        continue
                    }
                    
                    // Skip if already has a realistic strain score (> 5.0 to force recalculation of old formula values)
                    // Old formula produced values like 2.0-2.4 which are incorrect
                    // New Whoop-style formula produces 5-18 range for real workouts
                    if !forceRefresh && scores.strainScore > 5.0 {
                        skippedCount += 1
                        continue
                    }
                    
                    // Fetch DailyLoad for TSS data
                    let loadRequest = DailyLoad.fetchRequest()
                    loadRequest.predicate = NSPredicate(format: "date == %@", date as NSDate)
                    loadRequest.fetchLimit = 1
                    
                    guard let load = try context.fetch(loadRequest).first else {
                        // No training load data, set minimal NEAT strain
                        scores.strainScore = 2.0
                        updatedCount += 1
                        continue
                    }
                    
                    // Get historical data from Core Data
                    let physio = scores.physio
                    
                    // Calculate strain using the SAME formula as real-time calculation
                    // (athleteProfile already fetched outside the closure)
                    // Build inputs from historical data
                    let inputs = StrainScore.StrainInputs(
                        continuousHRData: nil,
                        dailyTRIMP: load.tss > 0 ? load.tss : nil, // Use TSS as TRIMP proxy
                        cardioDailyTRIMP: load.tss > 0 ? load.tss : nil,
                        cardioDurationMinutes: nil, // Not available historically
                        averageIntensityFactor: nil,
                        workoutTypes: nil,
                        strengthSessionRPE: nil,
                        strengthDurationMinutes: nil,
                        strengthVolume: nil,
                        strengthSets: nil,
                        muscleGroupsTrained: nil,
                        isEccentricFocused: nil,
                        dailySteps: nil, // Not available historically
                        activeEnergyCalories: nil, // Not available historically
                        nonWorkoutMETmin: nil,
                        hrvOvernight: physio?.hrv,
                        hrvBaseline: physio?.hrvBaseline,
                        rmrToday: physio?.rhr,
                        rmrBaseline: physio?.rhrBaseline,
                        sleepQuality: scores.sleepScore > 0 ? Int(scores.sleepScore) : nil,
                        userFTP: athleteProfile.ftp,
                        userMaxHR: athleteProfile.maxHR,
                        userRestingHR: athleteProfile.restingHR,
                        userBodyMass: nil
                    )
                    
                    // Use the SAME calculation as real-time (Whoop-style algorithm)
                    let result = StrainScoreCalculator.calculate(inputs: inputs)
                    
                    scores.strainScore = result.score
                    scores.lastUpdated = Date()
                    updatedCount += 1
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM dd"
                    Logger.debug("📊 [STRAIN BACKFILL]   \(dateFormatter.string(from: date)): \(String(format: "%.1f", result.score)) (TSS: \(String(format: "%.0f", load.tss)), Band: \(result.band.rawValue))")
                }
                
                return (updated: updatedCount, skipped: skippedCount)
            }
        }
    }
    
    // MARK: - Physio Data Backfill
    
    /// Backfill historical HRV/RHR/Sleep data from HealthKit for chart display
    func backfillHistoricalPhysioData(days: Int = 60) async {
        Logger.data("📊 [PHYSIO BACKFILL] Starting backfill for last \(days) days...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch HRV, RHR, and Sleep data from HealthKit for the entire period
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        
        // Fetch all HRV samples (use HealthKitManager.shared directly to avoid MainActor isolation)
        let hrvSamples = await HealthKitManager.shared.fetchHRVSamples(from: startDate, to: Date())
        
        // Fetch all RHR samples
        let rhrSamples = await HealthKitManager.shared.fetchRHRSamples(from: startDate, to: Date())
        
        // Fetch all sleep samples
        let sleepSamples = (try? await HealthKitManager.shared.fetchSleepData(from: startDate, to: Date())) ?? []
        
        Logger.data("📊 [PHYSIO BACKFILL] Fetched \(hrvSamples.count) HRV, \(rhrSamples.count) RHR, \(sleepSamples.count) sleep samples")
        
        // Group by day
        var dailyData: [Date: (hrv: Double?, rhr: Double?, sleep: TimeInterval?)] = [:]
        
        for sample in hrvSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            if dailyData[day] == nil {
                dailyData[day] = (hrv, nil, nil)
            } else {
                dailyData[day]?.hrv = hrv
            }
        }
        
        for sample in rhrSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            let rhr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            if dailyData[day] == nil {
                dailyData[day] = (nil, rhr, nil)
            } else {
                dailyData[day]?.rhr = rhr
            }
        }
        
        for sample in sleepSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            if dailyData[day] == nil {
                dailyData[day] = (nil, nil, duration)
            } else {
                let existing = dailyData[day]?.sleep ?? 0
                dailyData[day]?.sleep = existing + duration
            }
        }
        
        Logger.data("📊 [PHYSIO BACKFILL] Grouped into \(dailyData.count) days with data")
        
        // Save to Core Data
        let context = persistence.container.newBackgroundContext()
        await context.perform {
            var savedCount = 0
            var skippedCount = 0
            
            for (date, data) in dailyData {
                // Only save if we have at least one metric
                guard data.hrv != nil || data.rhr != nil || data.sleep != nil else {
                    skippedCount += 1
                    continue
                }
                
                // Fetch or create DailyPhysio
                let request = DailyPhysio.fetchRequest()
                request.predicate = NSPredicate(format: "date == %@", date as NSDate)
                request.fetchLimit = 1
                
                let physio: DailyPhysio
                if let existing = try? context.fetch(request).first {
                    physio = existing
                } else {
                    physio = DailyPhysio(context: context)
                    physio.date = date
                }
                
                // Update values (only if not already set)
                if let hrv = data.hrv, physio.hrv == 0 {
                    physio.hrv = hrv
                }
                if let rhr = data.rhr, physio.rhr == 0 {
                    physio.rhr = rhr
                }
                if let sleep = data.sleep, physio.sleepDuration == 0 {
                    physio.sleepDuration = sleep
                }
                
                physio.lastUpdated = Date()
                savedCount += 1
            }
            
            // Save
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.data("✅ [PHYSIO BACKFILL] Saved \(savedCount) days, skipped \(skippedCount)")
                } catch {
                    Logger.error("❌ [PHYSIO BACKFILL] Failed to save: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Execute a backfill operation with throttling (once per 24h unless forced)
    private func throttledBackfill(
        key: String,
        logPrefix: String,
        forceRefresh: Bool,
        operation: () async throws -> Void
    ) async rethrows {
        // Check throttle
        if !forceRefresh, let lastRun = UserDefaults.standard.object(forKey: key) as? Date {
            let hoursSince = Date().timeIntervalSince(lastRun) / 3600
            if hoursSince < 24 {
                Logger.data("⏭️ [\(logPrefix)] Skipping - last run was \(String(format: "%.1f", hoursSince))h ago (< 24h)")
                return
            }
        }
        
        // Execute operation
        try await operation()
        
        // Save timestamp
        UserDefaults.standard.set(Date(), forKey: key)
    }
    
    /// Execute Core Data batch operations with progress tracking
    private func performBatchInBackground(
        logPrefix: String,
        operation: @escaping (NSManagedObjectContext) throws -> (updated: Int, skipped: Int)
    ) async {
        let context = persistence.newBackgroundContext()
        
        await context.perform {
            do {
                let counts = try operation(context)
                
                // Save if changes exist
                if context.hasChanges {
                    try context.save()
                    if counts.updated > 0 {
                        Logger.debug("✅ [\(logPrefix)] Updated \(counts.updated) days, skipped \(counts.skipped)")
                    } else {
                        Logger.debug("📊 [\(logPrefix)] No changes to save (\(counts.skipped) days skipped)")
                    }
                } else {
                    Logger.debug("📊 [\(logPrefix)] No changes to save (\(counts.skipped) days skipped)")
                }
            } catch {
                Logger.error("❌ [\(logPrefix)] Failed to save: \(error)")
            }
        }
    }
    
    /// Generate a sequence of historical dates (excluding today)
    private func historicalDates(daysBack: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (1...daysBack).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return calendar.startOfDay(for: date)
        }
    }
}
