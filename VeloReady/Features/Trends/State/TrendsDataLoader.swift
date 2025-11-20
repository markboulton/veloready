import Foundation
import HealthKit

/// Data loader for Trends feature (Phase 1 Refactor)
/// Handles all data fetching, transformation, and caching for trends
/// Follows the pattern established in TodayDataLoader and ActivitiesDataLoader
@MainActor
final class TrendsDataLoader {

    // MARK: - Data Transfer Objects

    /// Grouped recovery and wellness metrics
    struct TrendsScoresData {
        let recovery: [TrendDataPoint]
        let hrv: [HRVTrendDataPoint]
        let restingHR: [TrendDataPoint]
        let sleep: [TrendDataPoint]
        let stress: [TrendDataPoint]
    }

    /// Grouped fitness and training metrics
    struct TrendsFitnessData {
        let ftp: [TrendDataPoint]
        let weeklyTSS: [WeeklyTSSDataPoint]
        let dailyLoad: [TrendDataPoint]
        let activities: [Activity]
    }

    /// Grouped analytics and correlations
    struct TrendsAnalyticsData {
        let recoveryVsPower: [CorrelationDataPoint]
        let recoveryVsPowerCorrelation: CorrelationCalculator.CorrelationResult?
        let trainingPhase: TrainingPhaseDetector.PhaseDetectionResult?
        let overtrainingRisk: OvertrainingRiskCalculator.RiskResult?
    }

    /// Complete trends data bundle
    struct TrendsBundle {
        let scores: TrendsScoresData
        let fitness: TrendsFitnessData
        let analytics: TrendsAnalyticsData
    }

    // MARK: - Data Models (from TrendsViewModel)
    // Note: TrendDataPoint and HRVTrendDataPoint now come from StressSynthesisService

