import Foundation

/// Data loader for Today view with cache-first strategy (Phase 1 - V2 Architecture)
/// Handles all data fetching with intelligent caching to achieve 0ms to cached content
@MainActor
final class TodayDataLoader {

    // MARK: - Data Transfer Objects

    struct ScoresData {
        let recovery: Double?
        let sleep: Double?
        let strain: Double?
        let phase: RecoveryPhaseType
    }

    struct PhysioData {
        let hrv: Double?
        let hrvBaseline: Double?
        let rhr: Double?
        let rhrBaseline: Double?
    }

    struct SleepData {
        let duration: TimeInterval?
        let baseline: TimeInterval?
    }

    struct TrainingLoadData {
        let ctl: Double?
        let atl: Double?
        let tsb: Double?
        let todayTSS: Double?
        let history: [TrainingLoadDataPoint]
    }

    struct ActivitiesData {
        let latest: Activity?
        let recent: [Activity]
    }

    struct LiveActivityData {
        let steps: Int?
        let stepGoal: Int?
        let calories: Double?
        let calorieGoal: Double?
        let distance: Double?
    }

    struct PerformanceData {
        let ftp: Double?
        let ftpTrend: TrendDirection
        let vo2Max: Double?
        let vo2MaxTrend: TrendDirection
    }

    // MARK: - Services

    private let cacheManager = UnifiedCacheManager.shared
    private let healthKitManager = HealthKitManager.shared
    private let liveActivityService = LiveActivityService.shared
    private let unifiedActivityService = UnifiedActivityService.shared
    private let wellnessService = WellnessDetectionService.shared
    private let illnessService = IllnessDetectionService.shared
    private let stressService = StressAnalysisService.shared

    private var scoresCoordinator: ScoresCoordinator {
        ServiceContainer.shared.scoresCoordinator
    }

    private var stravaAuthService: StravaAuthService {
        ServiceContainer.shared.stravaAuthService
    }

    private var stravaDataService: StravaDataService {
        ServiceContainer.shared.stravaDataService
    }

    private var intervalsOAuthManager: IntervalsOAuthManager {
        ServiceContainer.shared.intervalsOAuthManager
    }

    private var deduplicationService: ActivityDeduplicationService {
        ServiceContainer.shared.deduplicationService
    }

    // MARK: - Cache Keys

    private let today = Calendar.current.startOfDay(for: Date())
    private var todayTimestamp: TimeInterval { today.timeIntervalSince1970 }

    // MARK: - Public API - Cached Data (0ms)

    func loadCachedScores() async -> ScoresData? {
        // Check Core Data for today's scores
        guard let dailyScores = await fetchTodayScores() else {
            Logger.trace("💾 No cached scores in Core Data")
            return nil
        }

        return ScoresData(
            recovery: dailyScores.recoveryScore,
            sleep: dailyScores.sleepScore,
            strain: dailyScores.strainScore,
            phase: mapPhase(dailyScores.recoveryScore)
        )
    }

    func loadCachedPhysio() async -> PhysioData? {
        guard let dailyPhysio = await fetchTodayPhysio() else {
            Logger.trace("💾 No cached physio in Core Data")
            return nil
        }

        return PhysioData(
            hrv: dailyPhysio.hrv == 0 ? nil : dailyPhysio.hrv,
            hrvBaseline: dailyPhysio.hrvBaseline == 0 ? nil : dailyPhysio.hrvBaseline,
            rhr: dailyPhysio.rhr == 0 ? nil : dailyPhysio.rhr,
            rhrBaseline: dailyPhysio.rhrBaseline == 0 ? nil : dailyPhysio.rhrBaseline
        )
    }

    func loadCachedSleep() async -> SleepData? {
        guard let dailyPhysio = await fetchTodayPhysio() else {
            Logger.trace("💾 No cached sleep in Core Data")
            return nil
        }

        return SleepData(
            duration: dailyPhysio.sleepDuration == 0 ? nil : dailyPhysio.sleepDuration,
            baseline: dailyPhysio.sleepBaseline == 0 ? nil : dailyPhysio.sleepBaseline
        )
    }

    func loadCachedTrainingLoad() async -> TrainingLoadData? {
        guard let dailyLoad = await fetchTodayLoad() else {
            Logger.trace("💾 No cached training load in Core Data")
            return nil
        }

        // TODO: Load history from Core Data
        let history: [TrainingLoadDataPoint] = []

        return TrainingLoadData(
            ctl: dailyLoad.ctl,
            atl: dailyLoad.atl,
            tsb: dailyLoad.tsb,
            todayTSS: dailyLoad.tss,
            history: history
        )
    }

    func loadCachedActivities() async -> ActivitiesData? {
        // TODO: Implement caching for activities
        // Need to understand UnifiedCacheManager.fetch() API
        Logger.trace("💾 No cached activities (not implemented)")
        return nil
    }

    func loadCachedLiveActivity() async -> LiveActivityData? {
        // TODO: Implement caching for live activity
        // Need to understand UnifiedCacheManager.fetch() API and LiveActivityService interface
        Logger.trace("💾 No cached live activity (not implemented)")
        return nil
    }

