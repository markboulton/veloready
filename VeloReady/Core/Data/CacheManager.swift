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
    private let trainingLoadCalculator = TrainingLoadCalculator()
    private let baselineCalculator = BaselineCalculator()
    
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
        
        // CRITICAL FIX: Only refresh TODAY
        // Historical dates can't be fetched from HealthKit (no historical API)
        // Historical data is already in Core Data from when it was "today"
        // Trying to refresh historical dates overwrites good data with zeros
        
        do {
            async let healthData = fetchHealthData()  // Today only
            async let intervalsData = fetchIntervalsData()  // Today only
            
            let (health, intervals) = try await (healthData, intervalsData)
            
            await saveToCache(date: today, health: health, intervals: intervals)
            refreshedCount = 1
        } catch {
            Logger.warning("️ Failed to refresh today: \(error)")
        }
        
        lastRefreshDate = Date()
        Logger.debug("✅ Cache refresh complete: \(refreshedCount) day(s) updated (today only)")
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
        
        // Calculate 7-day baselines using BaselineCalculator
        let hrvBaseline = await baselineCalculator.calculateHRVBaseline()
        let rhrBaseline = await baselineCalculator.calculateRHRBaseline()
        let sleepBaseline = await baselineCalculator.calculateSleepBaseline()
        
        Logger.debug("📊 [CacheManager] Calculated baselines: HRV=\(hrvBaseline?.description ?? "nil"), RHR=\(rhrBaseline?.description ?? "nil"), Sleep=\(sleepBaseline?.description ?? "nil")")
        
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
        var activities: [Activity] = []
        
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
        
        // If not authenticated with Intervals, calculate training load from HealthKit
        guard oauthManager.isAuthenticated else {
            Logger.debug("📊 [CacheManager] Intervals.icu not authenticated - calculating training load from HealthKit")
            
            // Calculate training load from HealthKit workouts
            let (ctl, atl) = await trainingLoadCalculator.calculateTrainingLoad()
            let tsb = ctl - atl
            
            Logger.debug("📊 [CacheManager] HealthKit training load: CTL=\(ctl), ATL=\(atl), TSB=\(tsb)")
            
            return IntervalsData(
                ctl: ctl,
                atl: atl,
                tsb: tsb,
                tss: nil, // No TSS for today without activity data
                eftp: nil,
                workout: nil
            )
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
            
            Logger.debug("🔍 [DailyScores] Fetching existing scores for date: \(startOfDay)")
            let existingScores = try? context.fetch(scoresRequest).first
            if let existing = existingScores {
                Logger.debug("✅ [DailyScores] Found existing scores for \(startOfDay) - will update")
            } else {
                Logger.debug("❌ [DailyScores] No existing scores for \(startOfDay) - creating new")
            }
            
            let scores = existingScores ?? DailyScores(context: context)
            scores.date = startOfDay
            scores.physio = physio
            scores.load = load
            
            // Always update scores for today (may change throughout the day)
            // For historical dates, only set if no data exists
            if isToday {
                let recoveryScoreValue = Double(recoveryScore?.score ?? 50)
                let sleepScoreValue = Double(sleepScore?.score ?? 50)
                let strainScoreValue = Double(strainScore?.score ?? 0)
                let effortTarget = self.calculateEffortTarget(recovery: recoveryScoreValue, ctl: intervals.ctl)
                
                // Always update today's scores (even if previously saved)
                scores.recoveryScore = recoveryScoreValue
                scores.recoveryBand = recoveryScore?.band.rawValue ?? self.recoveryBand(for: recoveryScoreValue)
                scores.sleepScore = sleepScoreValue
                scores.strainScore = strainScoreValue
                scores.effortTarget = effortTarget
                
                Logger.debug("💾 [DailyScores] Updated today's scores: R=\(recoveryScoreValue), S=\(sleepScoreValue), St=\(strainScoreValue)")
            } else if scores.recoveryScore == 0 {
                // Only set defaults for historical dates if no data exists
                scores.recoveryScore = 50
                scores.recoveryBand = "amber"
                scores.sleepScore = 50
                scores.strainScore = 0
                scores.effortTarget = self.calculateEffortTarget(recovery: 50, ctl: intervals.ctl)
                
                Logger.debug("💾 [DailyScores] Set default scores for historical date: \(startOfDay)")
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
    
    /// Clean up corrupt training load data from previous bugs
    /// Called once on app launch to fix historical data issues
    func cleanupCorruptTrainingLoadData() async {
        Logger.data("🧹 [CTL/ATL CLEANUP] Checking for corrupt training load data...")
        
        let context = persistence.newBackgroundContext()
        
        await context.perform {
            let request = DailyLoad.fetchRequest()
            // Fetch all DailyLoad entries
            guard let allLoads = try? context.fetch(request) else {
                Logger.error("❌ [CTL/ATL CLEANUP] Failed to fetch DailyLoad entries")
                return
            }
            
            var corruptCount = 0
            
            for load in allLoads {
                // Normal CTL/ATL for recreational cyclists: 0-200 max
                // Values >500 indicate data corruption from previous bugs
                let isCorrupt = load.ctl > 500 || load.atl > 500 || abs(load.tsb) > 1000
                
                if isCorrupt {
                    corruptCount += 1
                    Logger.data("   🗑️ Deleting corrupt entry: date=\(load.date?.description ?? "nil"), CTL=\(load.ctl), ATL=\(load.atl)")
                    context.delete(load)
                }
            }
            
            if corruptCount > 0 {
                Logger.data("   Deleted \(corruptCount) corrupt entries")
                
                do {
                    try context.save()
                    Logger.data("✅ [CTL/ATL CLEANUP] Cleanup complete - deleted \(corruptCount) corrupt entries")
                } catch {
                    Logger.error("❌ [CTL/ATL CLEANUP] Failed to save: \(error)")
                }
            } else {
                Logger.data("✅ [CTL/ATL CLEANUP] No corrupt data found")
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
    let workout: Activity?
}
