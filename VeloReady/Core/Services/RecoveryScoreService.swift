import Foundation
import HealthKit
import WidgetKit

/// Service for calculating daily recovery scores
@MainActor
class RecoveryScoreService: ObservableObject {
    static let shared = RecoveryScoreService()
    
    @Published var currentRecoveryScore: RecoveryScore?
    @Published var currentRecoveryDebt: RecoveryDebt?
    @Published var currentReadinessScore: ReadinessScore?
    @Published var currentResilienceScore: ResilienceScore?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthKitManager = HealthKitManager.shared
    let baselineCalculator = BaselineCalculator() // Made public for cache clearing
    private let intervalsAPIClient: IntervalsAPIClient
    private let intervalsCache = IntervalsCache.shared
    private let sleepScoreService = SleepScoreService.shared
    private let cache = UnifiedCacheManager.shared
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    // Track when recovery score was last calculated to prevent recalculation
    private var lastRecoveryCalculationDate: Date?
    private let userDefaults = UserDefaults.standard
    private let recoveryScoreKey = "lastRecoveryCalculationDate"
    
    init() {
        self.intervalsAPIClient = IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared)
        // Load last calculation date from UserDefaults
        if let savedDate = userDefaults.object(forKey: recoveryScoreKey) as? Date {
            self.lastRecoveryCalculationDate = savedDate
        }
        
