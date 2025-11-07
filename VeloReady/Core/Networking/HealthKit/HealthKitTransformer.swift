import Foundation
import HealthKit

/// Transforms raw HealthKit data into app-specific formats and aggregations
class HealthKitTransformer {
    
    private let healthStore: HKHealthStore
    private let dataFetcher: HealthKitDataFetcher
    private let cacheManager = UnifiedCacheManager.shared
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
    }
    
    // MARK: - Sleep Data Transformation
    
    /// Fetch and transform detailed sleep data for last night
    func fetchDetailedSleepData() async -> HealthKitSleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let cacheKey = "healthkit:sleep:\(startOfToday.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) {
                return await self.fetchDetailedSleepDataInternal()
            }
        } catch {
            return await fetchDetailedSleepDataInternal()
        }
    }
    
    private func fetchDetailedSleepDataInternal() async -> HealthKitSleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<HealthKitSleepData?, Never>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                guard error == nil, let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    Logger.error("No HealthKit sleep samples found")
                    continuation.resume(returning: nil)
                    return
                }
                
                let sleepData = self.transformSleepSamples(sleepSamples)
                continuation.resume(returning: sleepData)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch and transform historical sleep data
    func fetchHistoricalSleepData(days: Int = 7) async -> [(bedtime: Date?, wakeTime: Date?)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cacheKey = "healthkit:sleep_history:\(days):\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 3600) {
                return await self.fetchHistoricalSleepDataInternal(days: days)
            }
        } catch {
            return await fetchHistoricalSleepDataInternal(days: days)
        }
    }
    
    private func fetchHistoricalSleepDataInternal(days: Int) async -> [(bedtime: Date?, wakeTime: Date?)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                
                guard error == nil, let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    Logger.error("No historical sleep data found")
                    continuation.resume(returning: [])
                    return
                }
                
                Logger.debug("🔍 HISTORICAL SLEEP ANALYSIS:")
                Logger.data("Found \(sleepSamples.count) historical sleep samples over \(days) days")
                
                let sessions = self.groupSleepSessions(sleepSamples)
                Logger.debug("   Found \(sessions.count) total sleep sessions across \(days) days")
                
                var sleepTimes: [(bedtime: Date?, wakeTime: Date?)] = []
                
                for (index, session) in sessions.enumerated() {
                    var earliestBedtime: Date?
                    var latestWakeTime: Date?
                    
                    for sample in session {
                        if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                            earliestBedtime = sample.startDate
                        }
                        if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                            latestWakeTime = sample.endDate
                        }
                    }
                    
                    sleepTimes.append((bedtime: earliestBedtime, wakeTime: latestWakeTime))
                    
                    Logger.debug("     Session \(index + 1): bedtime=\(earliestBedtime?.description ?? "nil"), wake=\(latestWakeTime?.description ?? "nil")")
                }
                
                continuation.resume(returning: sleepTimes)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Heart Rate Variability Transformation
    
    func fetchLatestHRVData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:hrv:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) {
                return await self.dataFetcher.fetchLatestQuantity(
                    for: hrvType,
                    unit: HKUnit.secondUnit(with: .milli)
                )
            }
        } catch {
            return await dataFetcher.fetchLatestQuantity(for: hrvType, unit: HKUnit.secondUnit(with: .milli))
        }
    }
    
    func fetchOvernightHRVData(bedtime: Date? = nil, wakeTime: Date? = nil) async -> (sample: HKQuantitySample?, value: Double?) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return (nil, nil)
        }
        
        let calendar = Calendar.current
        let overnightStart: Date
        let overnightEnd: Date
        
        if let bedtime = bedtime, let wakeTime = wakeTime {
            overnightStart = bedtime
            overnightEnd = wakeTime
            Logger.debug("🍷 Using ACTUAL sleep session times for overnight HRV")
        } else {
            let now = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let startOfYesterday = calendar.startOfDay(for: yesterday)
            let endOfToday = calendar.startOfDay(for: now)
            overnightStart = calendar.date(byAdding: .hour, value: 18, to: startOfYesterday)!
            overnightEnd = calendar.date(byAdding: .hour, value: 6, to: endOfToday)!
            Logger.debug("🍷 Using ESTIMATED sleep window for overnight HRV")
        }
        
        Logger.debug("🍷 Fetching overnight HRV from \(overnightStart) to \(overnightEnd)")
        
        let predicate = HKQuery.predicateForSamples(withStart: overnightStart, end: overnightEnd, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    Logger.debug("🍷 ⚠️ No overnight HRV samples found")
                    continuation.resume(returning: (nil, nil))
                    return
                }
                
                let unit = HKUnit.secondUnit(with: .milli)
                let values = samples.map { $0.quantity.doubleValue(for: unit) }
                let average = values.reduce(0, +) / Double(values.count)
                
                Logger.debug("🍷 Found \(samples.count) overnight HRV samples")
                Logger.debug("🍷 Average overnight HRV: \(String(format: "%.2f", average)) ms")
                
                continuation.resume(returning: (samples.first, average))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Resting Heart Rate Transformation
    
    func fetchLatestRHRData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:rhr:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) {
                return await self.dataFetcher.fetchLatestQuantity(for: rhrType, unit: HKUnit(from: "count/min"))
            }
        } catch {
            return await dataFetcher.fetchLatestQuantity(for: rhrType, unit: HKUnit(from: "count/min"))
        }
    }
    
    // MARK: - Activity Data Transformation
    
    func fetchDailySteps() async -> Int? {
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:steps:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 30) {
                return await self.fetchDailyStepsInternal()
            }
        } catch {
            return await fetchDailyStepsInternal()
        }
    }
    
    private func fetchDailyStepsInternal() async -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: today, end: endOfDay, options: .strictStartDate)
        
        let steps = await dataFetcher.fetchSum(
            for: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            predicate: predicate,
            unit: HKUnit.count()
        )
        
        return steps > 0 ? Int(steps) : nil
    }
    
    func fetchDailyActiveCalories() async -> Double? {
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:active_calories:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 30) {
                return await self.fetchDailyActiveCaloriesInternal()
            }
        } catch {
            return await fetchDailyActiveCaloriesInternal()
        }
    }
    
    private func fetchDailyActiveCaloriesInternal() async -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: today, end: endOfDay, options: .strictStartDate)
        
        let calories = await dataFetcher.fetchSum(
            for: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            predicate: predicate,
            unit: HKUnit.kilocalorie()
        )
        
        return calories > 0 ? calories : nil
    }
    
    func fetchLatestSleepData() async -> (sample: HKCategorySample?, duration: TimeInterval?) {
        if let sleepData = await fetchDetailedSleepData() {
            return (sleepData.sample, sleepData.sleepDuration)
        }
        return (nil, nil)
    }
    
    func fetchLatestRespiratoryRateData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let respType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            return (nil, nil)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "healthkit:respiratory:\(today.timeIntervalSince1970)"
        
        do {
            return try await cacheManager.fetch(key: cacheKey, ttl: 300) {
                return await self.dataFetcher.fetchLatestQuantity(for: respType, unit: HKUnit(from: "count/min"))
            }
        } catch {
            return await dataFetcher.fetchLatestQuantity(for: respType, unit: HKUnit(from: "count/min"))
        }
    }
    
    func fetchLatestVO2MaxData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            return (nil, nil)
        }
        
        return await dataFetcher.fetchLatestQuantity(for: vo2MaxType, unit: HKUnit(from: "mL/kg*min"))
    }
    
    func fetchLatestOxygenSaturationData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            return (nil, nil)
        }
        
        return await dataFetcher.fetchLatestQuantity(for: spo2Type, unit: HKUnit.percent())
    }
    
    func fetchLatestBodyTemperatureData() async -> (sample: HKQuantitySample?, value: Double?) {
        guard let tempType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else {
            return (nil, nil)
        }
        
        return await dataFetcher.fetchLatestQuantity(for: tempType, unit: HKUnit.degreeFahrenheit())
    }
    
    func fetchTodayActivity() async -> (steps: Int, activeCalories: Double, exerciseMinutes: Double, walkingDistance: Double) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let steps = await dataFetcher.fetchSum(
            for: .quantityType(forIdentifier: .stepCount)!,
            predicate: predicate,
            unit: HKUnit.count()
        )
        
        let calories = await dataFetcher.fetchSum(
            for: .quantityType(forIdentifier: .activeEnergyBurned)!,
            predicate: predicate,
            unit: HKUnit.kilocalorie()
        )
        
        let exercise = await dataFetcher.fetchSum(
            for: .quantityType(forIdentifier: .appleExerciseTime)!,
            predicate: predicate,
            unit: HKUnit.minute()
        )
        
        let distance = await dataFetcher.fetchSum(
            for: .quantityType(forIdentifier: .distanceWalkingRunning)!,
            predicate: predicate,
            unit: HKUnit.meterUnit(with: .kilo)
        )
        
        return (Int(steps), calories, exercise, distance)
    }
    
    func fetchTodayHourlySteps() async -> [Int] {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return Array(repeating: 0, count: 24)
        }
        
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            var interval = DateComponents()
            interval.hour = 1
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepsType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: startOfDay,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    Logger.error("HealthKit hourly steps error: \(error.localizedDescription)")
                    continuation.resume(returning: Array(repeating: 0, count: 24))
                    return
                }
                
                var hourlySteps = Array(repeating: 0, count: 24)
                
                results?.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                    let hour = calendar.component(.hour, from: statistics.startDate)
                    if hour < 24, let sum = statistics.sumQuantity() {
                        hourlySteps[hour] = Int(sum.doubleValue(for: .count()))
                    }
                }
                
                continuation.resume(returning: hourlySteps)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchRecentWorkouts(limit: Int = 50, daysBack: Int = 30) async -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: startOfToday) else {
            return []
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let strengthPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
        let functionalStrengthPredicate = HKQuery.predicateForWorkouts(with: .functionalStrengthTraining)
        let walkingPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let hikingPredicate = HKQuery.predicateForWorkouts(with: .hiking)
        
        let typePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            strengthPredicate,
            functionalStrengthPredicate,
            walkingPredicate,
            hikingPredicate
        ])
        
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            datePredicate,
            typePredicate
        ])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: combinedPredicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("Failed to fetch workouts: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                Logger.debug("✅ Fetched \(workouts.count) strength/walking workouts")
                
                continuation.resume(returning: workouts)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Private Transformation Methods
    
    private func transformSleepSamples(_ samples: [HKCategorySample]) -> HealthKitSleepData? {
        let sessions = groupSleepSessions(samples)
        
        guard let mostRecentSession = sessions.last else {
            Logger.error("No valid sleep sessions found")
            return nil
        }
        
        Logger.debug("✅ Using most recent sleep session (\(mostRecentSession.count) samples)")
        
        var deepSleep = 0.0
        var remSleep = 0.0
        var coreSleep = 0.0
        var awake = 0.0
        var wakeCount = 0
        var earliestBedtime: Date?
        var latestWakeTime: Date?
        var firstSleepTime: Date?
        
        for sample in mostRecentSession {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                earliestBedtime = sample.startDate
            }
            if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                latestWakeTime = sample.endDate
            }
            
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleep += duration
                if firstSleepTime == nil { firstSleepTime = sample.startDate }
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleep += duration
                if firstSleepTime == nil { firstSleepTime = sample.startDate }
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                coreSleep += duration
                if firstSleepTime == nil { firstSleepTime = sample.startDate }
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
                wakeCount += 1
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                coreSleep += duration
                if firstSleepTime == nil { firstSleepTime = sample.startDate }
            default:
                break
            }
        }
        
        let totalSleep = deepSleep + remSleep + coreSleep
        let timeInBed = earliestBedtime != nil && latestWakeTime != nil ?
            latestWakeTime!.timeIntervalSince(earliestBedtime!) : totalSleep + awake
        
        var correctedSleepDuration = totalSleep
        var correctedTimeInBed = timeInBed
        
        if totalSleep > 8*3600 && timeInBed < totalSleep {
            Logger.warning("️ POTENTIAL VALUE SWAP DETECTED: Swapping values")
            correctedSleepDuration = timeInBed
            correctedTimeInBed = totalSleep
        }
        
        return HealthKitSleepData(
            sleepDuration: correctedSleepDuration,
            timeInBed: correctedTimeInBed,
            deepSleepDuration: deepSleep,
            remSleepDuration: remSleep,
            coreSleepDuration: coreSleep,
            awakeDuration: awake,
            wakeEvents: max(0, wakeCount - 1),
            bedtime: earliestBedtime,
            wakeTime: latestWakeTime,
            firstSleepTime: firstSleepTime,
            sample: mostRecentSession.first
        )
    }
    
    private func groupSleepSessions(_ samples: [HKCategorySample]) -> [[HKCategorySample]] {
        var sessions: [[HKCategorySample]] = []
        var currentSession: [HKCategorySample] = []
        let maxGapBetweenSessions: TimeInterval = 30 * 60
        
        for i in 0..<samples.count {
            currentSession.append(samples[i])
            
            if i + 1 < samples.count {
                let timeGap = samples[i + 1].startDate.timeIntervalSince(samples[i].endDate)
                if timeGap > maxGapBetweenSessions {
                    sessions.append(currentSession)
                    currentSession = []
                }
            }
        }
        
        if !currentSession.isEmpty {
            sessions.append(currentSession)
        }
        
        return sessions
    }
}
