import Foundation

/// Pure sleep score calculation functions
/// These functions are extracted from the iOS app for independent testing
public struct SleepCalculations {
    
    // MARK: - Constants
    
    /// Weight for performance (duration vs need) in sleep score (30%)
    public static let performanceWeight = 0.30
    
    /// Weight for sleep efficiency in sleep score (22%)
    public static let efficiencyWeight = 0.22
    
    /// Weight for stage quality (deep/REM) in sleep score (32%)
    public static let stageQualityWeight = 0.32
    
    /// Weight for disturbances in sleep score (14%)
    public static let disturbancesWeight = 0.14
    
    /// Weight for timing consistency in sleep score (2%)
    public static let timingWeight = 0.02
    
    // MARK: - Sleep Bands
    
    public enum SleepBand: String, CaseIterable {
        case optimal = "Optimal"
        case good = "Good"
        case fair = "Fair"
        case payAttention = "Pay Attention"
        
        public var minScore: Int {
            switch self {
            case .optimal: return 80
            case .good: return 60
            case .fair: return 40
            case .payAttention: return 0
            }
        }
        
        public var maxScore: Int {
            switch self {
            case .optimal: return 100
            case .good: return 79
            case .fair: return 59
            case .payAttention: return 39
            }
        }
        
        public var color: String {
            switch self {
            case .optimal: return "green"
            case .good: return "yellow"
            case .fair: return "orange"
            case .payAttention: return "red"
            }
        }
    }
    
    // MARK: - Sleep Score Result
    
    public struct SleepScore {
        public let score: Int
        public let band: SleepBand
        public let performanceScore: Int
        public let efficiencyScore: Int
        public let stageQualityScore: Int
        public let disturbancesScore: Int
        public let timingScore: Int
        
