import Foundation
import HealthKit
import Combine

/// Service for calculating cumulative sleep debt
@MainActor
class SleepDebtService: ObservableObject {
    static let shared = SleepDebtService()
    
    @Published var currentDebt: TimeInterval = 0  /// Current sleep debt in seconds
    @Published var debtTrend: [SleepDebtDataPoint] = []  /// Historical debt trend
    @Published var isLoading = false  /// Loading state
    @Published var lastError: String?  /// Last error message
    
    private let healthStore = HKHealthStore()
    private let userSettings = UserSettings.shared
    private let cacheKey = "sleep_debt_cache"
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Calculate sleep debt for the specified period
    func calculateSleepDebt(days: Int = 30) async {
        isLoading = true
        lastError = nil
        
        // Check cache first
        if let cached = loadFromCache(), cached.timestamp.timeIntervalSinceNow > -cacheDuration {
            self.debtTrend = cached.data
            self.currentDebt = cached.data.last?.cumulativeDebt ?? 0
            isLoading = false
            return
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "HealthKit not available"
            isLoading = false
            return
        }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
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
                
                guard let samples = samples as? [HKCategorySample] else {
                    self.lastError = "No sleep data found"
                    self.isLoading = false
                    return
                }
                
                // Calculate daily sleep totals
                let dailySleep = self.calculateDailySleep(from: samples, startDate: startDate, days: days)
                
                // Calculate cumulative debt
                let debtData = self.calculateCumulativeDebt(dailySleep: dailySleep)
                
                self.debtTrend = debtData
                self.currentDebt = debtData.last?.cumulativeDebt ?? 0
                
                // Cache the results
                self.saveToCache(CachedSleepDebtData(data: debtData, timestamp: Date()))
                
                self.isLoading = false
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Get sleep debt summary
    func getDebtSummary() -> SleepDebtSummary {
        let hoursDebt = currentDebt / 3600
        let severity = getDebtSeverity(hours: hoursDebt)
        
        // Calculate weekly average deficit
        let lastWeek = debtTrend.suffix(7)
        let weeklyDeficit = lastWeek.isEmpty ? 0 : lastWeek.map(\.dailyDeficit).reduce(0, +) / Double(lastWeek.count)
        
        return SleepDebtSummary(
            totalDebtHours: hoursDebt,
            severity: severity,
            averageWeeklyDeficit: weeklyDeficit / 3600,
            daysToRecover: calculateRecoveryDays(debt: hoursDebt),
            recommendation: getRecommendation(severity: severity)
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateDailySleep(from samples: [HKCategorySample], startDate: Date, days: Int) -> [Date: TimeInterval] {
        var dailySleep: [Date: TimeInterval] = [:]
        
        // Filter for asleep samples only
        let asleepSamples = samples.filter { sample in
            if #available(iOS 16.0, *) {
                return sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            } else {
                return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        }
        
        // Group by day
        for sample in asleepSamples {
            let day = Calendar.current.startOfDay(for: sample.startDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            dailySleep[day, default: 0] += duration
        }
        
        return dailySleep
    }
    
    private func calculateCumulativeDebt(dailySleep: [Date: TimeInterval]) -> [SleepDebtDataPoint] {
        var cumulativeDebt: TimeInterval = 0
        var dataPoints: [SleepDebtDataPoint] = []
        
        // Get sleep target in seconds
        let targetSeconds = userSettings.sleepTargetSeconds
        
        // Sort dates
        let sortedDates = dailySleep.keys.sorted()
        
        for date in sortedDates {
            let actualSleep = dailySleep[date] ?? 0
            let deficit = targetSeconds - actualSleep
            
            // Accumulate debt (positive = debt, negative = surplus)
            cumulativeDebt += deficit
            
            // Cap debt at 0 (can't have negative debt)
            cumulativeDebt = max(0, cumulativeDebt)
            
            dataPoints.append(SleepDebtDataPoint(
                date: date,
                actualSleep: actualSleep,
                targetSleep: targetSeconds,
                dailyDeficit: deficit,
                cumulativeDebt: cumulativeDebt
            ))
        }
        
        return dataPoints
    }
    
    private func getDebtSeverity(hours: Double) -> DebtSeverity {
        switch hours {
        case ..<2:
            return .minimal
        case 2..<5:
            return .moderate
        case 5..<10:
            return .significant
        default:
            return .severe
        }
    }
    
    private func calculateRecoveryDays(debt: Double) -> Int {
        // Assume you can recover 1 hour per night with extra sleep
        return Int(ceil(debt))
    }
    
    private func getRecommendation(severity: DebtSeverity) -> String {
        switch severity {
        case .minimal:
            return "Your sleep debt is minimal. Keep up the good sleep habits!"
        case .moderate:
            return "Consider going to bed 30-60 minutes earlier to reduce sleep debt."
        case .significant:
            return "Prioritize sleep recovery. Aim for 8-9 hours per night this week."
        case .severe:
            return "Significant sleep debt detected. Consider a recovery week with extended sleep."
        }
    }
    
    private func saveToCache(_ data: CachedSleepDebtData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() -> CachedSleepDebtData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(CachedSleepDebtData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Data Models

struct SleepDebtDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date  /// Date
    let actualSleep: TimeInterval  /// Actual sleep duration
    let targetSleep: TimeInterval  /// Target sleep duration
    let dailyDeficit: TimeInterval  /// Daily deficit (positive = debt)
    let cumulativeDebt: TimeInterval  /// Running total debt
    
    enum CodingKeys: String, CodingKey {
        case date, actualSleep, targetSleep, dailyDeficit, cumulativeDebt
    }
}

struct SleepDebtSummary {
    let totalDebtHours: Double  /// Total debt in hours
    let severity: DebtSeverity  /// Severity level
    let averageWeeklyDeficit: Double  /// Average weekly deficit in hours
    let daysToRecover: Int  /// Estimated days to recover
    let recommendation: String  /// Recommendation text
}

enum DebtSeverity: String {
    case minimal = "Minimal"  /// < 2 hours
    case moderate = "Moderate"  /// 2-5 hours
    case significant = "Significant"  /// 5-10 hours
    case severe = "Severe"  /// > 10 hours
    
    var color: String {
        switch self {
        case .minimal: return "green"
        case .moderate: return "yellow"
        case .significant: return "orange"
        case .severe: return "red"
        }
    }
}

private struct CachedSleepDebtData: Codable {
    let data: [SleepDebtDataPoint]  /// Cached debt data
    let timestamp: Date  /// Cache timestamp
}
