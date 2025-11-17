import Foundation
import Combine

/// Centralized service for managing training load metrics (CTL/ATL/TSB)
/// Caches data and provides it to multiple views
@MainActor
class TrainingLoadService: ObservableObject {
    static let shared = TrainingLoadService()
    
    // MARK: - Published Data
    
    @Published var weekData: [FitnessTrajectoryChart.DataPoint] = []
    @Published var monthData: [FitnessTrajectoryChart.DataPoint] = []
    @Published var threeMonthData: [FitnessTrajectoryChart.DataPoint] = []
    @Published var isLoading = false
    var lastUpdated: Date?
    
    // MARK: - Cache
    
    private var dataCache: [Int: [FitnessTrajectoryChart.DataPoint]] = [:]
    private let cacheExpiryInterval: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch training load data for all time ranges
    /// This should be called during app initialization (Phase 3)
    func fetchAllData() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch data for all ranges in parallel
            async let weekTask = fetchData(days: 7)
            async let monthTask = fetchData(days: 30)
            async let threeMonthTask = fetchData(days: 90)
            
            let (week, month, threeMonth) = try await (weekTask, monthTask, threeMonthTask)
            
            // Update published properties
            self.weekData = week
            self.monthData = month
            self.threeMonthData = threeMonth
            self.lastUpdated = Date()
            
            // Update cache
            dataCache[7] = week
            dataCache[30] = month
            dataCache[90] = threeMonth
            
            Logger.debug("📊 [TRAINING LOAD] Fetched data: Week=\(week.count), Month=\(month.count), 3M=\(threeMonth.count)")
        } catch {
            Logger.error("📊 [TRAINING LOAD] Failed to fetch: \(error.localizedDescription)")
        }
    }
    
    /// Get cached data for specific time range
    func getData(days: Int) -> [FitnessTrajectoryChart.DataPoint] {
        switch days {
        case 7: return weekData
        case 30: return monthData
        case 90: return threeMonthData
        default: return []
        }
    }
    
    /// Check if cache is valid
    var isCacheValid: Bool {
        guard let lastUpdated = lastUpdated else { return false }
        return Date().timeIntervalSince(lastUpdated) < cacheExpiryInterval
    }
    
    /// Force refresh if cache is stale
    func refreshIfNeeded() async {
        if !isCacheValid {
            await fetchAllData()
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetch training load data for specific time range from Core Data
    private func fetchData(days: Int) async throws -> [FitnessTrajectoryChart.DataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        // Fetch from Core Data (DailyScores with DailyLoad relationship)
        let context = PersistenceController.shared.container.viewContext
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let dailyScores = try? context.fetch(request) else {
            Logger.error("📊 [TRAINING LOAD] Failed to fetch from Core Data")
            return []
        }
        
        // Convert to trajectory data points (historical only, no projections)
        var points: [FitnessTrajectoryChart.DataPoint] = []
        
        for score in dailyScores {
            guard let date = score.date, let load = score.load else { continue }
            
            // Only include if we have valid CTL/ATL data
            guard load.ctl > 0 || load.atl > 0 else { continue }
            
            points.append(FitnessTrajectoryChart.DataPoint(
                date: date,
                ctl: load.ctl,
                atl: load.atl,
                tsb: load.tsb,
                isFuture: false
            ))
        }
        
        return points
    }
}

