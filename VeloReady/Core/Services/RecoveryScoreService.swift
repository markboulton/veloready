import Foundation
import HealthKit

/// Service for calculating daily recovery scores
@MainActor
class RecoveryScoreService: ObservableObject {
    static let shared = RecoveryScoreService()
    
    @Published var currentRecoveryScore: RecoveryScore?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthKitManager = HealthKitManager.shared
    let baselineCalculator = BaselineCalculator() // Made public for cache clearing
    private let intervalsAPIClient: IntervalsAPIClient
    private let intervalsCache = IntervalsCache.shared
    private let sleepScoreService = SleepScoreService.shared
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    // Track when recovery score was last calculated to prevent recalculation
    private var lastRecoveryCalculationDate: Date?
    private let userDefaults = UserDefaults.standard
    private let recoveryScoreKey = "lastRecoveryCalculationDate"
    private let cachedRecoveryScoreKey = "cachedRecoveryScore"
    private let cachedRecoveryScoreDateKey = "cachedRecoveryScoreDate"
    
    init() {
        self.intervalsAPIClient = IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared)
        // Load last calculation date from UserDefaults
        if let savedDate = userDefaults.object(forKey: recoveryScoreKey) as? Date {
            self.lastRecoveryCalculationDate = savedDate
        }
        