    struct WeeklyTSSDataPoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let tss: Double
    }

    struct CorrelationDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let x: Double  // Independent variable (e.g., recovery)
        let y: Double  // Dependent variable (e.g., power)
    }

    // MARK: - Dependencies (Dependency Injection)

    private let healthKitManager: HealthKitManager
    private let unifiedActivityService: UnifiedActivityService
    private let recoveryScoreService: RecoveryScoreService
    private let persistence: PersistenceController
    private let profileManager: AthleteProfileManager
    private let proConfig: ProFeatureConfig

    init(
        healthKitManager: HealthKitManager = .shared,
        unifiedActivityService: UnifiedActivityService = .shared,
        recoveryScoreService: RecoveryScoreService = .shared,
        persistence: PersistenceController = .shared,
        profileManager: AthleteProfileManager = .shared,
        proConfig: ProFeatureConfig = .shared
    ) {
        self.healthKitManager = healthKitManager
        self.unifiedActivityService = unifiedActivityService
        self.recoveryScoreService = recoveryScoreService
        self.persistence = persistence
        self.profileManager = profileManager
        self.proConfig = proConfig
    }

    // MARK: - Public API

    /// Load cached trends data (instant, from Core Data)
    func loadCachedTrends(timeRange: TrendsViewState.TimeRange) async -> TrendsBundle? {
        // Load scores from Core Data cache
        async let recovery = loadCachedRecoveryTrend(timeRange: timeRange)
        async let sleep = loadCachedSleepTrend(timeRange: timeRange)

        guard let recoveryData = await recovery,
              let sleepData = await sleep else {
            return nil
        }

        // Return partial data (scores only, fitness/analytics need fresh data)
        let scores = TrendsScoresData(
            recovery: recoveryData,
            hrv: [],  // HRV requires HealthKit query
            restingHR: [],  // RHR requires HealthKit query
            sleep: sleepData,
            stress: []  // Stress synthesized from multiple sources
        )

        // Empty fitness/analytics (require fresh computation)
        let fitness = TrendsFitnessData(
            ftp: [],
            weeklyTSS: [],
            dailyLoad: [],
            activities: []
        )

        let analytics = TrendsAnalyticsData(
            recoveryVsPower: [],
            recoveryVsPowerCorrelation: nil,
            trainingPhase: nil,
            overtrainingRisk: nil
        )

        return TrendsBundle(scores: scores, fitness: fitness, analytics: analytics)
    }

    /// Load fresh trends data (complete dataset)
    func loadFreshTrends(timeRange: TrendsViewState.TimeRange) async throws -> TrendsBundle {
        // PERFORMANCE FIX: Fetch activities once, share between methods
        let sharedActivities = try? await unifiedActivityService.fetchRecentActivities(
            limit: 500,
            daysBack: timeRange.days
        )

        // Load all categories in parallel
        async let scores = loadFreshScores(timeRange: timeRange)
        async let fitness = loadFreshFitness(timeRange: timeRange, activities: sharedActivities)
        async let analytics = loadAnalytics(timeRange: timeRange, activities: sharedActivities)

        return try await TrendsBundle(
            scores: scores,
            fitness: fitness,
            analytics: analytics
        )
    }

    // MARK: - Category Loaders

    private func loadFreshScores(timeRange: TrendsViewState.TimeRange) async throws -> TrendsScoresData {
        async let recovery = loadRecoveryTrend(timeRange: timeRange)
        async let hrv = loadHRVTrend(timeRange: timeRange)
        async let rhr = loadRestingHRTrend(timeRange: timeRange)
        async let sleep = loadSleepTrend(timeRange: timeRange)

        // Stress requires other scores to be loaded first
        let recoveryData = try await recovery
        let hrvData = try await hrv
        let rhrData = try await rhr
        let sleepData = try await sleep

        // Synthesize stress from multiple sources
        let stress = await loadStressTrend(
            recovery: recoveryData,
            hrv: hrvData,
            rhr: rhrData,
            sleep: sleepData,
            dailyLoad: []  // Will be filled after fitness loads
        )

        return TrendsScoresData(
            recovery: recoveryData,
            hrv: hrvData,
            restingHR: rhrData,
            sleep: sleepData,
            stress: stress
        )
    }

    private func loadFreshFitness(timeRange: TrendsViewState.TimeRange, activities: [Activity]?) async throws -> TrendsFitnessData {
        async let ftp = loadFTPTrend()
        async let weeklyTSS = loadWeeklyTSSTrend(activities: activities, timeRange: timeRange)
        async let dailyLoad = loadDailyLoadTrend(activities: activities, timeRange: timeRange)

        return try await TrendsFitnessData(
            ftp: ftp,
            weeklyTSS: weeklyTSS,
            dailyLoad: dailyLoad,
            activities: activities ?? []
        )
    }

    private func loadAnalytics(timeRange: TrendsViewState.TimeRange, activities: [Activity]?) async throws -> TrendsAnalyticsData {
        async let correlation = loadRecoveryVsPowerCorrelation(activities: activities, timeRange: timeRange)
        async let phase = loadTrainingPhaseDetection(timeRange: timeRange)
        async let risk = loadOvertrainingRisk(timeRange: timeRange)

        let correlationData = try await correlation

        return try await TrendsAnalyticsData(
            recoveryVsPower: correlationData.data,
            recoveryVsPowerCorrelation: correlationData.result,
            trainingPhase: phase,
            overtrainingRisk: risk
        )
    }

    // MARK: - Individual Data Loaders (Extracted from TrendsViewModel)

    // MARK: FTP Trend

    private func loadFTPTrend() async throws -> [TrendDataPoint] {
        let profile = profileManager.profile

        // Show current FTP as a single data point
        if let ftp = profile.ftp {
            Logger.debug("📈 Loaded FTP trend: 1 point")
            return [TrendDataPoint(date: Date(), value: ftp)]
        }

        Logger.debug("📈 Loaded FTP trend: 0 points")
        return []
    }

    // MARK: Recovery Trend

    private func loadRecoveryTrend(timeRange: TrendsViewState.TimeRange) async throws -> [TrendDataPoint] {
        if proConfig.showMockDataForTesting {
            let mock = generateMockRecoveryData()
            Logger.debug("📈 Loaded recovery trend: \(mock.count) points [MOCK DATA]")
            return mock
        }

        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.predicate = NSPredicate(
            format: "date >= %@ AND recoveryScore > 0",
            timeRange.startDate as NSDate
        )

        let cachedDays = persistence.fetch(request)

        // Deduplicate by date
        let calendar = Calendar.current
        var seenDates = Set<Date>()
        let deduplicatedDays = cachedDays.filter { cached in
            guard let date = cached.date else { return false }
            let normalizedDate = calendar.startOfDay(for: date)

            if seenDates.contains(normalizedDate) {
                return false
            } else {
                seenDates.insert(normalizedDate)
                return true
            }
        }

        // Convert to TrendDataPoint
        let data = deduplicatedDays.compactMap { cached -> TrendDataPoint? in
            guard let date = cached.date else { return nil }
            return TrendDataPoint(
                date: date,
                value: cached.recoveryScore
            )
        }.sorted { $0.date < $1.date }

        Logger.debug("📈 Loaded recovery trend: \(data.count) points")
        return data
    }

    private func loadCachedRecoveryTrend(timeRange: TrendsViewState.TimeRange) async -> [TrendDataPoint]? {
        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.predicate = NSPredicate(
            format: "date >= %@ AND recoveryScore > 0",
            timeRange.startDate as NSDate
        )

        let cachedDays = persistence.fetch(request)
        guard !cachedDays.isEmpty else { return nil }

        let data = cachedDays.compactMap { cached -> TrendDataPoint? in
            guard let date = cached.date else { return nil }
            return TrendDataPoint(date: date, value: cached.recoveryScore)
        }

        return data.isEmpty ? nil : data
    }

    // MARK: HRV Trend

    private func loadHRVTrend(timeRange: TrendsViewState.TimeRange) async throws -> [HRVTrendDataPoint] {
        if proConfig.showMockDataForTesting {
            let mock = generateMockHRVData()
            Logger.debug("📈 Loaded HRV trend: \(mock.count) points [MOCK DATA]")
            return mock
        }

        guard let hrvSamples = try? await healthKitManager.fetchHRVData(
            from: timeRange.startDate,
            to: Date()
        ) else {
            Logger.debug("📈 Loaded HRV trend: 0 points (no HealthKit data)")
            return []
        }

        // Group by day and average
        let calendar = Calendar.current
        var dailyHRV: [Date: [Double]] = [:]

        for sample in hrvSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            dailyHRV[day, default: []].append(sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
        }

        // Calculate daily averages
        let data = dailyHRV.map { date, values in
            HRVTrendDataPoint(
                date: date,
                value: values.reduce(0, +) / Double(values.count),
                baseline: nil  // Will calculate baseline separately
            )
        }.sorted { $0.date < $1.date }

        // Calculate baseline from all values
        let allValues = data.map { $0.value }
        let baseline = allValues.isEmpty ? nil : allValues.reduce(0, +) / Double(allValues.count)

        // Add baseline to each point
        let dataWithBaseline = data.map { point in
            HRVTrendDataPoint(
                date: point.date,
                value: point.value,
                baseline: baseline
            )
        }

        Logger.debug("📈 Loaded HRV trend: \(dataWithBaseline.count) points (baseline: \(baseline ?? 0))")
        return dataWithBaseline
    }

    // MARK: Weekly TSS Trend

    private func loadWeeklyTSSTrend(activities: [Activity]?, timeRange: TrendsViewState.TimeRange) async throws -> [WeeklyTSSDataPoint] {
        if proConfig.showMockDataForTesting {
            let mock = generateMockWeeklyTSSData()
            Logger.debug("📈 Loaded weekly TSS trend: \(mock.count) points [MOCK DATA]")
            return mock
        }

        guard let activities = activities else {
            Logger.debug("📈 Loaded weekly TSS trend: 0 points (no activities)")
            return []
        }

        // Group activities by week (Monday = week start)
        let calendar = Calendar.current
        var weeklyTSS: [Date: Double] = [:]

        for activity in activities {
            guard let startDate = parseActivityDate(activity.startDateLocal) else { continue }
            guard let tss = activity.tss else { continue }

            // Get Monday of the week
            let weekday = calendar.component(.weekday, from: startDate)
            let daysToMonday = (weekday + 5) % 7  // Convert to Monday
            guard let monday = calendar.date(byAdding: .day, value: -Int(daysToMonday), to: startDate) else { continue }
            let weekStart = calendar.startOfDay(for: monday)

            weeklyTSS[weekStart, default: 0] += tss
        }

        // Convert to data points
        let data = weeklyTSS.map { weekStart, tss in
            WeeklyTSSDataPoint(weekStart: weekStart, tss: tss)
        }.sorted { $0.weekStart < $1.weekStart }

        Logger.debug("📈 Loaded weekly TSS trend: \(data.count) points")
        return data
    }

    // MARK: Daily Load Trend

    private func loadDailyLoadTrend(activities: [Activity]?, timeRange: TrendsViewState.TimeRange) async throws -> [TrendDataPoint] {
        guard let activities = activities, !activities.isEmpty else {
            Logger.debug("📈 Loaded daily load trend: 0 points (no activities)")
            return []
        }

        // Group activities by day and sum TSS
        let calendar = Calendar.current
        var dailyTSS: [Date: Double] = [:]

        for activity in activities {
            guard let startDate = parseActivityDate(activity.startDateLocal) else { continue }
            guard let tss = activity.tss else { continue }

            let day = calendar.startOfDay(for: startDate)
            dailyTSS[day, default: 0] += tss
        }

        // Normalize to 0-100 scale (300 TSS = 100%)
        let maxTSS: Double = 300
        let data = dailyTSS.map { date, tss in
            let normalized = min(tss / maxTSS * 100, 100)
            return TrendDataPoint(date: date, value: normalized)
        }.sorted { $0.date < $1.date }

        Logger.debug("📈 Loaded daily load trend: \(data.count) points")
        return data
    }

    // MARK: Sleep Trend

    private func loadSleepTrend(timeRange: TrendsViewState.TimeRange) async throws -> [TrendDataPoint] {
        if proConfig.showMockDataForTesting {
            let mock = generateMockSleepData()
            Logger.debug("📈 Loaded sleep trend: \(mock.count) points [MOCK DATA]")
            return mock
        }

        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.predicate = NSPredicate(
            format: "date >= %@ AND sleepScore > 0",
            timeRange.startDate as NSDate
        )

        let cachedDays = persistence.fetch(request)

        let data = cachedDays.compactMap { cached -> TrendDataPoint? in
            guard let date = cached.date else { return nil }
            return TrendDataPoint(date: date, value: cached.sleepScore)
        }

        Logger.debug("📈 Loaded sleep trend: \(data.count) points")
        return data
    }

    private func loadCachedSleepTrend(timeRange: TrendsViewState.TimeRange) async -> [TrendDataPoint]? {
        return try? await loadSleepTrend(timeRange: timeRange)
    }

    // MARK: Resting HR Trend

    private func loadRestingHRTrend(timeRange: TrendsViewState.TimeRange) async throws -> [TrendDataPoint] {
        if proConfig.showMockDataForTesting {
            let mock = generateMockRestingHRData()
            Logger.debug("📈 Loaded resting HR trend: \(mock.count) points [MOCK DATA]")
            return mock
        }

        guard let rhrSamples = try? await healthKitManager.fetchRestingHeartRateData(
            from: timeRange.startDate,
            to: Date()
        ) else {
            Logger.debug("📈 Loaded resting HR trend: 0 points (no HealthKit data)")
            return []
        }

        // Group by day and average
        let calendar = Calendar.current
        var dailyRHR: [Date: [Double]] = [:]

        for sample in rhrSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            dailyRHR[day, default: []].append(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        }

        // Calculate daily averages
        let data = dailyRHR.map { date, values in
            TrendDataPoint(
                date: date,
                value: values.reduce(0, +) / Double(values.count)
            )
        }.sorted { $0.date < $1.date }

        Logger.debug("📈 Loaded resting HR trend: \(data.count) points")
        return data
    }

    // MARK: Stress Trend (Synthesized)

    private func loadStressTrend(
        recovery: [TrendDataPoint],
        hrv: [HRVTrendDataPoint],
        rhr: [TrendDataPoint],
        sleep: [TrendDataPoint],
        dailyLoad: [TrendDataPoint]
    ) async -> [TrendDataPoint] {
        // Delegate to StressSynthesisService
        let service = StressSynthesisService.shared
        return service.synthesizeStress(
            recovery: recovery,
            hrv: hrv,
            rhr: rhr,
            sleep: sleep,
            dailyLoad: dailyLoad
        )
    }

    // MARK: Recovery vs Power Correlation

    private func loadRecoveryVsPowerCorrelation(
        activities: [Activity]?,
        timeRange: TrendsViewState.TimeRange
    ) async throws -> (data: [CorrelationDataPoint], result: CorrelationCalculator.CorrelationResult?) {
        guard let activities = activities else {
            return (data: [], result: nil)
        }

        // Fetch recovery data
        let recovery = try await loadRecoveryTrend(timeRange: timeRange)

        // Match activities with recovery data
        let calendar = Calendar.current
        var correlationData: [CorrelationDataPoint] = []
        var xValues: [Double] = []
        var yValues: [Double] = []

        for activity in activities {
            guard let startDate = parseActivityDate(activity.startDateLocal) else { continue }
            guard let power = activity.averagePower else { continue }

            // Find recovery score for this day
            if let recoveryPoint = recovery.first(where: { calendar.isDate($0.date, inSameDayAs: startDate) }) {
                correlationData.append(CorrelationDataPoint(
                    date: startDate,
                    x: recoveryPoint.value,
                    y: power
                ))
                xValues.append(recoveryPoint.value)
                yValues.append(power)
            }
        }

        // Calculate correlation
        let correlation = CorrelationCalculator.pearsonCorrelation(x: xValues, y: yValues)

        Logger.debug("📈 Loaded recovery vs power correlation: \(correlationData.count) points (r=\(correlation?.coefficient ?? 0))")
        return (data: correlationData, result: correlation)
    }

    // MARK: Training Phase Detection

    private func loadTrainingPhaseDetection(timeRange: TrendsViewState.TimeRange) async throws -> TrainingPhaseDetector.PhaseDetectionResult? {
        // Placeholder - requires weekly TSS data
        // TODO: Implement with actual weekly TSS
        return nil
    }

    // MARK: Overtraining Risk

    private func loadOvertrainingRisk(timeRange: TrendsViewState.TimeRange) async throws -> OvertrainingRiskCalculator.RiskResult? {
        // Placeholder - requires recovery, HRV, RHR data
        // TODO: Implement with actual wellness data
        return nil
    }

    // MARK: - Mock Data Generation

    private func generateMockRecoveryData() -> [TrendDataPoint] {
        let days = 90
        return (0..<days).map { day in
            let date = Calendar.current.date(byAdding: .day, value: -days + day, to: Date())!
            let value = 50 + Double.random(in: -20...30)
            return TrendDataPoint(date: date, value: value)
        }
    }

    private func generateMockHRVData() -> [HRVTrendDataPoint] {
        let days = 90
        let baseline = 60.0
        return (0..<days).map { day in
            let date = Calendar.current.date(byAdding: .day, value: -days + day, to: Date())!
            let value = baseline + Double.random(in: -15...15)
            return HRVTrendDataPoint(date: date, value: value, baseline: baseline)
        }
    }

    private func generateMockWeeklyTSSData() -> [WeeklyTSSDataPoint] {
        let weeks = 12
        return (0..<weeks).map { week in
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weeks + week, to: Date())!
            let tss = Double.random(in: 200...600)
            return WeeklyTSSDataPoint(weekStart: weekStart, tss: tss)
        }
    }

    private func generateMockSleepData() -> [TrendDataPoint] {
        let days = 90
        return (0..<days).map { day in
            let date = Calendar.current.date(byAdding: .day, value: -days + day, to: Date())!
            let value = 70 + Double.random(in: -20...20)
            return TrendDataPoint(date: date, value: value)
        }
    }

    private func generateMockRestingHRData() -> [TrendDataPoint] {
        let days = 90
        return (0..<days).map { day in
            let date = Calendar.current.date(byAdding: .day, value: -days + day, to: Date())!
            let value = 60 + Double.random(in: -10...10)
            return TrendDataPoint(date: date, value: value)
        }
    }

    // MARK: - Helper Functions

    /// Parse Activity.startDateLocal (String) to Date
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Fall back to local format
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
}
