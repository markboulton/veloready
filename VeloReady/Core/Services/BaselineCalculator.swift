import Foundation
import HealthKit
import VeloReadyCore

/// Service for calculating 7-day rolling baselines from HealthKit data (Whoop-like)
/// This service fetches data from HealthKit and delegates calculation to VeloReadyCore
/// Actor-isolated to run heavy calculations on background threads
actor BaselineCalculator {
    private let healthStore = HKHealthStore()
    
    // HealthKit types
    private let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
    
    // Cache baselines for 1 hour to improve performance (balances freshness vs speed)
    private var cachedBaselines: (hrv: Double?, rhr: Double?, sleep: Double?, respiratory: Double?)?
    private var cacheTimestamp: Date?
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Public Methods
    
    /// Calculate 7-day HRV baseline (rolling average)
    func calculateHRVBaseline() async -> Double? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    Logger.error("Error fetching HRV baseline: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                } else {
                    let hrvSamples = samples as? [HKQuantitySample] ?? []
                    let values = hrvSamples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                    let baseline = VeloReadyCore.BaselineCalculations.calculateHRVBaseline(hrvValues: values)
                    Logger.data("HRV Baseline (7-day avg): \(baseline?.description ?? "No data") from \(values.count) samples")
                    continuation.resume(returning: baseline)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Calculate 7-day RHR baseline (rolling average)
    func calculateRHRBaseline() async -> Double? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: rhrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    Logger.error("Error fetching RHR baseline: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                } else {
                    let rhrSamples = samples as? [HKQuantitySample] ?? []
                    let values = rhrSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                    let baseline = VeloReadyCore.BaselineCalculations.calculateRHRBaseline(rhrValues: values)
                    Logger.data("RHR Baseline (7-day avg): \(baseline?.description ?? "No data") from \(values.count) samples")
                    continuation.resume(returning: baseline)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Calculate 7-day sleep baseline (rolling average duration in seconds)
    func calculateSleepBaseline() async -> Double? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    Logger.error("Error fetching sleep baseline: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                } else {
                    let sleepSamples = samples as? [HKCategorySample] ?? []
                    // Group sleep samples by date and calculate total sleep per night
                    let calendar = Calendar.current
                    var sleepByDate: [String: TimeInterval] = [:]
                    
                    // Create a consistent date formatter
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone.current
                    
                    for sample in sleepSamples {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        let isActualSleep = sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue
                        
                        if duration >= 300 && isActualSleep { // 5+ minutes and actually sleeping
                            // Use the start date to determine which "night" this belongs to
                            // For sleep that starts after 6 PM, consider it part of the next day's sleep
                            let hour = calendar.component(.hour, from: sample.startDate)
                            let sleepDate = hour >= 18 ? 
                                calendar.date(byAdding: .day, value: 1, to: sample.startDate) ?? sample.startDate : 
                                sample.startDate
                            
                            let dateKey = calendar.startOfDay(for: sleepDate)
                            let dateString = dateFormatter.string(from: dateKey)
                            sleepByDate[dateString, default: 0] += duration
                            
                            // Only log sleep data in debug mode to reduce performance impact
                            #if DEBUG
                            if ProcessInfo.processInfo.environment["SLEEP_DEBUG"] == "1" {
                                Logger.debug("🛏️ Adding sleep: \(duration/3600)h to date \(dateString) (sample from \(sample.startDate))")
                            }
                            #endif
                        }
                    }
                    
                    // Get total sleep durations per night (only nights with 1+ hour total)
                    let actualSleepDurations = sleepByDate.values.filter { $0 >= 3600 }
                    
                    // Debug sleep baseline calculation
                    Logger.debug("🔍 Sleep Baseline Debug:")
                    Logger.debug("   Total sleep samples: \(sleepSamples.count)")
                    Logger.debug("   Sleep nights with 1+ hour: \(actualSleepDurations.count)")
                    if !actualSleepDurations.isEmpty {
                        let minSleep = actualSleepDurations.min() ?? 0
                        let maxSleep = actualSleepDurations.max() ?? 0
                        let avgSleep = actualSleepDurations.reduce(0, +) / Double(actualSleepDurations.count)
                        Logger.debug("   Sleep range: \(minSleep/3600)h - \(maxSleep/3600)h (avg: \(avgSleep/3600)h)")
                    }
                    
                    let baseline = VeloReadyCore.BaselineCalculations.calculateSleepBaseline(sleepDurations: actualSleepDurations)
                    Logger.data("Sleep Baseline (7-day avg): \(baseline?.description ?? "No data") seconds from \(actualSleepDurations.count) actual sleep periods (filtered from \(sleepSamples.count) total samples)")
                    continuation.resume(returning: baseline)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Calculate 7-day sleep SCORE baseline (rolling average of 0-100 scores)
    /// This is different from calculateSleepBaseline() which returns duration in seconds
    func calculateSleepScoreBaseline() async -> Double? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // Fetch sleep scores from cache (0-100 values)
        var scores: [Int] = []
        let calendar = Calendar.current
        let cacheManager = UnifiedCacheManager.shared
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            
            let cacheKey = CacheKey.sleepScore(date: date)
            
            // PERFORMANCE FIX: Check if cache exists before attempting fetch
            // This prevents redundant cache layer lookups (Memory → Disk → CoreData)
            if let cachedScore: Int = await CacheOrchestrator.shared.get(
                key: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.dailyScores
            ) {
                scores.append(cachedScore)
                continue
            }
            
            // Cache miss - only fetch if we really need it
            do {
                let score = try await cacheManager.fetch(
                    key: cacheKey,
                    ttl: UnifiedCacheManager.CacheTTL.dailyScores
                ) {
                    return await SleepScoreService.shared.currentSleepScore?.score
                }
                
                if let score = score {
                    scores.append(score)
                }
            } catch {
                Logger.debug("⚠️ Failed to fetch sleep score for baseline: \(error)")
            }
        }
        
        // Calculate average of sleep scores
        guard !scores.isEmpty else { return nil }
        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        Logger.data("Sleep Score Baseline (7-day avg): \(avg) from \(scores.count) days")
        return avg
    }
    
    /// Calculate 7-day respiratory rate baseline (rolling average)
    func calculateRespiratoryBaseline() async -> Double? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: respiratoryType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if error != nil {
                    Logger.error("Error fetching respiratory baseline: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                } else {
                    let respiratorySamples = samples as? [HKQuantitySample] ?? []
                    let values = respiratorySamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                    let baseline = VeloReadyCore.BaselineCalculations.calculateRespiratoryBaseline(respiratoryRates: values)
                    Logger.data("Respiratory Baseline (7-day avg): \(baseline?.description ?? "No data") from \(values.count) samples")
                    continuation.resume(returning: baseline)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Calculate all baselines at once with caching
    func calculateAllBaselines() async -> (hrv: Double?, rhr: Double?, sleep: Double?, respiratory: Double?) {
        // Check if we have valid cached baselines
        if let cached = cachedBaselines,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpiryInterval {
            Logger.debug("📱 Using cached baselines (age: \(String(format: "%.1f", Date().timeIntervalSince(timestamp) / 60)) minutes)")
            return cached
        }
        
        Logger.debug("🔄 Calculating fresh baselines...")
        
        // Calculate all baselines concurrently
        async let hrvBaseline = calculateHRVBaseline()
        async let rhrBaseline = calculateRHRBaseline()
        async let sleepBaseline = calculateSleepBaseline()
        async let respiratoryBaseline = calculateRespiratoryBaseline()
        
        let (hrv, rhr, sleep, respiratory) = await (hrvBaseline, rhrBaseline, sleepBaseline, respiratoryBaseline)
        
        // Cache the results
        cachedBaselines = (hrv, rhr, sleep, respiratory)
        cacheTimestamp = Date()
        
        Logger.data("All 7-Day Baselines Calculated & Cached:")
        Logger.debug("   HRV: \(hrv?.description ?? "No data") ms")
        Logger.debug("   RHR: \(rhr?.description ?? "No data") bpm")
        Logger.debug("   Sleep: \(sleep?.description ?? "No data") seconds")
        Logger.debug("   Respiratory: \(respiratory?.description ?? "No data") breaths/min")
        
        return (hrv, rhr, sleep, respiratory)
    }
    
    /// Clear cached baselines (useful for testing or when data changes)
    func clearCache() {
        cachedBaselines = nil
        cacheTimestamp = nil
        Logger.debug("🗑️ Baseline cache cleared")
    }
    
    // MARK: - Helper Methods
    
    // Removed duplicate calculation methods - now use VeloReadyCore.BaselineCalculations
}
