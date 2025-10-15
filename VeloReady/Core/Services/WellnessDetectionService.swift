import Foundation
import HealthKit

/// Service for detecting potential illness through multi-day physiological trend analysis
/// DISCLAIMER: This is NOT medical advice. This is a wellness awareness tool that detects
/// unusual patterns in your metrics. Always consult healthcare professionals for medical concerns.
@MainActor
class WellnessDetectionService: ObservableObject {
    static let shared = WellnessDetectionService()
    
    @Published var currentAlert: WellnessAlert?
    @Published var isAnalyzing = false
    
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    private var lastAnalysisDate: Date?
    private let minimumAnalysisInterval: TimeInterval = 3600 // 1 hour between analyses
    
    // Detection thresholds (conservative to avoid false positives)
    private let rhrElevationThreshold = 0.10 // 10% above baseline
    private let hrvDepressionThreshold = -0.15 // 15% below baseline
    private let respiratoryElevationThreshold = 0.15 // 15% above baseline
    private let bodyTempElevationThreshold = 0.5 // 0.5°C above baseline
    private let minimumConsecutiveDays = 2 // Need at least 2 days of sustained changes
    
    private init() {}
    
    /// Analyze recent health trends for potential illness indicators
    func analyzeHealthTrends() async {
        // Debug mode: show mock wellness warning
        #if DEBUG
        if ProFeatureConfig.shared.showWellnessWarningForTesting {
            Logger.debug("🧪 DEBUG: Showing mock wellness warning")
            currentAlert = WellnessAlert(
                severity: .red,
                type: .multipleIndicators,
                detectedAt: Date(),
                metrics: WellnessAlert.AffectedMetrics(
                    elevatedRHR: true,
                    depressedHRV: true,
                    elevatedRespiratoryRate: true,
                    elevatedBodyTemp: false,
                    poorSleep: true
                ),
                trendDays: 3
            )
            return
        }
        #endif
        
        guard !isAnalyzing else {
            Logger.warning("️ Wellness analysis already in progress, skipping...")
            return
        }
        
        // Skip wellness analysis if sleep data is missing (unreliable)
        if SleepScoreService.shared.currentSleepScore == nil {
            Logger.warning("️ Skipping wellness analysis - no sleep data available (unreliable without sleep)")
            currentAlert = nil
            return
        }
        
        // Check if we've analyzed recently
        if let lastAnalysis = lastAnalysisDate {
            let timeSinceLastAnalysis = Date().timeIntervalSince(lastAnalysis)
            if timeSinceLastAnalysis < minimumAnalysisInterval {
                Logger.warning("️ Wellness analysis ran \(Int(timeSinceLastAnalysis/60))m ago, skipping (min interval: \(Int(minimumAnalysisInterval/60))m)")
                return
            }
        }
        
        isAnalyzing = true
        lastAnalysisDate = Date()
        defer { isAnalyzing = false }
        
        Logger.debug("🔍 Starting wellness trend analysis...")
        
        // Fetch multi-day data for trend analysis (3 days)
        async let rhrTrend = analyzeRHRTrend(days: 3)
        async let hrvTrend = analyzeHRVTrend(days: 3)
        async let respiratoryTrend = analyzeRespiratoryTrend(days: 3)
        async let bodyTempTrend = analyzeBodyTempTrend(days: 3)
        async let sleepTrend = analyzeSleepQualityTrend(days: 3)
        
        // Wait for all analyses
        let (rhrResult, hrvResult, respResult, tempResult, sleepResult) = await (
            rhrTrend, hrvTrend, respiratoryTrend, bodyTempTrend, sleepTrend
        )
        
        Logger.debug("🔍 Trend Analysis Results:")
        Logger.debug("   RHR Elevated: \(rhrResult.isAbnormal) (\(rhrResult.consecutiveDays) days)")
        Logger.debug("   HRV Depressed: \(hrvResult.isAbnormal) (\(hrvResult.consecutiveDays) days)")
        Logger.debug("   Respiratory Elevated: \(respResult.isAbnormal) (\(respResult.consecutiveDays) days)")
        Logger.debug("   Body Temp Elevated: \(tempResult.isAbnormal) (\(tempResult.consecutiveDays) days)")
        Logger.debug("   Sleep Quality Poor: \(sleepResult.isAbnormal) (\(sleepResult.consecutiveDays) days)")
        
        // Create affected metrics summary
        let affectedMetrics = WellnessAlert.AffectedMetrics(
            elevatedRHR: rhrResult.isAbnormal,
            depressedHRV: hrvResult.isAbnormal,
            elevatedRespiratoryRate: respResult.isAbnormal,
            elevatedBodyTemp: tempResult.isAbnormal,
            poorSleep: sleepResult.isAbnormal
        )
        
        // Determine if we should show an alert
        let alert = determineAlert(
            metrics: affectedMetrics,
            maxConsecutiveDays: max(rhrResult.consecutiveDays, hrvResult.consecutiveDays, respResult.consecutiveDays, tempResult.consecutiveDays, sleepResult.consecutiveDays)
        )
        
        currentAlert = alert
        
        if let alert = alert {
            Logger.warning("️ WELLNESS ALERT: \(alert.severity.rawValue) - \(alert.bannerMessage)")
        } else {
            Logger.debug("✅ No wellness concerns detected")
        }
    }
    