    func loadCachedPerformance() async -> PerformanceData? {
        // TODO: Load from Core Data or cache
        Logger.trace("💾 No cached performance (not implemented)")
        return nil
    }

    // MARK: - Public API - Fresh Data (2-3s)

    func loadFreshScores() async throws -> ScoresData? {
        // Trigger fresh calculation
        await scoresCoordinator.calculateAll()

        // Wait for calculation to complete
        while scoresCoordinator.state.phase == .loading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        guard let dailyScores = await fetchTodayScores() else {
            return nil
        }

        return ScoresData(
            recovery: dailyScores.recoveryScore,
            sleep: dailyScores.sleepScore,
            strain: dailyScores.strainScore,
            phase: mapPhase(dailyScores.recoveryScore)
        )
    }

    func loadFreshPhysio() async throws -> PhysioData? {
        // Data is updated by scoresCoordinator.calculateAllScores()
        guard let dailyPhysio = await fetchTodayPhysio() else {
            return nil
        }

        return PhysioData(
            hrv: dailyPhysio.hrv == 0 ? nil : dailyPhysio.hrv,
            hrvBaseline: dailyPhysio.hrvBaseline == 0 ? nil : dailyPhysio.hrvBaseline,
            rhr: dailyPhysio.rhr == 0 ? nil : dailyPhysio.rhr,
            rhrBaseline: dailyPhysio.rhrBaseline == 0 ? nil : dailyPhysio.rhrBaseline
        )
    }

    func loadFreshSleep() async throws -> SleepData? {
        // Data is updated by scoresCoordinator.calculateAllScores()
        guard let dailyPhysio = await fetchTodayPhysio() else {
            return nil
        }

        return SleepData(
            duration: dailyPhysio.sleepDuration == 0 ? nil : dailyPhysio.sleepDuration,
            baseline: dailyPhysio.sleepBaseline == 0 ? nil : dailyPhysio.sleepBaseline
        )
    }

    func loadFreshTrainingLoad() async throws -> TrainingLoadData? {
        // Data is updated by scoresCoordinator.calculateAllScores()
        guard let dailyLoad = await fetchTodayLoad() else {
            return nil
        }

        // TODO: Load history from Core Data
        let history: [TrainingLoadDataPoint] = []

        return TrainingLoadData(
            ctl: dailyLoad.ctl,
            atl: dailyLoad.atl,
            tsb: dailyLoad.tsb,
            todayTSS: dailyLoad.tss,
            history: history
        )
    }

    func loadFreshActivities() async throws -> ActivitiesData {
        let startTime = Date()
        Logger.info("🔄 [TodayDataLoader] ━━━ Fetching activities from all sources ━━━")

        // Fetch from all sources in parallel (Intervals, Strava, HealthKit)
        async let intervalsActivities = fetchIntervalsActivities()
        async let stravaActivities = fetchStravaActivities()
        async let healthWorkouts = fetchHealthWorkouts()

        let (intervals, strava, health) = await (intervalsActivities, stravaActivities, healthWorkouts)

        Logger.info("✅ [TodayDataLoader] Fetched - Intervals: \(intervals.count), Strava: \(strava.count), Health: \(health.count)")

        // Deduplicate activities across sources
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervals,
            stravaActivities: strava,
            appleHealthActivities: health
        )

        Logger.info("✅ [TodayDataLoader] Deduplicated: \(deduplicated.count) unique activities")

        // Sort by date descending and take top 15
        let sortedActivities = deduplicated
            .sorted { $0.startDate > $1.startDate }
            .prefix(15)
            .map { $0 }

        let duration = Date().timeIntervalSince(startTime)
        Logger.info("✅ [TodayDataLoader] ━━━ Activity fetch completed in \(String(format: "%.2f", duration))s - \(sortedActivities.count) activities ━━━")

        // Convert back to [Activity] for ActivitiesData
        let activities = sortedActivities.compactMap { $0.activity }

