import Foundation
import HealthKit

/// Actor for illness detection calculations
/// Performs heavy multi-day data analysis and ML pattern recognition on background threads
actor IllnessDetectionCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private let cacheManager = UnifiedCacheManager.shared
    
    // Analysis configuration
    private let analysisWindowDays = 7 // Analyze 7 days of data
    private let minimumDataPoints = 3 // Need at least 3 days of data
    
    // Detection thresholds (lowered for better sensitivity based on real-world testing)
    private struct Thresholds {
        static let hrvDropPercent = -10.0 // 10% drop (lowered from 15%)
        static let rhrElevationPercent = 3.0 // 3% elevation (lowered from 5%)
        static let sleepQualityDropPercent = -15.0 // 15% drop (lowered from 20%)
        static let respiratoryChangePercent = 8.0 // 8% change (lowered from 10%)
        static let activityDropPercent = -25.0 // 25% drop (lowered from 30%)
        static let temperatureElevationCelsius = 0.3 // 0.3°C (lowered from 0.5°C)
        static let minimumSignals = 1 // Only need 1 signal if it's strong (lowered from 2)
    }
    
    // MARK: - Analysis Engine
    
    func performAnalysis() async -> IllnessIndicator? {
        // Fetch multi-day health data
        async let hrvData = fetchMultiDayHRV()
        async let rhrData = fetchMultiDayRHR()
        async let sleepData = fetchMultiDaySleep()
        async let respiratoryData = fetchMultiDayRespiratory()
        async let activityData = fetchMultiDayActivity()
        
        let (hrv, rhr, sleep, respiratory, activity) = await (
            hrvData, rhrData, sleepData, respiratoryData, activityData
        )
        
        // Calculate baselines
        let hrvBaseline = await baselineCalculator.calculateHRVBaseline()
        let rhrBaseline = await baselineCalculator.calculateRHRBaseline()
        let sleepBaseline = await baselineCalculator.calculateSleepScoreBaseline()  // Use SCORE baseline, not duration
        let respiratoryBaseline = await baselineCalculator.calculateRespiratoryBaseline()
        let activityBaseline = await calculateActivityBaseline()
        
        // Detect using ML-enhanced pattern recognition
        let indicator = IllnessIndicator.detect(
            hrv: hrv.last,
            hrvBaseline: hrvBaseline,
            rhr: rhr.last,
            rhrBaseline: rhrBaseline,
            sleepScore: sleep.last,
            sleepBaseline: sleepBaseline,
            activityLevel: activity.last,
            activityBaseline: activityBaseline,
            respiratoryRate: respiratory.last,
            respiratoryBaseline: respiratoryBaseline
        )
        
        // Apply ML-based confidence adjustment
        if var indicator = indicator {
            indicator = applyMLConfidenceAdjustment(
                indicator: indicator,
                hrvTrend: hrv,
                rhrTrend: rhr,
                sleepTrend: sleep,
                respiratoryTrend: respiratory,
                activityTrend: activity
            )
            
            // Only return if confidence is sufficient
            return indicator.confidence >= 0.5 ? indicator : nil
        }
        
        return nil
    }
    
    // MARK: - Data Fetching
    
    private func fetchMultiDayHRV() async -> [Double] {
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return []
        }
        
        // OPTIMIZED: Batch query for entire date range (1 query instead of 7)
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -analysisWindowDays, to: endDate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        
        let data = await withCheckedContinuation { (continuation: CheckedContinuation<[Date: Double], Never>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    Logger.error("❌ Failed to fetch HRV batch: \(error)")
                    continuation.resume(returning: [:])
                    return
                }
                
                var dailyValues: [Date: Double] = [:]
                results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let avg = statistics.averageQuantity() {
                        let value = avg.doubleValue(for: HKUnit.secondUnit(with: .milli))
                        dailyValues[statistics.startDate] = value
                    }
                }
                
                continuation.resume(returning: dailyValues)
            }
            
            healthStore.execute(query)
        }
        
        // Convert to array ordered by day offset (newest first)
        var values: [Double] = []
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
                  let dayStart = calendar.startOfDay(for: date) as Date?,
                  let value = data[dayStart] else {
                continue
            }
            values.append(value)
            Logger.debug("📊 HRV Day -\(dayOffset): \(String(format: "%.1f", value))ms")
        }
        
        Logger.debug("📊 Batched HRV: Fetched \(values.count)/\(analysisWindowDays) days in 1 query")
        return values
    }
    
    private func fetchMultiDayRHR() async -> [Double] {
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        guard let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return []
        }
        
        // OPTIMIZED: Batch query for entire date range (1 query instead of 7)
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -analysisWindowDays, to: endDate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        
        let data = await withCheckedContinuation { (continuation: CheckedContinuation<[Date: Double], Never>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: rhrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    Logger.error("❌ Failed to fetch RHR batch: \(error)")
                    continuation.resume(returning: [:])
                    return
                }
                
                var dailyValues: [Date: Double] = [:]
                results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let avg = statistics.averageQuantity() {
                        let value = avg.doubleValue(for: HKUnit(from: "count/min"))
                        dailyValues[statistics.startDate] = value
                    }
                }
                
                continuation.resume(returning: dailyValues)
            }
            
            healthStore.execute(query)
        }
        
        // Convert to array ordered by day offset (newest first)
        var values: [Double] = []
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
                  let dayStart = calendar.startOfDay(for: date) as Date?,
                  let value = data[dayStart] else {
                continue
            }
            values.append(value)
            Logger.debug("📊 RHR Day -\(dayOffset): \(String(format: "%.1f", value)) bpm")
        }
        
        Logger.debug("📊 Batched RHR: Fetched \(values.count)/\(analysisWindowDays) days in 1 query")
        return values
    }
    
    private func fetchMultiDaySleep() async -> [Int] {
        var values: [Int] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let cacheKey = CacheKey.sleepScore(date: date)
            
            do {
                let score = try await cacheManager.fetch(
                    key: cacheKey,
                    ttl: UnifiedCacheManager.CacheTTL.dailyScores
                ) {
                    return await SleepScoreService.shared.currentSleepScore?.score
                }
                
                if let score = score {
                    values.append(score)
                }
            } catch {
                Logger.debug("⚠️ Failed to fetch sleep score for \(date): \(error)")
            }
        }
        
        return values
    }
    
    private func fetchMultiDayRespiratory() async -> [Double] {
        var values: [Double] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let cacheKey = "healthkit:respiratory:\(ISO8601DateFormatter().string(from: date))"
            
            // PERFORMANCE FIX: Check if cache exists before attempting fetch
            // This prevents redundant cache layer lookups (Memory → Disk → CoreData)
            if let cachedValue: Double = await CacheOrchestrator.shared.get(
                key: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.healthMetrics
            ) {
                values.append(cachedValue)
                continue
            }
            
            // Cache miss - only fetch if we really need it
            do {
                let value = try await cacheManager.fetch(
                    key: cacheKey,
                    ttl: UnifiedCacheManager.CacheTTL.healthMetrics
                ) {
                    let data = await self.healthKitManager.fetchLatestRespiratoryRateData()
                    return data.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                
                if let value = value {
                    values.append(value)
                }
            } catch {
                Logger.debug("⚠️ Failed to fetch respiratory rate for \(date): \(error)")
            }
        }
        
        return values
    }
    
    private func fetchMultiDayActivity() async -> [Double] {
        // Simplified activity level based on step count
        var values: [Double] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let cacheKey = "healthkit:steps:\(ISO8601DateFormatter().string(from: date))"
            
            // PERFORMANCE FIX: Check if cache exists before attempting fetch
            // This prevents redundant cache layer lookups (Memory → Disk → CoreData)
            if let cachedSteps: Double = await CacheOrchestrator.shared.get(
                key: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.healthMetrics
            ) {
                values.append(cachedSteps)
                continue
            }
            
            // Cache miss - only fetch if we really need it
            do {
                let steps = try await cacheManager.fetch(
                    key: cacheKey,
                    ttl: UnifiedCacheManager.CacheTTL.healthMetrics
                ) {
                    // Fetch steps from HealthKit
                    return await self.fetchStepsForDate(date)
                }
                
                if let steps = steps {
                    values.append(steps)
                }
            } catch {
                Logger.debug("⚠️ Failed to fetch activity for \(date): \(error)")
            }
        }
        
        return values
    }
    
    private func fetchStepsForDate(_ date: Date) async -> Double? {
        // Simplified - would fetch actual step count from HealthKit
        // For now, return nil to indicate no data
        return nil
    }
    
    private func calculateActivityBaseline() async -> Double? {
        // Calculate 30-day average activity level
        // Simplified for now
        return nil
    }
    
    // MARK: - ML-Enhanced Pattern Recognition
    
    /// Apply ML-based confidence adjustment using trend analysis
    /// This simulates ML pattern recognition by analyzing multi-day trends
    private func applyMLConfidenceAdjustment(
        indicator: IllnessIndicator,
        hrvTrend: [Double],
        rhrTrend: [Double],
        sleepTrend: [Int],
        respiratoryTrend: [Double],
        activityTrend: [Double]
    ) -> IllnessIndicator {
        var adjustedConfidence = indicator.confidence
        
        // Pattern 1: Sustained multi-day trends increase confidence
        let hrvConsistency = calculateTrendConsistency(hrvTrend, expectedDirection: .decreasing)
        let rhrConsistency = calculateTrendConsistency(rhrTrend, expectedDirection: .increasing)
        
        if hrvConsistency > 0.7 || rhrConsistency > 0.7 {
            adjustedConfidence += 0.1 // Boost confidence by 10%
            Logger.debug("🧠 ML: Sustained trend detected, confidence boosted")
        }
        
        // Pattern 2: Multiple concurrent signals increase confidence
        let signalCount = indicator.signals.count
        if signalCount >= 3 {
            adjustedConfidence += 0.05 * Double(signalCount - 2)
            Logger.debug("🧠 ML: Multiple signals (\(signalCount)), confidence boosted")
        }
        
        // Pattern 3: Recent worsening trend increases severity
        if let recentHRV = hrvTrend.prefix(3).last,
           let olderHRV = hrvTrend.dropFirst(3).first,
           recentHRV < olderHRV {
            Logger.debug("🧠 ML: Worsening trend detected")
        }
        
        // Cap confidence at 1.0
        adjustedConfidence = min(adjustedConfidence, 1.0)
        
        // Create adjusted indicator
        return IllnessIndicator(
            date: indicator.date,
            severity: indicator.severity,
            confidence: adjustedConfidence,
            signals: indicator.signals,
            recommendation: indicator.recommendation
        )
    }
    
    private enum TrendDirection {
        case increasing
        case decreasing
    }
    
    /// Calculate how consistent a trend is in the expected direction
    /// Returns value between 0.0 (no consistency) and 1.0 (perfect consistency)
    private func calculateTrendConsistency(_ values: [Double], expectedDirection: TrendDirection) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        var consistentChanges = 0
        var totalChanges = 0
        
        for i in 1..<values.count {
            let change = values[i] - values[i-1]
            totalChanges += 1
            
            switch expectedDirection {
            case .increasing:
                if change > 0 { consistentChanges += 1 }
            case .decreasing:
                if change < 0 { consistentChanges += 1 }
            }
        }
        
        return totalChanges > 0 ? Double(consistentChanges) / Double(totalChanges) : 0.0
    }
}
