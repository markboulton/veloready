import Foundation

/// Pure recovery score calculation functions
/// These functions are extracted from the iOS app for independent testing
public struct RecoveryCalculations {
    
    // MARK: - Constants
    
    /// Weight for HRV in recovery score (30%)
    public static let hrvWeight = 0.30
    
    /// Weight for RHR in recovery score (20%)
    public static let rhrWeight = 0.20
    
    /// Weight for sleep in recovery score (30%)
    public static let sleepWeight = 0.30
    
    /// Weight for respiratory rate in recovery score (10%)
    public static let respiratoryWeight = 0.10
    
    /// Weight for training load (TSB) in recovery score (10%)
    public static let loadWeight = 0.10
    
    // MARK: - No Sleep Mode Weights (redistributed when sleep unavailable)
    
    /// HRV weight when no sleep data (42.8% - redistributed from 30%)
    public static let hrvWeightNoSleep = 0.428
    
    /// RHR weight when no sleep data (28.6% - redistributed from 20%)
    public static let rhrWeightNoSleep = 0.286
    
    /// Respiratory weight when no sleep data (14.3% - redistributed from 10%)
    public static let respiratoryWeightNoSleep = 0.143
    
    /// Load weight when no sleep data (14.3% - redistributed from 10%)
    public static let loadWeightNoSleep = 0.143
    
    // MARK: - Recovery Bands
    
    public enum RecoveryBand: String, CaseIterable {
        case optimal = "Optimal"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case limitedData = "Limited Data"
        
        public var minScore: Int {
            switch self {
            case .optimal: return 80
            case .good: return 60
            case .fair: return 40
            case .poor: return 0
            case .limitedData: return 0
            }
        }
        
        public var maxScore: Int {
            switch self {
            case .optimal: return 100
            case .good: return 79
            case .fair: return 59
            case .poor: return 39
            case .limitedData: return 100
            }
        }
        
        public var color: String {
            switch self {
            case .optimal: return "green"
            case .good: return "yellow"
            case .fair: return "orange"
            case .poor: return "red"
            case .limitedData: return "gray"
            }
        }
    }
    
    // MARK: - Recovery Score Result
    
    public struct RecoveryScore {
        public let score: Int
        public let band: RecoveryBand
        public let hrvScore: Int
        public let rhrScore: Int
        public let sleepScore: Int
        public let formScore: Int
        public let respiratoryScore: Int
        