        // Load cached recovery score immediately for instant display
        loadCachedRecoveryScore()
    }
    
    /// Calculate today's recovery score (only once per day, like Whoop)
    func calculateRecoveryScore() async {
        // Check if we already calculated today's recovery score
        if hasCalculatedToday() {
            print("✅ Recovery score already calculated today - skipping recalculation")
            print("🍷 NOTE: To test new alcohol detection algorithm, use forceRefreshRecoveryScoreIgnoringDailyLimit()")
            return
        }
        
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation(forceRefresh: false)
        }
        
        await calculationTask?.value
    }
    
    /// Force refresh recovery score with fresh API data
    func forceRefreshRecoveryScore() async {
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation(forceRefresh: true)
        }
        
        await calculationTask?.value
    }
    
    /// Force refresh recovery score (ignores daily calculation limit)
    func forceRefreshRecoveryScoreIgnoringDailyLimit() async {
        print("🔄 FORCE REFRESH: Ignoring daily limit and recalculating recovery score")
        
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation(forceRefresh: true, ignoreDailyLimit: true)
        }
        
        await calculationTask?.value
    }
    
    private func performCalculation(forceRefresh: Bool = false, ignoreDailyLimit: Bool = false) async {
        print("🔄 Starting recovery calculation (forceRefresh: \(forceRefresh))")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            print("⚠️ Recovery calculation already in progress, skipping...")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Add timeout to prevent hanging - reduced to 8 seconds for faster startup
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds
            throw CancellationError()
        }
        
        let calculationTask = Task {
            await performActualCalculation(forceRefresh: forceRefresh, ignoreDailyLimit: ignoreDailyLimit)
        }
        
        do {
            _ = try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await timeoutTask.value }
                group.addTask { await calculationTask.value }
                // Wait for first task to complete (either timeout or calculation)
                try await group.next()
                
                // Cancel the other task
                timeoutTask.cancel()
            }
            
            print("✅ Recovery calculation completed successfully")
        } catch {
            print("❌ Recovery calculation failed: \(error)")
            isLoading = false
        }
        
        isLoading = false
    }
    
    private func performActualCalculation(forceRefresh: Bool = false, ignoreDailyLimit: Bool = false) async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvStatus = healthKitManager.getAuthorizationStatus(for: hrvType)
        
        if hrvStatus == .sharingDenied {
            print("❌ Recovery permissions explicitly denied - skipping calculation")
            await MainActor.run {
                currentRecoveryScore = nil
                isLoading = false
            }
            return
        }
        
        // Use real data
        let realScore = await calculateRealRecoveryScore(forceRefresh: forceRefresh)
        currentRecoveryScore = realScore
        // Mark that we've calculated today's recovery score and save to cache
        if let score = currentRecoveryScore {
            if !ignoreDailyLimit {
                markAsCalculatedToday()
            }
            saveRecoveryScoreToCache(score)
            
            // Refresh AI brief to sync with new recovery data
            await AIBriefService.shared.refresh()
            print("🔄 AI brief refreshed to sync with recovery score")
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealRecoveryScore(forceRefresh: Bool = false) async -> RecoveryScore? {
        print("⚡ Starting parallel data fetching for recovery score...")
        
        // Sleep score should be calculated first so we can use actual sleep times for overnight HRV
        if sleepScoreService.currentSleepScore == nil {
            await sleepScoreService.calculateSleepScore()
        }
        
        // Get actual sleep times for overnight HRV window (physiologically correct)
        let sleepBedtime = sleepScoreService.currentSleepScore?.inputs.bedtime
        let sleepWakeTime = sleepScoreService.currentSleepScore?.inputs.wakeTime
        
        // Start all data fetching operations in parallel
        async let latestHRV = healthKitManager.fetchLatestHRVData()
        async let overnightHRV = healthKitManager.fetchOvernightHRVData(bedtime: sleepBedtime, wakeTime: sleepWakeTime) // Use actual sleep times
        async let latestRHR = healthKitManager.fetchLatestRHRData()
        async let latestRespiratoryRate = healthKitManager.fetchLatestRespiratoryRateData()
        async let baselines = baselineCalculator.calculateAllBaselines()
        async let intervalsData = fetchIntervalsData(forceRefresh: forceRefresh)
        async let recentStrain = fetchRecentStrain(forceRefresh: false) // Never force refresh strain to avoid race conditions
        
        // Wait for all parallel operations to complete
        let (hrv, overnightHrv, rhr, respiratoryRate) = await (latestHRV, overnightHRV, latestRHR, latestRespiratoryRate)
        let sleepScoreResult = sleepScoreService.currentSleepScore
        let (hrvBaseline, rhrBaseline, sleepBaseline, respiratoryBaseline) = await baselines
        let (atl, ctl) = await intervalsData
        let strain = await recentStrain
        
        print("⚡ All parallel data fetching completed")
        
        // Extract values for debugging
        let hrvValue = hrv.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        let overnightHrvValue = overnightHrv.value // Use the calculated average value from fetchOvernightHRVData
        let rhrValue = rhr.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        let respiratoryValue = respiratoryRate.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        print("🔍 Recovery Score Inputs:")
        print("   HRV: \(hrvValue?.description ?? "nil") ms (baseline: \(hrvBaseline?.description ?? "nil"))")
        print("   Overnight HRV: \(overnightHrvValue?.description ?? "nil") ms (for alcohol detection)")
        if overnightHrvValue == nil {
            print("   ⚠️ WARNING: No overnight HRV data - alcohol detection may fail!")
        }
        print("   RHR: \(rhrValue?.description ?? "nil") bpm (baseline: \(rhrBaseline?.description ?? "nil"))")
        print("   Sleep Score: \(sleepScoreResult?.score.description ?? "nil") (band: \(sleepScoreResult?.band.rawValue ?? "nil"))")
        if let sleepScore = sleepScoreResult {
            print("   Sleep Breakdown: Perf=\(sleepScore.subScores.performance), Quality=\(sleepScore.subScores.stageQuality), Eff=\(sleepScore.subScores.efficiency), Disturb=\(sleepScore.subScores.disturbances)")
        }
        print("   Respiratory: \(respiratoryValue?.description ?? "nil") breaths/min (baseline: \(respiratoryBaseline?.description ?? "nil"))")
        print("   ATL: \(atl?.description ?? "nil"), CTL: \(ctl?.description ?? "nil")")
        print("   Recent Strain: \(strain?.description ?? "nil")")
        
        // Calculate percentage changes for alcohol detection using OVERNIGHT HRV
        if let overnightHrv = overnightHrvValue, let hrvBase = hrvBaseline, hrvBase > 0 {
            let hrvChange = ((overnightHrv - hrvBase) / hrvBase) * 100
            print("🍷 Overnight HRV Change: \(String(format: "%.1f", hrvChange))% (alcohol threshold: -15%)")
        }
        if let rhr = rhrValue, let rhrBase = rhrBaseline, rhrBase > 0 {
            let rhrChange = ((rhr - rhrBase) / rhrBase) * 100
            print("🍷 RHR Change: \(String(format: "%.1f", rhrChange))% (alcohol threshold: +10%)")
        }
        
        // Create inputs with sleep score
        let inputs = RecoveryScore.RecoveryInputs(
            hrv: hrvValue,
            overnightHrv: overnightHrvValue,
            hrvBaseline: hrvBaseline,
            rhr: rhrValue,
            rhrBaseline: rhrBaseline,
            sleepDuration: sleepScoreResult?.inputs.sleepDuration,
            sleepBaseline: sleepBaseline,
            respiratoryRate: respiratoryValue,
            respiratoryBaseline: respiratoryBaseline,
            atl: atl,
            ctl: ctl,
            recentStrain: strain,
            sleepScore: sleepScoreResult
        )
        
        return RecoveryScoreCalculator.calculate(inputs: inputs)
    }
    
    // MARK: - Intervals Data Fetching
    
    private func fetchIntervalsData(forceRefresh: Bool = false) async -> (atl: Double?, ctl: Double?) {
        do {
            // Try Intervals.icu first (if available)
            let activities = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: forceRefresh)
            
            print("🔍 Using pre-calculated CTL/ATL from \(activities.count) cached activities")
            
            // Use the most recent activity's pre-calculated ATL/CTL values
            // Intervals.icu calculates these for us using their algorithms
            if let latestActivity = activities.first {
                let atl = latestActivity.atl
                let ctl = latestActivity.ctl
                
                print("📊 Pre-calculated Training Load Data from latest activity '\(latestActivity.name ?? "Unknown")':")
                print("   ATL=\(atl?.description ?? "nil"), CTL=\(ctl?.description ?? "nil")")
                print("   TSS=\(latestActivity.tss?.description ?? "nil")")
                
                return (atl, ctl)
            } else {
                print("⚠️ No Intervals.icu activities found, falling back to HealthKit")
                return await calculateTrainingLoadFromHealthKit()
            }
        } catch {
            print("❌ Failed to fetch Intervals data: \(error)")
            print("⚠️ Falling back to HealthKit training load calculation")
            return await calculateTrainingLoadFromHealthKit()
        }
    }
    
    /// Calculate training load from HealthKit workouts (fallback when Intervals.icu unavailable)
    private func calculateTrainingLoadFromHealthKit() async -> (atl: Double?, ctl: Double?) {
        let calculator = TrainingLoadCalculator()
        let (ctl, atl) = await calculator.calculateTrainingLoad()
        
        print("📊 HealthKit-based Training Load:")
        print("   CTL=\(String(format: "%.1f", ctl)), ATL=\(String(format: "%.1f", atl))")
        
        return (atl, ctl)
    }
    
    // MARK: - Recent Strain Calculation
    
    private func fetchRecentStrain(forceRefresh: Bool = false) async -> Double? {
        do {
            // Use normal caching behavior - cache serialization is now fixed
            // Never force refresh here to avoid race conditions - use cached data from fetchIntervalsData
            let recentActivities = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: false)
            
            // Filter for last 8 days to be more inclusive of "last week" activities
            let calendar = Calendar.current
            let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: Date()) ?? Date()
            
            print("🗓️ Filtering activities: eightDaysAgo=\(eightDaysAgo), today=\(Date())")
            print("🗓️ Sample activity dates from \(recentActivities.count) total activities:")
            for (index, activity) in recentActivities.prefix(3).enumerated() {
                if let date = parseActivityDate(activity.startDateLocal) {
                    print("   Activity \(index + 1): '\(activity.name ?? "Unnamed")' - \(date) (\(activity.startDateLocal))")
                } else {
                    print("   Activity \(index + 1): '\(activity.name ?? "Unnamed")' - FAILED TO PARSE (\(activity.startDateLocal))")
                }
            }
            
            let recentActivitiesFiltered = recentActivities.filter { activity in
                guard let activityDate = parseActivityDate(activity.startDateLocal) else { 
                    print("⚠️ Failed to parse date: \(activity.startDateLocal)")
                    return false 
                }
                let isRecent = activityDate >= eightDaysAgo
                if !isRecent {
                    print("🗓️ Activity '\(activity.name ?? "Unnamed")' is too old: \(activityDate) < \(eightDaysAgo)")
                }
                return isRecent
            }
            
            // Debug: Check what TSS values we have
            print("🔍 Checking TSS values in \(recentActivitiesFiltered.count) activities:")
            for (index, activity) in recentActivitiesFiltered.prefix(5).enumerated() {
                print("   Activity \(index + 1): \(activity.name ?? "Unnamed") - TSS: \(activity.tss?.description ?? "nil"), IF: \(activity.intensityFactor?.description ?? "nil")")
            }
            
            // Calculate total TSS from recent activities
            let totalTSS = recentActivitiesFiltered.compactMap { $0.tss }.reduce(0, +)
            
            // Calculate yesterday's TSS specifically for penalty
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            
            let yesterdayTSS = recentActivitiesFiltered.filter { activity in
                guard let activityDate = parseActivityDate(activity.startDateLocal) else { return false }
                return calendar.isDate(activityDate, inSameDayAs: yesterday)
            }.compactMap { $0.tss }.reduce(0, +)
            
            print("📊 Recent Strain: Total 8-day TSS=\(totalTSS), Yesterday TSS=\(yesterdayTSS) (from \(recentActivitiesFiltered.count) cached activities)")
            
            // Return yesterday's TSS as the primary strain metric
            return yesterdayTSS > 0 ? yesterdayTSS : nil
        } catch {
            print("❌ Failed to fetch recent strain: \(error)")
            return nil
        }
    }
    
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
    
    // MARK: - Cache Testing
    
    /// Test cache serialization by clearing cache and verifying data persistence
    func testCacheSerialization() async {
        print("🧪 Testing cache serialization...")
        
        // Clear cache and fetch fresh data
        intervalsCache.clearAllCache()
        
        do {
            // First fetch - should get fresh data from API
            print("🔄 First fetch (fresh from API)...")
            let activities1 = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: true)
            if let first1 = activities1.first {
                print("✅ Fresh API data: TSS=\(first1.tss?.description ?? "nil"), ATL=\(first1.atl?.description ?? "nil"), CTL=\(first1.ctl?.description ?? "nil")")
            }
            
            // Second fetch - should use cached data
            print("🔄 Second fetch (from cache)...")
            let activities2 = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: false)
            if let first2 = activities2.first {
                print("✅ Cached data: TSS=\(first2.tss?.description ?? "nil"), ATL=\(first2.atl?.description ?? "nil"), CTL=\(first2.ctl?.description ?? "nil")")
            }
            
            // Compare values
            if let first1 = activities1.first, let first2 = activities2.first {
                let tssMatch = first1.tss == first2.tss
                let atlMatch = first1.atl == first2.atl
                let ctlMatch = first1.ctl == first2.ctl
                
                if tssMatch && atlMatch && ctlMatch {
                    print("✅ Cache serialization test PASSED - all values match!")
                } else {
                    print("❌ Cache serialization test FAILED - values don't match")
                    print("   TSS: \(tssMatch ? "✅" : "❌") (\(first1.tss?.description ?? "nil") vs \(first2.tss?.description ?? "nil"))")
                    print("   ATL: \(atlMatch ? "✅" : "❌") (\(first1.atl?.description ?? "nil") vs \(first2.atl?.description ?? "nil"))")
                    print("   CTL: \(ctlMatch ? "✅" : "❌") (\(first1.ctl?.description ?? "nil") vs \(first2.ctl?.description ?? "nil"))")
                }
            }
        } catch {
            print("❌ Cache serialization test failed with error: \(error)")
        }
    }
    
    /// Force refresh all data and clear caches
    func forceRefreshData() async {
        print("🔄 Force refreshing data from API...")
        
        // Clear all caches first
        intervalsCache.clearAllCache()
        baselineCalculator.clearCache()
        
        // Wait a moment for cache clear to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Trigger fresh calculation with force refresh (ignoring daily limit for testing)
        await performCalculation(forceRefresh: true, ignoreDailyLimit: true)
    }
    
    /// Test alcohol detection algorithm (ignores daily limit)
    func testAlcoholDetection() async {
        print("🍷 Testing alcohol detection algorithm...")
        
        // Clear cached recovery score first
        clearCachedRecoveryScore()
        
        // Force recalculation with new algorithm
        await forceRefreshRecoveryScoreIgnoringDailyLimit()
    }
    
    // MARK: - Daily Recovery Score Tracking
    
    /// Check if we've already calculated today's recovery score
    private func hasCalculatedToday() -> Bool {
        guard let lastCalculation = lastRecoveryCalculationDate else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        return calendar.isDate(lastCalculation, inSameDayAs: today)
    }
    
    /// Mark that we've calculated today's recovery score
    private func markAsCalculatedToday() {
        lastRecoveryCalculationDate = Date()
        userDefaults.set(lastRecoveryCalculationDate, forKey: recoveryScoreKey)
        print("📅 Marked recovery score as calculated for today")
    }
    
    /// Reset daily calculation tracking (useful for testing or new day)
    func resetDailyCalculation() {
        lastRecoveryCalculationDate = nil
        userDefaults.removeObject(forKey: recoveryScoreKey)
        print("🔄 Reset daily recovery calculation tracking")
    }
}

