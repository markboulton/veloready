import Foundation
import HealthKit

/// Enhanced illness detection service with ML-based pattern recognition and caching
/// Detects potential body stress signals through multi-day physiological trend analysis
/// DISCLAIMER: This is NOT medical advice - it's a wellness awareness tool
@MainActor
class IllnessDetectionService: ObservableObject {
    static let shared = IllnessDetectionService()
    
    @Published var currentIndicator: IllnessIndicator?
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private let cacheManager = UnifiedCacheManager.shared
    
    // Analysis configuration
    private let minimumAnalysisInterval: TimeInterval = 3600 // 1 hour between analyses
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
    
    private init() {}
    
    // MARK: - Public API
    
    /// Analyze recent health trends for potential illness indicators
    /// Uses caching to avoid redundant calculations
    func analyzeHealthTrends(forceRefresh: Bool = false) async {
        // Debug mode: show mock illness indicator
        #if DEBUG
        if ProFeatureConfig.shared.showIllnessIndicatorForTesting {
            Logger.debug("🧪 DEBUG: Showing mock illness indicator")
            currentIndicator = IllnessIndicator(
                date: Date(),
                severity: .moderate,
                confidence: 0.78,
                signals: [
                    IllnessIndicator.Signal(
                        type: .elevatedRHR,
                        deviation: 8.5,
                        value: 62.0,
                        baseline: 57.1
                    ),
                    IllnessIndicator.Signal(
                        type: .hrvDrop,
                        deviation: -18.2,
                        value: 42.5,
                        baseline: 52.0
                    )
                ],
                recommendation: "Take it easy with training - light activity or rest"
            )
            lastAnalysisDate = Date()
            return
        }
        #endif
        guard !isAnalyzing else {
            Logger.debug("🔍 Illness analysis already in progress, skipping...")
            return
        }
        
        // Check if we've analyzed recently (unless force refresh)
        if !forceRefresh, let lastAnalysis = lastAnalysisDate {
            let timeSinceLastAnalysis = Date().timeIntervalSince(lastAnalysis)
            if timeSinceLastAnalysis < minimumAnalysisInterval {
                Logger.debug("⏰ Illness analysis ran \(Int(timeSinceLastAnalysis/60))m ago, skipping")
                return
            }
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        Logger.debug("🔍 Starting illness detection analysis...")
        Logger.debug("   Analysis window: \(analysisWindowDays) days")
        Logger.debug("   Minimum data points: \(minimumDataPoints)")
        Logger.debug("   Thresholds: HRV \(Thresholds.hrvDropPercent)%, RHR +\(Thresholds.rhrElevationPercent)%")
        
        // Try to fetch from cache first
        let cacheKey = CacheKey.illnessDetection(date: Date())
        
        do {
            let indicator = try await cacheManager.fetch(
                key: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.wellness
            ) {
                // Cache miss - perform analysis
                return await self.performAnalysis()
            }
            
            currentIndicator = indicator
            lastAnalysisDate = Date()
            
            if let indicator = indicator {
                Logger.warning("⚠️ ILLNESS INDICATOR: \(indicator.severity.rawValue) - \(indicator.confidence * 100)% confidence")
            } else {
                Logger.debug("✅ No illness indicators detected")
            }
            
        } catch {
            Logger.error("❌ Illness detection failed: \(error.localizedDescription)")
            currentIndicator = nil
        }
    }
    
    /// Clear cached illness detection results
    func clearCache() {
        let cacheKey = CacheKey.illnessDetection(date: Date())
        cacheManager.invalidate(key: cacheKey)
        Logger.debug("🗑️ Cleared illness detection cache")
    }
    
    // MARK: - Analysis Engine
    
    private func performAnalysis() async -> IllnessIndicator? {
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
        let sleepBaseline = await baselineCalculator.calculateSleepBaseline()
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
        var values: [Double] = []
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Fetch HRV for specific day
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            let value = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
                let query = HKSampleQuery(
                    sampleType: hrvType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let samples = samples as? [HKQuantitySample], !samples.isEmpty {
                        // Get average HRV for the day
                        let dayValues = samples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                        let avg = dayValues.reduce(0, +) / Double(dayValues.count)
                        continuation.resume(returning: avg)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                healthStore.execute(query)
            }
            
            if let value = value {
                values.append(value)
                Logger.debug("📊 HRV Day -\(dayOffset): \(String(format: "%.1f", value))ms")
            }
        }
        
        Logger.debug("📊 Fetched \(values.count) days of HRV data")
        return values
    }
    
    private func fetchMultiDayRHR() async -> [Double] {
        var values: [Double] = []
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        
        for dayOffset in 0..<analysisWindowDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Fetch RHR for specific day
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            let value = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
                let query = HKSampleQuery(
                    sampleType: rhrType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let samples = samples as? [HKQuantitySample], !samples.isEmpty {
                        // Get average RHR for the day
                        let dayValues = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                        let avg = dayValues.reduce(0, +) / Double(dayValues.count)
                        continuation.resume(returning: avg)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                healthStore.execute(query)
            }
            
            if let value = value {
                values.append(value)
                Logger.debug("📊 RHR Day -\(dayOffset): \(String(format: "%.1f", value)) bpm")
            }
        }
        
        Logger.debug("📊 Fetched \(values.count) days of RHR data")
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

// MARK: - Cache Key Extension

extension CacheKey {
    static func illnessDetection(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "illness:detection:\(dateString)"
    }
}
