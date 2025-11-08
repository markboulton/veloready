import Foundation

/// Pure calculation logic for baseline calculations
/// No dependencies on iOS frameworks or UI
public struct BaselineCalculations {
    
    // MARK: - HRV Baseline
    
    /// Calculate adaptive HRV baseline with outlier removal and robust statistics
    /// Uses 30-day window with 3-sigma outlier removal and median (robust to outliers)
    /// - Parameter hrvValues: Array of daily HRV values (ms) - most recent last
    /// - Returns: HRV baseline or nil if insufficient data
    public static func calculateHRVBaseline(
        hrvValues: [Double]
    ) -> Double? {
        guard !hrvValues.isEmpty else { return nil }
        
        // Use last 30 days if available (more stable), minimum 7 days
        let windowSize = min(30, hrvValues.count)
        let recentValues = Array(hrvValues.suffix(windowSize))
        
        guard recentValues.count >= 3 else {
            // Not enough data for outlier removal, use simple average
            return recentValues.reduce(0, +) / Double(recentValues.count)
        }
        
        // Remove outliers using 3-sigma rule
        let cleanedValues = removeOutliers(from: recentValues, sigmaThreshold: 3.0)
        
        guard !cleanedValues.isEmpty else { return nil }
        
        // Use median instead of mean (robust to remaining outliers)
        return calculateMedian(cleanedValues)
    }
    
    /// Calculate 7-day HRV baseline (legacy compatibility)
    /// - Parameter hrvValues: Array of daily HRV values (ms)
    /// - Returns: HRV baseline or nil if insufficient data
    public static func calculateHRVBaseline7Day(
        hrvValues: [Double]
    ) -> Double? {
        guard !hrvValues.isEmpty else { return nil }
        
        let windowSize = min(7, hrvValues.count)
        let recentValues = Array(hrvValues.suffix(windowSize))
        
        let sum = recentValues.reduce(0, +)
        let average = sum / Double(recentValues.count)
        
        return average
    }
    
    // MARK: - RHR Baseline
    
    /// Calculate adaptive RHR baseline with outlier removal and robust statistics
    /// Uses 30-day window with 3-sigma outlier removal and median
    /// - Parameter rhrValues: Array of daily RHR values (bpm) - most recent last
    /// - Returns: RHR baseline or nil if insufficient data
    public static func calculateRHRBaseline(
        rhrValues: [Double]
    ) -> Double? {
        guard !rhrValues.isEmpty else { return nil }
        
        // Use last 30 days if available, minimum 7 days
        let windowSize = min(30, rhrValues.count)
        let recentValues = Array(rhrValues.suffix(windowSize))
        
        guard recentValues.count >= 3 else {
            // Not enough data for outlier removal, use simple average
            return recentValues.reduce(0, +) / Double(recentValues.count)
        }
        
        // Remove outliers using 3-sigma rule
        let cleanedValues = removeOutliers(from: recentValues, sigmaThreshold: 3.0)
        
        guard !cleanedValues.isEmpty else { return nil }
        
        // Use median instead of mean (robust to remaining outliers)
        return calculateMedian(cleanedValues)
    }
    
    // MARK: - Sleep Baseline
    
    /// Calculate 7-day sleep baseline (rolling average duration in hours)
    /// - Parameter sleepDurations: Array of daily sleep durations (hours)
    /// - Returns: Sleep baseline or nil if insufficient data
    public static func calculateSleepBaseline(
        sleepDurations: [Double]
    ) -> Double? {
        guard !sleepDurations.isEmpty else { return nil }
        
        // Calculate mean
        let sum = sleepDurations.reduce(0, +)
        let average = sum / Double(sleepDurations.count)
        
        return average
    }
    
    // MARK: - Sleep Score Baseline
    
    /// Calculate 7-day sleep score baseline (rolling average of 0-100 scores)
    /// - Parameter sleepScores: Array of daily sleep scores (0-100)
    /// - Returns: Sleep score baseline or nil if insufficient data
    public static func calculateSleepScoreBaseline(
        sleepScores: [Double]
    ) -> Double? {
        guard !sleepScores.isEmpty else { return nil }
        
        // Calculate mean
        let sum = sleepScores.reduce(0, +)
        let average = sum / Double(sleepScores.count)
        
        return average
    }
    
    // MARK: - Respiratory Baseline
    
    /// Calculate adaptive respiratory rate baseline with outlier removal
    /// Uses 30-day window with 3-sigma outlier removal and median
    /// - Parameter respiratoryRates: Array of daily respiratory rates (breaths/min) - most recent last
    /// - Returns: Respiratory baseline or nil if insufficient data
    public static func calculateRespiratoryBaseline(
        respiratoryRates: [Double]
    ) -> Double? {
        guard !respiratoryRates.isEmpty else { return nil }
        
        // Use last 30 days if available, minimum 7 days
        let windowSize = min(30, respiratoryRates.count)
        let recentValues = Array(respiratoryRates.suffix(windowSize))
        
        guard recentValues.count >= 3 else {
            return recentValues.reduce(0, +) / Double(recentValues.count)
        }
        
        // Remove outliers using 3-sigma rule
        let cleanedValues = removeOutliers(from: recentValues, sigmaThreshold: 3.0)
        
        guard !cleanedValues.isEmpty else { return nil }
        
        // Use median for stability
        return calculateMedian(cleanedValues)
    }
    
    // MARK: - Statistical Utilities
    
    /// Remove outliers from dataset using sigma threshold
    /// - Parameters:
    ///   - values: Input values
    ///   - sigmaThreshold: Number of standard deviations for outlier threshold (typically 2.0-3.0)
    /// - Returns: Values with outliers removed
    private static func removeOutliers(
        from values: [Double],
        sigmaThreshold: Double = 3.0
    ) -> [Double] {
        guard values.count >= 3 else { return values }
        
        // Calculate mean and standard deviation
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        // Filter values within threshold
        let threshold = stdDev * sigmaThreshold
        return values.filter { abs($0 - mean) <= threshold }
    }
    
    /// Calculate median of values (robust central tendency)
    /// - Parameter values: Input values
    /// - Returns: Median value
    private static func calculateMedian(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            // Even count: average of two middle values
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            // Odd count: middle value
            return sorted[count/2]
        }
    }
    
    /// Calculate standard deviation of values
    /// - Parameter values: Input values
    /// - Returns: Standard deviation
    public static func calculateStandardDeviation(_ values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    /// Calculate coefficient of variation (CV) - measures relative variability
    /// CV = (std dev / mean) * 100
    /// - Parameter values: Input values
    /// - Returns: CV percentage or nil if insufficient data
    public static func calculateCoefficientOfVariation(_ values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        guard let stdDev = calculateStandardDeviation(values) else { return nil }
        
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return nil }
        
        return (stdDev / mean) * 100.0
    }
}
