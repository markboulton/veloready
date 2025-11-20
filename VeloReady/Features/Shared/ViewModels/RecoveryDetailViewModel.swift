import SwiftUI
import CoreData

/// ViewModel for RecoveryDetailView
/// Handles data fetching for recovery trends, HRV/RHR charts, and health metrics
@MainActor
@Observable
final class RecoveryDetailViewModel {
    // MARK: - Published Properties

    private(set) var recoveryTrendData: [TrendDataPoint] = []
    private(set) var hrvData: [HRVDataPoint] = []
    private(set) var rhrData: [RHRDataPoint] = []
    private(set) var isRefreshing = false
    
    // MARK: - Dependencies

    private let recoveryScoreService: RecoveryScoreService
    private let persistenceController: PersistenceController
    private let proConfig: ProFeatureConfig
    private let dailyDataService: DailyDataService

    // MARK: - Initialization

    init(
        recoveryScoreService: RecoveryScoreService = .shared,
        persistenceController: PersistenceController = .shared,
        proConfig: ProFeatureConfig = .shared,
        dailyDataService: DailyDataService = .shared
    ) {
        self.recoveryScoreService = recoveryScoreService
        self.persistenceController = persistenceController
        self.proConfig = proConfig
        self.dailyDataService = dailyDataService
    }
    
    // MARK: - Public Methods
    
    func refreshData() async {
        isRefreshing = true
        await recoveryScoreService.forceRefreshRecoveryScore()
        isRefreshing = false
    }
    
    // MARK: - Recovery Trend Data
    
    func getHistoricalRecoveryData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if proConfig.showMockDataForTesting {
            return generateMockRecoveryData(for: period)
        }
        #endif
        
        return fetchRecoveryTrendData(for: period)
    }
    
    private func fetchRecoveryTrendData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Use shared DailyDataService for consistent trend fetching
        return dailyDataService.fetchRecoveryTrend(for: period.days)
    }
    
    private func generateMockRecoveryData(for period: TrendPeriod) -> [TrendDataPoint] {
        (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 60...85)
            )
        }
    }
    
    // MARK: - HRV Candlestick Data
    
    func getHistoricalHRVCandlestickData(for period: TrendPeriod) -> [HRVDataPoint] {
        let context = persistenceController.container.viewContext
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) else {
            Logger.error("❤️ [HRV CHART] Failed to calculate start date")
            return []
        }
        
        let fetchRequest = DailyPhysio.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND hrv > 0",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest) else {
            Logger.error("❤️ [HRV CHART] Core Data fetch failed")
            return []
        }
        
        // Group by day to avoid duplicates
        var dailyData: [Date: [Double]] = [:]
        
        for record in results {
            guard let date = record.date, record.hrv > 0 else { continue }
            let dayStart = calendar.startOfDay(for: date)
            dailyData[dayStart, default: []].append(record.hrv)
        }
        
        // Convert to HRVDataPoint (one per day)
        let dataPoints = dailyData.map { (date, values) -> HRVDataPoint in
            let avgHRV = values.reduce(0, +) / Double(values.count)
            return HRVDataPoint(
                date: date,
                open: avgHRV,
                close: avgHRV,
                high: avgHRV + 3, // Add small visual variation
                low: avgHRV - 3,
                average: avgHRV
            )
        }.sorted { $0.date < $1.date }
        
        Logger.debug("❤️ [HRV CHART] \(results.count) records → \(dataPoints.count) points for \(period.days)d view (grouped by day)")
        
        if dataPoints.isEmpty {
            Logger.warning("❤️ [HRV CHART] No data available")
        }
        
        return dataPoints
    }
    
    // MARK: - RHR Candlestick Data
    
    func getHistoricalRHRData(for period: TrendPeriod) -> [RHRDataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) else {
            Logger.error("💔 [RHR CHART] Failed to calculate start date")
            return []
        }
        
        // Fetch from Core Data (DailyPhysio) - MUCH faster than HealthKit
        let context = persistenceController.container.viewContext
        let request = DailyPhysio.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let physioRecords = try? context.fetch(request) else {
            Logger.error("💔 [RHR CHART] Failed to fetch from Core Data")
            return []
        }
        
        Logger.debug("💔 [RHR CHART] \(physioRecords.count) records → \(physioRecords.filter { $0.rhr > 0 }.count) points for \(period.days)d view")
        
        // Group by day to avoid duplicates
        var dailyData: [Date: [Double]] = [:]
        
        for record in physioRecords {
            guard let date = record.date, record.rhr > 0 else { continue }
            let dayStart = calendar.startOfDay(for: date)
            dailyData[dayStart, default: []].append(record.rhr)
        }
        
        // Convert to RHRDataPoint (one per day)
        let dataPoints = dailyData.map { (date, values) -> RHRDataPoint in
            let avgRHR = values.reduce(0, +) / Double(values.count)
            return RHRDataPoint(
                date: date,
                open: avgRHR,
                close: avgRHR,
                high: avgRHR + 2,
                low: avgRHR - 2,
                average: avgRHR
            )
        }.sorted { $0.date < $1.date }
        
        Logger.debug("💔 [RHR CHART] Loaded \(dataPoints.count) data points (grouped by day)")
        
        return dataPoints
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