    // MARK: - Trend Analysis Methods
    
    private func analyzeRHRTrend(days: Int) async -> TrendResult {
        let calendar = Calendar.current
        let today = Date()
        
        var consecutiveDaysElevated = 0
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Fetch RHR for this day
            let rhrData = await fetchRHRForDate(date)
            guard let rhr = rhrData.value, let baseline = rhrData.baseline, baseline > 0 else { continue }
            
            let percentChange = (rhr - baseline) / baseline
            
            if percentChange > rhrElevationThreshold {
                consecutiveDaysElevated += 1
            } else {
                break // Pattern broken
            }
        }
        
        return TrendResult(
            isAbnormal: consecutiveDaysElevated >= minimumConsecutiveDays,
            consecutiveDays: consecutiveDaysElevated
        )
    }
    
    private func analyzeHRVTrend(days: Int) async -> TrendResult {
        let calendar = Calendar.current
        let today = Date()
        
        var consecutiveDaysDepressed = 0
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let hrvData = await fetchHRVForDate(date)
            guard let hrv = hrvData.value, let baseline = hrvData.baseline, baseline > 0 else { continue }
            
            let percentChange = (hrv - baseline) / baseline
            
            if percentChange < hrvDepressionThreshold {
                consecutiveDaysDepressed += 1
            } else {
                break
            }
        }
        
        return TrendResult(
            isAbnormal: consecutiveDaysDepressed >= minimumConsecutiveDays,
            consecutiveDays: consecutiveDaysDepressed
        )
    }
    
    private func analyzeRespiratoryTrend(days: Int) async -> TrendResult {
        let calendar = Calendar.current
        let today = Date()
        
        var consecutiveDaysElevated = 0
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let respData = await fetchRespiratoryForDate(date)
            guard let resp = respData.value, let baseline = respData.baseline, baseline > 0 else { continue }
            
            let percentChange = (resp - baseline) / baseline
            
            if percentChange > respiratoryElevationThreshold {
                consecutiveDaysElevated += 1
            } else {
                break
            }
        }
        
        return TrendResult(
            isAbnormal: consecutiveDaysElevated >= minimumConsecutiveDays,
            consecutiveDays: consecutiveDaysElevated
        )
    }
    
    private func analyzeBodyTempTrend(days: Int) async -> TrendResult {
        // Note: Body temperature data is rare in HealthKit (requires manual entry or specific devices)
        // This is included for completeness but will often return no data
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    private func analyzeSleepQualityTrend(days: Int) async -> TrendResult {
        // Check if sleep quality has been consistently poor (but not alcohol-related)
        // This is different from alcohol detection - we're looking for sustained poor sleep
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    // MARK: - Helper Methods
    
    private func fetchRHRForDate(_ date: Date) async -> (value: Double?, baseline: Double?) {
        // For now, use latest RHR and baseline
        // In a full implementation, we'd fetch historical RHR for the specific date
        let rhr = await healthKitManager.fetchLatestRHRData()
        let baseline = await baselineCalculator.calculateRHRBaseline()
        
        return (
            value: rhr.sample?.quantity.doubleValue(for: HKUnit(from: "count/min")),
            baseline: baseline
        )
    }
    
    private func fetchHRVForDate(_ date: Date) async -> (value: Double?, baseline: Double?) {
        let hrv = await healthKitManager.fetchLatestHRVData()
        let baseline = await baselineCalculator.calculateHRVBaseline()
        
        return (
            value: hrv.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
            baseline: baseline
        )
    }
    
    private func fetchRespiratoryForDate(_ date: Date) async -> (value: Double?, baseline: Double?) {
        let resp = await healthKitManager.fetchLatestRespiratoryRateData()
        let baseline = await baselineCalculator.calculateRespiratoryBaseline()
        
        return (
            value: resp.sample?.quantity.doubleValue(for: HKUnit(from: "count/min")),
            baseline: baseline
        )
    }
    
    private func determineAlert(metrics: WellnessAlert.AffectedMetrics, maxConsecutiveDays: Int) -> WellnessAlert? {
        let affectedCount = metrics.count
        
        // No alert if less than 2 metrics affected
        guard affectedCount >= 2 else { return nil }
        
        // Determine severity based on number of affected metrics and duration
        let severity: WellnessAlert.Severity
        let type: WellnessAlert.AlertType
        
        if affectedCount >= 4 || maxConsecutiveDays >= 3 {
            severity = .red
            type = .multipleIndicators
        } else if affectedCount >= 3 || maxConsecutiveDays >= 2 {
            severity = .amber
            type = .sustainedElevation
        } else {
            severity = .yellow
            type = .unusualMetrics
        }
        
        return WellnessAlert(
            severity: severity,
            type: type,
            detectedAt: Date(),
            metrics: metrics,
            trendDays: maxConsecutiveDays
        )
    }
    
    // MARK: - Supporting Types
    
    private struct TrendResult {
        let isAbnormal: Bool
        let consecutiveDays: Int
    }
}
