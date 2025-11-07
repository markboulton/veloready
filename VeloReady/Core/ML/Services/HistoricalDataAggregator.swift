import Foundation
import HealthKit
import CoreData

/// Aggregates historical data from all sources for ML training
@MainActor
class HistoricalDataAggregator {
    
    // MARK: - Dependencies
    
    private let persistence = PersistenceController.shared
    private let healthKitManager = HealthKitManager.shared
    // IntervalsCache deleted - use UnifiedActivityService instead
    private let intervalsAPIClient: IntervalsAPIClient
    private let unifiedActivityService = UnifiedActivityService.shared
    
    // MARK: - Initialization
    
    init() {
        self.intervalsAPIClient = IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared)
    }
    
    // MARK: - Public API
    
    /// Aggregate all historical data for specified time period
    /// - Parameter days: Number of days to look back (default: 90)
    /// - Returns: Aggregated historical data organized by date
    func aggregateHistoricalData(days: Int = 90) async -> [Date: HistoricalDataPoint] {
        Logger.debug("📊 [ML] Starting historical data aggregation for \(days) days...")
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            Logger.error("[ML] Failed to calculate start date")
            return [:]
        }
        
        // Fetch data from all sources in parallel
        async let coreDataScores = fetchCoreDataScores(from: startDate, to: endDate)
        async let healthKitData = fetchHealthKitData(from: startDate, to: endDate)
        async let activitiesData = fetchActivitiesData(from: startDate, to: endDate)
        
        let (scores, healthKit, activities) = await (coreDataScores, healthKitData, activitiesData)
        
        // Merge all data by date
        var dataByDate: [Date: HistoricalDataPoint] = [:]
        
        // Start with Core Data scores (most complete)
        for score in scores {
            guard let date = score.date else { continue }
            let day = calendar.startOfDay(for: date)
            
            dataByDate[day] = HistoricalDataPoint(
                date: day,
                coreDataScore: score,
                healthKitData: nil,
                activities: []
            )
        }
        
        // Merge HealthKit data
        for (date, data) in healthKit {
            let day = calendar.startOfDay(for: date)
            if dataByDate[day] == nil {
                dataByDate[day] = HistoricalDataPoint(date: day, coreDataScore: nil, healthKitData: nil, activities: [])
            }
            dataByDate[day]?.healthKitData = data
        }
        
        // Merge activities
        for activity in activities {
            let day = calendar.startOfDay(for: activity.startDate)
            if dataByDate[day] == nil {
                dataByDate[day] = HistoricalDataPoint(date: day, coreDataScore: nil, healthKitData: nil, activities: [])
            }
            dataByDate[day]?.activities.append(activity)
        }
        
        Logger.debug("📊 [ML] Aggregation complete: \(dataByDate.count) days with data")
        return dataByDate
    }
    
    // MARK: - Core Data Fetching
    
    private func fetchCoreDataScores(from startDate: Date, to endDate: Date) async -> [DailyScores] {
        return await withCheckedContinuation { continuation in
            let request = DailyScores.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            let scores = persistence.fetch(request)
            Logger.debug("📊 [ML] Fetched \(scores.count) Core Data scores")
            continuation.resume(returning: scores)
        }
    }
    
    // MARK: - HealthKit Fetching
    
    private func fetchHealthKitData(from startDate: Date, to endDate: Date) async -> [Date: HealthKitDayData] {
        Logger.debug("📊 [ML] Fetching HealthKit data...")
        
        // Fetch all HealthKit metrics in parallel
        async let hrvData = fetchHRVHistory(from: startDate, to: endDate)
        async let rhrData = fetchRHRHistory(from: startDate, to: endDate)
        async let sleepData = fetchSleepHistory(from: startDate, to: endDate)
        async let workoutData = fetchWorkoutHistory(from: startDate, to: endDate)
        async let stepsData = fetchStepsHistory(from: startDate, to: endDate)
        async let caloriesData = fetchCaloriesHistory(from: startDate, to: endDate)
        
        let (hrv, rhr, sleep, workouts, steps, calories) = await (hrvData, rhrData, sleepData, workoutData, stepsData, caloriesData)
        
        // Organize by date
        var dataByDate: [Date: HealthKitDayData] = [:]
        let calendar = Calendar.current
        
        // Merge all metrics
        let allDates = Set(hrv.keys).union(rhr.keys).union(sleep.keys).union(workouts.keys).union(steps.keys).union(calories.keys)
        
        for date in allDates {
            let day = calendar.startOfDay(for: date)
            dataByDate[day] = HealthKitDayData(
                date: day,
                hrv: hrv[day],
                rhr: rhr[day],
                sleepDuration: sleep[day],
                workouts: workouts[day] ?? [],
                steps: steps[day],
                activeCalories: calories[day]
            )
        }
        
        Logger.debug("📊 [ML] Fetched HealthKit data for \(dataByDate.count) days")
        return dataByDate
    }
    
    private func fetchHRVHistory(from startDate: Date, to endDate: Date) async -> [Date: Double] {
        // Fetch HRV samples and organize by date
        let samples = await healthKitManager.fetchHRVSamples(from: startDate, to: endDate)
        var hrvByDate: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            hrvByDate[day, default: []].append(value)
        }
        
        // Average multiple samples per day
        return hrvByDate.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
    }
    
    private func fetchRHRHistory(from startDate: Date, to endDate: Date) async -> [Date: Double] {
        let samples = await healthKitManager.fetchRHRSamples(from: startDate, to: endDate)
        var rhrByDate: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            rhrByDate[day, default: []].append(value)
        }
        
        return rhrByDate.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
    }
    
    private func fetchSleepHistory(from startDate: Date, to endDate: Date) async -> [Date: Double] {
        guard let samples = try? await healthKitManager.fetchSleepData(from: startDate, to: endDate) else {
            return [:]
        }
        
        var sleepByDate: [Date: TimeInterval] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            // Only count actual sleep (not in bed)
            guard sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue else {
                continue
            }
            
            // Sleep is attributed to the day it ends (morning)
            let day = calendar.startOfDay(for: sample.endDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            sleepByDate[day, default: 0] += duration
        }
        
        // Convert to hours
        return sleepByDate.mapValues { $0 / 3600.0 }
    }
    
    private func fetchWorkoutHistory(from startDate: Date, to endDate: Date) async -> [Date: [HKWorkout]] {
        let workouts = await healthKitManager.fetchWorkouts(
            from: startDate,
            to: endDate,
            activityTypes: [
                .cycling, .running, .swimming, .walking,
                .functionalStrengthTraining, .traditionalStrengthTraining,
                .hiking, .rowing, .other
            ]
        )
        
        var workoutsByDate: [Date: [HKWorkout]] = [:]
        let calendar = Calendar.current
        
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.startDate)
            workoutsByDate[day, default: []].append(workout)
        }
        
        return workoutsByDate
    }
    
    private func fetchStepsHistory(from startDate: Date, to endDate: Date) async -> [Date: Double] {
        // Fetch daily step counts
        let calendar = Calendar.current
        var stepsByDate: [Date: Double] = [:]
        
        // Iterate through each day
        var currentDate = startDate
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let steps = await healthKitManager.fetchStepCount(from: currentDate, to: nextDate)
            if steps > 0 {
                stepsByDate[calendar.startOfDay(for: currentDate)] = steps
            }
            currentDate = nextDate
        }
        
        return stepsByDate
    }
    
    private func fetchCaloriesHistory(from startDate: Date, to endDate: Date) async -> [Date: Double] {
        let calendar = Calendar.current
        var caloriesByDate: [Date: Double] = [:]
        
        var currentDate = startDate
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let calories = await healthKitManager.fetchActiveCalories(from: currentDate, to: nextDate)
            if calories > 0 {
                caloriesByDate[calendar.startOfDay(for: currentDate)] = calories
            }
            currentDate = nextDate
        }
        
        return caloriesByDate
    }
    
    // MARK: - Activities Fetching (Intervals.icu + Strava)
    
    private func fetchActivitiesData(from startDate: Date, to endDate: Date) async -> [UnifiedActivity] {
        Logger.debug("📊 [ML] Fetching activities from all sources...")
        
        do {
            // Fetch from unified activity service (handles Intervals.icu + Strava fallback)
            let activities = try await unifiedActivityService.fetchActivities(
                from: startDate,
                to: endDate
            )
            
            Logger.debug("📊 [ML] Fetched \(activities.count) activities (Intervals.icu + Strava + HealthKit)")
            return activities
        } catch {
            Logger.error("[ML] Failed to fetch activities: \(error)")
            
            // Fallback: Try cached Intervals activities
            do {
                // IntervalsCache deleted - use UnifiedActivityService
                let cached = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 365)
                
                let filtered = cached.filter { activity in
                    guard let activityDate = parseActivityDate(activity.startDateLocal) else { return false }
                    return activityDate >= startDate && activityDate <= endDate
                }
                
                Logger.debug("📊 [ML] Using \(filtered.count) cached Intervals activities")
                return filtered.map { UnifiedActivity(from: $0) }
            } catch {
                Logger.error("[ML] Failed to fetch cached activities: \(error)")
                return []
            }
        }
    }
    
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

// MARK: - Data Structures

/// Complete historical data for a single day
struct HistoricalDataPoint {
    let date: Date
    var coreDataScore: DailyScores?
    var healthKitData: HealthKitDayData?
    var activities: [UnifiedActivity]
    
    /// Calculate daily TSS from activities
    var dailyTSS: Double {
        activities.compactMap { $0.tss }.reduce(0, +)
    }
    
    /// Calculate daily duration from activities (hours)
    var dailyDuration: Double {
        let totalSeconds = activities.compactMap { $0.duration }.reduce(0, +)
        return totalSeconds / 3600.0
    }
    
    /// Check if this day has sufficient data for ML training
    var hasSufficientData: Bool {
        // Need either Core Data score or HealthKit data
        return coreDataScore != nil || (healthKitData?.hrv != nil && healthKitData?.rhr != nil)
    }
}

/// HealthKit data for a single day
struct HealthKitDayData {
    let date: Date
    let hrv: Double?
    let rhr: Double?
    let sleepDuration: Double? // hours
    let workouts: [HKWorkout]
    let steps: Double?
    let activeCalories: Double?
}
