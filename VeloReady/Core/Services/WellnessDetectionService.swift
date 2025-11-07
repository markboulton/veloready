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
    
    private let calculator = WellnessDetectionCalculator()
    private var lastAnalysisDate: Date?
    private let minimumAnalysisInterval: TimeInterval = 3600 // 1 hour between analyses
    
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
        
        // Delegate heavy calculation to actor (runs on background thread)
        async let rhrTrend = calculator.analyzeRHRTrend(days: 3)
        async let hrvTrend = calculator.analyzeHRVTrend(days: 3)
        async let respiratoryTrend = calculator.analyzeRespiratoryTrend(days: 3)
        async let bodyTempTrend = calculator.analyzeBodyTempTrend(days: 3)
        async let sleepTrend = calculator.analyzeSleepQualityTrend(days: 3)
        
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
    
    // MARK: - Helper Methods
    
    private func determineAlert(metrics: WellnessAlert.AffectedMetrics, maxConsecutiveDays: Int) -> WellnessAlert? {
        let affectedCount = metrics.count
        
        // No alert if less than 3 metrics affected (increased from 2)
        guard affectedCount >= 3 else { return nil }
        
        // Override: If recovery score is good (>75), don't show alert unless very severe
        if let recoveryScore = RecoveryScoreService.shared.currentRecoveryScore?.score,
           recoveryScore > 75 {
            // Only show alert if 4+ metrics affected (very severe)
            guard affectedCount >= 4 else { return nil }
        }
        
        // Determine severity based on number of affected metrics and duration
        let severity: WellnessAlert.Severity
        let type: WellnessAlert.AlertType
        
        if affectedCount >= 5 || maxConsecutiveDays >= 4 {
            severity = .red
            type = .multipleIndicators
        } else if affectedCount >= 4 || maxConsecutiveDays >= 3 {
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
}
