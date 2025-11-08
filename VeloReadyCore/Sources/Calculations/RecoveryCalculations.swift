import Foundation

/// Pure calculation logic for recovery scores
/// No dependencies on iOS frameworks or UI
/// Extracted from RecoveryScoreCalculator in iOS app
public struct RecoveryCalculations {
    
    // MARK: - Data Structures
    
    public struct RecoveryInputs {
        public let hrv: Double?
        public let overnightHrv: Double?
        public let hrvBaseline: Double?
        public let rhr: Double?
        public let rhrBaseline: Double?
        public let sleepDuration: Double?
        public let sleepBaseline: Double?
        public let respiratoryRate: Double?
        public let respiratoryBaseline: Double?
        public let atl: Double?
        public let ctl: Double?
        public let recentStrain: Double?
        public let sleepScore: Int?
        
        public init(hrv: Double? = nil, overnightHrv: Double? = nil, hrvBaseline: Double? = nil,
                    rhr: Double? = nil, rhrBaseline: Double? = nil,
                    sleepDuration: Double? = nil, sleepBaseline: Double? = nil,
                    respiratoryRate: Double? = nil, respiratoryBaseline: Double? = nil,
                    atl: Double? = nil, ctl: Double? = nil,
                    recentStrain: Double? = nil, sleepScore: Int? = nil) {
            self.hrv = hrv
            self.overnightHrv = overnightHrv
            self.hrvBaseline = hrvBaseline
            self.rhr = rhr
            self.rhrBaseline = rhrBaseline
            self.sleepDuration = sleepDuration
            self.sleepBaseline = sleepBaseline
            self.respiratoryRate = respiratoryRate
            self.respiratoryBaseline = respiratoryBaseline
            self.atl = atl
            self.ctl = ctl
            self.recentStrain = recentStrain
            self.sleepScore = sleepScore
        }
    }
    
    public struct SubScores {
        public let hrv: Int
        public let rhr: Int
        public let sleep: Int
        public let form: Int
        public let respiratory: Int
        
        public init(hrv: Int, rhr: Int, sleep: Int, form: Int, respiratory: Int) {
            self.hrv = hrv
            self.rhr = rhr
            self.sleep = sleep
            self.form = form
            self.respiratory = respiratory
        }
    }
    
    // MARK: - Main Recovery Score Calculation
    
    /// Calculate recovery score from physiological inputs
    public static func calculateScore(
        inputs: RecoveryInputs,
        hasIllnessIndicator: Bool = false,
        hasSleepData: Bool = true
    ) -> (score: Int, subScores: SubScores) {
        let subScores = calculateSubScores(inputs: inputs)
        
        // Choose weights based on sleep availability
        let hrvFactor: Double
        let rhrFactor: Double
        let sleepFactor: Double
        let respiratoryFactor: Double
        let loadFactor: Double
        
        if hasSleepData {
            // Normal weights (with sleep)
            // HRV 30%, RHR 20%, Sleep 30%, Respiratory 10%, Load 10%
            hrvFactor = Double(subScores.hrv) * 0.30
            rhrFactor = Double(subScores.rhr) * 0.20
            sleepFactor = Double(subScores.sleep) * 0.30
            respiratoryFactor = Double(subScores.respiratory) * 0.10
            loadFactor = Double(subScores.form) * 0.10
        } else {
            // Rebalanced weights (without sleep - redistributed proportionally)
            // HRV 42.8%, RHR 28.6%, Respiratory 14.3%, Load 14.3%
            hrvFactor = Double(subScores.hrv) * 0.428
            rhrFactor = Double(subScores.rhr) * 0.286
            sleepFactor = 0.0 // Sleep excluded
            respiratoryFactor = Double(subScores.respiratory) * 0.143
            loadFactor = Double(subScores.form) * 0.143
        }
        
        var finalScore = hrvFactor + rhrFactor + sleepFactor + respiratoryFactor + loadFactor
        
        // Apply alcohol-specific compound effect detection
        finalScore = applyAlcoholCompoundEffect(
            baseScore: finalScore,
            hrvScore: subScores.hrv,
            rhrScore: subScores.rhr,
            sleepScore: subScores.sleep,
            inputs: inputs,
            hasIllnessIndicator: hasIllnessIndicator
        )
        
        finalScore = max(0, min(100, finalScore))
        
        return (score: Int(finalScore), subScores: subScores)
    }
    
