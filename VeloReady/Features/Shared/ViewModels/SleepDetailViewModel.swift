import SwiftUI
import CoreData

/// ViewModel for SleepDetailView
/// Handles data fetching for sleep trends and metrics
@MainActor
@Observable
final class SleepDetailViewModel {
    // MARK: - Published Properties

    private(set) var sleepTrendData: [TrendDataPoint] = []
    private(set) var isRefreshing = false
    
    // MARK: - Dependencies

    private let sleepScoreService: SleepScoreService
    private let persistenceController: PersistenceController
    private let proConfig: ProFeatureConfig
    private let dailyDataService: DailyDataService

    // MARK: - Initialization

    init(
        sleepScoreService: SleepScoreService = .shared,
        persistenceController: PersistenceController = .shared,
        proConfig: ProFeatureConfig = .shared,
        dailyDataService: DailyDataService = .shared
    ) {
        self.sleepScoreService = sleepScoreService
        self.persistenceController = persistenceController
        self.proConfig = proConfig
        self.dailyDataService = dailyDataService
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
        // Use shared DailyDataService for consistent trend fetching
        return dailyDataService.fetchSleepTrend(for: period.days)
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
