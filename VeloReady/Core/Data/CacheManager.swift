import Foundation
import CoreData
import Combine
import HealthKit

/// Manages caching and refresh strategies for daily data
@MainActor
final class CacheManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = CacheManager()
    
    // MARK: - Properties
    
    private let persistence = PersistenceController.shared
    private let healthKit = HealthKitManager.shared
    private let intervalsAPI: IntervalsAPIClient
    private let oauthManager = IntervalsOAuthManager.shared
    
    // Access to actual score services
    private let recoveryService = RecoveryScoreService.shared
    private let sleepService = SleepScoreService.shared
    private let strainService = StrainScoreService.shared
    
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshDate: Date?
    
    // MARK: - Cache Age Thresholds
    
    private enum CacheAge {
        static let today: TimeInterval = 3600 // 1 hour
        static let yesterday: TimeInterval = 6 * 3600 // 6 hours
        static let recent: TimeInterval = 24 * 3600 // 24 hours
    }
    
    // MARK: - Initialization
    
    private init() {
        self.intervalsAPI = IntervalsAPIClient(oauthManager: oauthManager)
        // Schedule automatic pruning
        schedulePruning()
    }
    
    // MARK: - Fetch Cached Data
    
    /// Fetch cached data for a specific date
    func fetchCachedDay(for date: Date) -> DailyScores? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        request.fetchLimit = 1
        
        return persistence.fetch(request).first
    }
    
    /// Fetch cached data for the last N days
    func fetchCachedDays(count: Int = 7) -> [DailyScores] {
        let today = Calendar.current.startOfDay(for: Date())
        guard let startDate = Calendar.current.date(byAdding: .day, value: -(count - 1), to: today) else {
            return []
        }
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, today as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        return persistence.fetch(request)
    }
    
    // MARK: - Cache Validation
    
    /// Check if cached data needs refresh
    func needsRefresh(for date: Date) -> Bool {
        guard let cached = fetchCachedDay(for: date) else {
            return true // No cache = needs refresh
        }
        
        guard let lastUpdated = cached.lastUpdated else {
            return true // No lastUpdated = needs refresh
        }
        
        let age = Date().timeIntervalSince(lastUpdated)
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        switch daysAgo {
        case 0: // Today
            return age > CacheAge.today
        case 1: // Yesterday
            return age > CacheAge.yesterday
        case 2...6: // Recent days
            return age > CacheAge.recent
        default: // Older days
            return false // Don't refresh historical data
        }
    }
    
    // MARK: - Refresh Data
    
    /// Refresh data for today (force fetch from APIs)
    func refreshToday() async throws {
        isRefreshing = true
        defer { isRefreshing = false }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch fresh data from APIs
        async let healthData = fetchHealthData()
        async let intervalsData = fetchIntervalsData()
        
        let (health, intervals) = try await (healthData, intervalsData)
        
        // Save to Core Data
        await saveToCache(date: today, health: health, intervals: intervals)
        
        lastRefreshDate = Date()
        
        // Log summary
        let hasHealth = health.hrv != nil || health.rhr != nil || health.sleep != nil
        let hasIntervals = intervals.ctl != nil || intervals.atl != nil
        Logger.debug("✅ Refreshed today's data (Health: \(hasHealth), Intervals: \(hasIntervals))")
    }
    
    /// Refresh last N days (smart refresh based on cache age)
    func refreshRecentDays(count: Int = 7, force: Bool = false) async throws {
        // Prevent runaway refreshes - check if already refreshing
        guard !isRefreshing else {
            Logger.warning("️ Cache refresh already in progress, skipping")
            return
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let today = Calendar.current.startOfDay(for: Date())
        var refreshedCount = 0
        
        for dayOffset in 0..<count {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            // Skip if cache is fresh (unless forced)
            if !force && !needsRefresh(for: date) {
                continue
            }
            
            do {
                async let healthData = fetchHealthData(for: date)
                async let intervalsData = fetchIntervalsData(for: date)
                
                let (health, intervals) = try await (healthData, intervalsData)
                
                await saveToCache(date: date, health: health, intervals: intervals)
                refreshedCount += 1
            } catch {
                Logger.warning("️ Failed to refresh \(date): \(error)")
                // Continue with other days
            }
        }
        
        lastRefreshDate = Date()
        Logger.debug("✅ Cache refresh complete: \(refreshedCount)/\(count) days updated")
    }
    
    // MARK: - Fetch from APIs
    
    private func fetchHealthData(for date: Date = Date()) async throws -> HealthData {
        // For historical dates, we can't fetch "latest" - we need historical data
        // For now, only fetch for today; historical data should come from Core Data cache
        let isToday = Calendar.current.isDateInToday(date)
        
        if !isToday {
            // Don't fetch health data for historical dates - it's not available
            // Historical health data should already be in Core Data from when it was "today"
            return HealthData(hrv: nil, rhr: nil, sleep: nil, hrvBaseline: nil, rhrBaseline: nil, sleepBaseline: nil)
        }
        
        // Fetch latest HRV (only for today)
        let hrvData = await healthKit.fetchLatestHRVData()
        
        // Fetch latest RHR (only for today)
        let rhrData = await healthKit.fetchLatestRHRData()
        
        // Fetch sleep data (only for today)
        let sleepData = await healthKit.fetchDetailedSleepData()
        
        // Calculate 30-day baselines (simplified - you may want to implement proper baseline calculation)
        let hrvBaseline = hrvData.value // Placeholder - implement proper baseline
        let rhrBaseline = rhrData.value // Placeholder - implement proper baseline
        let sleepBaseline = sleepData?.sleepDuration // Placeholder - implement proper baseline
        
        return HealthData(
            hrv: hrvData.value,
            rhr: rhrData.value,
            sleep: sleepData?.sleepDuration,
            hrvBaseline: hrvBaseline,
            rhrBaseline: rhrBaseline,
            sleepBaseline: sleepBaseline
        )
    }
    
    private func fetchIntervalsData(for date: Date = Date()) async throws -> IntervalsData {
        // Fetch activities for adaptive FTP calculation
        var activities: [IntervalsActivity] = []
        
        // Check if authenticated with Intervals.icu
        if oauthManager.isAuthenticated {
            do {
                // Fetch wellness data (last 30 days)
                let wellnessArray = try await intervalsAPI.fetchWellnessData()
                
                // Find wellness data for the specific date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let targetDateString = dateFormatter.string(from: date)
                _ = wellnessArray.first { $0.id == targetDateString }
                
                // Fetch recent activities using unified service (respects Pro tier limits)
                activities = try await UnifiedActivityService.shared.fetchActivitiesForFTP()
                Logger.debug("📊 [Zones] Fetched \(activities.count) activities for zone computation")
            } catch {
                Logger.warning("⚠️ Failed to fetch Intervals data: \(error)")
            }
        } else {
            Logger.debug("📊 [Zones] Intervals.icu not authenticated - using unified service for Strava")
            
            // Use unified service (will fallback to Strava automatically)
            do {
                activities = try await UnifiedActivityService.shared.fetchActivitiesForFTP()
                Logger.debug("📊 [Zones] Fetched \(activities.count) activities for zone computation")
            } catch {
                Logger.warning("⚠️ Failed to fetch activities: \(error)")
            }
        }
        
        // Compute athlete zones from activities (async) - works with both Intervals and Strava
        // Run in background to avoid blocking UI
        if !activities.isEmpty {
            Task.detached(priority: .background) { @MainActor in
                Logger.data("🎯 [Zones] Starting background zone computation with \(activities.count) activities")
                await AthleteProfileManager.shared.computeFromActivities(activities)
                Logger.data("✅ [Zones] Background zone computation complete")
            }
        }
        
        // If not authenticated with Intervals, return empty Intervals-specific data
        guard oauthManager.isAuthenticated else {
            return IntervalsData(ctl: nil, atl: nil, tsb: nil, tss: nil, eftp: nil, workout: nil)
        }
        
        do {
            // Fetch wellness data again for Intervals-specific metrics
            let wellnessArray = try await intervalsAPI.fetchWellnessData()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let targetDateString = dateFormatter.string(from: date)
            let dateWellness = wellnessArray.first { $0.id == targetDateString }
            
            // Find activity for the specific date
            let calendar = Calendar.current
            let targetDay = calendar.startOfDay(for: date)
            let dateActivity = activities.first { activity in
                let activityFormatter = ISO8601DateFormatter()
                activityFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                guard let activityDate = activityFormatter.date(from: activity.startDateLocal) else { return false }
                return calendar.isDate(activityDate, inSameDayAs: targetDay)
            }
            
            // For CTL/ATL, use the most recent activity up to and including this date
            // CTL/ATL are cumulative values that represent training load as of that date
            let mostRecentActivity = activities.first { activity in
                let activityFormatter = ISO8601DateFormatter()
                activityFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                guard let activityDate = activityFormatter.date(from: activity.startDateLocal) else { return false }
                return activityDate <= date
            }
            
            // Try to fetch athlete data, but don't fail if it errors (403)
            var ftp: Double? = nil
            do {
                let athleteData = try await intervalsAPI.fetchAthleteData()
                ftp = athleteData.powerZones?.ftp
            } catch {
                Logger.warning("️ Could not fetch athlete data (non-critical): \(error)")
                // Continue without FTP - not critical for caching
            }
            
            return IntervalsData(
                ctl: mostRecentActivity?.ctl ?? dateWellness?.fitness, // CTL from most recent activity or wellness.fitness
                atl: mostRecentActivity?.atl ?? dateWellness?.fatigue, // ATL from most recent activity or wellness.fatigue
                tsb: dateWellness?.form, // Form is TSB in Intervals.icu
                tss: dateActivity?.tss, // TSS only for activities on this specific date
                eftp: ftp,
                workout: dateActivity // Workout only if there was one on this date
            )
        } catch {
            // If any Intervals API call fails, return empty data instead of throwing
            Logger.warning("️ Failed to fetch Intervals data: \(error) - using empty data")
            return IntervalsData(ctl: nil, atl: nil, tsb: nil, tss: nil, eftp: nil, workout: nil)
        }
    }
    
    // MARK: - Save to Cache
    
    private func saveToCache(date: Date, health: HealthData, intervals: IntervalsData) async {
        let context = persistence.newBackgroundContext()
        
        // Only use current scores for today - historical dates should not be overwritten
        let isToday = Calendar.current.isDateInToday(date)
        let recoveryScore = isToday ? self.recoveryService.currentRecoveryScore : nil
        let sleepScore = isToday ? self.sleepService.currentSleepScore : nil
        let strainScore = isToday ? self.strainService.currentStrainScore : nil
        
        await context.perform {
            let startOfDay = Calendar.current.startOfDay(for: date)
            
            // Fetch or create DailyPhysio
            let physioRequest = DailyPhysio.fetchRequest()
            physioRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
            physioRequest.fetchLimit = 1
            
            let physio = (try? context.fetch(physioRequest).first) ?? DailyPhysio(context: context)
            physio.date = startOfDay
            
            // Only update health data if we have new data (for today) or if it's empty
            if isToday {
                // Use actual values from RecoveryScore inputs for today
                physio.hrv = recoveryScore?.inputs.hrv ?? health.hrv ?? 0
                physio.hrvBaseline = recoveryScore?.inputs.hrvBaseline ?? health.hrvBaseline ?? 0
                physio.rhr = recoveryScore?.inputs.rhr ?? health.rhr ?? 0
                physio.rhrBaseline = recoveryScore?.inputs.rhrBaseline ?? health.rhrBaseline ?? 0
                physio.sleepDuration = recoveryScore?.inputs.sleepDuration ?? health.sleep ?? 0
                physio.sleepBaseline = recoveryScore?.inputs.sleepBaseline ?? health.sleepBaseline ?? 0
            } else if physio.hrv == 0 && physio.rhr == 0 {
                // Only set to 0 if no data exists (don't overwrite historical data)
                physio.hrv = 0
                physio.rhr = 0
                physio.sleepDuration = 0
            }
            // Always set lastUpdated, even for historical dates
            physio.lastUpdated = Date()
            
            // Fetch or create DailyLoad
            let loadRequest = DailyLoad.fetchRequest()
            loadRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
            loadRequest.fetchLimit = 1
            
            let load = (try? context.fetch(loadRequest).first) ?? DailyLoad(context: context)
            load.date = startOfDay
            
            // Use Intervals data if available, otherwise calculate locally
            if let ctl = intervals.ctl, let atl = intervals.atl {
                load.ctl = ctl
                load.atl = atl
                load.tsb = intervals.tsb ?? (ctl - atl)
            } else {
                // Calculate CTL/ATL locally if Intervals doesn't provide it
                // This will be populated by calculateMissingCTLATL() method
                load.ctl = load.ctl // Keep existing value if already calculated
                load.atl = load.atl
                load.tsb = load.ctl - load.atl
            }
            
            load.tss = intervals.tss ?? 0
            load.eftp = intervals.eftp ?? 0
            load.workoutId = intervals.workout?.id
            load.workoutName = intervals.workout?.name
            load.workoutType = intervals.workout?.type
            load.lastUpdated = Date()
            
            // Fetch or create DailyScores
            let scoresRequest = DailyScores.fetchRequest()
            scoresRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
            scoresRequest.fetchLimit = 1
            
            let scores = (try? context.fetch(scoresRequest).first) ?? DailyScores(context: context)
            scores.date = startOfDay
            scores.physio = physio
            scores.load = load
            
            // Only update scores for today - don't overwrite historical scores
            if isToday {
                let recoveryScoreValue = Double(recoveryScore?.score ?? 50)
                let sleepScoreValue = Double(sleepScore?.score ?? 50)
                let strainScoreValue = Double(strainScore?.score ?? 0)
                let effortTarget = self.calculateEffortTarget(recovery: recoveryScoreValue, ctl: intervals.ctl)
                
                scores.recoveryScore = recoveryScoreValue
                scores.recoveryBand = recoveryScore?.band.rawValue ?? self.recoveryBand(for: recoveryScoreValue)
                scores.sleepScore = sleepScoreValue
                scores.strainScore = strainScoreValue
                scores.effortTarget = effortTarget
            } else if scores.recoveryScore == 0 {
                // Only set defaults if no data exists
                scores.recoveryScore = 50
                scores.recoveryBand = "amber"
                scores.sleepScore = 50
                scores.strainScore = 0
                scores.effortTarget = self.calculateEffortTarget(recovery: 50, ctl: intervals.ctl)
            }
            // Always set lastUpdated, even for historical dates
            scores.lastUpdated = Date()
            
            // Debug logging
            Logger.debug("💾 Saving to Core Data:")
            Logger.debug("   Date: \(startOfDay)")
            Logger.debug("   HRV: \(physio.hrv), RHR: \(physio.rhr), Sleep: \(physio.sleepDuration/3600)h")
            Logger.debug("   CTL: \(load.ctl), ATL: \(load.atl), TSS: \(load.tss)")
            Logger.debug("   Recovery: \(scores.recoveryScore) (\(scores.recoveryBand ?? "unknown"))")
            Logger.debug("   Sleep Score: \(scores.sleepScore), Strain: \(scores.strainScore)")
            Logger.debug("   Effort Target: \(scores.effortTarget)")
            
            self.persistence.save(context: context)
            
            Logger.debug("✅ Core Data save completed successfully")
        }
    }
    
    // MARK: - Score Calculations (Simplified)
    
    private func calculateRecoveryScore(health: HealthData, intervals: IntervalsData) -> Double {
        // Simplified - use your actual RecoveryScore logic
        var score = 50.0
        
        if let hrv = health.hrv, let hrvBaseline = health.hrvBaseline, hrvBaseline > 0 {
            let hrvRatio = hrv / hrvBaseline
            score += (hrvRatio - 1.0) * 30
        }
        
        if let rhr = health.rhr, let rhrBaseline = health.rhrBaseline, rhrBaseline > 0 {
            let rhrRatio = rhr / rhrBaseline
            score += (1.0 - rhrRatio) * 20
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateSleepScore(health: HealthData) -> Double {
        guard let sleep = health.sleep, let baseline = health.sleepBaseline, baseline > 0 else {
            return 50
        }
        
        let ratio = sleep / baseline
        return max(0, min(100, ratio * 100))
    }
    
    private func calculateStrainScore(intervals: IntervalsData) -> Double {
        guard let tss = intervals.tss else { return 0 }
        return min(100, tss)
    }
    
    private func calculateEffortTarget(recovery: Double, ctl: Double?) -> Double {
        let baseTarget = (ctl ?? 60) * 0.8
        let recoveryMultiplier = 0.6 + (recovery / 100) * 0.8
        return baseTarget * recoveryMultiplier
    }
    
    private func recoveryBand(for score: Double) -> String {
        if score >= 70 { return "green" }
        if score >= 40 { return "amber" }
        return "red"
    }
    
    // MARK: - Pruning
    
    private func schedulePruning() {
        // Prune old data once per day
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 24 * 3600 * 1_000_000_000) // 24 hours
                persistence.pruneOldData(olderThanDays: 90)
            }
        }
    }
    
    // MARK: - CTL/ATL Calculation
    
    /// Calculate missing CTL/ATL values from activities
    /// Called when Intervals.icu doesn't provide CTL/ATL data
    /// Optimized to backfill last 42 days and save TSS values
    /// Smart caching: Only runs once per day to avoid redundant calculations
    func calculateMissingCTLATL() async {
        // Check if backfill ran recently (within 24 hours)
        let lastBackfillKey = "lastCTLBackfill"
        if let lastBackfill = UserDefaults.standard.object(forKey: lastBackfillKey) as? Date {
            let hoursSinceBackfill = Date().timeIntervalSince(lastBackfill) / 3600
            if hoursSinceBackfill < 24 {
                Logger.data("⏭️ [CTL/ATL BACKFILL] Skipping - last run was \(String(format: "%.1f", hoursSinceBackfill))h ago (< 24h)")
                return
            }
            Logger.data("🔄 [CTL/ATL BACKFILL] Last run was \(String(format: "%.1f", hoursSinceBackfill))h ago - running fresh backfill")
        }
        
        Logger.data("📊 [CTL/ATL BACKFILL] Starting calculation for last 42 days...")
        
        let calculator = TrainingLoadCalculator()
        var progressiveLoad: [Date: (ctl: Double, atl: Double, tss: Double)] = [:]
        
        // Try Intervals.icu first
        Logger.data("📊 [CTL/ATL BACKFILL] Step 1: Checking Intervals.icu...")
        let intervalsActivities = (try? await IntervalsAPIClient.shared.fetchRecentActivities(limit: 200, daysBack: 60)) ?? []
        
        if !intervalsActivities.isEmpty {
            let activitiesWithTSS = intervalsActivities.filter { ($0.tss ?? 0) > 0 }
            Logger.data("📊 [CTL/ATL BACKFILL] Found \(activitiesWithTSS.count) Intervals activities with TSS")
            
            if !activitiesWithTSS.isEmpty {
                // Get progressive CTL/ATL with TSS per day
                let ctlAtlData = calculator.calculateProgressiveTrainingLoad(intervalsActivities)
                let dailyTSS = calculator.getDailyTSSFromActivities(intervalsActivities)
                
                Logger.data("📊 [CTL/ATL BACKFILL] Intervals gave us \(ctlAtlData.count) days of CTL/ATL")
                Logger.data("📊 [CTL/ATL BACKFILL] Daily TSS has \(dailyTSS.count) entries")
                
                // Combine CTL/ATL with TSS
                for (date, load) in ctlAtlData {
                    let tss = dailyTSS[date] ?? 0
                    progressiveLoad[date] = (ctl: load.ctl, atl: load.atl, tss: tss)
                }
            }
        } else {
            Logger.data("📊 [CTL/ATL BACKFILL] No Intervals activities found")
        }
        
        // If no Intervals data, calculate from HealthKit using TRIMP
        if progressiveLoad.isEmpty {
            Logger.data("📊 [CTL/ATL BACKFILL] Step 2: Falling back to HealthKit workouts...")
            progressiveLoad = await calculator.calculateProgressiveTrainingLoadFromHealthKit()
            Logger.data("📊 [CTL/ATL BACKFILL] HealthKit calculation returned \(progressiveLoad.count) days")
            
            // Log first few entries
            let sortedDates = progressiveLoad.keys.sorted()
            for date in sortedDates.prefix(5) {
                if let load = progressiveLoad[date] {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd"
                    Logger.data("📊   \(formatter.string(from: date)): CTL=\(String(format: "%.1f", load.ctl)), ATL=\(String(format: "%.1f", load.atl)), TSS=\(String(format: "%.1f", load.tss))")
                }
            }
        }
        
        Logger.data("📊 [CTL/ATL BACKFILL] Step 3: Saving \(progressiveLoad.count) days to Core Data...")
        
        // Batch update DailyLoad entities for performance
        await updateDailyLoadBatch(progressiveLoad)
        
        // Save timestamp of successful backfill
        UserDefaults.standard.set(Date(), forKey: "lastCTLBackfill")
        
        Logger.data("✅ [CTL/ATL BACKFILL] Complete! (Next run allowed in 24h)")
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
                
                let loadRequest = DailyLoad.fetchRequest()
                loadRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
                loadRequest.fetchLimit = 1
                
                let existingLoad: DailyLoad
                let isNew: Bool
                if let fetched = try? context.fetch(loadRequest).first {
                    existingLoad = fetched
                    isNew = false
                } else {
                    // Create new DailyLoad if doesn't exist
                    existingLoad = DailyLoad(context: context)
                    existingLoad.date = startOfDay
                    isNew = true
                    createdCount += 1
                }
                
                // Update if:
                // 1. It's a new entry (just created), OR
                // 2. TSS is currently 0 (needs backfill), OR
                // 3. CTL/ATL are both 0 or very small
                let shouldUpdate = isNew || existingLoad.tss == 0.0 || (existingLoad.ctl < 1.0 && existingLoad.atl < 1.0)
                
                if shouldUpdate {
                    existingLoad.ctl = load.ctl
                    existingLoad.atl = load.atl
                    existingLoad.tsb = load.ctl - load.atl
                    existingLoad.tss = load.tss
                    existingLoad.lastUpdated = Date()
                    updatedCount += 1
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd"
                    Logger.data("  ✅ \(formatter.string(from: startOfDay)): CTL=\(String(format: "%.1f", load.ctl)), ATL=\(String(format: "%.1f", load.atl)), TSS=\(String(format: "%.1f", load.tss)) \(isNew ? "[NEW]" : "[UPDATED]")")
                } else {
                    skippedCount += 1
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd"
                    Logger.data("  ⏭️ \(formatter.string(from: startOfDay)): Skipped (has existing data: CTL=\(existingLoad.ctl), TSS=\(existingLoad.tss))")
                }
            }
            
            // Batch save for performance
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.data("✅ [BATCH UPDATE] Saved \(updatedCount) updates (\(createdCount) new, \(updatedCount - createdCount) modified, \(skippedCount) skipped)")
                } catch {
                    Logger.error("❌ [BATCH UPDATE] Failed to save: \(error)")
                }
            } else {
                Logger.data("📊 [BATCH UPDATE] No changes to save (\(skippedCount) entries skipped)")
            }
        }
    }
    
    // MARK: - Historical Data Backfill
    
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
        
        // Fetch all sleep sessions
        let sleepSessions = await HealthKitManager.shared.fetchSleepSessions(from: startDate, to: Date())
        
        Logger.data("📊 [PHYSIO BACKFILL] Fetched \(hrvSamples.count) HRV, \(rhrSamples.count) RHR, \(sleepSessions.count) sleep samples")
        
        // Group samples by day
        var dailyData: [Date: (hrv: Double?, rhr: Double?, sleep: TimeInterval?)] = [:]
        
        // Group HRV by day (use average)
        for sample in hrvSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            
            if let existing = dailyData[day]?.hrv {
                dailyData[day] = (hrv: (existing + value) / 2, rhr: dailyData[day]?.rhr, sleep: dailyData[day]?.sleep)
            } else {
                dailyData[day] = (hrv: value, rhr: dailyData[day]?.rhr, sleep: dailyData[day]?.sleep)
            }
        }
        
        // Group RHR by day (use minimum)
        for sample in rhrSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            if let existing = dailyData[day]?.rhr {
                dailyData[day] = (hrv: dailyData[day]?.hrv, rhr: min(existing, value), sleep: dailyData[day]?.sleep)
            } else {
                dailyData[day] = (hrv: dailyData[day]?.hrv, rhr: value, sleep: dailyData[day]?.sleep)
            }
        }
        
        // Group sleep by day (sum duration for each night)
        for session in sleepSessions {
            let day = calendar.startOfDay(for: session.wakeTime)
            let duration = session.wakeTime.timeIntervalSince(session.bedtime)
            
            if let existing = dailyData[day]?.sleep {
                dailyData[day] = (hrv: dailyData[day]?.hrv, rhr: dailyData[day]?.rhr, sleep: existing + duration)
            } else {
                dailyData[day] = (hrv: dailyData[day]?.hrv, rhr: dailyData[day]?.rhr, sleep: duration)
            }
        }
        
        Logger.data("📊 [PHYSIO BACKFILL] Grouped into \(dailyData.count) days with data")
        
        // Save to Core Data
        let context = persistence.container.newBackgroundContext()
        await context.perform {
            var savedCount = 0
            var skippedCount = 0
            
            for (date, data) in dailyData {
                // Skip today (it's handled by normal refresh)
                if calendar.isDateInToday(date) {
                    skippedCount += 1
                    continue
                }
                
                // Fetch or create DailyPhysio
                let request = DailyPhysio.fetchRequest()
                request.predicate = NSPredicate(format: "date == %@", date as NSDate)
                request.fetchLimit = 1
                
                let physio = (try? context.fetch(request).first) ?? DailyPhysio(context: context)
                physio.date = date
                
                // Only update if we have new data and existing is 0 (don't overwrite)
                if let hrv = data.hrv, physio.hrv == 0 {
                    physio.hrv = hrv
                    savedCount += 1
                }
                if let rhr = data.rhr, physio.rhr == 0 {
                    physio.rhr = rhr
                }
                if let sleep = data.sleep, physio.sleepDuration == 0 {
                    physio.sleepDuration = sleep
                }
                
                physio.lastUpdated = Date()
            }
            
            if savedCount > 0 {
                do {
                    try context.save()
                    Logger.data("✅ [PHYSIO BACKFILL] Saved \(savedCount) days (\(skippedCount) skipped)")
                } catch {
                    Logger.error("❌ [PHYSIO BACKFILL] Failed to save: \(error)")
                }
            } else {
                Logger.data("📊 [PHYSIO BACKFILL] No new data to save")
            }
        }
    }
}

// MARK: - Supporting Types

struct HealthData {
    let hrv: Double?
    let rhr: Double?
    let sleep: TimeInterval?
    let hrvBaseline: Double?
    let rhrBaseline: Double?
    let sleepBaseline: TimeInterval?
}

struct IntervalsData {
    let ctl: Double?
    let atl: Double?
    let tsb: Double?
    let tss: Double?
    let eftp: Double?
    let workout: IntervalsActivity?
}
