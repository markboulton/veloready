import SwiftUI
import CoreData

/// ViewModel for SleepDetailView
/// Handles data fetching for sleep trends and metrics
@MainActor
class SleepDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var sleepTrendData: [TrendDataPoint] = []
    @Published private(set) var isRefreshing = false
    
    // MARK: - Dependencies
    
    private let sleepScoreService: SleepScoreService
    private let persistenceController: PersistenceController
    private let proConfig: ProFeatureConfig
    
    // MARK: - Initialization
    
    init(
        sleepScoreService: SleepScoreService = .shared,
        persistenceController: PersistenceController = .shared,
        proConfig: ProFeatureConfig = .shared
    ) {
        self.sleepScoreService = sleepScoreService
        self.persistenceController = persistenceController
        self.proConfig = proConfig
    }
    
    // MARK: - Public Methods
    
    func refreshData() async {
        isRefreshing = true
        await sleepScoreService.calculateSleepScore()
        isRefreshing = false
    }
    
    // MARK: - Sleep Trend Data
    
    func getHistoricalSleepData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if proConfig.showMockDataForTesting {
            return generateMockSleepData(for: period)
        }
        #endif
        
        return fetchSleepTrendData(for: period)
    }
    
    private func fetchSleepTrendData(for period: TrendPeriod) -> [TrendDataPoint] {
        let context = persistenceController.container.viewContext
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) else {
            Logger.error("💤 [SLEEP CHART] Failed to calculate start date")
            return []
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND sleepScore > 0",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest) else {
            Logger.error("💤 [SLEEP CHART] Core Data fetch failed")
            return []
        }
        
        let dataPoints = results.compactMap { dailyScore -> TrendDataPoint? in
            guard let date = dailyScore.date else { return nil }
            return TrendDataPoint(
                date: date,
                value: dailyScore.sleepScore
            )
        }
        
        Logger.debug("💤 [SLEEP CHART] \(results.count) records → \(dataPoints.count) points for \(period.days)d view")
        
        if dataPoints.isEmpty {
            Logger.warning("💤 [SLEEP CHART] No data available for \(period.days)d period")
        } else if dataPoints.count < period.days {
            Logger.data("💤 [SLEEP CHART] Showing \(dataPoints.count)/\(period.days) days")
        }
        
        return dataPoints
    }
    
    private func generateMockSleepData(for period: TrendPeriod) -> [TrendDataPoint] {
        (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 70...95)
            )
        }
    }
    
    // MARK: - Helper Properties
    
    var canViewWeeklyTrends: Bool {
        proConfig.canViewWeeklyTrends
    }
    
    var showMockData: Bool {
        #if DEBUG
        return proConfig.showMockDataForTesting
        #else
        return false
        #endif
    }
}
