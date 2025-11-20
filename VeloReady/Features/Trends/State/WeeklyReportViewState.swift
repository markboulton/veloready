import Foundation
import SwiftUI

/// View state for WeeklyReportView
/// Part of Phase 7 Weekly Report Refactor - separates state management from view
@MainActor
class WeeklyReportViewState: ObservableObject {

    // MARK: - Published State

    @Published var aiSummary: String?
    @Published var isLoadingAI = false
    @Published var aiError: String?
    @Published var weekStartDate: Date
    @Published var daysUntilNextReport: Int = 0

    // Wellness Foundation
    @Published var wellnessFoundation: WellnessFoundation?

    // Weekly Metrics
    @Published var weeklyMetrics: WeeklyReportDataLoader.WeeklyMetrics?
    @Published var trainingZoneDistribution: WeeklyReportDataLoader.TrainingZoneDistribution?
    @Published var sleepArchitecture: [SleepDayData] = []
    @Published var sleepHypnograms: [SleepNightData] = []
    @Published var weeklyHeatmap: WeeklyReportDataLoader.WeeklyHeatmapData?
    @Published var circadianRhythm: CircadianRhythmData?
    @Published var ctlHistoricalData: [FitnessTrajectoryChart.DataPoint]?

    // MARK: - Dependencies

    private let dataLoader: WeeklyReportDataLoader

    // MARK: - Notification Observer

    nonisolated(unsafe) private var backfillObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(dataLoader: WeeklyReportDataLoader = WeeklyReportDataLoader()) {
        self.dataLoader = dataLoader
        self.weekStartDate = WeeklyReportDataLoader.getMondayOfCurrentWeek()
        self.daysUntilNextReport = WeeklyReportDataLoader.daysUntilNextMonday()

        // Setup notification observer for backfill completion
        backfillObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BackfillComplete"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.info("📢 [WeeklyReportViewState] Received BackfillComplete notification - reloading weekly report")
            Task { @MainActor in
                await self?.loadWeeklyReport()
            }
        }

        Logger.debug("📊 [WeeklyReportViewState] Initialized with backfill observer")
    }

    deinit {
        if let observer = backfillObserver {
            NotificationCenter.default.removeObserver(observer)
            Logger.debug("📊 [WeeklyReportViewState] Removed backfill observer")
        }
    }

    // MARK: - Public Methods

    /// Load weekly report from all sources
    func loadWeeklyReport() async {
        isLoadingAI = true

        let reportData = await dataLoader.loadWeeklyReport()

        // Update published properties
        aiSummary = reportData.aiSummary
        aiError = reportData.aiError
        weekStartDate = reportData.weekStartDate
        daysUntilNextReport = reportData.daysUntilNextReport
        wellnessFoundation = reportData.wellnessFoundation
        weeklyMetrics = reportData.weeklyMetrics
        trainingZoneDistribution = reportData.trainingZoneDistribution
        sleepArchitecture = reportData.sleepArchitecture
        sleepHypnograms = reportData.sleepHypnograms
        weeklyHeatmap = reportData.weeklyHeatmap
        circadianRhythm = reportData.circadianRhythm
        ctlHistoricalData = reportData.ctlHistoricalData

        isLoadingAI = false

        Logger.debug("✅ WeeklyReportViewState loaded")
    }
}
