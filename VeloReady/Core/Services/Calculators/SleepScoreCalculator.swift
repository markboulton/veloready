import Foundation
import HealthKit
import VeloReadyCore

/// Actor for sleep score data calculation
/// Performs data aggregation and delegates scoring to VeloReadyCore
actor SleepDataCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()

    // MARK: - Sleep Band Thresholds

    /// Minimum score for optimal sleep band (80-100)
    /// Based on sleep research indicating excellent sleep quality above 80%
    private static let optimalSleepThreshold = 80

    /// Minimum score for good sleep band (60-79)
    /// Indicates adequate sleep quality for most training demands
    private static let goodSleepThreshold = 60

    /// Minimum score for fair sleep band (40-59)
    /// Suggests suboptimal sleep requiring attention
    private static let fairSleepThreshold = 40

    // MARK: - HealthKit Retry Configuration

    /// Maximum retry attempts for HealthKit queries
    /// iOS can require time to propagate permissions after authorization
    private static let maxRetries = 2

    /// Delay between retry attempts in seconds
    /// Allows time for HealthKit authorization to propagate
    private static let retryDelaySeconds = 3

    // MARK: - Fallback Sleep Times

    /// Default bedtime hour offset when no historical data available (10 PM)
    private static let defaultBedtimeHourOffset = -10

    /// Default wake time hour offset when no historical data available (6 AM)
    private static let defaultWakeTimeHourOffset = -6

    // MARK: - Input Validation

    /// Valid sleep need range in seconds (4-12 hours)
    /// Allows 4-12 hours to cover individual variation
    private static let validSleepNeedRange: ClosedRange<Double> = (4 * 3600)...(12 * 3600)

    // MARK: - Main Calculation

    func calculateSleepScore(sleepNeed: Double) async -> SleepScore? {
        // Validate sleep need parameter
        guard Self.validSleepNeedRange.contains(sleepNeed) else {
            Logger.warning("⚠️ Invalid sleep need: \(sleepNeed/3600)h (valid: 4-12h). Using default 8h.")
            return await calculateSleepScore(sleepNeed: 8 * 3600) // Fallback to 8 hours
        }
        // Get detailed sleep data (with retry for HealthKit authorization timing issues)
        var sleepInfo: HealthKitSleepData?
        var retryCount = 0

        // Retry with delay between attempts - handles HealthKit authorization propagation
        // iOS can require time to make data available after permission is granted
        while sleepInfo == nil && retryCount <= Self.maxRetries {
            if retryCount > 0 {
                Logger.info("🔄 [SleepCalculator] Retry \(retryCount)/\(Self.maxRetries) - waiting \(Self.retryDelaySeconds)s before fetching sleep data...")
                try? await Task.sleep(nanoseconds: UInt64(Self.retryDelaySeconds) * 1_000_000_000)
            }
            
            sleepInfo = await healthKitManager.fetchDetailedSleepData()
            
            if sleepInfo == nil {
                Logger.warning("⚠️ [SleepCalculator] Attempt \(retryCount + 1)/\(Self.maxRetries + 1) - no sleep data returned")
                retryCount += 1
            }
        }

        // Fetch HRV and baselines in parallel (no retry needed for these)
        async let hrvData = healthKitManager.fetchLatestHRVData()
        async let baselines = baselineCalculator.calculateAllBaselines()

        let (hrv, (hrvBaseline, _, _, _)) = await (hrvData, baselines)

        guard let sleepInfo = sleepInfo else {
            Logger.error("❌ [SleepCalculator] No sleep data available after \(Self.maxRetries + 1) attempts")
            return nil
        }

        Logger.info("✅ [SleepCalculator] Sleep data fetched successfully (attempt \(retryCount + 1)/\(Self.maxRetries + 1))")
        
        // Check if sleep data is from last night (within last 24 hours)
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        // Sleep should have ended within the last 24 hours
        guard let wakeTime = sleepInfo.wakeTime, wakeTime > yesterday else {
            Logger.error("Sleep data is outdated (wake: \(sleepInfo.wakeTime?.description ?? "unknown")) - not calculating score")
            return nil
        }
        
        Logger.debug("✅ Sleep data is fresh (wake: \(wakeTime)) - calculating score")
        
        // Calculate real baselines from historical data
        async let historicalSleepData = healthKitManager.fetchHistoricalSleepData(days: 7)
        let sleepTimes = await historicalSleepData
        
        // Calculate sleep latency (time from in bed to first sleep)
        let sleepLatency: Double? = {
            guard let bedtime = sleepInfo.bedtime,
                  let firstSleep = sleepInfo.firstSleepTime else {
                return nil
            }
            return firstSleep.timeIntervalSince(bedtime)
        }()
        
        // Build sleep score inputs
        let inputs = SleepScore.SleepInputs(
            sleepDuration: sleepInfo.sleepDuration,
            timeInBed: sleepInfo.timeInBed,
            sleepNeed: sleepNeed,
            deepSleepDuration: sleepInfo.deepSleepDuration,
            remSleepDuration: sleepInfo.remSleepDuration,
            coreSleepDuration: sleepInfo.coreSleepDuration,
            awakeDuration: sleepInfo.awakeDuration,
            wakeEvents: sleepInfo.wakeEvents,
            bedtime: sleepInfo.bedtime,
            wakeTime: sleepInfo.wakeTime,
            baselineBedtime: calculateBaselineBedtime(from: sleepTimes),
            baselineWakeTime: calculateBaselineWakeTime(from: sleepTimes),
            hrvOvernight: hrv.value,
            hrvBaseline: hrvBaseline,
            sleepLatency: sleepLatency
        )
        
        Logger.debug("🔍 Sleep Score Inputs:")
        Logger.debug("   Sleep Duration: \(inputs.sleepDuration?.description ?? "nil") seconds")
        Logger.debug("   Time in Bed: \(inputs.timeInBed?.description ?? "nil") seconds")
        Logger.debug("   Sleep Need: \(inputs.sleepNeed?.description ?? "nil") seconds")
        Logger.debug("   Deep Sleep: \(inputs.deepSleepDuration?.description ?? "nil") seconds")
        Logger.debug("   REM Sleep: \(inputs.remSleepDuration?.description ?? "nil") seconds")
        Logger.debug("   Wake Events: \(inputs.wakeEvents?.description ?? "nil")")
        Logger.debug("   HRV Overnight: \(inputs.hrvOvernight?.description ?? "nil") ms")
        Logger.debug("   HRV Baseline: \(inputs.hrvBaseline?.description ?? "nil") ms")
        
        // Create inputs for VeloReadyCore calculation
        let coreInputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: inputs.sleepDuration,
            timeInBed: inputs.timeInBed,
            sleepNeed: inputs.sleepNeed,
            deepSleepDuration: inputs.deepSleepDuration,
            remSleepDuration: inputs.remSleepDuration,
            coreSleepDuration: inputs.coreSleepDuration,
            awakeDuration: inputs.awakeDuration,
            wakeEvents: inputs.wakeEvents,
            bedtime: inputs.bedtime,
            wakeTime: inputs.wakeTime,
            baselineBedtime: inputs.baselineBedtime,
            baselineWakeTime: inputs.baselineWakeTime,
            hrvOvernight: inputs.hrvOvernight,
            hrvBaseline: inputs.hrvBaseline,
            sleepLatency: inputs.sleepLatency
        )
        
        // Get current illness indicator
        let illnessIndicator = await IllnessDetectionService.shared.currentIndicator
        let illnessDetected = illnessIndicator != nil
        let illnessSeverity = illnessIndicator?.severity.rawValue
        
        // Call VeloReadyCore for pure calculation (runs on background thread)
        let result = VeloReadyCore.SleepCalculations.calculateScore(inputs: coreInputs)
        
        // Map score to band
        let band: SleepScore.SleepBand
        switch result.score {
        case Self.optimalSleepThreshold...100: band = .optimal
        case Self.goodSleepThreshold..<Self.optimalSleepThreshold: band = .good
        case Self.fairSleepThreshold..<Self.goodSleepThreshold: band = .fair
        default: band = .payAttention
        }
        
        // Map VeloReadyCore results back to iOS SleepScore model
        let modelSubScores = SleepScore.SubScores(
            performance: result.subScores.performance,
            efficiency: result.subScores.efficiency,
            stageQuality: result.subScores.stageQuality,
            disturbances: result.subScores.disturbances,
            timing: result.subScores.timing
        )
        
        return SleepScore(
            score: result.score,
            band: band,
            subScores: modelSubScores,
            inputs: inputs,
            calculatedAt: Date(),
            illnessDetected: illnessDetected,
            illnessSeverity: illnessSeverity
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculate baseline bedtime from historical sleep data
    private func calculateBaselineBedtime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
        guard !sleepTimes.isEmpty else {
            Logger.warning("️ No historical sleep data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: Self.defaultBedtimeHourOffset, to: Date())
        }

        // Extract valid bedtimes and filter recent nights
        let validBedtimes = sleepTimes.compactMap { $0.bedtime }

        guard !validBedtimes.isEmpty else {
            Logger.warning("️ No valid bedtime data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: Self.defaultBedtimeHourOffset, to: Date())
        }
        
        // Calculate average bedtime
        let totalSeconds = validBedtimes.reduce(0) { $0 + $1.timeIntervalSince1970 }
        let averageEpoch = totalSeconds / Double(validBedtimes.count)
        let baselineBedtime = Date(timeIntervalSince1970: averageEpoch)
        
        // Convert to time-only for consistency
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: baselineBedtime)
        let minute = calendar.component(.minute, from: baselineBedtime)
        
        let today = calendar.startOfDay(for: Date())
        let timeOnlyBaseline = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
        
        Logger.debug("🔍 BASELINE CALCULATION:")
        Logger.debug("   Valid bedtime samples: \(validBedtimes.count)")
        Logger.debug("   Calculated baseline bedtime: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
    
    /// Calculate baseline wake time from historical sleep data
    private func calculateBaselineWakeTime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
        guard !sleepTimes.isEmpty else {
            Logger.warning("️ No historical sleep data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: Self.defaultWakeTimeHourOffset, to: Date())
        }

        // Extract valid wake times
        let validWakeTimes = sleepTimes.compactMap { $0.wakeTime }

        guard !validWakeTimes.isEmpty else {
            Logger.warning("️ No valid wake time data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: Self.defaultWakeTimeHourOffset, to: Date())
        }
        
        // Calculate average wake time
        let totalSeconds = validWakeTimes.reduce(0) { $0 + $1.timeIntervalSince1970 }
        let averageEpoch = totalSeconds / Double(validWakeTimes.count)
        let baselineWakeTime = Date(timeIntervalSince1970: averageEpoch)
        
        // Convert to time-only for consistency
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: baselineWakeTime)
        let minute = calendar.component(.minute, from: baselineWakeTime)
        
        let today = calendar.startOfDay(for: Date())
        let timeOnlyBaseline = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
        
        Logger.debug("   Valid wake time samples: \(validWakeTimes.count)")
        Logger.debug("   Calculated baseline wake time: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
}