        public init(score: Int, band: SleepBand, performanceScore: Int, efficiencyScore: Int, stageQualityScore: Int, disturbancesScore: Int, timingScore: Int) {
            self.score = score
            self.band = band
            self.performanceScore = performanceScore
            self.efficiencyScore = efficiencyScore
            self.stageQualityScore = stageQualityScore
            self.disturbancesScore = disturbancesScore
            self.timingScore = timingScore
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate sleep score from individual components
    /// - Parameters:
    ///   - sleepDuration: Total sleep duration (seconds)
    ///   - sleepNeed: Sleep need based on baseline + training load (seconds)
    ///   - timeInBed: Total time in bed (seconds)
    ///   - deepSleep: Deep sleep duration (seconds)
    ///   - remSleep: REM sleep duration (seconds)
    ///   - wakeEvents: Number of wake events during sleep
    ///   - bedtime: Actual bedtime
    ///   - wakeTime: Actual wake time
    ///   - baselineBedtime: Typical bedtime
    ///   - baselineWakeTime: Typical wake time
    /// - Returns: SleepScore with final score and breakdown
    public static func calculateSleepScore(
        sleepDuration: Double?,
        sleepNeed: Double?,
        timeInBed: Double?,
        deepSleep: Double?,
        remSleep: Double?,
        wakeEvents: Int?,
        bedtime: Date?,
        wakeTime: Date?,
        baselineBedtime: Date?,
        baselineWakeTime: Date?
    ) -> SleepScore {
        // Calculate sub-components
        let performanceScore = calculatePerformanceScore(
            sleepDuration: sleepDuration,
            sleepNeed: sleepNeed
        )
        
        let efficiencyScore = calculateEfficiencyScore(
            sleepDuration: sleepDuration,
            timeInBed: timeInBed
        )
        
        let stageQualityScore = calculateStageQualityScore(
            sleepDuration: sleepDuration,
            deepSleep: deepSleep,
            remSleep: remSleep
        )
        
        let disturbancesScore = calculateDisturbancesScore(wakeEvents: wakeEvents)
        
        let timingScore = calculateTimingScore(
            bedtime: bedtime,
            wakeTime: wakeTime,
            baselineBedtime: baselineBedtime,
            baselineWakeTime: baselineWakeTime
        )
        
        // Weighted combination
        let performanceFactor = Double(performanceScore) * performanceWeight
        let efficiencyFactor = Double(efficiencyScore) * efficiencyWeight
        let stageQualityFactor = Double(stageQualityScore) * stageQualityWeight
        let disturbancesFactor = Double(disturbancesScore) * disturbancesWeight
        let timingFactor = Double(timingScore) * timingWeight
        
        let finalScore = performanceFactor + efficiencyFactor + stageQualityFactor + disturbancesFactor + timingFactor
        let clampedScore = max(0, min(100, Int(finalScore)))
        
        let band = determineSleepBand(score: clampedScore)
        
        return SleepScore(
            score: clampedScore,
            band: band,
            performanceScore: performanceScore,
            efficiencyScore: efficiencyScore,
            stageQualityScore: stageQualityScore,
            disturbancesScore: disturbancesScore,
            timingScore: timingScore
        )
    }
    
    // MARK: - Performance Score Calculation
    
    /// Calculate performance sub-score (0-100)
    /// Based on actual sleep vs sleep need
    /// - Parameters:
    ///   - sleepDuration: Actual sleep duration (seconds)
    ///   - sleepNeed: Sleep need (seconds)
    /// - Returns: Performance score (0-100)
    public static func calculatePerformanceScore(
        sleepDuration: Double?,
        sleepNeed: Double?
    ) -> Int {
        guard let sleepDuration = sleepDuration,
              let sleepNeed = sleepNeed,
              sleepNeed > 0 else { return 50 }
        
        // Performance = (actual sleep / sleep need) * 100, capped at 100
        let ratio = sleepDuration / sleepNeed
        let score = min(100, ratio * 100)
        return max(0, Int(score))
    }
    
    // MARK: - Efficiency Score Calculation
    
    /// Calculate efficiency sub-score (0-100)
    /// Based on time asleep vs time in bed
    /// - Parameters:
    ///   - sleepDuration: Time actually asleep (seconds)
    ///   - timeInBed: Total time in bed (seconds)
    /// - Returns: Efficiency score (0-100)
    public static func calculateEfficiencyScore(
        sleepDuration: Double?,
        timeInBed: Double?
    ) -> Int {
        guard let sleepDuration = sleepDuration,
              let timeInBed = timeInBed,
              timeInBed > 0 else { return 50 }
        
        // Efficiency = (time asleep / time in bed) * 100
        let efficiency = sleepDuration / timeInBed
        let score = efficiency * 100
        return max(0, min(100, Int(score)))
    }
    
    // MARK: - Stage Quality Score Calculation
    
    /// Calculate stage quality sub-score (0-100)
    /// Based on percentage of deep + REM sleep
    /// - Parameters:
    ///   - sleepDuration: Total sleep duration (seconds)
    ///   - deepSleep: Deep sleep duration (seconds)
    ///   - remSleep: REM sleep duration (seconds)
    /// - Returns: Stage quality score (0-100)
    public static func calculateStageQualityScore(
        sleepDuration: Double?,
        deepSleep: Double?,
        remSleep: Double?
    ) -> Int {
        guard let sleepDuration = sleepDuration,
              sleepDuration > 0 else { return 50 }
        
        let deepDuration = deepSleep ?? 0
        let remDuration = remSleep ?? 0
        
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
    
    // MARK: - Disturbances Score Calculation
    
    /// Calculate disturbances sub-score (0-100)
    /// Based on number of wake events
    /// - Parameter wakeEvents: Number of times woken during sleep
    /// - Returns: Disturbances score (0-100)
    public static func calculateDisturbancesScore(wakeEvents: Int?) -> Int {
        guard let wakeEvents = wakeEvents else { return 50 }
        
        // Fewer disturbances = higher score
        // 0-2 wake events = 100, 3-5 = 75, 6-8 = 50, 9+ = 25
        switch wakeEvents {
        case 0...2: return 100
        case 3...5: return 75
        case 6...8: return 50
        default: return 25
        }
    }
    
    // MARK: - Timing Score Calculation
    
    /// Calculate timing sub-score (0-100)
    /// Based on consistency with baseline sleep/wake times
    /// - Parameters:
    ///   - bedtime: Actual bedtime
    ///   - wakeTime: Actual wake time
    ///   - baselineBedtime: Typical bedtime
    ///   - baselineWakeTime: Typical wake time
    /// - Returns: Timing score (0-100)
    public static func calculateTimingScore(
        bedtime: Date?,
        wakeTime: Date?,
        baselineBedtime: Date?,
        baselineWakeTime: Date?
    ) -> Int {
        guard let bedtime = bedtime,
              let wakeTime = wakeTime,
              let baselineBedtime = baselineBedtime,
              let baselineWakeTime = baselineWakeTime else { return 50 }
        
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
    
    // MARK: - Helper Functions
    
    /// Determine sleep band from score
    /// - Parameter score: Sleep score (0-100)
    /// - Returns: Sleep band
    public static func determineSleepBand(score: Int) -> SleepBand {
        switch score {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .payAttention
        }
    }
}

