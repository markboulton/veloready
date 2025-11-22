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
    ///
    /// REDESIGNED based on real-world data:
    /// - User had 1/2 bottle wine + 4 cocktails (~8 standard drinks)
    /// - HRV: 26.95ms vs 30.89ms baseline = -12.7%
    /// - RHR: 66 bpm vs 64.5 bpm baseline = +2.3%
    /// - Old algorithm gave 89 recovery (too high)
    /// - Expected recovery: 60-70 range
    ///
    /// Key changes:
    /// 1. Lower HRV thresholds - moderate suppression (10-15%) is significant
    /// 2. RHR percentage-based detection (not score-based)
    /// 3. Compound HRV+RHR signal - both changing together is strong indicator
    /// 4. Lower confidence threshold (30% vs 40-50%)
    /// 5. Higher penalties for confirmed cases
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

        // Use the LOWER of overnight HRV or latest HRV for alcohol detection
        // This catches cases where overnight HRV recovered but morning HRV is still suppressed
        // (User reported: overnight=32.43ms vs baseline 30.89ms = +5%, but latest=27.85ms = -9.8%)
        let hrvBaseline = inputs.hrvBaseline
        guard let hrvBase = hrvBaseline, hrvBase > 0 else {
            return baseScore
        }

        // Calculate both HRV changes
        let overnightHrvChange: Double? = inputs.overnightHrv.map { ((($0 - hrvBase) / hrvBase) * 100) }
        let latestHrvChange: Double? = inputs.hrv.map { ((($0 - hrvBase) / hrvBase) * 100) }

        // Use the MORE SUPPRESSED value (lower percentage = more suppressed)
        let hrvChange: Double
        if let overnight = overnightHrvChange, let latest = latestHrvChange {
            hrvChange = min(overnight, latest) // Use the worse (more negative) value
        } else if let overnight = overnightHrvChange {
            hrvChange = overnight
        } else if let latest = latestHrvChange {
            hrvChange = latest
        } else {
            return baseScore // No HRV data available
        }

        // Calculate RHR elevation (percentage) - NEW: percentage-based, not score-based
        var rhrChange: Double = 0
        if let rhr = inputs.rhr, let rhrBase = inputs.rhrBaseline, rhrBase > 0 {
            rhrChange = ((rhr - rhrBase) / rhrBase) * 100
        }

        // Multi-signal confidence scoring (0-100%)
        var alcoholConfidence: Double = 0
        var basePenalty: Double = 0

        // Signal 1: HRV suppression (40% max confidence) - RECALIBRATED THRESHOLDS
        // Base penalties are DIRECT impact on recovery score (not scaled down)
        // Thresholds shifted: -9.8% should be "significant" not "moderate"
        if hrvChange < -35.0 {
            alcoholConfidence += 40.0 // Extreme HRV suppression
            basePenalty = 35.0
        } else if hrvChange < -30.0 {
            alcoholConfidence += 38.0
            basePenalty = 30.0
        } else if hrvChange < -25.0 {
            alcoholConfidence += 35.0
            basePenalty = 27.0
        } else if hrvChange < -20.0 {
            alcoholConfidence += 32.0
            basePenalty = 24.0
        } else if hrvChange < -15.0 {
            alcoholConfidence += 30.0
            basePenalty = 20.0
        } else if hrvChange < -12.0 {
            // Heavy drinking range (12-15%)
            alcoholConfidence += 28.0
            basePenalty = 18.0
        } else if hrvChange < -9.0 {
            // Significant drinking (9-12% range) - user's -9.8% falls here
            // 8 drinks should result in 20-25pt penalty after amplifiers
            alcoholConfidence += 25.0
            basePenalty = 16.0
        } else if hrvChange < -6.0 {
            // Moderate drinking (6-9%)
            alcoholConfidence += 20.0
            basePenalty = 12.0
        } else if hrvChange < -4.0 {
            // Light-moderate drinking (4-6%)
            alcoholConfidence += 15.0
            basePenalty = 8.0
        } else if hrvChange < -2.0 {
            // Light drinking (2-4%)
            alcoholConfidence += 10.0
            basePenalty = 5.0
        }

        // If no HRV suppression at all, unlikely to be alcohol
        guard alcoholConfidence > 0 else { return baseScore }

        // Signal 2: RHR elevation - PERCENTAGE BASED (25% max confidence)
        // +2.3% RHR elevation is meaningful, old algorithm missed it entirely
        if rhrChange > 15.0 {
            alcoholConfidence += 25.0 // Strong RHR elevation
        } else if rhrChange > 10.0 {
            alcoholConfidence += 20.0
        } else if rhrChange > 5.0 {
            alcoholConfidence += 15.0
        } else if rhrChange > 2.0 {
            // +2% to +5% range (user's +2.3% falls here)
            alcoholConfidence += 10.0  // NEW: was 0% before!
        } else if rhrChange > 0.0 {
            alcoholConfidence += 5.0   // Any elevation is signal
        }

        // Signal 3: COMPOUND EFFECT - HRV down + RHR up together (25% max confidence)
        // This is the KEY differentiator - alcohol causes BOTH simultaneously
        // User's -12.7% HRV + 2.3% RHR is a STRONG compound signal
        if hrvChange < -5.0 && rhrChange > 0.0 {
            // Both signals present - strong alcohol indicator
            // Compound score = HRV drop magnitude + (RHR rise * 5)
            let compoundScore = abs(hrvChange) + (rhrChange * 5)
            if compoundScore > 30.0 {
                alcoholConfidence += 25.0 // Strong compound effect
            } else if compoundScore > 20.0 {
                // User's -12.7 + (2.3 * 5) = 12.7 + 11.5 = 24.2 → falls here
                alcoholConfidence += 20.0 // Moderate-strong compound effect
            } else if compoundScore > 12.0 {
                alcoholConfidence += 15.0 // Moderate compound effect
            } else if compoundScore > 6.0 {
                alcoholConfidence += 10.0 // Mild compound effect
            }
        }

        // Signal 4: Poor sleep quality (15% confidence) - OPTIONAL
        if let sleepScore = inputs.sleepScore {
            if sleepScore < 40 {
                alcoholConfidence += 15.0 // Very poor sleep
            } else if sleepScore < 55 {
                alcoholConfidence += 10.0 // Moderately poor sleep
            } else if sleepScore < 70 {
                alcoholConfidence += 5.0  // Below average sleep
            }
        }

        // Signal 5: Normal respiratory rate (10% confidence) - OPTIONAL
        // Alcohol doesn't usually elevate RR, but illness does
        if let respiratory = inputs.respiratoryRate,
           let respBaseline = inputs.respiratoryBaseline,
           respBaseline > 0 {
            let rrChange = (respiratory - respBaseline) / respBaseline
            if abs(rrChange) < 0.10 {
                // RR is stable - more likely alcohol than illness
                alcoholConfidence += 10.0
            } else if rrChange > 0.15 {
                // RR is elevated - more likely illness, reduce confidence
                alcoholConfidence -= 15.0
            }
        }

        // Signal 6: Timing/context (10% confidence) - ALWAYS AVAILABLE
        // Weekend/Friday = higher likelihood of alcohol
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 || weekday == 6 { // Sun, Sat, or Fri
            alcoholConfidence += 10.0
        }

        // Ensure confidence is bounded [0, 100]
        alcoholConfidence = max(0, min(100, alcoholConfidence))

        // LOWER confidence threshold (was 40-50%, now 30-35%)
        let confidenceThreshold = inputs.sleepScore == nil ? 30.0 : 35.0

        guard alcoholConfidence >= confidenceThreshold else {
            // Low confidence - likely not alcohol, could be stress/illness
            return baseScore
        }

        // Scale penalty by confidence - but keep it meaningful
        // At 55% confidence (user's case), we want most of the base penalty applied
        // Formula: penalty = basePenalty * (0.5 + confidence/200)
        // At 35% confidence: 0.5 + 0.175 = 0.675 (67.5% of base penalty)
        // At 55% confidence: 0.5 + 0.275 = 0.775 (77.5% of base penalty)
        // At 80% confidence: 0.5 + 0.4 = 0.9 (90% of base penalty)
        let confidenceMultiplier = 0.5 + (alcoholConfidence / 200.0)
        var finalPenalty = basePenalty * confidenceMultiplier

        // Compound effect amplifier: Both HRV down + RHR up = more severe
        // User's -12.7% HRV + 2.3% RHR → amplifier = 1.0 + 0.127 + 0.046 = 1.173
        if hrvChange < -7.0 && rhrChange > 1.0 {
            let amplifier = 1.0 + (min(abs(hrvChange), 25.0) * 0.01) + (min(rhrChange, 15.0) * 0.02)
            finalPenalty *= amplifier
        }

        // Weekend/Friday pattern amplifier
        if (weekday == 1 || weekday == 7 || weekday == 6) && alcoholConfidence > 45 {
            finalPenalty *= 1.15  // Weekend + moderate confidence = 15% worse
        }

        // NOTE: Sleep score mitigation REMOVED
        // Sleep score now has HRV-based quality adjustment (SleepCalculations.applyHRVQualityAdjustment)
        // but only uses overnight HRV, while recovery uses min(overnight, latest) HRV
        // Keep sleep mitigation disabled for now to avoid complexity; may revisit if scoring feels too harsh

        // Cap maximum penalty at 35 points
        finalPenalty = min(finalPenalty, 35.0)

        // Apply alcohol penalty to base score
        let adjustedScore = baseScore - finalPenalty

        return adjustedScore
    }
}
