import Foundation
import HealthKit
import Combine

/// Service for tracking VO₂ Max trends over time
@MainActor
class VO2MaxTrackingService: ObservableObject {
    static let shared = VO2MaxTrackingService()
    
    @Published var currentVO2Max: Double?  /// Most recent VO₂ Max value
    @Published var vo2MaxTrend: [VO2MaxDataPoint] = []  /// Historical trend data
    @Published var trendDirection: TrendDirection = .stable  /// Trend direction
    @Published var isLoading = false  /// Loading state
    @Published var lastError: String?  /// Last error message
    
    private let healthStore = HKHealthStore()
    private let cacheKey = "vo2max_trend_cache"
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch VO₂ Max trend data for the specified period
    func fetchVO2MaxTrend(days: Int = 90) async {
        isLoading = true
        lastError = nil
        
        // Check cache first
        if let cached = loadFromCache(), cached.timestamp.timeIntervalSinceNow > -cacheDuration {
            self.vo2MaxTrend = cached.data
            self.currentVO2Max = cached.data.last?.value
            self.trendDirection = calculateTrendDirection(cached.data)
            isLoading = false
            return
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "HealthKit not available"
            isLoading = false
            return
        }
        
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: vo2MaxType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.lastError = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    self.lastError = "No VO₂ Max data found"
                    self.isLoading = false
                    return
                }
                
                // Convert samples to data points
                let dataPoints = samples.map { sample in
                    VO2MaxDataPoint(
                        date: sample.startDate,
                        value: sample.quantity.doubleValue(for: HKUnit(from: "mL/kg*min"))
                    )
                }
                
                // Group by day and average (in case multiple readings per day)
                let grouped = Dictionary(grouping: dataPoints) { point in
                    Calendar.current.startOfDay(for: point.date)
                }
                
                let averaged = grouped.map { date, points in
                    VO2MaxDataPoint(
                        date: date,
                        value: points.map(\.value).reduce(0, +) / Double(points.count)
                    )
                }.sorted { $0.date < $1.date }
                
                self.vo2MaxTrend = averaged
                self.currentVO2Max = averaged.last?.value
                self.trendDirection = self.calculateTrendDirection(averaged)
                
                // Cache the results
                self.saveToCache(CachedVO2MaxData(data: averaged, timestamp: Date()))
                
                self.isLoading = false
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Get trend summary statistics
    func getTrendSummary() -> VO2MaxTrendSummary? {
        guard !vo2MaxTrend.isEmpty else { return nil }
        
        let values = vo2MaxTrend.map(\.value)
        let average = values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        
        // Calculate 30-day change
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentData = vo2MaxTrend.filter { $0.date >= thirtyDaysAgo }
        
        var change: Double?
        if let first = recentData.first?.value, let last = recentData.last?.value {
            change = last - first
        }
        
        return VO2MaxTrendSummary(
            current: currentVO2Max ?? 0,
            average: average,
            min: min,
            max: max,
            thirtyDayChange: change,
            trendDirection: trendDirection
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateTrendDirection(_ data: [VO2MaxDataPoint]) -> TrendDirection {
        guard data.count >= 2 else { return .stable }
        
        // Compare last 30 days to previous 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        
        let recent = data.filter { $0.date >= thirtyDaysAgo }
        let previous = data.filter { $0.date >= sixtyDaysAgo && $0.date < thirtyDaysAgo }
        
        guard !recent.isEmpty, !previous.isEmpty else { return .stable }
        
        let recentAvg = recent.map(\.value).reduce(0, +) / Double(recent.count)
        let previousAvg = previous.map(\.value).reduce(0, +) / Double(previous.count)
        
        let change = recentAvg - previousAvg
        
        if change > 1.0 {
            return .improving
        } else if change < -1.0 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func saveToCache(_ data: CachedVO2MaxData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() -> CachedVO2MaxData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(CachedVO2MaxData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Data Models

struct VO2MaxDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date  /// Date of measurement
    let value: Double  /// VO₂ Max value in mL/kg/min
    
    enum CodingKeys: String, CodingKey {
        case date, value
    }
}

struct VO2MaxTrendSummary {
    let current: Double  /// Current VO₂ Max
    let average: Double  /// Average over period
    let min: Double  /// Minimum value
    let max: Double  /// Maximum value
    let thirtyDayChange: Double?  /// Change over last 30 days
    let trendDirection: TrendDirection  /// Overall trend direction
}

enum TrendDirection: String, Codable {
    case improving = "Improving"  /// Trending upward
    case declining = "Declining"  /// Trending downward
    case stable = "Stable"  /// No significant change
}

private struct CachedVO2MaxData: Codable {
    let data: [VO2MaxDataPoint]  /// Cached trend data
    let timestamp: Date  /// Cache timestamp
}
