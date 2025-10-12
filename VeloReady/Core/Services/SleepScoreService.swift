import Foundation
import HealthKit

/// Service for calculating daily sleep scores using Whoop-like algorithm
@MainActor
class SleepScoreService: ObservableObject {
    static let shared = SleepScoreService()
    
    @Published var currentSleepScore: SleepScore?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private let userSettings = UserSettings.shared
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    // Persistent caching
    private let userDefaults = UserDefaults.standard
    private let cachedSleepScoreKey = "cachedSleepScore"
    private let cachedSleepScoreDateKey = "cachedSleepScoreDate"
    
    init() {
        // Load cached sleep score immediately for instant display
        loadCachedSleepScore()
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
        print("🔄 Starting sleep score calculation")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            print("⚠️ Sleep score calculation already in progress, skipping...")
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
            
            print("✅ Sleep score calculation completed successfully")
        } catch {
            if error is CancellationError {
                print("⏰ Sleep score calculation timed out after 10 seconds")
                errorMessage = "Calculation timed out. Please try again."
            } else {
                print("❌ Sleep score calculation error: \(error)")
                errorMessage = "Calculation failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func performActualCalculation() async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepStatus = healthKitManager.getAuthorizationStatus(for: sleepType)
        
        if sleepStatus == .sharingDenied {
            print("❌ Sleep permissions explicitly denied - skipping calculation")
            await MainActor.run {
                currentSleepScore = nil
                isLoading = false
            }
            return
        }
        
        // Use real data
        let realScore = await calculateRealSleepScore()
        currentSleepScore = realScore
        
        // Save to persistent cache for instant loading next time
        if let score = currentSleepScore {
            saveSleepScoreToCache(score)
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealSleepScore() async -> SleepScore? {
        // Get detailed sleep data
        async let sleepData = healthKitManager.fetchDetailedSleepData()
        async let hrvData = healthKitManager.fetchLatestHRVData()
        async let baselines = baselineCalculator.calculateAllBaselines()
        
        let (sleepInfo, hrv, (hrvBaseline, _, _, _)) = await (sleepData, hrvData, baselines)
        
        guard let sleepInfo = sleepInfo else {
            print("❌ No sleep data available")
            return nil
        }
        
        // Calculate sleep need based on user target and training load
        let sleepNeed = calculateSleepNeed()
        
        // Calculate real baselines from historical data
        async let historicalSleepData = healthKitManager.fetchHistoricalSleepData(days: 7)
        let sleepTimes = await historicalSleepData
        
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
            hrvBaseline: hrvBaseline
        )
        
        print("🔍 Sleep Score Inputs:")
        print("   Sleep Duration: \(inputs.sleepDuration?.description ?? "nil") seconds")
        print("   Time in Bed: \(inputs.timeInBed?.description ?? "nil") seconds")
        print("   Sleep Need: \(inputs.sleepNeed?.description ?? "nil") seconds")
        print("   Deep Sleep: \(inputs.deepSleepDuration?.description ?? "nil") seconds")
        print("   REM Sleep: \(inputs.remSleepDuration?.description ?? "nil") seconds")
        print("   Wake Events: \(inputs.wakeEvents?.description ?? "nil")")
        print("   HRV Overnight: \(inputs.hrvOvernight?.description ?? "nil") ms")
        print("   HRV Baseline: \(inputs.hrvBaseline?.description ?? "nil") ms")
        
        return SleepScoreCalculator.calculate(inputs: inputs)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate sleep need based on user target and training load
    private func calculateSleepNeed() -> Double {
        // Base sleep need from user settings
        let sleepNeed = userSettings.sleepTargetSeconds
        
        // TODO: Adjust based on training load from Intervals.icu
        // For now, just return the user's target
        
        return sleepNeed
    }
    
    /// Calculate real baseline bedtime from historical sleep data
    private func calculateRealBaselineBedtime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
        guard !sleepTimes.isEmpty else {
            print("⚠️ No historical sleep data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: -10, to: Date()) // Fallback to 10 PM
        }
        
        // Extract valid bedtimes and filter recent nights
        let validBedtimes = sleepTimes.compactMap { $0.bedtime }
        
        guard !validBedtimes.isEmpty else {
            print("⚠️ No valid bedtime data for baseline calculation")
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
        
        print("🔍 BASELINE CALCULATION:")
        print("   Valid bedtime samples: \(validBedtimes.count)")
        for (index, bedtime) in validBedtimes.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            print("     Sample \(index + 1): \(formatter.string(from: bedtime))")
        }
        print("   Calculated baseline bedtime: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
    
    /// Calculate real baseline wake time from historical sleep data
    private func calculateRealBaselineWakeTime(from sleepTimes: [(bedtime: Date?, wakeTime: Date?)]) -> Date? {
        guard !sleepTimes.isEmpty else {
            print("⚠️ No historical sleep data for baseline calculation")
            return Calendar.current.date(byAdding: .hour, value: -6, to: Date()) // Fallback to 6 AM
        }
        
        // Extract valid wake times
        let validWakeTimes = sleepTimes.compactMap { $0.wakeTime }
        
        guard !validWakeTimes.isEmpty else {
            print("⚠️ No valid wake time data for baseline calculation")
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
        
        print("   Valid wake time samples: \(validWakeTimes.count)")
        for (index, wakeTime) in validWakeTimes.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            print("     Sample \(index + 1): \(formatter.string(from: wakeTime))")
        }
        print("   Calculated baseline wake time: \(timeOnlyBaseline?.description ?? "nil")")
        
        return timeOnlyBaseline
    }
    
    /// Update sleep target
    func updateSleepTarget(_ target: Double) {
        userSettings.sleepTargetHours = target / 3600
        print("🔄 Sleep target updated to \(String(format: "%.1f", target/3600)) hours")
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
        guard let cachedData = userDefaults.data(forKey: cachedSleepScoreKey),
              let cachedDate = userDefaults.object(forKey: cachedSleepScoreDateKey) as? Date else {
            print("📦 No cached sleep score found")
            return
        }
        
        // Check if cache is from today
        let calendar = Calendar.current
        if calendar.isDate(cachedDate, inSameDayAs: Date()) {
            do {
                let decoder = JSONDecoder()
                let cachedScore = try decoder.decode(SleepScore.self, from: cachedData)
                currentSleepScore = cachedScore
                print("⚡ Loaded cached sleep score: \(cachedScore.score)")
            } catch {
                print("❌ Failed to decode cached sleep score: \(error)")
            }
        } else {
            print("📦 Cached sleep score is outdated, clearing cache")
            clearCachedSleepScore()
        }
    }
    
    /// Save sleep score to persistent cache
    private func saveSleepScoreToCache(_ score: SleepScore) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(score)
            userDefaults.set(data, forKey: cachedSleepScoreKey)
            userDefaults.set(Date(), forKey: cachedSleepScoreDateKey)
            print("💾 Saved sleep score to cache: \(score.score)")
        } catch {
            print("❌ Failed to save sleep score to cache: \(error)")
        }
    }
    
    /// Clear cached sleep score
    private func clearCachedSleepScore() {
        userDefaults.removeObject(forKey: cachedSleepScoreKey)
        userDefaults.removeObject(forKey: cachedSleepScoreDateKey)
    }
}