    // MARK: - Sub-Score Calculations
    
    public static func calculateSubScores(inputs: RecoveryInputs) -> SubScores {
        let hrvScore = calculateHRVComponent(hrv: inputs.hrv, baseline: inputs.hrvBaseline)
        let rhrScore = calculateRHRComponent(rhr: inputs.rhr, baseline: inputs.rhrBaseline)
        let sleepScore = calculateSleepComponent(sleepScore: inputs.sleepScore, sleepDuration: inputs.sleepDuration, baseline: inputs.sleepBaseline)
        let respiratoryScore = calculateRespiratoryComponent(respiratory: inputs.respiratoryRate, baseline: inputs.respiratoryBaseline)
        let formScore = calculateFormComponent(atl: inputs.atl, ctl: inputs.ctl, recentStrain: inputs.recentStrain)
        
        return SubScores(
            hrv: hrvScore,
            rhr: rhrScore,
            sleep: sleepScore,
            form: formScore,
            respiratory: respiratoryScore
        )
    }
    
    /// Calculate HRV component of recovery score (0-100)
    public static func calculateHRVComponent(hrv: Double?, baseline: Double?) -> Int {
        guard let hrv = hrv, let baseline = baseline, baseline > 0 else { return 50 }
        
        // Softer HRV scoring - less aggressive penalties
        let percentageChange = (hrv - baseline) / baseline
        
        if percentageChange >= 0 {
            return 100 // At or above baseline = excellent
        } else {
            // Gentler non-linear scaling
            let absChange = abs(percentageChange)
            
            if absChange <= 0.10 {
                // Small drop (0-10%): Minimal penalty
                let score = 100 - (absChange * 150) // Scale 0-10% to 100-85
                return max(85, Int(score))
            } else if absChange <= 0.20 {
                // Moderate drop (10-20%): Moderate penalty
                let score = 85 - ((absChange - 0.10) * 250) // Scale 10-20% to 85-60
                return max(60, Int(score))
            } else if absChange <= 0.35 {
                // Significant drop (20-35%): Larger penalty
                let score = 60 - ((absChange - 0.20) * 200) // Scale 20-35% to 60-30
                return max(30, Int(score))
            } else {
                // Extreme drop (>35%): Maximum penalty
                let score = 30 - ((absChange - 0.35) * 60) // Scale 35%+ to 30-0
                return max(0, Int(score))
            }
        }
    }
    
    /// Calculate RHR component of recovery score (0-100)
    public static func calculateRHRComponent(rhr: Double?, baseline: Double?) -> Int {
        guard let rhr = rhr, let baseline = baseline, baseline > 0 else { return 50 }
        
        // Softer RHR scoring - less aggressive penalties
        let percentageChange = (rhr - baseline) / baseline
        
        if percentageChange <= 0 {
            return 100 // At or below baseline = excellent
        } else {
            // Gentler non-linear scaling
            if percentageChange <= 0.08 {
                // Small increase (0-8%): Minimal penalty
                let score = 100 - (percentageChange * 150) // Scale 0-8% to 100-88
                return max(88, Int(score))
            } else if percentageChange <= 0.15 {
                // Moderate increase (8-15%): Moderate penalty
                let score = 88 - ((percentageChange - 0.08) * 300) // Scale 8-15% to 88-67
                return max(67, Int(score))
            } else if percentageChange <= 0.25 {
                // Significant increase (15-25%): Larger penalty
                let score = 67 - ((percentageChange - 0.15) * 300) // Scale 15-25% to 67-37
                return max(37, Int(score))
            } else {
                // Extreme increase (>25%): Maximum penalty
                let score = 37 - ((percentageChange - 0.25) * 100) // Scale 25%+ to 37-0
                return max(0, Int(score))
            }
        }
    }
    
    /// Calculate sleep component of recovery score (0-100)
    public static func calculateSleepComponent(sleepScore: Int?, sleepDuration: Double?, baseline: Double?) -> Int {
        // Use comprehensive sleep score if available, otherwise fall back to simple duration-based calculation
        if let sleepScore = sleepScore {
            return sleepScore
        } else {
            // Fallback to simple duration-based calculation
            guard let sleep = sleepDuration, let baseline = baseline, baseline > 0 else { return 50 }
            
            // Whoop-like sleep scoring: (Hours slept / baseline) * 100, capped at 100
            let ratio = sleep / baseline
            let score = min(100, ratio * 100)
            return max(0, Int(score))
        }
    }
    
