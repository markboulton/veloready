import Foundation
import SwiftUI

/// ViewModel for Training Load Detail page
/// Manages training load data, CTL/ATL/TSB calculations, and trend analysis
/// Follows MVVM pattern established by RecoveryDetailViewModel and SleepDetailViewModel
@MainActor
@Observable
final class TrainingLoadDetailViewModel {
    // MARK: - Published Properties

    private(set) var loadTrendData: [TrendDataPoint] = []
    private(set) var activitiesWithLoad: [Activity] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Current CTL/ATL/TSB values
    private(set) var currentCTL: Double?
    private(set) var currentATL: Double?
    var currentTSB: Double? {
        guard let ctl = currentCTL, let atl = currentATL else { return nil }
        return ctl - atl
    }

    // MARK: - Dependencies

    private let activityService: UnifiedActivityService
    private let calculator: TrainingLoadCalculator
    private let profileManager: AthleteProfileManager
    private let persistenceController: PersistenceController

    // MARK: - Initialization

    init(
        activityService: UnifiedActivityService = .shared,
        calculator: TrainingLoadCalculator = TrainingLoadCalculator(),
        profileManager: AthleteProfileManager = .shared,
        persistenceController: PersistenceController = .shared
    ) {
        self.activityService = activityService
        self.calculator = calculator
        self.profileManager = profileManager
        self.persistenceController = persistenceController

        Logger.debug("📊 [TrainingLoadDetailViewModel] Initialized")
    }

    // MARK: - Public Methods

    /// Load all training load data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        Logger.debug("📊 [TrainingLoadDetailViewModel] Loading training load data")

        do {
            // Fetch activities for the last 90 days (sufficient for CTL calculation)
            let activities = try await activityService.fetchRecentActivities(limit: 500, daysBack: 90)

            Logger.debug("📊 [TrainingLoadDetailViewModel] Fetched \(activities.count) activities")

            // Get FTP for TSS enrichment
            let ftp = profileManager.profile.ftp

            // Enrich activities with TSS
            let enrichedActivities = activities.map { activity in
                ActivityConverter.enrichWithMetrics(activity, ftp: ftp)
            }

            // Calculate progressive CTL/ATL
            let progressiveLoad = await calculator.calculateProgressiveTrainingLoad(enrichedActivities)

            Logger.debug("📊 [TrainingLoadDetailViewModel] Calculated progressive load for \(progressiveLoad.count) days")

            // Date formatter for matching
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            iso8601Formatter.timeZone = TimeZone.current

            // Add CTL/ATL to activities
            let activitiesWithLoadValues = enrichedActivities.filter { $0.tss != nil }.compactMap { activity -> Activity? in
                guard let activityDate = iso8601Formatter.date(from: activity.startDateLocal) else {
                    return nil
                }

                let day = Calendar.current.startOfDay(for: activityDate)
                guard let load = progressiveLoad[day] else {
                    return nil
                }

                return Activity(
                    id: activity.id,
                    name: activity.name,
                    description: activity.description,
                    startDateLocal: activity.startDateLocal,
                    type: activity.type,
                    duration: activity.duration,
                    distance: activity.distance,
                    elevationGain: activity.elevationGain,
                    averagePower: activity.averagePower,
                    normalizedPower: activity.normalizedPower,
                    averageHeartRate: activity.averageHeartRate,
                    maxHeartRate: activity.maxHeartRate,
                    averageCadence: activity.averageCadence,
                    averageSpeed: activity.averageSpeed,
                    maxSpeed: activity.maxSpeed,
                    calories: activity.calories,
                    fileType: activity.fileType,
                    tss: activity.tss,
                    intensityFactor: activity.intensityFactor,
                    atl: load.atl,
                    ctl: load.ctl,
                    icuZoneTimes: activity.icuZoneTimes,
                    icuHrZoneTimes: activity.icuHrZoneTimes
                )
            }

            // Store activities with load
            self.activitiesWithLoad = activitiesWithLoadValues.sorted {
                guard let date1 = parseActivityDate($0.startDateLocal),
                      let date2 = parseActivityDate($1.startDateLocal) else {
                    return false
                }
                return date1 > date2  // Most recent first
            }

            // Set current CTL/ATL from most recent activity
            if let mostRecent = self.activitiesWithLoad.first {
                self.currentCTL = mostRecent.ctl
                self.currentATL = mostRecent.atl

                Logger.debug("📊 [TrainingLoadDetailViewModel] Current CTL: \(String(format: "%.1f", mostRecent.ctl ?? 0)), ATL: \(String(format: "%.1f", mostRecent.atl ?? 0)), TSB: \(String(format: "%.1f", currentTSB ?? 0))")
            }

            // Generate trend data for charts (daily CTL values)
            self.loadTrendData = progressiveLoad
                .sorted { $0.key < $1.key }
                .map { date, load in
                    TrendDataPoint(date: date, value: load.ctl)
                }

            Logger.debug("📊 [TrainingLoadDetailViewModel] Loaded \(self.loadTrendData.count) trend points")

        } catch {
            Logger.error("📊 [TrainingLoadDetailViewModel] Failed to load data: \(error)")
            self.errorMessage = "Failed to load training load data"

            // Try offline fallback
            await loadFromCoreData()
        }

        isLoading = false
    }

    /// Get historical load data for a specific period
    func getHistoricalLoadData(for period: TrendPeriod) async -> [TrendDataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) ?? endDate

        // Filter existing trend data by period
        return loadTrendData.filter { $0.date >= startDate }
    }

    /// Get CTL/ATL/TSB for a specific date
    func getLoadMetrics(for date: Date) -> (ctl: Double, atl: Double, tsb: Double)? {
        let day = Calendar.current.startOfDay(for: date)

        // Find activity on or before this date
        guard let activity = activitiesWithLoad.first(where: { activity in
            guard let activityDate = parseActivityDate(activity.startDateLocal) else { return false }
            let activityDay = Calendar.current.startOfDay(for: activityDate)
            return activityDay <= day
        }), let ctl = activity.ctl, let atl = activity.atl else {
            return nil
        }

        return (ctl: ctl, atl: atl, tsb: ctl - atl)
    }

    // MARK: - Private Methods

    /// Load training load data from Core Data (offline fallback)
    private func loadFromCoreData() async {
        Logger.debug("📱 [OFFLINE] TrainingLoadDetailViewModel: Loading from Core Data")

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        // Fetch from Core Data (DailyScores with DailyLoad relationship)
        let context = persistenceController.container.viewContext
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        guard let dailyScores = try? context.fetch(request) else {
            Logger.error("📱 [OFFLINE] Failed to fetch from Core Data")
            return
        }

        Logger.debug("📱 [OFFLINE] Loaded \(dailyScores.count) days from Core Data")

        // Convert to trend data
        var trendData: [TrendDataPoint] = []

        for score in dailyScores {
            guard let date = score.date,
                  let load = score.load,
                  load.ctl > 0 else { continue }

            trendData.append(TrendDataPoint(date: date, value: load.ctl))

            // Update current values from most recent
            if date > (currentCTL != nil ? Date.distantPast : date) {
                self.currentCTL = load.ctl
                self.currentATL = load.atl
            }
        }

        self.loadTrendData = trendData.sorted { $0.date < $1.date }

        Logger.debug("📱 [OFFLINE] Loaded \(self.loadTrendData.count) trend points from Core Data")
    }

    /// Parse activity date string
    private func parseActivityDate(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
}

// Note: TrendDataPoint and TrendPeriod are defined in TrendChart.swift and reused here
