import SwiftUI
import CoreData

/// ViewModel for StrainDetailView
/// Handles data fetching for load/strain trends from DailyLoad (TSS data)
@MainActor
class StrainDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var loadTrendData: [TrendDataPoint] = []
    @Published private(set) var isRefreshing = false
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let proConfig: ProFeatureConfig
    
    // MARK: - Initialization
    
    init(
        persistenceController: PersistenceController = .shared,
        proConfig: ProFeatureConfig = .shared
    ) {
        self.persistenceController = persistenceController
        self.proConfig = proConfig
    }
    
    // MARK: - Load Trend Data
    
    func getHistoricalLoadData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if proConfig.showMockDataForTesting {
            return generateMockLoadData(for: period)
        }
        #endif
        
        return fetchLoadTrendData(for: period)
    }
    
    private func fetchLoadTrendData(for period: TrendPeriod) -> [TrendDataPoint] {
        let context = persistenceController.container.viewContext
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate) else {
            Logger.error("📊 [LOAD CHART] Failed to calculate start date")
            return []
        }
        
        // Fetch real TSS data from DailyLoad (not strainScore from DailyScores)
        let fetchRequest = DailyLoad.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest) else {
            Logger.error("📊 [LOAD CHART] Core Data fetch failed")
            return []
        }
        
        let dataPoints = results.compactMap { dailyLoad -> TrendDataPoint? in
            guard let date = dailyLoad.date else { return nil }
            
            // Validate TSS - filter out unrealistic values (data errors)
            // Typical TSS range: 0-500 (500 = very hard 5+ hour ride)
            let tss = dailyLoad.tss
            if tss > 500 {
                Logger.warning("📊 [LOAD CHART] Filtering out unrealistic TSS value: \(Int(tss)) on \(date)")
                return nil
            }
            
            // TSS can be 0 for rest days, so include all valid records
            return TrendDataPoint(
                date: date,
                value: tss
            )
        }
        
        Logger.debug("📊 [LOAD CHART] \(results.count) records → \(dataPoints.count) points for \(period.days)d view")
        
        // Log TSS range for debugging
        if !dataPoints.isEmpty {
            let tssValues = dataPoints.map { $0.value }
            let minTSS = tssValues.min() ?? 0
            let maxTSS = tssValues.max() ?? 0
            let avgTSS = tssValues.reduce(0, +) / Double(tssValues.count)
            Logger.debug("📊 [LOAD CHART] TSS range: min=\(Int(minTSS)), max=\(Int(maxTSS)), avg=\(Int(avgTSS))")
        }
        
        if dataPoints.isEmpty {
            Logger.warning("📊 [LOAD CHART] No data available for \(period.days)d period")
        }
        
        return dataPoints
    }
    
    private func generateMockLoadData(for period: TrendPeriod) -> [TrendDataPoint] {
        (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 60...95)  // Realistic range matching recovery/sleep
            )
        }
    }
    
    // MARK: - Helper Properties
    
    var canView7DayLoad: Bool {
        proConfig.canView7DayLoad
    }
    
    var showMockData: Bool {
        #if DEBUG
        return proConfig.showMockDataForTesting
        #else
        return false
        #endif
    }
}
