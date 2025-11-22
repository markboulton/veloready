import Foundation

/// Pure calculation logic for sleep scores
/// No dependencies on iOS frameworks or UI
/// Extracted from SleepScoreCalculator in iOS app
public struct SleepCalculations {
    
    // MARK: - Data Structures
    
    public struct SleepInputs {
        public let sleepDuration: Double?
        public let timeInBed: Double?
        public let sleepNeed: Double?
        public let deepSleepDuration: Double?
        public let remSleepDuration: Double?
        public let coreSleepDuration: Double?
        public let awakeDuration: Double?
        public let wakeEvents: Int?
        public let bedtime: Date?
        public let wakeTime: Date?
        public let baselineBedtime: Date?
        public let baselineWakeTime: Date?
        public let hrvOvernight: Double?
        public let hrvBaseline: Double?
        public let sleepLatency: Double?
        
        public init(sleepDuration: Double? = nil, timeInBed: Double? = nil, sleepNeed: Double? = nil,
                    deepSleepDuration: Double? = nil, remSleepDuration: Double? = nil, coreSleepDuration: Double? = nil,
                    awakeDuration: Double? = nil, wakeEvents: Int? = nil,
                    bedtime: Date? = nil, wakeTime: Date? = nil,
                    baselineBedtime: Date? = nil, baselineWakeTime: Date? = nil,
                    hrvOvernight: Double? = nil, hrvBaseline: Double? = nil, sleepLatency: Double? = nil) {
            self.sleepDuration = sleepDuration
            self.timeInBed = timeInBed
            self.sleepNeed = sleepNeed
            self.deepSleepDuration = deepSleepDuration
            self.remSleepDuration = remSleepDuration
            self.coreSleepDuration = coreSleepDuration
            self.awakeDuration = awakeDuration
            self.wakeEvents = wakeEvents
            self.bedtime = bedtime
            self.wakeTime = wakeTime
            self.baselineBedtime = baselineBedtime
            self.baselineWakeTime = baselineWakeTime
            self.hrvOvernight = hrvOvernight
            self.hrvBaseline = hrvBaseline
            self.sleepLatency = sleepLatency
        }
    }
    
    public struct SubScores {
        public let performance: Int
        public let efficiency: Int
        public let stageQuality: Int
        public let disturbances: Int
        public let timing: Int
        
        public init(performance: Int, efficiency: Int, stageQuality: Int, disturbances: Int, timing: Int) {
            self.performance = performance
            self.efficiency = efficiency
            self.stageQuality = stageQuality
            self.disturbances = disturbances
            self.timing = timing
        }
    }
    
    // MARK: - Main Sleep Score Calculation

    /// Calculate sleep score from inputs using Whoop-like algorithm
    public static func calculateScore(
        inputs: SleepInputs
    ) -> (score: Int, subScores: SubScores) {
        let subScores = calculateSubScores(inputs: inputs)

        // Reweighted formula: Performance 30%, Stage Quality 32%, Efficiency 22%, Disturbances 14%, Timing 2%
        let performanceFactor = Double(subScores.performance) * 0.30
        let efficiencyFactor = Double(subScores.efficiency) * 0.22
        let stageQualityFactor = Double(subScores.stageQuality) * 0.32
        let disturbancesFactor = Double(subScores.disturbances) * 0.14
        let timingFactor = Double(subScores.timing) * 0.02

        var finalScore = performanceFactor + efficiencyFactor + stageQualityFactor + disturbancesFactor + timingFactor

        // Apply HRV-based quality adjustment
        // Alcohol/stress suppresses HRV even when sleep duration/stages look normal
        // This catches "false good sleep" scenarios
        finalScore = applyHRVQualityAdjustment(baseScore: finalScore, inputs: inputs)

        return (score: Int(max(0, min(100, finalScore))), subScores: subScores)
    }

    // MARK: - HRV Quality Adjustment

