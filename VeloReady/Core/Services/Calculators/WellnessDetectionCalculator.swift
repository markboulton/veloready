import Foundation
import HealthKit

/// Actor for wellness detection calculations
/// Performs heavy trend analysis on background threads
actor WellnessDetectionCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    
    // Detection thresholds (conservative to avoid false positives)
    private let rhrElevationThreshold = 0.15 // 15% above baseline
    private let hrvDepressionThreshold = -0.20 // 20% below baseline
    private let respiratoryElevationThreshold = 0.20 // 20% above baseline
    private let bodyTempElevationThreshold = 0.5 // 0.5°C above baseline
    private let minimumConsecutiveDays = 2 // Need at least 2 days of sustained changes
    
    // MARK: - Trend Analysis Methods
    
    func analyzeRHRTrend(days: Int) async -> TrendResult {
        // PERFORMANCE FIX: Fetch data once before loop
        // Currently fetchRHRForDate uses "latest" data (not historical per-day)
        // So calling it in a loop is redundant - fetch once and use for all iterations
        let rhrData = await fetchRHRForDate(Date())
        guard let rhr = rhrData.value, let baseline = rhrData.baseline, baseline > 0 else {
            return TrendResult(isAbnormal: false, consecutiveDays: 0)
        }
        
        let percentChange = (rhr - baseline) / baseline
        
        // If current RHR is elevated, check if it's been sustained
        // Note: When historical data is implemented, this logic will need updating
        if percentChange > rhrElevationThreshold {
            // For now, assume if current is elevated, it's been sustained for 1 day
            // TODO: Implement historical RHR fetching for accurate multi-day analysis
            return TrendResult(
                isAbnormal: true,
                consecutiveDays: 1
            )
        }
        
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    func analyzeHRVTrend(days: Int) async -> TrendResult {
        // PERFORMANCE FIX: Fetch data once before loop
        // Currently fetchHRVForDate uses "latest" data (not historical per-day)
        // So calling it in a loop is redundant - fetch once and use for all iterations
        let hrvData = await fetchHRVForDate(Date())
        guard let hrv = hrvData.value, let baseline = hrvData.baseline, baseline > 0 else {
            return TrendResult(isAbnormal: false, consecutiveDays: 0)
        }
        
        let percentChange = (hrv - baseline) / baseline
        
        // If current HRV is depressed, check if it's been sustained
        // Note: When historical data is implemented, this logic will need updating
        if percentChange < hrvDepressionThreshold {
            // For now, assume if current is depressed, it's been sustained for 1 day
            // TODO: Implement historical HRV fetching for accurate multi-day analysis
            return TrendResult(
                isAbnormal: true,
                consecutiveDays: 1
            )
        }
        
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    func analyzeRespiratoryTrend(days: Int) async -> TrendResult {
        // PERFORMANCE FIX: Fetch data once before loop
        // Currently fetchRespiratoryForDate uses "latest" data (not historical per-day)
        // So calling it in a loop is redundant - fetch once and use for all iterations
        let respData = await fetchRespiratoryForDate(Date())
        guard let resp = respData.value, let baseline = respData.baseline, baseline > 0 else {
            return TrendResult(isAbnormal: false, consecutiveDays: 0)
        }
        
        let percentChange = (resp - baseline) / baseline
        
        // If current respiratory rate is elevated, check if it's been sustained
        // Note: When historical data is implemented, this logic will need updating
        if percentChange > respiratoryElevationThreshold {
            // For now, assume if current is elevated, it's been sustained for 1 day
            // TODO: Implement historical respiratory fetching for accurate multi-day analysis
            return TrendResult(
                isAbnormal: true,
                consecutiveDays: 1
            )
        }
        
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    func analyzeBodyTempTrend(days: Int) async -> TrendResult {
        // Note: Body temperature data is rare in HealthKit (requires manual entry or specific devices)
        // This is included for completeness but will often return no data
        return TrendResult(isAbnormal: false, consecutiveDays: 0)
    }
    
    func analyzeSleepQualityTrend(days: Int) async -> TrendResult {
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
    
    // MARK: - Supporting Types
    
    struct TrendResult {
        let isAbnormal: Bool
        let consecutiveDays: Int
    }
}
