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

    // MARK: - Rolling HRV Average (Research-Backed)

    /// Calculate 7-day rolling LnRMSSD average for recovery assessment
    /// Research: "A 7-day running average of LnRMSSD instead of daily measures" (Plews et al., 2013)
    /// This reduces day-to-day noise and provides more stable recovery indication
    /// - Parameters:
    ///   - hrvValues: Array of daily HRV values (ms) - most recent last
    ///   - days: Window size for rolling average (default 7)
    /// - Returns: Rolling average or nil if insufficient data
    public static func calculateRollingHRVAverage(
        hrvValues: [Double],
        days: Int = 7
    ) -> Double? {
        guard !hrvValues.isEmpty else { return nil }

        let windowSize = min(days, hrvValues.count)
        let recentValues = Array(hrvValues.suffix(windowSize))

        guard !recentValues.isEmpty else { return nil }

        // Calculate rolling average of natural log transformed values (LnRMSSD)
        let lnValues = recentValues.map { log($0) }
        let sum = lnValues.reduce(0, +)
        let average = sum / Double(lnValues.count)

        // Return in original scale (exponential of average)
        return exp(average)
    }

    /// Calculate raw 7-day rolling average (without log transformation)
    /// Use when you want simple average without LnRMSSD transformation
    /// - Parameters:
    ///   - hrvValues: Array of daily HRV values (ms) - most recent last
    ///   - days: Window size for rolling average (default 7)
    /// - Returns: Rolling average or nil if insufficient data
    public static func calculateRollingHRVAverageSimple(
        hrvValues: [Double],
        days: Int = 7
    ) -> Double? {
        guard !hrvValues.isEmpty else { return nil }

        let windowSize = min(days, hrvValues.count)
        let recentValues = Array(hrvValues.suffix(windowSize))

        guard !recentValues.isEmpty else { return nil }

        return recentValues.reduce(0, +) / Double(recentValues.count)
    }

    // MARK: - HRV Coefficient of Variation (CV)

    /// Calculate HRV Coefficient of Variation for readiness assessment
    /// Research: "Athletes with smallest CV handle overload well... highest CV respond least favorably"
    /// CV measures day-to-day HRV stability - higher CV = less stable = need more recovery
    /// - Parameters:
    ///   - hrvValues: Array of daily HRV values (ms) - most recent last
    ///   - days: Window size for CV calculation (default 7)
    /// - Returns: CV as percentage (e.g., 8.5 means 8.5% variation) or nil if insufficient data
    public static func calculateHRVCV(
        hrvValues: [Double],
        days: Int = 7
    ) -> Double? {
        guard hrvValues.count >= 3 else { return nil }

        let windowSize = min(days, hrvValues.count)
        let recentValues = Array(hrvValues.suffix(windowSize))

        guard recentValues.count >= 3 else { return nil }

        // Calculate mean
        let mean = recentValues.reduce(0, +) / Double(recentValues.count)
        guard mean > 0 else { return nil }

        // Calculate standard deviation
        let variance = recentValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(recentValues.count)
        let stdDev = sqrt(variance)

        // CV = (std dev / mean) * 100
        return (stdDev / mean) * 100.0
    }

    /// Interpret HRV CV value for readiness
    /// Based on research: CV < 5% = excellent stability, 5-10% = good, 10-15% = moderate, >15% = high
    public enum HRVStability: String {
        case excellent = "excellent"  // CV < 5%
        case good = "good"            // CV 5-10%
        case moderate = "moderate"    // CV 10-15%
        case poor = "poor"            // CV > 15%

        /// Recovery modifier based on stability (-5 to +5 points)
        public var recoveryModifier: Int {
            switch self {
            case .excellent: return 5   // Very stable = bonus
            case .good: return 0        // Normal = no change
            case .moderate: return -5   // Less stable = penalty
            case .poor: return -10      // Unstable = significant penalty
            }
        }
    }

    /// Get HRV stability category from CV value
    public static func getHRVStability(cv: Double) -> HRVStability {
        switch cv {
        case ..<5.0: return .excellent
        case 5.0..<10.0: return .good
        case 10.0..<15.0: return .moderate
        default: return .poor
        }
    }

    // MARK: - HRV Trend Detection

    /// HRV trend direction
    public enum HRVTrendDirection: String {
        case improving = "improving"    // 7-day > 30-day baseline
        case stable = "stable"          // Within ±5% of baseline
        case declining = "declining"    // 7-day < 30-day baseline
    }

    /// HRV trend result with direction and magnitude
    public struct HRVTrend {
        public let direction: HRVTrendDirection
        public let magnitude: Double  // Percentage change from baseline
        public let shortTermAverage: Double
        public let longTermBaseline: Double

        public init(direction: HRVTrendDirection, magnitude: Double, shortTermAverage: Double, longTermBaseline: Double) {
            self.direction = direction
            self.magnitude = magnitude
            self.shortTermAverage = shortTermAverage
            self.longTermBaseline = longTermBaseline
        }
    }

    /// Detect HRV trend by comparing 7-day average to 30-day baseline
    /// Research: "An increasing HRV trend... is not always good" - context matters
    /// - Parameters:
    ///   - hrvValues: Array of daily HRV values (ms) - most recent last, need at least 14 days
    ///   - shortTermDays: Days for short-term average (default 7)
    ///   - longTermDays: Days for long-term baseline (default 30)
    /// - Returns: HRV trend with direction and magnitude, or nil if insufficient data
    public static func detectHRVTrend(
        hrvValues: [Double],
        shortTermDays: Int = 7,
        longTermDays: Int = 30
    ) -> HRVTrend? {
        guard hrvValues.count >= shortTermDays else { return nil }

        // Calculate short-term average (most recent 7 days)
        guard let shortTermAvg = calculateRollingHRVAverageSimple(hrvValues: hrvValues, days: shortTermDays) else {
            return nil
        }

        // Calculate long-term baseline (up to 30 days)
        let longTermValues = Array(hrvValues.suffix(longTermDays))
        guard let longTermBaseline = calculateHRVBaseline(hrvValues: longTermValues), longTermBaseline > 0 else {
            return nil
        }

        // Calculate percentage change
        let percentChange = ((shortTermAvg - longTermBaseline) / longTermBaseline) * 100

        // Determine direction
        let direction: HRVTrendDirection
        if percentChange > 5.0 {
            direction = .improving
        } else if percentChange < -5.0 {
            direction = .declining
        } else {
            direction = .stable
        }

        return HRVTrend(
            direction: direction,
            magnitude: percentChange,
            shortTermAverage: shortTermAvg,
            longTermBaseline: longTermBaseline
        )
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

    // MARK: - Adaptive Baseline Weighting (Phase 4)

    /// Calculate exponentially-weighted baseline that adapts faster to recent changes
    /// More recent data is weighted more heavily using exponential decay
    /// - Parameters:
    ///   - values: Array of values (most recent last)
    ///   - halfLifeDays: Half-life in days (default 10 = recent 10 days weighted 2x older 10)
    /// - Returns: Exponentially-weighted baseline
    public static func calculateAdaptiveBaseline(
        values: [Double],
        halfLifeDays: Double = 10.0
    ) -> Double? {
        guard !values.isEmpty else { return nil }

        // Decay constant: weight = e^(-decay * days_ago)
        // Half-life: when days_ago = halfLifeDays, weight = 0.5
        // decay = ln(2) / halfLifeDays
        let decay = log(2.0) / halfLifeDays

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        // Weight more recent values higher
        // values[n-1] = today (days_ago = 0, weight = 1.0)
        // values[0] = oldest (days_ago = n-1)
        let n = values.count
        for (index, value) in values.enumerated() {
            let daysAgo = Double(n - 1 - index)
            let weight = exp(-decay * daysAgo)
            weightedSum += value * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return nil }
        return weightedSum / totalWeight
    }

    /// Calculate adaptive baseline with outlier removal
    /// Combines adaptive weighting with robust outlier detection
    /// - Parameters:
    ///   - values: Array of values (most recent last)
    ///   - halfLifeDays: Half-life for weighting (default 10)
    ///   - sigmaThreshold: Outlier threshold (default 2.5)
    /// - Returns: Robust adaptive baseline
    public static func calculateRobustAdaptiveBaseline(
        values: [Double],
        halfLifeDays: Double = 10.0,
        sigmaThreshold: Double = 2.5
    ) -> Double? {
        guard values.count >= 3 else {
            return calculateAdaptiveBaseline(values: values, halfLifeDays: halfLifeDays)
        }

        // First pass: remove outliers
        let cleanedValues = removeOutliers(from: values, sigmaThreshold: sigmaThreshold)

        guard !cleanedValues.isEmpty else { return nil }

        // Second pass: calculate adaptive baseline
        return calculateAdaptiveBaseline(values: cleanedValues, halfLifeDays: halfLifeDays)
    }

    // MARK: - Recovery Profile Detection (Phase 4)

    /// Recovery profile classification based on historical patterns
    public enum RecoveryProfile: String {
        case fast = "Fast Recoverer"           // Bounces back quickly from hard efforts
        case normal = "Normal Recoverer"       // Standard recovery timeline
        case slow = "Slow Recoverer"           // Needs more time between hard sessions
        case unknown = "Unknown"               // Insufficient data

        /// Recommended recovery modifier for scoring (-10 to +10)
        public var scoringModifier: Int {
            switch self {
            case .fast: return 5      // Can train harder more often
            case .normal: return 0    // Standard scoring
            case .slow: return -5     // More conservative recommendations
            case .unknown: return 0
            }
        }

        /// Description for UI display
        public var description: String {
            switch self {
            case .fast: return "You recover quickly from hard efforts. Your body handles training stress well."
            case .normal: return "Your recovery follows typical patterns. Standard training guidelines apply."
            case .slow: return "You benefit from more recovery between hard sessions. Quality over quantity."
            case .unknown: return "More data needed to determine your recovery profile."
            }
        }
    }

    /// Detect user's recovery profile from historical HRV patterns
    /// Analyzes how quickly HRV returns to baseline after hard training days
    /// - Parameters:
    ///   - hrvValues: Array of daily HRV values (most recent last)
    ///   - tssValues: Array of daily TSS values matching HRV dates
    /// - Returns: Recovery profile classification
    public static func detectRecoveryProfile(
        hrvValues: [Double],
        tssValues: [Double]
    ) -> RecoveryProfile {
        guard hrvValues.count >= 14, tssValues.count >= 14 else {
            return .unknown // Need at least 2 weeks of data
        }

        // Find hard training days (TSS > 100)
        var recoveryTimes: [Int] = []

        // Calculate baseline for comparison
        guard let hrvBaseline = calculateHRVBaseline(hrvValues: hrvValues) else {
            return .unknown
        }

        let threshold = hrvBaseline * 0.95 // Within 5% of baseline = recovered

        // Analyze recovery after each hard day
        for i in 0..<(tssValues.count - 3) {
            if tssValues[i] > 100 {
                // Found a hard day, track recovery
                var recoveryDays = 0
                for j in (i+1)..<min(i+5, hrvValues.count) {
                    if hrvValues[j] >= threshold {
                        recoveryDays = j - i
                        break
                    }
                }
                if recoveryDays > 0 {
                    recoveryTimes.append(recoveryDays)
                }
            }
        }

        guard recoveryTimes.count >= 3 else {
            return .unknown // Not enough hard training days to analyze
        }

        // Calculate average recovery time
        let avgRecoveryDays = Double(recoveryTimes.reduce(0, +)) / Double(recoveryTimes.count)

        // Classify based on average recovery time
        switch avgRecoveryDays {
        case ..<1.5: return .fast      // Recovers in ~1 day
        case 1.5..<2.5: return .normal // Recovers in 1-2 days
        default: return .slow          // Takes 2+ days
        }
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
