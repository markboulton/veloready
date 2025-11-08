import Foundation

/// Pure calculation logic for baseline calculations
/// No dependencies on iOS frameworks or UI
public struct BaselineCalculations {
    
    // MARK: - Data Structures
    
    /// Sample data for historical alcohol detection
    public struct HistoricalSample {
        public let date: Date
        public let hrv: Double
        public let rhr: Double
        public let sleepScore: Int?
        
        public init(date: Date, hrv: Double, rhr: Double, sleepScore: Int?) {
            self.date = date
            self.hrv = hrv
            self.rhr = rhr
            self.sleepScore = sleepScore
        }
    }
    
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
    
    // MARK: - Smart Alcohol Detection for Baseline Exclusion
    
    /// Detect likely alcohol days in historical data to exclude from baseline calculation
    /// This prevents baseline contamination from regular alcohol consumption
    /// - Parameter samples: Historical samples with date, HRV, RHR, and optional sleep score
    /// - Returns: Set of dates to exclude from baseline (alcohol days + recovery days)
    public static func detectHistoricalAlcoholDays(
        samples: [HistoricalSample]
    ) -> Set<Date> {
        var alcoholDays = Set<Date>()
        
        guard samples.count >= 2 else { return alcoholDays }
        
        let calendar = Calendar.current
        
        for i in 1..<samples.count {
            let today = samples[i]
            let yesterday = samples[i-1]
            
            // Calculate changes
            let hrvDrop = (today.hrv - yesterday.hrv) / yesterday.hrv
            let rhrSpike = today.rhr - yesterday.rhr
            
            // Alcohol signature detection (score-based)
            var alcoholScore = 0
            
            // Signal 1: Sharp HRV drop (>20% overnight)
            if hrvDrop < -0.30 {
                alcoholScore += 3  // Severe drop
            } else if hrvDrop < -0.20 {
                alcoholScore += 2  // Moderate drop
            } else if hrvDrop < -0.15 {
                alcoholScore += 1  // Mild drop
            }
            
            // Signal 2: RHR spike (>5 bpm increase)
            if rhrSpike > 8 {
                alcoholScore += 3  // Large spike
            } else if rhrSpike > 5 {
                alcoholScore += 2  // Moderate spike
            } else if rhrSpike > 3 {
                alcoholScore += 1  // Mild spike
            }
            
            // Signal 3: Poor sleep quality
            if let sleep = today.sleepScore {
                if sleep < 50 {
                    alcoholScore += 2  // Very poor sleep
                } else if sleep < 65 {
                    alcoholScore += 1  // Poor sleep
                }
            }
            
            // Signal 4: Weekend timing (not exclusive, just a hint)
            let weekday = calendar.component(.weekday, from: today.date)
            if weekday == 1 || weekday == 7 {  // Sunday or Saturday
                alcoholScore += 1
            }
            
            // Signal 5: Rapid recovery (next day HRV rebounds)
            // Alcohol often shows rapid rebound (>15% next day)
            if i < samples.count - 1 {
                let tomorrow = samples[i+1]
                let hrvRebound = (tomorrow.hrv - today.hrv) / today.hrv
                
                if hrvRebound > 0.20 {
                    alcoholScore += 2  // Strong rebound
                } else if hrvRebound > 0.15 {
                    alcoholScore += 1  // Moderate rebound
                }
            }
            
            // Threshold: Score ≥5 = likely alcohol
            if alcoholScore >= 5 {
                // Normalize dates to start of day for comparison
                let todayNormalized = calendar.startOfDay(for: today.date)
                alcoholDays.insert(todayNormalized)
                
                // Also exclude the recovery day (next day)
                if i < samples.count - 1 {
                    let tomorrowNormalized = calendar.startOfDay(for: samples[i+1].date)
                    alcoholDays.insert(tomorrowNormalized)
                }
            }
        }
        
        return alcoholDays
    }
    
    /// Calculate HRV baseline with smart alcohol exclusion
    /// Detects and excludes historical alcohol days to prevent baseline contamination
    /// - Parameter samples: Historical samples with date, HRV, RHR, and optional sleep score
    /// - Returns: Clean HRV baseline or nil if insufficient data
    public static func calculateHRVBaselineWithAlcoholExclusion(
        samples: [HistoricalSample]
    ) -> Double? {
        guard !samples.isEmpty else { return nil }
        
        // Step 1: Detect alcohol days
        let alcoholDays = detectHistoricalAlcoholDays(samples: samples)
        
        // Step 2: Filter out alcohol days
        let calendar = Calendar.current
        let cleanSamples = samples.filter { sample in
            let normalizedDate = calendar.startOfDay(for: sample.date)
            return !alcoholDays.contains(normalizedDate)
        }
        
        // Step 3: Use last 30 clean days
        let recentClean = Array(cleanSamples.suffix(30))
        
        guard recentClean.count >= 15 else {
            // Not enough clean data, fall back to standard 30-day baseline
            let allValues = samples.suffix(30).map { $0.hrv }
            return calculateHRVBaseline(hrvValues: Array(allValues))
        }
        
        // Step 4: Apply outlier removal and median
        let cleanedValues = removeOutliers(from: recentClean.map { $0.hrv }, sigmaThreshold: 3.0)
        
        guard !cleanedValues.isEmpty else { return nil }
        
        return calculateMedian(cleanedValues)
    }
}