    /// Apply HRV-based sleep quality adjustment
    /// Catches alcohol/stress impact that duration-based metrics miss
    ///
    /// Research: Alcohol causes HRV suppression during sleep even when:
    /// - Sleep duration meets target
    /// - Sleep stages (deep/REM %) appear normal
    /// - Efficiency is high
    ///
    /// This adjustment penalizes sleep scores when HRV is suppressed,
    /// reflecting actual recovery quality vs perceived sleep quality.
    private static func applyHRVQualityAdjustment(baseScore: Double, inputs: SleepInputs) -> Double {
        guard let hrvOvernight = inputs.hrvOvernight,
              let hrvBaseline = inputs.hrvBaseline,
              hrvBaseline > 0 else {
            return baseScore // No HRV data, use base score
        }

        let hrvChange = ((hrvOvernight - hrvBaseline) / hrvBaseline) * 100

        // Only penalize for suppressed HRV (negative change)
        // Elevated HRV is positive for recovery
        guard hrvChange < -5.0 else {
            return baseScore // HRV is normal or elevated
        }

        // Calculate penalty based on suppression magnitude
        // Light suppression (5-10%): 3-8pt penalty
        // Moderate suppression (10-15%): 8-15pt penalty
        // Significant suppression (15-25%): 15-25pt penalty
        // Severe suppression (>25%): 25-35pt penalty
        let penalty: Double
        if hrvChange < -25.0 {
            penalty = 25 + min(10, (abs(hrvChange) - 25) * 0.5) // 25-35pt
        } else if hrvChange < -15.0 {
            penalty = 15 + (abs(hrvChange) - 15) * 1.0 // 15-25pt
        } else if hrvChange < -10.0 {
            penalty = 8 + (abs(hrvChange) - 10) * 1.4 // 8-15pt
        } else {
            // -5% to -10%
            penalty = 3 + (abs(hrvChange) - 5) * 1.0 // 3-8pt
        }

        return baseScore - penalty
    }
    
    // MARK: - Sub-Score Calculations
    
    public static func calculateSubScores(inputs: SleepInputs) -> SubScores {
        let performanceScore = calculatePerformanceScore(inputs: inputs)
        let efficiencyScore = calculateEfficiencyScore(inputs: inputs)
        let stageQualityScore = calculateStageQualityScore(inputs: inputs)
        let disturbancesScore = calculateDisturbancesScore(inputs: inputs)
        let timingScore = calculateTimingScore(inputs: inputs)
        
        return SubScores(
            performance: performanceScore,
            efficiency: efficiencyScore,
            stageQuality: stageQualityScore,
            disturbances: disturbancesScore,
            timing: timingScore
        )
    }
    
    /// Calculate performance component (duration vs need) - 0-100
    public static func calculatePerformanceScore(inputs: SleepInputs) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              let sleepNeed = inputs.sleepNeed,
              sleepNeed > 0 else { return 50 }
        