        public init(score: Int, band: RecoveryBand, hrvScore: Int, rhrScore: Int, sleepScore: Int, formScore: Int, respiratoryScore: Int) {
            self.score = score
            self.band = band
            self.hrvScore = hrvScore
            self.rhrScore = rhrScore
            self.sleepScore = sleepScore
            self.formScore = formScore
            self.respiratoryScore = respiratoryScore
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate recovery score from individual components
    /// - Parameters:
    ///   - hrv: Current HRV value (ms)
    ///   - hrvBaseline: Baseline HRV value (ms)
    ///   - rhr: Current resting heart rate (bpm)
    ///   - rhrBaseline: Baseline resting heart rate (bpm)
    ///   - sleepDuration: Sleep duration (seconds)
    ///   - sleepBaseline: Baseline sleep duration (seconds)
    ///   - sleepQualityScore: Comprehensive sleep score (0-100), if available
    ///   - respiratoryRate: Current respiratory rate (breaths/min)
    ///   - respiratoryBaseline: Baseline respiratory rate (breaths/min)
    ///   - atl: Acute Training Load (fatigue)
    ///   - ctl: Chronic Training Load (fitness)
    ///   - yesterdayTSS: Yesterday's training stress score
    ///   - useSleepData: Whether to include sleep in calculation (default: true)
    /// - Returns: RecoveryScore with final score and breakdown
    public static func calculateRecoveryScore(
        hrv: Double?,
        hrvBaseline: Double?,
        rhr: Double?,
        rhrBaseline: Double?,
        sleepDuration: Double?,
        sleepBaseline: Double?,
        sleepQualityScore: Int?,
        respiratoryRate: Double?,
        respiratoryBaseline: Double?,
        atl: Double?,
        ctl: Double?,
        yesterdayTSS: Double?,
        useSleepData: Bool = true
    ) -> RecoveryScore {
        // Calculate sub-components
        let hrvScore = calculateHRVScore(hrv: hrv, baseline: hrvBaseline)
        let rhrScore = calculateRHRScore(rhr: rhr, baseline: rhrBaseline)
        let sleepScore = calculateSleepScore(
            sleepDuration: sleepDuration,
            sleepBaseline: sleepBaseline,
            sleepQualityScore: sleepQualityScore
        )
        let respiratoryScore = calculateRespiratoryScore(
            respiratory: respiratoryRate,
            baseline: respiratoryBaseline
        )
        let formScore = calculateFormScore(
            atl: atl,
            ctl: ctl,
            yesterdayTSS: yesterdayTSS
        )
        
        // Weighted combination - use rebalanced weights if sleep unavailable
        let hrvFactor: Double
        let rhrFactor: Double
        let sleepFactor: Double
        let respiratoryFactor: Double
        let loadFactor: Double
        
        if useSleepData {
            // Normal weights (with sleep)
            hrvFactor = Double(hrvScore) * hrvWeight
            rhrFactor = Double(rhrScore) * rhrWeight
            sleepFactor = Double(sleepScore) * sleepWeight
            respiratoryFactor = Double(respiratoryScore) * respiratoryWeight
            loadFactor = Double(formScore) * loadWeight
        } else {
            // Rebalanced weights (without sleep - redistributed proportionally)
            hrvFactor = Double(hrvScore) * hrvWeightNoSleep
            rhrFactor = Double(rhrScore) * rhrWeightNoSleep
            sleepFactor = 0.0 // Sleep excluded
            respiratoryFactor = Double(respiratoryScore) * respiratoryWeightNoSleep
            loadFactor = Double(formScore) * loadWeightNoSleep
        }
        
        let finalScore = hrvFactor + rhrFactor + sleepFactor + respiratoryFactor + loadFactor
        let clampedScore = max(0, min(100, Int(finalScore)))
        
        let band = determineRecoveryBand(score: clampedScore)
        
        return RecoveryScore(
            score: clampedScore,
            band: band,
            hrvScore: hrvScore,
            rhrScore: rhrScore,
            sleepScore: sleepScore,
            formScore: formScore,
            respiratoryScore: respiratoryScore
        )
    }
    
    // MARK: - HRV Score Calculation
    
    /// Calculate HRV sub-score (0-100)
    /// Higher HRV = better recovery
    /// - Parameters:
    ///   - hrv: Current HRV (ms)
    ///   - baseline: Baseline HRV (ms)
    /// - Returns: HRV score (0-100)
    public static func calculateHRVScore(hrv: Double?, baseline: Double?) -> Int {
        guard let hrv = hrv, let baseline = baseline, baseline > 0 else { return 50 }
        
        let percentageChange = (hrv - baseline) / baseline
        
        if percentageChange >= 0 {
            return 100 // At or above baseline = excellent
        } else {
            let absChange = abs(percentageChange)
            
            if absChange <= 0.10 {
                // Small drop (0-10%): Minimal penalty (100-85)
                let score = 100 - (absChange * 150)
                return max(85, Int(score))
            } else if absChange <= 0.20 {
                // Moderate drop (10-20%): Moderate penalty (85-60)
                let score = 85 - ((absChange - 0.10) * 250)
                return max(60, Int(score))
            } else if absChange <= 0.35 {
                // Significant drop (20-35%): Larger penalty (60-30)
                let score = 60 - ((absChange - 0.20) * 200)
                return max(30, Int(score))
            } else {
                // Extreme drop (>35%): Maximum penalty (30-0)
                let score = 30 - ((absChange - 0.35) * 60)
                return max(0, Int(score))
            }
        }
    }
    
    // MARK: - RHR Score Calculation
    
    /// Calculate RHR sub-score (0-100)
    /// Lower RHR = better recovery
    /// - Parameters:
    ///   - rhr: Current resting heart rate (bpm)
    ///   - baseline: Baseline resting heart rate (bpm)
    /// - Returns: RHR score (0-100)
    public static func calculateRHRScore(rhr: Double?, baseline: Double?) -> Int {
        guard let rhr = rhr, let baseline = baseline, baseline > 0 else { return 50 }
        
        let percentageChange = (rhr - baseline) / baseline
        
        if percentageChange <= 0 {
            return 100 // At or below baseline = excellent
        } else {
            if percentageChange <= 0.08 {
                // Small increase (0-8%): Minimal penalty (100-88)
                let score = 100 - (percentageChange * 150)
                return max(88, Int(score))
            } else if percentageChange <= 0.15 {
                // Moderate increase (8-15%): Moderate penalty (88-67)
                let score = 88 - ((percentageChange - 0.08) * 300)
                return max(67, Int(score))
            } else if percentageChange <= 0.25 {
                // Significant increase (15-25%): Larger penalty (67-37)
                let score = 67 - ((percentageChange - 0.15) * 300)
                return max(37, Int(score))
            } else {
                // Extreme increase (>25%): Maximum penalty (37-0)
                let score = 37 - ((percentageChange - 0.25) * 100)
                return max(0, Int(score))
            }
        }
    }
    
    // MARK: - Sleep Score Calculation
    
    /// Calculate sleep sub-score (0-100)
    /// Uses comprehensive sleep score if available, otherwise duration-based
    /// - Parameters:
    ///   - sleepDuration: Sleep duration (seconds)
    ///   - sleepBaseline: Baseline sleep duration (seconds)
    ///   - sleepQualityScore: Comprehensive sleep score (0-100)
    /// - Returns: Sleep score (0-100)
    public static func calculateSleepScore(
        sleepDuration: Double?,
        sleepBaseline: Double?,
        sleepQualityScore: Int?
    ) -> Int {
        // Use comprehensive sleep score if available
        if let qualityScore = sleepQualityScore {
            return qualityScore
        }
        
        // Fallback to duration-based calculation
        guard let sleep = sleepDuration,
              let baseline = sleepBaseline,
              baseline > 0 else { return 50 }
        
        let ratio = sleep / baseline
        let score = min(100, ratio * 100)
        return max(0, Int(score))
    }
    
    // MARK: - Respiratory Score Calculation
    
    /// Calculate respiratory rate sub-score (0-100)
    /// Normal rate = better recovery
    /// - Parameters:
    ///   - respiratory: Current respiratory rate (breaths/min)
    ///   - baseline: Baseline respiratory rate (breaths/min)
    /// - Returns: Respiratory score (0-100)
    public static func calculateRespiratoryScore(
        respiratory: Double?,
        baseline: Double?
    ) -> Int {
        guard let respiratory = respiratory,
              let baseline = baseline,
              baseline > 0 else { return 50 }
        
        let percentageChange = abs(respiratory - baseline) / baseline
        
        if percentageChange <= 0.10 {
            return 100 // Within 10% of baseline
        } else if percentageChange <= 0.20 {
            let score = 100 - ((percentageChange - 0.10) * 500)
            return max(50, Int(score))
        } else {
            let score = 50 - ((percentageChange - 0.20) * 125)
            return max(0, Int(score))
        }
    }
    
    // MARK: - Form Score Calculation
    
    /// Calculate form/load sub-score (0-100)
    /// Based on ATL/CTL ratio and recent training
    /// - Parameters:
    ///   - atl: Acute Training Load (fatigue)
    ///   - ctl: Chronic Training Load (fitness)
    ///   - yesterdayTSS: Yesterday's training stress
    /// - Returns: Form score (0-100)
    public static func calculateFormScore(
        atl: Double?,
        ctl: Double?,
        yesterdayTSS: Double?
    ) -> Int {
        guard let atl = atl, let ctl = ctl, ctl > 0 else { return 50 }
        
        let loadRatio = atl / ctl
        
        // Base score from ATL/CTL ratio
        var baseScore: Int
        if loadRatio < 1.0 {
            baseScore = 100 // Fresh state
        } else if loadRatio < 1.5 {
            // Linear scale from 100 at 1.0 to 50 at 1.5
            let score = 100 - ((loadRatio - 1.0) * 100)
            baseScore = max(50, Int(score))
        } else {
            // High fatigue state
            let score = 50 - ((loadRatio - 1.5) * 50)
            baseScore = max(0, Int(score))
        }
        
        // Apply yesterday's TSS penalty if available
        if let yesterdayTSS = yesterdayTSS, yesterdayTSS > 0 {
            let tssPenalty = calculateTSSPenalty(yesterdayTSS: yesterdayTSS)
            let adjustedScore = Double(baseScore) - tssPenalty
            return max(0, Int(adjustedScore))
        }
        
        return baseScore
    }
    
    /// Calculate TSS penalty for yesterday's training
    /// - Parameter yesterdayTSS: Yesterday's training stress score
    /// - Returns: Penalty to apply (0-30 points)
    public static func calculateTSSPenalty(yesterdayTSS: Double) -> Double {
        switch yesterdayTSS {
        case 0..<50: return 0
        case 50..<100: return 5
        case 100..<150: return 10
        case 150..<200: return 15
        case 200..<250: return 20
        default: return 30
        }
    }
    
    // MARK: - Helper Functions
    
    /// Determine recovery band from score
    /// - Parameter score: Recovery score (0-100)
    /// - Returns: Recovery band
    public static func determineRecoveryBand(score: Int) -> RecoveryBand {
        switch score {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }
}