// MARK: - Recovery Score Extensions

extension RecoveryScore {
    /// Formatted score for display
    var formattedScore: String {
        return "\(score)"
    }
    
    /// Color for the score band
    var bandColor: String {
        return band.color
    }
    
    /// Description of the recovery band
    var bandDescription: String {
        return band.description
    }
    
    /// Detailed breakdown of sub-scores
    var scoreBreakdown: String {
        return "HRV: \(subScores.hrv), RHR: \(subScores.rhr), Sleep: \(subScores.sleep), Form: \(subScores.form)"
    }
}

// MARK: - Persistent Caching Extension

extension RecoveryScoreService {
    
    /// Load cached recovery score for instant display
    private func loadCachedRecoveryScore() {
        guard let cachedData = userDefaults.data(forKey: cachedRecoveryScoreKey),
              let cachedDate = userDefaults.object(forKey: cachedRecoveryScoreDateKey) as? Date else {
            print("📦 No cached recovery score found")
            return
        }
        
        // Check if cache is from today
        let calendar = Calendar.current
        if calendar.isDate(cachedDate, inSameDayAs: Date()) {
            do {
                let decoder = JSONDecoder()
                let cachedScore = try decoder.decode(RecoveryScore.self, from: cachedData)
                currentRecoveryScore = cachedScore
                print("⚡ Loaded cached recovery score: \(cachedScore.score)")
            } catch {
                print("❌ Failed to decode cached recovery score: \(error)")
            }
        } else {
            print("📦 Cached recovery score is outdated, clearing cache")
            clearCachedRecoveryScore()
        }
    }
    
    /// Save recovery score to persistent cache
    private func saveRecoveryScoreToCache(_ score: RecoveryScore) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(score)
            userDefaults.set(data, forKey: cachedRecoveryScoreKey)
            userDefaults.set(Date(), forKey: cachedRecoveryScoreDateKey)
            print("💾 Saved recovery score to cache: \(score.score)")
        } catch {
            print("❌ Failed to save recovery score to cache: \(error)")
        }
    }
    
    /// Clear cached recovery score
    private func clearCachedRecoveryScore() {
        userDefaults.removeObject(forKey: cachedRecoveryScoreKey)
        userDefaults.removeObject(forKey: cachedRecoveryScoreDateKey)
    }
    
    /// Clear baseline cache to force fresh calculation from HealthKit
    func clearBaselineCache() {
        baselineCalculator.clearCache()
    }
}