    /// Calculate respiratory component of recovery score (0-100)
    /// Enhanced with directional awareness - elevated RR is stronger illness/stress signal
    public static func calculateRespiratoryComponent(respiratory: Double?, baseline: Double?) -> Int {
        guard let respiratory = respiratory, let baseline = baseline, baseline > 0 else { return 50 }
        
        // Calculate directional change (positive = elevated, negative = suppressed)
        let absoluteChange = respiratory - baseline
        let percentageChange = absoluteChange / baseline
        
        // Elevated RR is stronger signal for illness/overtraining than suppressed RR
        if percentageChange > 0.15 {
            // Elevated >15% - strong illness/stress signal
            let score = 50 - (percentageChange * 200) // Aggressive penalty
            return max(0, Int(score))
        } else if percentageChange > 0.05 {
            // Elevated 5-15% - moderate concern
            let score = 100 - ((percentageChange - 0.05) * 500)
            return max(50, Int(score))
        } else if percentageChange >= -0.05 {
            // Within ±5% - optimal stability
            return 100
        } else if percentageChange >= -0.15 {
            // Suppressed 5-15% - mild concern (could indicate shallow breathing)
            let score = 100 - ((abs(percentageChange) - 0.05) * 300)
            return max(70, Int(score))
        } else {
            // Suppressed >15% - moderate concern
            let score = 70 - ((abs(percentageChange) - 0.15) * 200)
            return max(40, Int(score))
        }
    }
    
    /// Calculate form component of recovery score (0-100)
    public static func calculateFormComponent(atl: Double?, ctl: Double?, recentStrain: Double?) -> Int {
        // Calculate training load factor using ATL/CTL ratio
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
        if let yesterdayTSS = recentStrain, yesterdayTSS > 0 {
            let tssPenalty = calculateTSSPenalty(yesterdayTSS: yesterdayTSS)
            let adjustedScore = Double(baseScore) - tssPenalty
            return max(0, Int(adjustedScore))
        }
        
        return baseScore
    }
    
    /// Calculate TSS penalty for recent strain
    public static func calculateTSSPenalty(yesterdayTSS: Double) -> Double {
        // Apply penalty based on yesterday's TSS
        // High TSS = more fatigue = lower recovery
        if yesterdayTSS < 50 {
            return 0 // No penalty for easy days
        } else if yesterdayTSS < 100 {
            // Linear penalty from 0 at TSS 50 to 10 at TSS 100
            return (yesterdayTSS - 50) * 0.2
        } else if yesterdayTSS < 200 {
            // Linear penalty from 10 at TSS 100 to 25 at TSS 200
            return 10 + ((yesterdayTSS - 100) * 0.15)
        } else {
            // High penalty for very hard days (TSS > 200)
            return min(40, 25 + ((yesterdayTSS - 200) * 0.1))
        }
    }
    
    // MARK: - Alcohol Detection
    