        // Load cached recovery score immediately for instant display
        Task {
            await loadCachedRecoveryScore()
        }
    }
    
    /// Calculate today's recovery score (only once per day, like Whoop)
    func calculateRecoveryScore() async {
        // Check if we already calculated today's recovery score AND have a valid cached score
        if hasCalculatedToday() && currentRecoveryScore != nil {
            Logger.debug("✅ Recovery score already calculated today - skipping recalculation")
            Logger.debug("🍷 NOTE: To test new alcohol detection algorithm, use forceRefreshRecoveryScoreIgnoringDailyLimit()")
            return
        }
        
        // If we calculated today but cache is missing, recalculate
        if hasCalculatedToday() && currentRecoveryScore == nil {
            Logger.warning("⚠️ Recovery was calculated today but cache is missing - recalculating")
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
        Logger.debug("🔄 FORCE REFRESH: Ignoring daily limit and recalculating recovery score")
        
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation(forceRefresh: true, ignoreDailyLimit: true)
        }
        
        await calculationTask?.value
    }
    
    private func performCalculation(forceRefresh: Bool = false, ignoreDailyLimit: Bool = false) async {
        Logger.debug("🔄 Starting recovery calculation (forceRefresh: \(forceRefresh))")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            Logger.warning("️ Recovery calculation already in progress, skipping...")
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
            
            Logger.debug("✅ Recovery calculation completed successfully")
        } catch {
            Logger.error("Recovery calculation failed: \(error)")
            isLoading = false
        }
        
        isLoading = false
    }
    
    private func performActualCalculation(forceRefresh: Bool = false, ignoreDailyLimit: Bool = false) async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvStatus = healthKitManager.getAuthorizationStatus(for: hrvType)
        
        if hrvStatus == .sharingDenied {
            Logger.error("Recovery permissions explicitly denied - skipping calculation")
            await MainActor.run {
                currentRecoveryScore = nil
                isLoading = false
            }
            return
        }
        
        // Use real data
        let realScore = await calculateRealRecoveryScore(forceRefresh: forceRefresh)
        currentRecoveryScore = realScore
        
        // Sync to Apple Watch
        if let score = realScore {
            WatchConnectivityManager.shared.sendRecoveryScore(score)
        }
        
        // Calculate additional recovery metrics
        await calculateRecoveryDebt()
        await calculateReadinessScore()
        await calculateResilienceScore()
        
        // Send recovery alert if score is low
        if let score = realScore {
            await NotificationManager.shared.sendRecoveryAlert(score: Double(score.score), band: score.band.rawValue)
        }
        
        // Mark that we've calculated today's recovery score and save to cache
        if let score = currentRecoveryScore {
            // Check if recovery score actually changed
            let previousScore = await loadCachedRecoveryScoreData()
            let scoreChanged = previousScore?.score != score.score
            
            if !ignoreDailyLimit {
                markAsCalculatedToday()
            }
            await saveRecoveryScoreToCache(score)
            
            // Only refresh AI brief if recovery score actually changed (avoids unnecessary API calls)
            if scoreChanged {
                Logger.data("Recovery score changed (\(previousScore?.score ?? 0) → \(score.score)) - refreshing AI brief")
                await AIBriefService.shared.refresh()
            } else {
                Logger.warning("️ Recovery score unchanged - skipping AI brief refresh")
            }
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealRecoveryScore(forceRefresh: Bool = false) async -> RecoveryScore? {
        Logger.debug("⚡ Starting parallel data fetching for recovery score...")
        
        // CRITICAL: Sleep score MUST be calculated first for accurate recovery calculation
        // If sleep score is being calculated, wait for it. If not started, start it.
        if sleepScoreService.currentSleepScore == nil {
            if sleepScoreService.isLoading {
                // Sleep calculation already in progress - wait for it
                Logger.debug("⏳ Sleep calculation in progress - waiting for completion...")
                
                // Poll until sleep score is available or loading completes
                var attempts = 0
                while sleepScoreService.isLoading && attempts < 50 { // Max 5 seconds
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    attempts += 1
                }
                
                if sleepScoreService.currentSleepScore != nil {
                    Logger.debug("✅ Sleep score now available after waiting: \(sleepScoreService.currentSleepScore!.score)")
                } else {
                    Logger.warning("⚠️ Sleep score still nil after waiting - recovery will show 'Limited Data'")
                }
            } else {
                // Sleep not started yet - trigger it and wait
                Logger.debug("⏳ Starting sleep score calculation...")
                await sleepScoreService.calculateSleepScore()
                
                if sleepScoreService.currentSleepScore != nil {
                    Logger.debug("✅ Sleep score now available: \(sleepScoreService.currentSleepScore!.score)")
                } else {
                    Logger.warning("⚠️ Sleep score still nil after calculation - recovery will show 'Limited Data'")
                }
            }
        } else {
            Logger.debug("✅ Sleep score already available: \(sleepScoreService.currentSleepScore!.score)")
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
        
        // Get sleep score - should be available now since we waited for it
        let sleepScoreResult = sleepScoreService.currentSleepScore
        
        // Log if sleep data is still missing
        if sleepScoreResult == nil {
            Logger.warning("⚠️ Sleep score is nil - recovery will show 'Limited Data'")
            Logger.warning("   This usually means: no sleep data in HealthKit for last night")
        }
        
        let (hrvBaseline, rhrBaseline, sleepBaseline, respiratoryBaseline) = await baselines
        let (atl, ctl) = await intervalsData
        let strain = await recentStrain
        
        Logger.debug("⚡ All parallel data fetching completed")
        
        // Extract values for debugging
        let hrvValue = hrv.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        let overnightHrvValue = overnightHrv.value // Use the calculated average value from fetchOvernightHRVData
        let rhrValue = rhr.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        let respiratoryValue = respiratoryRate.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        Logger.debug("🔍 Recovery Score Inputs:")
        Logger.debug("   HRV: \(hrvValue?.description ?? "nil") ms (baseline: \(hrvBaseline?.description ?? "nil"))")
        Logger.debug("   Overnight HRV: \(overnightHrvValue?.description ?? "nil") ms (for alcohol detection)")
        if overnightHrvValue == nil {
            Logger.debug("   ⚠️ WARNING: No overnight HRV data - alcohol detection may fail!")
        }
        Logger.debug("   RHR: \(rhrValue?.description ?? "nil") bpm (baseline: \(rhrBaseline?.description ?? "nil"))")
        Logger.debug("   Sleep Score: \(sleepScoreResult?.score.description ?? "nil") (band: \(sleepScoreResult?.band.rawValue ?? "nil"))")
        if let sleepScore = sleepScoreResult {
            Logger.debug("   Sleep Breakdown: Perf=\(sleepScore.subScores.performance), Quality=\(sleepScore.subScores.stageQuality), Eff=\(sleepScore.subScores.efficiency), Disturb=\(sleepScore.subScores.disturbances)")
        }
        Logger.debug("   Respiratory: \(respiratoryValue?.description ?? "nil") breaths/min (baseline: \(respiratoryBaseline?.description ?? "nil"))")
        Logger.debug("   ATL: \(atl?.description ?? "nil"), CTL: \(ctl?.description ?? "nil")")
        Logger.debug("   Recent Strain: \(strain?.description ?? "nil")")
        
        // Calculate percentage changes for alcohol detection using OVERNIGHT HRV
        if let overnightHrv = overnightHrvValue, let hrvBase = hrvBaseline, hrvBase > 0 {
            let hrvChange = ((overnightHrv - hrvBase) / hrvBase) * 100
            Logger.debug("🍷 Overnight HRV Change: \(String(format: "%.1f", hrvChange))% (alcohol threshold: -15%)")
        }
        if let rhr = rhrValue, let rhrBase = rhrBaseline, rhrBase > 0 {
            let rhrChange = ((rhr - rhrBase) / rhrBase) * 100
            Logger.debug("🍷 RHR Change: \(String(format: "%.1f", rhrChange))% (alcohol threshold: +10%)")
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
        
        // Get current illness indicator
        let illnessIndicator = IllnessDetectionService.shared.currentIndicator
        
        return await RecoveryScoreCalculator.calculate(inputs: inputs, illnessIndicator: illnessIndicator)
    }
    
    // MARK: - Intervals Data Fetching
    
    private func fetchIntervalsData(forceRefresh: Bool = false) async -> (atl: Double?, ctl: Double?) {
        do {
            // Try Intervals.icu first (if available)
            let activities = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: forceRefresh)
            
            Logger.debug("🔍 Using pre-calculated CTL/ATL from \(activities.count) cached activities")
            
            // Use the most recent activity's pre-calculated ATL/CTL values
            // Intervals.icu calculates these for us using their algorithms
            if let latestActivity = activities.first {
                let atl = latestActivity.atl
                let ctl = latestActivity.ctl
                
                Logger.data("Pre-calculated Training Load Data from latest activity '\(latestActivity.name ?? "Unknown")':")
                Logger.debug("   ATL=\(atl?.description ?? "nil"), CTL=\(ctl?.description ?? "nil")")
                Logger.debug("   TSS=\(latestActivity.tss?.description ?? "nil")")
                
                // If Intervals.icu has CTL/ATL, use them
                if atl != nil && ctl != nil {
                    return (atl, ctl)
                }
                
                // Otherwise fall through to calculate from unified activities
                Logger.warning("️ Intervals.icu activities don't have CTL/ATL, calculating from unified activities")
            }
            
            // Fall back to calculating from all unified activities (Strava + Intervals + HealthKit)
            return await calculateTrainingLoadFromUnifiedActivities()
            
        } catch {
            Logger.error("Failed to fetch Intervals data: \(error)")
            Logger.warning("️ Falling back to unified activities calculation")
            return await calculateTrainingLoadFromUnifiedActivities()
        }
    }
    
    /// Calculate training load from unified activities (Strava + Intervals + HealthKit)
    /// This is more robust than relying on Intervals.icu pre-calculated values
    private func calculateTrainingLoadFromUnifiedActivities() async -> (atl: Double?, ctl: Double?) {
        Logger.data("Calculating CTL/ATL from unified activities (Strava + Intervals + HealthKit)...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fortyTwoDaysAgo = calendar.date(byAdding: .day, value: -42, to: today)!
        
        // Get activities from unified service (handles Intervals.icu + Strava fallback)
        var allActivities: [UnifiedActivity] = []
        
        do {
            // Use UnifiedActivityService which properly handles Strava fallback
            let activities = try await UnifiedActivityService.shared.fetchActivitiesForTrainingLoad()
            Logger.data("Got \(activities.count) activities from unified service")
            
            // Convert to UnifiedActivity using proper initializer
            for activity in activities {
                allActivities.append(UnifiedActivity(from: activity))
            }
        } catch {
            Logger.warning("️ Could not fetch activities from unified service: \(error)")
        }
        
        // Filter to last 42 days (should already be filtered, but double-check)
        let recentActivities = allActivities.filter { activity in
            activity.startDate >= fortyTwoDaysAgo
        }
        
        Logger.data("Found \(recentActivities.count) activities in last 42 days for CTL/ATL calculation")
        
        // Calculate daily TSS for each day
        var dailyTSS: [Date: Double] = [:]
        
        for activity in recentActivities {
            let day = calendar.startOfDay(for: activity.startDate)
            let tss = estimateTSS(for: activity)
            dailyTSS[day, default: 0] += tss
        }
        
        // Calculate CTL (42-day exponentially weighted average)
        let ctl = calculateCTL(from: dailyTSS, today: today)
        
        // Calculate ATL (7-day exponentially weighted average)
        let atl = calculateATL(from: dailyTSS, today: today)
        
        Logger.data("Calculated Training Load from unified activities:")
        Logger.debug("   CTL=\(String(format: "%.1f", ctl)), ATL=\(String(format: "%.1f", atl))")
        Logger.debug("   TSB=\(String(format: "%.1f", ctl - atl))")
        
        return (atl, ctl)
    }
    
    /// Estimate TSS for a unified activity
    private func estimateTSS(for activity: UnifiedActivity) -> Double {
        // If we have TSS from Intervals.icu, use it
        if let intervalsTSS = activity.intervalsActivity?.tss {
            return intervalsTSS
        }
        
        // Otherwise estimate from duration and intensity
        guard let duration = activity.duration else { return 0 }
        
        let durationHours = duration / 3600.0
        
        // Estimate based on activity type and duration
        switch activity.type {
        case .cycling:
            // Cycling: ~70 TSS/hour for moderate intensity
            return durationHours * 70
        case .running:
            // Running: ~100 TSS/hour (higher impact)
            return durationHours * 100
        case .swimming:
            // Swimming: ~60 TSS/hour
            return durationHours * 60
        case .walking:
            // Walking: ~30 TSS/hour
            return durationHours * 30
        case .strength:
            // Strength: ~50 TSS/hour
            return durationHours * 50
        default:
            // Other: ~50 TSS/hour
            return durationHours * 50
        }
    }
    
    /// Calculate CTL (Chronic Training Load) - 42-day exponentially weighted average
    private func calculateCTL(from dailyTSS: [Date: Double], today: Date) -> Double {
        let calendar = Calendar.current
        let ctlDecay = 1.0 / 42.0 // Time constant for CTL
        var ctl = 0.0
        
        // Calculate for last 42 days
        for dayOffset in (0..<42).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let tss = dailyTSS[date] ?? 0
            ctl = ctl + (tss - ctl) * ctlDecay
        }
        
        return ctl
    }
    
    /// Calculate ATL (Acute Training Load) - 7-day exponentially weighted average
    private func calculateATL(from dailyTSS: [Date: Double], today: Date) -> Double {
        let calendar = Calendar.current
        let atlDecay = 1.0 / 7.0 // Time constant for ATL
        var atl = 0.0
        
        // Calculate for last 7 days
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let tss = dailyTSS[date] ?? 0
            atl = atl + (tss - atl) * atlDecay
        }
        
        return atl
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
            
            Logger.debug("🗓️ Filtering activities: eightDaysAgo=\(eightDaysAgo), today=\(Date())")
            Logger.debug("🗓️ Sample activity dates from \(recentActivities.count) total activities:")
            for (index, activity) in recentActivities.prefix(3).enumerated() {
                if let date = parseActivityDate(activity.startDateLocal) {
                    Logger.debug("   Activity \(index + 1): '\(activity.name ?? "Unnamed")' - \(date) (\(activity.startDateLocal))")
                } else {
                    Logger.debug("   Activity \(index + 1): '\(activity.name ?? "Unnamed")' - FAILED TO PARSE (\(activity.startDateLocal))")
                }
            }
            
            let recentActivitiesFiltered = recentActivities.filter { activity in
                guard let activityDate = parseActivityDate(activity.startDateLocal) else { 
                    Logger.warning("️ Failed to parse date: \(activity.startDateLocal)")
                    return false 
                }
                let isRecent = activityDate >= eightDaysAgo
                if !isRecent {
                    Logger.debug("🗓️ Activity '\(activity.name ?? "Unnamed")' is too old: \(activityDate) < \(eightDaysAgo)")
                }
                return isRecent
            }
            
            // Debug: Check what TSS values we have
            Logger.debug("🔍 Checking TSS values in \(recentActivitiesFiltered.count) activities:")
            for (index, activity) in recentActivitiesFiltered.prefix(5).enumerated() {
                Logger.debug("   Activity \(index + 1): \(activity.name ?? "Unnamed") - TSS: \(activity.tss?.description ?? "nil"), IF: \(activity.intensityFactor?.description ?? "nil")")
            }
            
            // Calculate total TSS from recent activities
            let totalTSS = recentActivitiesFiltered.compactMap { $0.tss }.reduce(0, +)
            
            // Calculate yesterday's TSS specifically for penalty
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            
            let yesterdayTSS = recentActivitiesFiltered.filter { activity in
                guard let activityDate = parseActivityDate(activity.startDateLocal) else { return false }
                return calendar.isDate(activityDate, inSameDayAs: yesterday)
            }.compactMap { $0.tss }.reduce(0, +)
            
            Logger.data("Recent Strain: Total 8-day TSS=\(totalTSS), Yesterday TSS=\(yesterdayTSS) (from \(recentActivitiesFiltered.count) cached activities)")
            
            // Return yesterday's TSS as the primary strain metric
            return yesterdayTSS > 0 ? yesterdayTSS : nil
        } catch {
            Logger.error("Failed to fetch recent strain: \(error)")
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
        Logger.debug("🧪 Testing cache serialization...")
        
        // Clear cache and fetch fresh data
        intervalsCache.clearAllCache()
        
        do {
            // First fetch - should get fresh data from API
            Logger.debug("🔄 First fetch (fresh from API)...")
            let activities1 = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: true)
            if let first1 = activities1.first {
                Logger.debug("✅ Fresh API data: TSS=\(first1.tss?.description ?? "nil"), ATL=\(first1.atl?.description ?? "nil"), CTL=\(first1.ctl?.description ?? "nil")")
            }
            
            // Second fetch - should use cached data
            Logger.debug("🔄 Second fetch (from cache)...")
            let activities2 = try await intervalsCache.getCachedActivities(apiClient: intervalsAPIClient, forceRefresh: false)
            if let first2 = activities2.first {
                Logger.debug("✅ Cached data: TSS=\(first2.tss?.description ?? "nil"), ATL=\(first2.atl?.description ?? "nil"), CTL=\(first2.ctl?.description ?? "nil")")
            }
            
            // Compare values
            if let first1 = activities1.first, let first2 = activities2.first {
                let tssMatch = first1.tss == first2.tss
                let atlMatch = first1.atl == first2.atl
                let ctlMatch = first1.ctl == first2.ctl
                
                if tssMatch && atlMatch && ctlMatch {
                    Logger.debug("✅ Cache serialization test PASSED - all values match!")
                } else {
                    Logger.error("Cache serialization test FAILED - values don't match")
                    Logger.debug("   TSS: \(tssMatch ? "✅" : "❌") (\(first1.tss?.description ?? "nil") vs \(first2.tss?.description ?? "nil"))")
                    Logger.debug("   ATL: \(atlMatch ? "✅" : "❌") (\(first1.atl?.description ?? "nil") vs \(first2.atl?.description ?? "nil"))")
                    Logger.debug("   CTL: \(ctlMatch ? "✅" : "❌") (\(first1.ctl?.description ?? "nil") vs \(first2.ctl?.description ?? "nil"))")
                }
            }
        } catch {
            Logger.error("Cache serialization test failed with error: \(error)")
        }
    }
    
    /// Force refresh all data and clear caches
    func forceRefreshData() async {
        Logger.debug("🔄 Force refreshing data from API...")
        
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
        Logger.debug("🍷 Testing alcohol detection algorithm...")
        
        // Clear cached recovery score first
        let cacheKey = CacheKey.recoveryScore(date: Date())
        await cache.invalidate(key: cacheKey)
        
        // Force recalculation with new algorithm
        await forceRefreshRecoveryScoreIgnoringDailyLimit()
    }
    
    // MARK: - Daily Recovery Score Tracking
    
    /// Check if we've already calculated today's recovery score
    func hasCalculatedToday() -> Bool {
        guard let lastCalculation = lastRecoveryCalculationDate else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        return calendar.isDate(lastCalculation, inSameDayAs: today)
    }
    
    /// Mark that we've calculated today's recovery score
    private func markAsCalculatedToday() {
        lastRecoveryCalculationDate = Date()
        userDefaults.set(lastRecoveryCalculationDate, forKey: recoveryScoreKey)
        Logger.debug("📅 Marked recovery score as calculated for today")
    }
    
    /// Reset daily calculation tracking (useful for testing or new day)
    func resetDailyCalculation() {
        lastRecoveryCalculationDate = nil
        userDefaults.removeObject(forKey: recoveryScoreKey)
        Logger.debug("🔄 Reset daily recovery calculation tracking")
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
    private func loadCachedRecoveryScore() async {
        let cacheKey = CacheKey.recoveryScore(date: Date())
        
        // Try to get cached score - wrap in do-catch since we're checking if it exists
        do {
            let cachedScore: RecoveryScore = try await cache.fetch(key: cacheKey, ttl: 86400) {
                // If no cache, return nil to skip
                throw NSError(domain: "RecoveryScore", code: 404)
            }
            
            currentRecoveryScore = cachedScore
            Logger.debug("⚡ Loaded cached recovery score: \(cachedScore.score)")
            
            // Also save to shared UserDefaults for widget/watch
            if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
                sharedDefaults.set(cachedScore.score, forKey: "cachedRecoveryScore")
                sharedDefaults.set(cachedScore.band.rawValue, forKey: "cachedRecoveryBand")
                sharedDefaults.set(cachedScore.isPersonalized, forKey: "cachedRecoveryIsPersonalized")
                Logger.debug("⌚ Synced cached recovery score to shared defaults for widget/watch")
                
                // Reload widgets to show cached data
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            // No cached score or error - this is fine on first launch
            Logger.debug("📦 No cached recovery score found")
        }
    }
    
    /// Load cached recovery score data (for comparison)
    private func loadCachedRecoveryScoreData() async -> RecoveryScore? {
        let cacheKey = CacheKey.recoveryScore(date: Date())
        
        do {
            return try await cache.fetch(key: cacheKey, ttl: 86400) {
                throw NSError(domain: "RecoveryScore", code: 404)
            }
        } catch {
            return nil
        }
    }
    
    /// Save recovery score to persistent cache
    private func saveRecoveryScoreToCache(_ score: RecoveryScore) async {
        let cacheKey = CacheKey.recoveryScore(date: Date())
        
        // Store in UnifiedCacheManager - use fetch with immediate return
        do {
            let _ = try await cache.fetch(key: cacheKey, ttl: 86400) {
                return score
            }
            Logger.debug("💾 Saved recovery score to cache: \(score.score)")
        } catch {
            Logger.error("Failed to save recovery score to cache: \(error)")
        }
        
        // Also save to shared UserDefaults for widget/watch
        if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
            sharedDefaults.set(score.score, forKey: "cachedRecoveryScore")
            sharedDefaults.set(score.band.rawValue, forKey: "cachedRecoveryBand")
            sharedDefaults.set(score.isPersonalized, forKey: "cachedRecoveryIsPersonalized")
            Logger.debug("⌚ Saved recovery score to shared defaults for widget/watch")
            
            // Reload widgets to show new data immediately
            WidgetCenter.shared.reloadAllTimelines()
            Logger.debug("🔄 Reloaded widget timelines")
        }
    }
    
    /// Clear baseline cache to force fresh calculation from HealthKit
    func clearBaselineCache() {
        baselineCalculator.clearCache()
    }
    
    // MARK: - Additional Recovery Metrics
    
    /// Calculate recovery debt from Core Data history
    private func calculateRecoveryDebt() async {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // Fetch last 14 days of recovery scores from Core Data
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -14, to: endDate) else { return }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND recoveryScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try context.fetch(fetchRequest)
            let recoveryScores = results.compactMap { dailyScore -> (date: Date, score: Int)? in
                guard let date = dailyScore.date else { return nil }
                return (date: date, score: Int(dailyScore.recoveryScore))
            }
            
            let debt = RecoveryDebt.calculate(recoveryScores: recoveryScores)
            
            await MainActor.run {
                currentRecoveryDebt = debt
                Logger.debug("🔋 Recovery Debt: \(debt.consecutiveDays) days (\(debt.band.rawValue))")
            }
        } catch {
            Logger.error("Failed to fetch recovery history: \(error)")
        }
    }
    
    /// Calculate readiness score from recovery, sleep, and strain
    private func calculateReadinessScore() async {
        guard let recovery = currentRecoveryScore else { return }
        
        // Get sleep score
        let sleepScore = sleepScoreService.currentSleepScore?.score ?? 50
        
        // Get strain score from StrainScoreService
        let strainScore = StrainScoreService.shared.currentStrainScore?.score ?? 0
        
        let readiness = ReadinessScore.calculate(
            recoveryScore: recovery.score,
            sleepScore: sleepScore,
            strainScore: strainScore
        )
        
        await MainActor.run {
            currentReadinessScore = readiness
            Logger.debug("🎯 Readiness: \(readiness.score) (\(readiness.band.rawValue))")
            Logger.debug("   Recovery: \(recovery.score), Sleep: \(sleepScore), Load: \(Int(strainScore))")
        }
    }
    
    /// Calculate resilience score from 30-day history
    private func calculateResilienceScore() async {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // Fetch last 30 days of recovery and strain scores from Core Data
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else { return }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND recoveryScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try context.fetch(fetchRequest)
            
            let recoveryScores = results.compactMap { dailyScore -> (date: Date, score: Int)? in
                guard let date = dailyScore.date else { return nil }
                return (date: date, score: Int(dailyScore.recoveryScore))
            }
            
            let strainScores = results.compactMap { dailyScore -> (date: Date, score: Double)? in
                guard let date = dailyScore.date else { return nil }
                return (date: date, score: dailyScore.strainScore)
            }
            
            if let resilience = ResilienceScore.calculate(
                recoveryScores: recoveryScores,
                strainScores: strainScores
            ) {
                await MainActor.run {
                    currentResilienceScore = resilience
                    Logger.debug("💪 Resilience: \(resilience.score) (\(resilience.band.rawValue))")
                    Logger.debug("   Avg Recovery: \(String(format: "%.1f", resilience.averageRecovery)), Avg Load: \(String(format: "%.1f", resilience.averageLoad))")
                }
            } else {
                await MainActor.run {
                    currentResilienceScore = nil
                    Logger.debug("💪 Resilience: Insufficient valid data (need 14+ days with scores > 0)")
                }
            }
        } catch {
            Logger.error("Failed to fetch resilience history: \(error)")
        }
    }
}
