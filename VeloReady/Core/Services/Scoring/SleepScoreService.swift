import Foundation
import HealthKit
import WidgetKit
import VeloReadyCore

/// Service for calculating daily sleep scores using Whoop-like algorithm
/// This service orchestrates data fetching from HealthKit
/// and delegates calculation logic to VeloReadyCore for testability and reusability
@MainActor
class SleepScoreService: ObservableObject {
    static let shared = SleepScoreService()
    
    @Published var currentSleepScore: SleepScore?
    var currentSleepDebt: SleepDebt?
    var currentSleepConsistency: SleepConsistency?
    var isLoading = false
    var errorMessage: String?
    
    private let calculator = SleepDataCalculator()
    private let healthKitManager = HealthKitManager.shared
    private let userSettings = UserSettings.shared
    private let cache = UnifiedCacheManager.shared
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    // Track if we've already triggered recovery refresh for missing sleep
    private var hasTriggeredRecoveryRefresh = false
    
    init() {
        // Load cached sleep score synchronously for instant display (prevents empty rings)
        loadCachedSleepScoreSync()

        // Load cached sleep score immediately for instant display
        // But first check if we have actual sleep data from last night
        Task {
            await validateAndLoadCache()
        }
    }

    /// Load cached sleep score synchronously from UserDefaults for instant display
    /// This prevents empty rings when view re-renders due to network state changes
    private func loadCachedSleepScoreSync() {
        Logger.debug("🔍 [SLEEP SYNC] Starting synchronous load from UserDefaults")
        Logger.debug("🔍 [SLEEP SYNC] currentSleepScore BEFORE: \(currentSleepScore?.score ?? -1)")

        // Try loading from shared UserDefaults (fastest, always available)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
            if let score = sharedDefaults.value(forKey: "cachedSleepScore") as? Int {
                // Create a placeholder score with cached values
                // Map score to band
                let band: SleepScore.SleepBand
                if score >= 85 {
                    band = .optimal
                } else if score >= 70 {
                    band = .good
                } else if score >= 60 {
                    band = .fair
                } else {
                    band = .payAttention
                }

                let sleepScore = SleepScore(
                    score: score,
                    band: band,
                    subScores: SleepScore.SubScores(
                        performance: 0,
                        efficiency: 0,
                        stageQuality: 0,
                        disturbances: 0,
                        timing: 0
                    ),
                    inputs: SleepScore.SleepInputs(
                        sleepDuration: nil,
                        timeInBed: nil,
                        sleepNeed: nil,
                        deepSleepDuration: nil,
                        remSleepDuration: nil,
                        coreSleepDuration: nil,
                        awakeDuration: nil,
                        wakeEvents: nil,
                        bedtime: nil,
                        wakeTime: nil,
                        baselineBedtime: nil,
                        baselineWakeTime: nil,
                        hrvOvernight: nil,
                        hrvBaseline: nil,
                        sleepLatency: nil
                    ),
                    calculatedAt: Date()
                )

                currentSleepScore = sleepScore
                Logger.debug("⚡💾 [SLEEP SYNC] Loaded cached sleep score synchronously: \(score)")
                Logger.debug("🔍 [SLEEP SYNC] currentSleepScore AFTER: \(currentSleepScore?.score ?? -1)")
            } else {
                Logger.debug("⚠️ [SLEEP SYNC] No sleep score found in UserDefaults")
            }
        } else {
            Logger.debug("❌ [SLEEP SYNC] Failed to access shared UserDefaults")
        }
    }
    
    /// Validate that we have sleep data before loading cache
    private func validateAndLoadCache() async {
        // Check if we have sleep data from LAST NIGHT (not older data)
        guard let sleepInfo = await healthKitManager.fetchDetailedSleepData() else {
            // HealthKit returned nil - could be temporary access issue or genuinely no data
            // DON'T clear cache here - let the actual calculation handle it
            // This prevents flickering when HealthKit is temporarily inaccessible
            Logger.debug("️ Unable to fetch sleep data during validation - keeping cached data")
            loadCachedSleepScore() // Load what we have
            return
        }
        
        // Check if sleep data is from last night (within last 24 hours)
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        // Sleep should have ended within the last 24 hours
        if let wakeTime = sleepInfo.wakeTime, wakeTime > yesterday {
            // Fresh sleep data from last night - safe to load cache
            Logger.debug("✅ Sleep data from last night detected (wake: \(wakeTime))")
            loadCachedSleepScore()
        } else {
            // Sleep data is old (from 2+ nights ago) - clear cache
            Logger.warning("️ Sleep data is outdated (wake: \(sleepInfo.wakeTime?.description ?? "unknown")) - clearing cache")
            clearSleepScoreCache()
            currentSleepScore = nil
        }
    }
    
    /// Calculate today's sleep score
    func calculateSleepScore() async {
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation()
        }
        
        await calculationTask?.value
    }
    
    private func performCalculation() async {
        Logger.debug("🔄 Starting sleep score calculation")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            Logger.warning("️ Sleep score calculation already in progress, skipping...")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Add timeout to prevent hanging
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
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
            
            Logger.debug("✅ Sleep score calculation completed successfully")
        } catch {
            if error is CancellationError {
                Logger.debug("⏰ Sleep score calculation timed out after 10 seconds")
                errorMessage = "Calculation timed out. Please try again."
            } else {
                Logger.error("Sleep score calculation error: \(error)")
                errorMessage = "Calculation failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func performActualCalculation() async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        // iOS 26 WORKAROUND: Use isAuthorized instead of getAuthorizationStatus() which is buggy
        if !healthKitManager.isAuthorized {
            Logger.error("Sleep permissions not granted - skipping calculation")
            await MainActor.run {
                currentSleepScore = nil
                isLoading = false
            }
            return
        }
        
        #if DEBUG
        // Check if we're simulating no sleep data
        if UserDefaults.standard.bool(forKey: "simulateNoSleepData") {
            Logger.debug("💤 SIMULATION: No sleep data mode enabled - returning nil")
            currentSleepScore = nil
            // Still calculate sleep debt and consistency for historical data
            await calculateSleepDebt()
            await calculateSleepConsistency()
            clearSleepScoreCache()
            return
        }
        #endif
        
        // Use real data
        let realScore = await calculateRealSleepScore()
        currentSleepScore = realScore
        
        // Calculate additional sleep metrics
        await calculateSleepDebt()
        await calculateSleepConsistency()
        
        // Save to persistent cache for instant loading next time
        if let score = currentSleepScore {
            saveSleepScoreToCache(score)
        } else {
            // Clear cache if no sleep data available (user didn't wear watch)
            clearSleepScoreCache()
            Logger.debug("🗑️ Cleared sleep score cache - no data available")
            
            // Only trigger recovery refresh if it hasn't been calculated yet
            // (No need to recalculate if recovery is already done - it handles missing sleep gracefully)
            if !RecoveryScoreService.shared.hasCalculatedToday() {
                Task {
                    // Wait 2 seconds to let UI settle
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    Logger.debug("🔄 Triggering deferred recovery score refresh due to missing sleep data")
                    await RecoveryScoreService.shared.forceRefreshRecoveryScoreIgnoringDailyLimit()
                }
            } else {
                Logger.warning("️ Recovery already calculated today - skipping force refresh")
            }
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealSleepScore() async -> SleepScore? {
        // Calculate sleep need based on user target
        let sleepNeed = calculateSleepNeed()
        
        // Delegate to calculator (runs on background thread)
        return await calculator.calculateSleepScore(sleepNeed: sleepNeed)
    }
    
    // Legacy method - kept for reference but calculation moved to actor
    private func calculateRealSleepScoreOld() async -> SleepScore? {
        // Get detailed sleep data
        async let sleepData = healthKitManager.fetchDetailedSleepData()
        async let hrvData = healthKitManager.fetchLatestHRVData()
        async let baselines = BaselineCalculator().calculateAllBaselines()
        
        let (sleepInfo, hrv, (hrvBaseline, _, _, _)) = await (sleepData, hrvData, baselines)
        
        guard let sleepInfo = sleepInfo else {
            Logger.error("No sleep data available")
            return nil
        }
        
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
        
        // Calculate sleep need based on user target and training load
        let sleepNeed = calculateSleepNeed()
        
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
            baselineBedtime: calculateRealBaselineBedtime(from: sleepTimes),
            baselineWakeTime: calculateRealBaselineWakeTime(from: sleepTimes),
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
        let illnessIndicator = IllnessDetectionService.shared.currentIndicator
        let illnessDetected = illnessIndicator != nil
        let illnessSeverity = illnessIndicator?.severity.rawValue
        
        // Call VeloReadyCore for pure calculation
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
    
    /// Calculate sleep need based on user target and training load
    private func calculateSleepNeed() -> Double {
        // Base sleep need from user settings
        let sleepNeed = userSettings.sleepTargetSeconds
        
        return sleepNeed
    }
    
    /// Calculate real baseline bedtime from historical sleep data
    private func calculateRealBaselineBedtime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
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
        for (index, bedtime) in validBedtimes.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            Logger.debug("     Sample \(index + 1): \(formatter.string(from: bedtime))")
        }
        Logger.debug("   Calculated baseline bedtime: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
    
    /// Calculate real baseline wake time from historical sleep data
    private func calculateRealBaselineWakeTime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
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
        for (index, wakeTime) in validWakeTimes.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            Logger.debug("     Sample \(index + 1): \(formatter.string(from: wakeTime))")
        }
        Logger.debug("   Calculated baseline wake time: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
    
    /// Update sleep target
    func updateSleepTarget(_ target: Double) {
        userSettings.sleepTargetHours = target / 3600
        Logger.debug("🔄 Sleep target updated to \(String(format: "%.1f", target/3600)) hours")
    }
    
    /// Get current sleep target
    func getSleepTarget() -> Double {
        return userSettings.sleepTargetSeconds
    }
}

// MARK: - Sleep Score Extensions

extension SleepScore {
    /// Formatted sleep duration for display
    var formattedSleepDuration: String {
        guard let duration = inputs.sleepDuration else { return "No Data" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    /// Formatted sleep need for display
    var formattedSleepNeed: String {
        guard let need = inputs.sleepNeed else { return "No Data" }
        let hours = Int(need) / 3600
        let minutes = Int(need) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    /// Formatted sleep efficiency for display
    var formattedSleepEfficiency: String {
        guard let sleepDuration = inputs.sleepDuration,
              let timeInBed = inputs.timeInBed,
              timeInBed > 0 else { return "No Data" }
        
        let efficiency = (sleepDuration / timeInBed) * 100
        return String(format: "%.0f%%", efficiency)
    }
    
    /// Formatted deep sleep percentage for display
    var formattedDeepSleepPercentage: String {
        guard let sleepDuration = inputs.sleepDuration,
              let deepDuration = inputs.deepSleepDuration,
              sleepDuration > 0 else { return "No Data" }
        
        let percentage = (deepDuration / sleepDuration) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    /// Formatted REM sleep percentage for display
    var formattedREMSleepPercentage: String {
        guard let sleepDuration = inputs.sleepDuration,
              let remDuration = inputs.remSleepDuration,
              sleepDuration > 0 else { return "No Data" }
        
        let percentage = (remDuration / sleepDuration) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    
    /// Formatted wake events for display
    var formattedWakeEvents: String {
        guard let events = inputs.wakeEvents else { return "No Data" }
        return "\(events)"
    }
}

// MARK: - Persistent Caching Extension

extension SleepScoreService {
    
    /// Load cached sleep score for instant display
    private func loadCachedSleepScore() {
        Task {
            let cacheKey = CacheKey.sleepScore(date: Date())
            
            do {
                let cachedScore: SleepScore = try await cache.fetch(key: cacheKey, ttl: 86400) {
                    throw NSError(domain: "SleepScore", code: 404)
                }
                
                await MainActor.run {
                    currentSleepScore = cachedScore
                    Logger.debug("⚡ Loaded cached sleep score: \(cachedScore.score)")
                }
            } catch {
                Logger.debug("📦 No cached sleep score found")
            }
        }
    }
    
    /// Save sleep score to persistent cache
    private func saveSleepScoreToCache(_ score: SleepScore) {
        Task {
            let cacheKey = CacheKey.sleepScore(date: Date())
            
            do {
                let _ = try await cache.fetch(key: cacheKey, ttl: 86400) {
                    return score
                }
                Logger.debug("💾 Saved sleep score to cache: \(score.score)")
            } catch {
                Logger.error("Failed to save sleep score to cache: \(error)")
            }
            
            // Also save to shared UserDefaults for widget
            if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
                sharedDefaults.set(score.score, forKey: "cachedSleepScore")
                Logger.debug("⌚ Synced sleep score to shared defaults for widget")
                
                // Reload widgets to show new data
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    /// Clear sleep score cache
    private func clearSleepScoreCache() {
        Task {
            let cacheKey = CacheKey.sleepScore(date: Date())
            await cache.invalidate(key: cacheKey)
        }
    }
    
    // MARK: - Additional Sleep Metrics
    
    /// Calculate sleep debt from last 7 days
    private func calculateSleepDebt() async {
        let sleepNeed = calculateSleepNeed()
        
        // Fetch last 7 days of sleep data
        let sleepData = await healthKitManager.fetchHistoricalSleepData(days: 7)
        
        // Extract durations
        var sleepDurations: [(date: Date, duration: Double)] = []
        for (bedtime, wakeTime) in sleepData {
            if let bedtime = bedtime, let wakeTime = wakeTime {
                let duration = wakeTime.timeIntervalSince(bedtime)
                sleepDurations.append((date: bedtime, duration: duration))
            }
        }
        
        // Calculate sleep debt
        let debt = SleepDebt.calculate(sleepDurations: sleepDurations, sleepNeed: sleepNeed)
        
        await MainActor.run {
            currentSleepDebt = debt
            Logger.debug("💤 Sleep Debt: \(String(format: "%.1f", debt.totalDebtHours))h (\(debt.band.rawValue))")
        }
    }
    
    /// Calculate sleep consistency from last 7 days
    private func calculateSleepConsistency() async {
        // Fetch last 7 days of sleep data
        let sleepData = await healthKitManager.fetchHistoricalSleepData(days: 7)
        
        // Convert to sleep sessions
        var sleepSessions: [(bedtime: Date, wakeTime: Date)] = []
        for (bedtime, wakeTime) in sleepData {
            if let bedtime = bedtime, let wakeTime = wakeTime {
                sleepSessions.append((bedtime: bedtime, wakeTime: wakeTime))
            }
        }
        
        // Calculate consistency
        let consistency = SleepConsistency.calculate(sleepSessions: sleepSessions)
        
        await MainActor.run {
            currentSleepConsistency = consistency
            Logger.debug("📊 Sleep Consistency: \(consistency.score) (\(consistency.band.rawValue))")
            Logger.debug("   Bedtime variability: \(String(format: "%.1f", consistency.bedtimeVariability)) min")
            Logger.debug("   Wake time variability: \(String(format: "%.1f", consistency.wakeTimeVariability)) min")
        }
    }
}