        return ActivitiesData(
            latest: activities.first,
            recent: activities
        )
    }

    func loadFreshLiveActivity() async throws -> LiveActivityData {
        // LiveActivityService uses @Published properties that are updated automatically
        // Just read the current values
        let steps = liveActivityService.dailySteps > 0 ? liveActivityService.dailySteps : nil
        let calories = liveActivityService.activeCalories > 0 ? liveActivityService.activeCalories : nil
        let distance = liveActivityService.walkingDistance > 0 ? liveActivityService.walkingDistance : nil

        // Goals are typically hardcoded or user-configurable
        // Using common defaults for now
        let stepGoal = 10000
        let calorieGoal = 500.0

        return LiveActivityData(
            steps: steps,
            stepGoal: stepGoal,
            calories: calories,
            calorieGoal: calorieGoal,
            distance: distance
        )
    }

    func loadFreshPerformance() async throws -> PerformanceData {
        // TODO: Implement FTP/VO2Max loading
        return PerformanceData(
            ftp: nil,
            ftpTrend: .stable,
            vo2Max: nil,
            vo2MaxTrend: .stable
        )
    }

    func loadAlerts() async throws -> [TodayAlert] {
        // TODO: Implement alert loading from wellness/illness/stress services
        // For now, return empty array
        Logger.debug("📢 Alert loading not fully implemented yet")
        return []
    }

    // MARK: - Cache Invalidation

    func invalidateHealthKitCaches() async {
        // TODO: Implement cache invalidation using proper UnifiedCacheManager API
        Logger.debug("🗑️ Cache invalidation not implemented yet")
    }

    // MARK: - Private Helpers

    private func fetchTodayScores() async -> DailyScores? {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let context = PersistenceController.shared.viewContext
                let fetchRequest = DailyScores.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
                fetchRequest.fetchLimit = 1

                do {
                    let results = try context.fetch(fetchRequest)
                    continuation.resume(returning: results.first)
                } catch {
                    Logger.error("Failed to fetch today's scores: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func fetchTodayPhysio() async -> DailyPhysio? {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let context = PersistenceController.shared.viewContext
                let fetchRequest = DailyPhysio.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
                fetchRequest.fetchLimit = 1

                do {
                    let results = try context.fetch(fetchRequest)
                    continuation.resume(returning: results.first)
                } catch {
                    Logger.error("Failed to fetch today's physio: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func fetchTodayLoad() async -> DailyLoad? {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let context = PersistenceController.shared.viewContext
                let fetchRequest = DailyLoad.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
                fetchRequest.fetchLimit = 1

                do {
                    let results = try context.fetch(fetchRequest)
                    continuation.resume(returning: results.first)
                } catch {
                    Logger.error("Failed to fetch today's load: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func mapPhase(_ recoveryScore: Double?) -> RecoveryPhaseType {
        guard let score = recoveryScore else { return .calculating }

        // Map recovery score to phase
        switch score {
        case 90...:
            return .optimal
        case 70..<90:
            return .ready
        case 50..<70:
            return .recovering
        case 30..<50:
            return .fatigued
        default:
            return .overreaching
        }
    }

    // MARK: - Activity Fetching Helpers

    /// Fetch activities from Intervals.icu
    /// - Returns: Array of UnifiedActivity
    private func fetchIntervalsActivities() async -> [UnifiedActivity] {
        Logger.info("🔄 [TodayDataLoader] Fetching Intervals.icu activities...")

        // Check if authenticated
        guard intervalsOAuthManager.isAuthenticated else {
            Logger.info("⏭️ [TodayDataLoader] Intervals.icu not authenticated - skipping")
            return []
        }

        do {
            // OPTIMIZATION: Reduce from 500 → 50 for faster initial load
            // We only need 15 for Today view, so 50 provides buffer
            let activities = try await Task { @MainActor in
                try await unifiedActivityService.fetchRecentActivities(
                    limit: 50,
                    daysBack: 7
                )
            }.value

            // Filter out Strava duplicates (those with source == "STRAVA")
            let filtered = activities.filter { $0.source?.uppercased() != "STRAVA" }

            Logger.info("✅ [TodayDataLoader] Intervals.icu: \(filtered.count) activities (filtered from \(activities.count))")

            return filtered.map { UnifiedActivity(from: $0) }
        } catch {
            Logger.warning("⚠️ [TodayDataLoader] Intervals.icu fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch activities from Strava
    /// - Returns: Array of UnifiedActivity
    private func fetchStravaActivities() async -> [UnifiedActivity] {
        Logger.info("🔄 [TodayDataLoader] Fetching Strava activities...")
        Logger.info("🔄 [TodayDataLoader] Connection state: \(stravaAuthService.connectionState)")

        // Check if authenticated
        guard case .connected = stravaAuthService.connectionState else {
            Logger.info("⏭️ [TodayDataLoader] Strava not authenticated - skipping")
            return []
        }

        Logger.info("🔄 [TodayDataLoader] Calling stravaDataService.fetchActivitiesIfNeeded()")

        // Fetch activities using the backend-powered VeloReady API
        await stravaDataService.fetchActivitiesIfNeeded()
        let activities = stravaDataService.activities

        Logger.info("✅ [TodayDataLoader] Strava: \(activities.count) activities")

        return activities.map { UnifiedActivity(from: $0) }
    }

    /// Fetch workouts from Apple Health
    /// - Returns: Array of UnifiedActivity
    private func fetchHealthWorkouts() async -> [UnifiedActivity] {
        Logger.info("🔄 [TodayDataLoader] Fetching Apple Health workouts...")

        // Check if authorized
        guard healthKitManager.isAuthorized else {
            Logger.info("⏭️ [TodayDataLoader] HealthKit not authorized - skipping")
            return []
        }

        let workouts = await healthKitManager.fetchRecentWorkouts(daysBack: 7)

        Logger.info("✅ [TodayDataLoader] Apple Health: \(workouts.count) workouts")

        return workouts.map { UnifiedActivity(from: $0) }
    }
}