        // Performance = (actual sleep / sleep need) * 100, capped at 100
        let ratio = sleepDuration / sleepNeed
        let score = min(100, ratio * 100)
        return max(0, Int(score))
    }
    
    /// Calculate efficiency component (asleep vs in bed) - 0-100
    public static func calculateEfficiencyScore(inputs: SleepInputs) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              let timeInBed = inputs.timeInBed,
              timeInBed > 0 else { return 50 }
        
        // Efficiency = (time asleep / time in bed) * 100
        let efficiency = sleepDuration / timeInBed
        let score = efficiency * 100
        return max(0, min(100, Int(score)))
    }
    
    /// Calculate stage quality component (deep + REM percentage) - 0-100
    /// Uses fixed thresholds - for personalized scoring, use calculatePersonalizedStageQualityScore
    public static func calculateStageQualityScore(inputs: SleepInputs) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              sleepDuration > 0 else { return 50 }
        
        let deepDuration = inputs.deepSleepDuration ?? 0
        let remDuration = inputs.remSleepDuration ?? 0
        
        // Stage quality based on deep + REM percentage (target: >40%)
        let deepRemPercentage = (deepDuration + remDuration) / sleepDuration
        
        if deepRemPercentage >= 0.40 {
            return 100 // Excellent stage distribution
        } else if deepRemPercentage >= 0.30 {
            // Linear scale from 100 at 40% to 50 at 30%
            let score = 50 + ((deepRemPercentage - 0.30) * 500)
            return max(50, Int(score))
        } else {
            // Poor stage distribution
            let score = deepRemPercentage * 166.67 // Scale 0%-30% to 0-50
            return max(0, Int(score))
        }
    }
    
    /// Calculate personalized stage quality component using user's historical baselines
    /// - Parameters:
    ///   - inputs: Sleep inputs
    ///   - personalDeepBaseline: User's 30-day average deep sleep percentage (optional, uses 0.15 if nil)
    ///   - personalREMBaseline: User's 30-day average REM sleep percentage (optional, uses 0.20 if nil)
    /// - Returns: Stage quality score 0-100
    public static func calculatePersonalizedStageQualityScore(
        inputs: SleepInputs,
        personalDeepBaseline: Double? = nil,
        personalREMBaseline: Double? = nil
    ) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              sleepDuration > 0 else { return 50 }
        
        let deepDuration = inputs.deepSleepDuration ?? 0
        let remDuration = inputs.remSleepDuration ?? 0
        
        // Calculate actual percentages
        let deepPercentage = deepDuration / sleepDuration
        let remPercentage = remDuration / sleepDuration
        
        // Use personalized baselines if available, otherwise use population averages
        let targetDeep = personalDeepBaseline ?? 0.15 // Default: 15% deep sleep
        let targetREM = personalREMBaseline ?? 0.20   // Default: 20% REM sleep
        
        // Score deep sleep component (0-50 points)
        var deepScore: Double = 0
        if deepPercentage >= targetDeep {
            // At or above baseline - excellent
            deepScore = 50
        } else {
            // Below baseline - scale proportionally
            let ratio = deepPercentage / targetDeep
            deepScore = ratio * 50
        }
        
        // Score REM sleep component (0-50 points)
        var remScore: Double = 0
        if remPercentage >= targetREM {
            // At or above baseline - excellent
            remScore = 50
        } else {
            // Below baseline - scale proportionally
            let ratio = remPercentage / targetREM
            remScore = ratio * 50
        }
        
        // Combined score (0-100)
        let finalScore = deepScore + remScore
        
        return max(0, min(100, Int(finalScore)))
    }
    
    /// Calculate disturbances component (wake events penalty) - 0-100
    public static func calculateDisturbancesScore(inputs: SleepInputs) -> Int {
        guard let wakeEvents = inputs.wakeEvents else { return 50 }
        
        // Fewer disturbances = higher score
        // 0-2 wake events = 100, 3-5 = 75, 6-8 = 50, 9+ = 25
        switch wakeEvents {
        case 0...2: return 100
        case 3...5: return 75
        case 6...8: return 50
        default: return 25
        }
    }
    
    /// Calculate timing component (consistency) - 0-100
    public static func calculateTimingScore(inputs: SleepInputs) -> Int {
        guard let bedtime = inputs.bedtime,
              let wakeTime = inputs.wakeTime,
              let baselineBedtime = inputs.baselineBedtime,
              let baselineWakeTime = inputs.baselineWakeTime else { return 50 }
        
        // Calculate deviation from baseline timing
        let bedtimeDeviation = abs(bedtime.timeIntervalSince(baselineBedtime))
        let wakeTimeDeviation = abs(wakeTime.timeIntervalSince(baselineWakeTime))
        
        // Convert to minutes
        let bedtimeDeviationMinutes = bedtimeDeviation / 60
        let wakeTimeDeviationMinutes = wakeTimeDeviation / 60
        
        // Average deviation
        let avgDeviation = (bedtimeDeviationMinutes + wakeTimeDeviationMinutes) / 2
        
        // Score based on consistency (0-30 minutes = 100, 30-60 = 75, 60-90 = 50, 90+ = 25)
        switch avgDeviation {
        case 0...30: return 100
        case 30...60: return 75
        case 60...90: return 50
        default: return 25
        }
    }
}