    /// Apply alcohol-specific compound effect detection with multi-signal confidence scoring
    /// Sleep data is OPTIONAL - detection works with HRV/RHR alone
    /// This reduces false positives by requiring multiple confirming signals
    public static func applyAlcoholCompoundEffect(
        baseScore: Double,
        hrvScore: Int,
        rhrScore: Int,
        sleepScore: Int,
        inputs: RecoveryInputs,
        hasIllnessIndicator: Bool
    ) -> Double {
        
        // Skip alcohol detection if illness is detected (same signals as alcohol)
        if hasIllnessIndicator {
            return baseScore
        }
        
        // Use overnight HRV for alcohol detection (more accurate than latest HRV)
        let hrvForAlcoholDetection = inputs.overnightHrv ?? inputs.hrv
        let hrvBaseline = inputs.hrvBaseline
        
        guard let overnightHrv = hrvForAlcoholDetection, let hrvBase = hrvBaseline, hrvBase > 0 else {
            return baseScore
        }
        
        // Calculate HRV suppression
        let hrvChange = ((overnightHrv - hrvBase) / hrvBase) * 100
        
        // Multi-signal confidence scoring (0-100%)
        var alcoholConfidence: Double = 0
        var basePenalty: Double = 0
        
        // Signal 1: HRV suppression (30% max confidence) - INCREASED PENALTIES
        if hrvChange < -35.0 {
            alcoholConfidence += 30.0 // Severe HRV suppression
            basePenalty = 20.0  // Was 12.0
        } else if hrvChange < -30.0 {
            alcoholConfidence += 28.0
            basePenalty = 16.0  // New tier
        } else if hrvChange < -25.0 {
            alcoholConfidence += 25.0
            basePenalty = 12.0  // Was 8.0
        } else if hrvChange < -20.0 {
            alcoholConfidence += 20.0
            basePenalty = 10.0  // Was 5.0
        } else if hrvChange < -15.0 {
            alcoholConfidence += 15.0
            basePenalty = 7.0   // New tier
        } else if hrvChange < -10.0 {
            alcoholConfidence += 10.0
            basePenalty = 4.0   // Was 3.0
        }
        
        // If no HRV suppression, unlikely to be alcohol
        guard alcoholConfidence > 0 else { return baseScore }
        
        // Signal 2: Poor sleep quality (20% confidence) - OPTIONAL
        if let sleepScore = inputs.sleepScore {
            if sleepScore < 40 {
                alcoholConfidence += 20.0 // Very poor sleep
            } else if sleepScore < 60 {
                alcoholConfidence += 10.0 // Moderately poor sleep
            }
            
            // Signal 3: Deep sleep suppression (15% confidence) - OPTIONAL
            if sleepScore < 50 {
                alcoholConfidence += 15.0 // Likely deep sleep suppression
            }
        }
        
        // Signal 4: Elevated RHR (15% confidence) - ALWAYS AVAILABLE
        if rhrScore < 30 {
            alcoholConfidence += 15.0 // Strong RHR elevation
        } else if rhrScore < 50 {
            alcoholConfidence += 10.0 // Moderate RHR elevation
        }
        
        // Signal 5: Normal respiratory rate (15% confidence) - OPTIONAL
        // Alcohol doesn't usually elevate RR, but illness does
        if let respiratory = inputs.respiratoryRate,
           let respBaseline = inputs.respiratoryBaseline,
           respBaseline > 0 {
            let rrChange = (respiratory - respBaseline) / respBaseline
            if abs(rrChange) < 0.10 {
                // RR is stable - more likely alcohol than illness
                alcoholConfidence += 15.0
            } else if rrChange > 0.15 {
                // RR is elevated - more likely illness, reduce confidence
                alcoholConfidence -= 20.0
            }
        }
        
        // Signal 6: Timing/context (10% confidence) - ALWAYS AVAILABLE
        // Weekend = higher likelihood of alcohol
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Sunday or Saturday
            alcoholConfidence += 10.0
        }
        
        // Ensure confidence is bounded [0, 100]
        alcoholConfidence = max(0, min(100, alcoholConfidence))
        
        // Adaptive threshold: lower when sleep data unavailable
        let confidenceThreshold = inputs.sleepScore == nil ? 40.0 : 50.0
        
        guard alcoholConfidence >= confidenceThreshold else {
            // Low confidence - likely not alcohol, could be stress/illness
            return baseScore
        }
        
        // Scale penalty by confidence
        var finalPenalty = basePenalty * (alcoholConfidence / 100.0)
        
        // RHR multiplier: Elevated RHR compounds the penalty
        if rhrScore < 30 {
            finalPenalty *= 1.5  // Strong RHR elevation = 50% worse
        } else if rhrScore < 50 {
            finalPenalty *= 1.25 // Moderate RHR elevation = 25% worse
        }
        
        // Weekend pattern amplifier: High confidence on weekend = likely heavy drinking
        if (weekday == 1 || weekday == 7) && alcoholConfidence > 60 {
            finalPenalty *= 1.2  // Weekend + high confidence = 20% worse
        }
        
        // Sleep quality mitigation: Good sleep reduces alcohol penalty (OPTIONAL)
        // (If you managed good sleep despite drinking, impact is less)
        if let sleepScore = inputs.sleepScore {
            if sleepScore >= 80 {
                // Excellent sleep mitigates by 30%
                finalPenalty *= 0.70
            } else if sleepScore >= 65 {
                // Good sleep mitigates by 15%
                finalPenalty *= 0.85
            }
        }
        
        // Cap maximum penalty at 25 points (was 15)
        finalPenalty = min(finalPenalty, 25.0)
        
        // Apply alcohol penalty to base score
        let adjustedScore = baseScore - finalPenalty
        
        return adjustedScore
    }
}
