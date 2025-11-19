import SwiftUI
import CoreData

/// ViewModel for StrainDetailView
/// Handles data fetching for load/strain trends from DailyScores (strain score 0-18)
@MainActor
@Observable
final class StrainDetailViewModel {
    // MARK: - Published Properties

    private(set) var loadTrendData: [TrendDataPoint] = []
    private(set) var isRefreshing = false
    
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
        
        // For 7 days, we want last 7 days INCLUDING today
        // So if today is Nov 3, we want Oct 28 - Nov 3 (7 days)
        guard let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) else {
            Logger.error("📊 [LOAD CHART] Failed to calculate start date")
            return []
        }
        
        Logger.debug("📊 [LOAD CHART] Date range: \(startDate) to \(endDate) (\(period.days) days)")
        
        // Fetch strain score (0-18 load) from DailyScores
        let fetchRequest = DailyScores.fetchRequest()
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
        
        Logger.debug("📊 [LOAD CHART] Fetched \(results.count) records from Core Data")
        for (index, score) in results.enumerated() {
            if let date = score.date {
                Logger.debug("📊 [LOAD CHART]   Record \(index + 1): \(date) - Strain: \(score.strainScore)")
            }
        }
        
        let dataPoints = results.compactMap { dailyScore -> TrendDataPoint? in
            guard let date = dailyScore.date else { return nil }
            
            // Strain score is 0-18 scale
            let strainScore = dailyScore.strainScore
            
            // Validate strain score range (0-18)
            if strainScore < 0 || strainScore > 18 {
                Logger.warning("📊 [LOAD CHART] Invalid strain score: \(strainScore) on \(date)")
                return nil
            }
            
            // Strain can be 0 for rest days, so include all valid records
            return TrendDataPoint(
                date: date,
                value: strainScore
            )
        }
        
        Logger.debug("📊 [LOAD CHART] \(results.count) records → \(dataPoints.count) points for \(period.days)d view")
        
        // Group by date and take the latest record for each day (handles duplicate dates)
        var dataPointsByDate: [Date: TrendDataPoint] = [:]
        for point in dataPoints {
            let startOfDay = calendar.startOfDay(for: point.date)
            // Keep the latest record for each day (or highest strain value)
            if let existing = dataPointsByDate[startOfDay] {
                if point.value > existing.value {
                    dataPointsByDate[startOfDay] = point
                }
            } else {
                dataPointsByDate[startOfDay] = point
            }
        }
        
        Logger.debug("📊 [LOAD CHART] Deduplicated to \(dataPointsByDate.count) unique days")
        
        // Fill in missing days with 0 strain for complete chart
        var completeDataPoints: [TrendDataPoint] = []
        
        // Generate all dates in range (inclusive)
        for dayOffset in 0..<period.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            if let existingPoint = dataPointsByDate[startOfDay] {
                completeDataPoints.append(existingPoint)
            } else {
                // Fill missing day with 0 strain (rest day)
                completeDataPoints.append(TrendDataPoint(date: startOfDay, value: 0))
            }
        }
        
        // Log strain range for debugging
        if !completeDataPoints.isEmpty {
            let strainValues = completeDataPoints.map { $0.value }
            let minStrain = strainValues.min() ?? 0
            let maxStrain = strainValues.max() ?? 0
            let avgStrain = strainValues.reduce(0, +) / Double(strainValues.count)
            let nonZeroDays = strainValues.filter { $0 > 0 }.count
            Logger.debug("📊 [LOAD CHART] Strain range: min=\(String(format: "%.1f", minStrain)), max=\(String(format: "%.1f", maxStrain)), avg=\(String(format: "%.1f", avgStrain))")
            Logger.debug("📊 [LOAD CHART] Activity breakdown: \(nonZeroDays) days with training, \(completeDataPoints.count - nonZeroDays) rest days")
            Logger.debug("📊 [LOAD CHART] Filled \(completeDataPoints.count - dataPointsByDate.count) missing days with 0 strain")
        }
        
        if completeDataPoints.isEmpty {
            Logger.warning("📊 [LOAD CHART] No data available for \(period.days)d period")
        }
        
        return completeDataPoints
    }
    
    private func generateMockLoadData(for period: TrendPeriod) -> [TrendDataPoint] {
        (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 0...18)  // Strain score range 0-18
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
