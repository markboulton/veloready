import Foundation
import CoreData
import Combine

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
        
        do {
            // Fetch fresh data from APIs
            async let healthData = fetchHealthData()
            async let intervalsData = fetchIntervalsData()
            
            let (health, intervals) = try await (healthData, intervalsData)
            
            // Save to Core Data
            await saveToCache(date: today, health: health, intervals: intervals)
            
            lastRefreshDate = Date()
            print("✅ Refreshed today's data")
        } catch {
            print("❌ Failed to refresh today: \(error)")
            throw error
        }
    }
    
    /// Refresh last N days (smart refresh based on cache age)
    func refreshRecentDays(count: Int = 7, force: Bool = false) async throws {
        // Prevent runaway refreshes - check if already refreshing
        guard !isRefreshing else {
            print("⚠️ Cache refresh already in progress, skipping")
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
                print("⚠️ Failed to refresh \(date): \(error)")
                // Continue with other days
            }
        }
        
        lastRefreshDate = Date()
        print("✅ Cache refresh complete: \(refreshedCount)/\(count) days updated")
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
        // Fetch wellness data (last 30 days)
        let wellnessArray = try await intervalsAPI.fetchWellnessData()
        
        // Find wellness data for the specific date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let targetDateString = dateFormatter.string(from: date)
        let dateWellness = wellnessArray.first { $0.id == targetDateString }
        
        // Fetch recent activities (last 120 days for accurate zone computation)
        let activities = try await intervalsAPI.fetchRecentActivities(limit: 300, daysBack: 120)
        
        // Compute athlete zones from activities (async)
        Task {
            await MainActor.run {
                AthleteProfileManager.shared.computeFromActivities(activities)
            }
        }
        
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
            print("⚠️ Could not fetch athlete data (non-critical): \(error)")
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
            load.ctl = intervals.ctl ?? 0
            load.atl = intervals.atl ?? 0
            load.tsb = intervals.tsb ?? 0
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
            print("💾 Saving to Core Data:")
            print("   Date: \(startOfDay)")
            print("   HRV: \(physio.hrv), RHR: \(physio.rhr), Sleep: \(physio.sleepDuration/3600)h")
            print("   CTL: \(load.ctl), ATL: \(load.atl), TSS: \(load.tss)")
            print("   Recovery: \(scores.recoveryScore) (\(scores.recoveryBand ?? "unknown"))")
            print("   Sleep Score: \(scores.sleepScore), Strain: \(scores.strainScore)")
            print("   Effort Target: \(scores.effortTarget)")
            
            self.persistence.save(context: context)
            
            print("✅ Core Data save completed successfully")
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
