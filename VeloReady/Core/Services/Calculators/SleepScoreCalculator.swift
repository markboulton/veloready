import Foundation
import HealthKit
import VeloReadyCore

/// Actor for sleep score data calculation
/// Performs data aggregation and delegates scoring to VeloReadyCore
actor SleepDataCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    
    // MARK: - Main Calculation
    
    func calculateSleepScore(sleepNeed: Double) async -> SleepScore? {
        // Get detailed sleep data (with retry for HealthKit authorization timing issues)
        var sleepInfo: (sleepDuration: TimeInterval?, timeInBed: TimeInterval?, deepSleepDuration: TimeInterval?, remSleepDuration: TimeInterval?, coreSleepDuration: TimeInterval?, awakeDuration: TimeInterval?, wakeEvents: Int?, bedtime: Date?, wakeTime: Date?, firstSleepTime: Date?)?
        var retryCount = 0
        let maxRetries = 2
        
        // Retry up to 2 times with a 1-second delay between attempts
        // This handles the race condition where HealthKit authorization was just granted
        while sleepInfo == nil && retryCount <= maxRetries {
            if retryCount > 0 {
                Logger.info("🔄 [SleepCalculator] Retry \(retryCount)/\(maxRetries) - waiting 1s before fetching sleep data...")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            
            sleepInfo = await healthKitManager.fetchDetailedSleepData()
            
            if sleepInfo == nil {
                Logger.warning("⚠️ [SleepCalculator] Attempt \(retryCount + 1)/\(maxRetries + 1) - no sleep data returned")
                retryCount += 1
            }
        }
        
        // Fetch HRV and baselines in parallel (no retry needed for these)
        async let hrvData = healthKitManager.fetchLatestHRVData()
        async let baselines = baselineCalculator.calculateAllBaselines()
        
        let (hrv, (hrvBaseline, _, _, _)) = await (hrvData, baselines)
        
        guard let sleepInfo = sleepInfo else {
            Logger.error("❌ [SleepCalculator] No sleep data available after \(maxRetries + 1) attempts")
            return nil
        }
        
        Logger.info("✅ [SleepCalculator] Sleep data fetched successfully (attempt \(retryCount + 1)/\(maxRetries + 1))")
        
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
        case 80...100: band = .optimal
        case 60..<80: band = .good
        case 40..<60: band = .fair
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
            return Calendar.current.date(byAdding: .hour, value: -10, to: Date()) // Fallback to 10 PM
        }
        
        // Extract valid bedtimes and filter recent nights
        let validBedtimes = sleepTimes.compactMap { $0.bedtime }
        
        guard !validBedtimes.isEmpty else {
            Logger.warning("️ No valid bedtime data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: -10, to: Date()) // Fallback to 10 PM
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
            return Calendar.current.date(byAdding: .hour, value: -6, to: Date()) // Fallback to 6 AM
        }
        
        // Extract valid wake times
        let validWakeTimes = sleepTimes.compactMap { $0.wakeTime }
        
        guard !validWakeTimes.isEmpty else {
            Logger.warning("️ No valid wake time data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: -6, to: Date()) // Fallback to 6 AM
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
