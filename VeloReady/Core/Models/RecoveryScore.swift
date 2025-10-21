import Foundation
import SwiftUI

/// Recovery Score calculation and data model
/// Implements the core MVP algorithm for determining daily recovery status
struct RecoveryScore: Codable {
    let score: Int // 0-100
    let band: RecoveryBand
    let subScores: SubScores
    let inputs: RecoveryInputs
    let calculatedAt: Date
    let isPersonalized: Bool // Whether ML was used
    let mlConfidence: Double? // ML confidence (0-1)
    let illnessDetected: Bool // Whether illness indicator is present
    let illnessSeverity: String? // Severity if illness detected
    
    // Default initializer for backward compatibility
    init(score: Int, band: RecoveryBand, subScores: SubScores, inputs: RecoveryInputs, 
         calculatedAt: Date, isPersonalized: Bool = false, mlConfidence: Double? = nil,
         illnessDetected: Bool = false, illnessSeverity: String? = nil) {
        self.score = score
        self.band = band
        self.subScores = subScores
        self.inputs = inputs
        self.calculatedAt = calculatedAt
        self.isPersonalized = isPersonalized
        self.mlConfidence = mlConfidence
        self.illnessDetected = illnessDetected
        self.illnessSeverity = illnessSeverity
    }
    
    // Custom decoder for backward compatibility with cached data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        band = try container.decode(RecoveryBand.self, forKey: .band)
        subScores = try container.decode(SubScores.self, forKey: .subScores)
        inputs = try container.decode(RecoveryInputs.self, forKey: .inputs)
        calculatedAt = try container.decode(Date.self, forKey: .calculatedAt)
        
        // New fields - use defaults if not present (backward compatibility)
        isPersonalized = try container.decodeIfPresent(Bool.self, forKey: .isPersonalized) ?? false
        mlConfidence = try container.decodeIfPresent(Double.self, forKey: .mlConfidence)
        illnessDetected = try container.decodeIfPresent(Bool.self, forKey: .illnessDetected) ?? false
        illnessSeverity = try container.decodeIfPresent(String.self, forKey: .illnessSeverity)
    }
    
    private enum CodingKeys: String, CodingKey {
        case score, band, subScores, inputs, calculatedAt, isPersonalized, mlConfidence, illnessDetected, illnessSeverity
    }
    
    enum RecoveryBand: String, CaseIterable, Codable {
        case optimal = "Optimal"
        case good = "Good"
        case fair = "Fair"
        case payAttention = "Pay Attention"
        
        // Custom decoder to handle legacy cached values
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            
            // Map old values to new cases
            switch rawValue {
            case "Excellent": self = .optimal
            case "Good": self = .good
            case "Fair": self = .fair
            case "Poor": self = .payAttention
            case "Optimal": self = .optimal
            case "Pay Attention": self = .payAttention
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Cannot initialize RecoveryBand from invalid String value \(rawValue)"
                    )
                )
            }
        }
        
        var color: String {
            switch self {
            case .optimal: return "green"
            case .good: return "yellow"
            case .fair: return "orange"
            case .payAttention: return "red"
            }
        }
        
        /// Get the SwiftUI Color token for this recovery band
        var colorToken: Color {
            switch self {
            case .optimal: return ColorScale.greenAccent
            case .good: return ColorScale.yellowAccent
            case .fair: return ColorScale.amberAccent
            case .payAttention: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .optimal: return RecoveryContent.Bands.optimal
            case .good: return RecoveryContent.Bands.good
            case .fair: return RecoveryContent.Bands.fair
            case .payAttention: return RecoveryContent.Bands.payAttention
            }
        }
    }
    
    struct SubScores: Codable {
        let hrv: Int // 0-100
        let rhr: Int // 0-100
        let sleep: Int // 0-100
        let form: Int // 0-100 (TSB-based)
        let respiratory: Int // 0-100 (respiratory rate stability)
    }
    
    struct RecoveryInputs: Codable {
        let hrv: Double? // ms (RMSSD from Apple Watch)
        let overnightHrv: Double? // ms (overnight HRV for alcohol detection)
        let hrvBaseline: Double? // 7-day rolling average
        let rhr: Double? // bpm (overnight/morning)
        let rhrBaseline: Double? // 7-day rolling average
        let sleepDuration: Double? // seconds (total sleep time)
        let sleepBaseline: Double? // 7-day rolling average
        let respiratoryRate: Double? // breaths per minute
        let respiratoryBaseline: Double? // 7-day rolling average
        let atl: Double? // Acute Training Load (7-day)
        let ctl: Double? // Chronic Training Load (42-day)
        let recentStrain: Double? // Recent training strain
        let sleepScore: SleepScore? // Comprehensive sleep score
    }
}

// MARK: - Recovery Score Calculator

class RecoveryScoreCalculator {
    
    /// Calculate recovery score from inputs using ML or rule-based algorithm (async version)
    static func calculate(inputs: RecoveryScore.RecoveryInputs) async -> RecoveryScore {
        // Try ML prediction first if available
        if let mlScore = await tryMLPrediction(inputs: inputs) {
            return mlScore
        }
        
        // Fall back to rule-based calculation
        return calculateRuleBased(inputs: inputs)
    }
    
    /// Calculate recovery score synchronously (for previews/testing - always uses rule-based)
    static func calculate(inputs: RecoveryScore.RecoveryInputs) -> RecoveryScore {
        return calculateRuleBased(inputs: inputs)
    }
    
    /// Try ML prediction (returns nil if ML not available)
    private static func tryMLPrediction(inputs: RecoveryScore.RecoveryInputs) async -> RecoveryScore? {
        // Check if ML is enabled
        let mlRegistry = await MLModelRegistry.shared
        guard await mlRegistry.isMLEnabled else {
            return nil
        }
        
        // Convert inputs to feature vector
        guard let features = convertInputsToFeatures(inputs: inputs) else {
            Logger.warning("⚠️ [RecoveryScore] Could not convert inputs to features for ML")
            return nil
        }
        
        // Get ML prediction
        let calculator = await PersonalizedRecoveryCalculator.shared
        let result = await calculator.calculateRecoveryScore(features: features)
        
        // Check if ML was actually used
        guard result.method == .machineLearning else {
            return nil // ML not available, will use rule-based
        }
        
        // Create RecoveryScore from ML prediction
        let subScores = calculateSubScores(inputs: inputs) // Still calculate sub-scores for display
        let band = determineBand(score: result.score)
        
        Logger.info("🤖 [RecoveryScore] Using ML prediction: \(Int(result.score)) (confidence: \(Int(result.confidence * 100))%)")
        
        return RecoveryScore(
            score: Int(result.score),
            band: band,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date(),
            isPersonalized: true,
            mlConfidence: result.confidence
        )
    }
    
    /// Convert RecoveryInputs to MLFeatureVector
    private static func convertInputsToFeatures(inputs: RecoveryScore.RecoveryInputs) -> MLFeatureVector? {
        // This is a simplified conversion - in production, you'd use FeatureEngineer
        // For now, just check if we have minimum required features
        guard inputs.hrv != nil || inputs.rhr != nil || inputs.sleepDuration != nil else {
            return nil
        }
        
        // Create feature vector with available data
        return MLFeatureVector(
            hrv: inputs.hrv,
            hrvBaseline: inputs.hrvBaseline,
            hrvDelta: inputs.hrv.flatMap { hrv in
                inputs.hrvBaseline.map { baseline in
                    baseline > 0 ? (hrv - baseline) / baseline : 0
                }
            },
            hrvCoefficientOfVariation: nil,
            rhr: inputs.rhr,
            rhrBaseline: inputs.rhrBaseline,
            rhrDelta: inputs.rhr.flatMap { rhr in
                inputs.rhrBaseline.map { baseline in
                    baseline > 0 ? (rhr - baseline) / baseline : 0
                }
            },
            sleepDuration: inputs.sleepDuration,
            sleepBaseline: inputs.sleepBaseline,
            sleepDelta: inputs.sleepDuration.flatMap { duration in
                inputs.sleepBaseline.map { baseline in
                    baseline > 0 ? duration - baseline : 0
                }
            },
            respiratoryRate: inputs.respiratoryRate,
            yesterdayStrain: inputs.recentStrain,
            yesterdayTSS: nil,
            ctl: inputs.ctl,
            atl: inputs.atl,
            tsb: inputs.ctl.flatMap { ctl in inputs.atl.map { atl in ctl - atl } },
            acuteChronicRatio: inputs.atl.flatMap { atl in
                inputs.ctl.map { ctl in ctl > 0 ? atl / ctl : 0 }
            },
            trainingMonotony: nil,
            trainingStrain: nil,
            recoveryTrend7d: nil,
            recoveryTrend3d: nil,
            yesterdayRecovery: nil,
            recoveryChange: nil,
            sleepTrend7d: nil,
            sleepDebt7d: nil,
            sleepQualityScore: inputs.sleepScore.map { Double($0.score) },
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            daysSinceHardWorkout: nil,
            trainingBlockDay: nil,
            alcoholDetected: nil,
            illnessMarker: nil,
            monthOfYear: Calendar.current.component(.month, from: Date()),
            timestamp: Date()
        )
    }
    
    /// Calculate recovery score using rule-based algorithm (original method)
    static func calculateRuleBased(inputs: RecoveryScore.RecoveryInputs) -> RecoveryScore {
        let subScores = calculateSubScores(inputs: inputs)
        
        // Reweighted formula to increase sleep importance (better for alcohol detection):
        // HRV 30%, RHR 20%, Sleep 30%, Respiratory 10%, Load 10%
        let hrvFactor = Double(subScores.hrv) * 0.30
        let rhrFactor = Double(subScores.rhr) * 0.20
        let sleepFactor = Double(subScores.sleep) * 0.30
        let respiratoryFactor = Double(subScores.respiratory) * 0.10
        let loadFactor = Double(subScores.form) * 0.10
        
        var finalScore = hrvFactor + rhrFactor + sleepFactor + respiratoryFactor + loadFactor
        
        Logger.debug("🏥 RECOVERY SCORE CALCULATION (NEW WEIGHTS):")
        Logger.debug("   Sub-scores: HRV=\(subScores.hrv), RHR=\(subScores.rhr), Sleep=\(subScores.sleep), Resp=\(subScores.respiratory), Load=\(subScores.form)")
        Logger.debug("   Weighted:   HRV=\(String(format: "%.1f", hrvFactor)) (30%), RHR=\(String(format: "%.1f", rhrFactor)) (20%), Sleep=\(String(format: "%.1f", sleepFactor)) (30%), Resp=\(String(format: "%.1f", respiratoryFactor)) (10%), Load=\(String(format: "%.1f", loadFactor)) (10%)")
        Logger.debug("   Base Score: \(String(format: "%.1f", finalScore)) (before alcohol detection)")
        
        // Apply alcohol-specific compound effect detection
        finalScore = applyAlcoholCompoundEffect(
            baseScore: finalScore,
            hrvScore: subScores.hrv,
            rhrScore: subScores.rhr,
            sleepScore: subScores.sleep,
            inputs: inputs
        )
        
        finalScore = max(0, min(100, finalScore))
        let band = determineBand(score: finalScore)
        
        // Check for illness indicator
        let illnessDetected = IllnessDetectionService.shared.currentIndicator != nil
        let illnessSeverity = IllnessDetectionService.shared.currentIndicator?.severity.rawValue
        
        if illnessDetected {
            Logger.debug("   ⚠️ Illness detected: \(illnessSeverity ?? "unknown") - Score should be interpreted cautiously")
        }
        
        Logger.debug("   Final Score: \(Int(finalScore)) (\(band.rawValue.uppercased())) after alcohol detection")
        
        return RecoveryScore(
            score: Int(finalScore),
            band: band,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date(),
            illnessDetected: illnessDetected,
            illnessSeverity: illnessSeverity
        )
    }
    
    // MARK: - Sub-Score Calculations
    
    private static func calculateSubScores(inputs: RecoveryScore.RecoveryInputs) -> RecoveryScore.SubScores {
        let hrvScore = calculateHRVScore(hrv: inputs.hrv, baseline: inputs.hrvBaseline)
        let rhrScore = calculateRHRScore(rhr: inputs.rhr, baseline: inputs.rhrBaseline)
        let sleepScore = calculateSleepScore(inputs: inputs)
        let respiratoryScore = calculateRespiratoryScore(respiratory: inputs.respiratoryRate, baseline: inputs.respiratoryBaseline)
        let formScore = calculateFormScore(inputs: inputs)
        
        return RecoveryScore.SubScores(
            hrv: hrvScore,
            rhr: rhrScore,
            sleep: sleepScore,
            form: formScore,
            respiratory: respiratoryScore
        )
    }
    
    private static func calculateHRVScore(hrv: Double?, baseline: Double?) -> Int {
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
    
    private static func calculateRHRScore(rhr: Double?, baseline: Double?) -> Int {
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
    
    private static func calculateSleepScore(inputs: RecoveryScore.RecoveryInputs) -> Int {
        // Use comprehensive sleep score if available, otherwise fall back to simple duration-based calculation
        if let sleepScore = inputs.sleepScore {
            // Use the comprehensive sleep score directly
            return sleepScore.score
        } else {
            // Fallback to simple duration-based calculation
            guard let sleep = inputs.sleepDuration, let baseline = inputs.sleepBaseline, baseline > 0 else { return 50 }
            
            // Whoop-like sleep scoring: (Hours slept / baseline) * 100, capped at 100
            let ratio = sleep / baseline
            let score = min(100, ratio * 100)
            return max(0, Int(score))
        }
    }
    
    private static func calculateRespiratoryScore(respiratory: Double?, baseline: Double?) -> Int {
        guard let respiratory = respiratory, let baseline = baseline, baseline > 0 else { return 50 }
        
        // Respiratory rate stability scoring: stable = good, high variability = poor
        let percentageChange = abs(respiratory - baseline) / baseline
        
        // Score based on stability: 100 if within 5% of baseline, drops with variability
        if percentageChange <= 0.05 {
            return 100 // Very stable
        } else if percentageChange <= 0.15 {
            // Linear scale from 100 at 5% to 50 at 15%
            let score = 100 - ((percentageChange - 0.05) * 500) // Scale 5%-15% to 100-50
            return max(50, Int(score))
        } else {
            // High variability = poor recovery
            let score = 50 - ((percentageChange - 0.15) * 100) // Further penalty beyond 15%
            return max(0, Int(score))
        }
    }
    
    private static func calculateFormScore(inputs: RecoveryScore.RecoveryInputs) -> Int {
        // Calculate training load factor using ATL/CTL ratio
        guard let atl = inputs.atl, let ctl = inputs.ctl, ctl > 0 else { return 50 }
        
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
        if let yesterdayTSS = inputs.recentStrain, yesterdayTSS > 0 {
            let tssPenalty = calculateTSSPenalty(yesterdayTSS: yesterdayTSS)
            let adjustedScore = Double(baseScore) - tssPenalty
            return max(0, Int(adjustedScore))
        }
        
        return baseScore
    }
    
    // MARK: - Base Score Calculation
    
    private static func calculateBaseScore(subScores: RecoveryScore.SubScores) -> Double {
        // Weighted average: HRV 40%, RHR 30%, Sleep 30%
        let weightedScore = (Double(subScores.hrv) * 0.4) + 
                           (Double(subScores.rhr) * 0.3) + 
                           (Double(subScores.sleep) * 0.3)
        return weightedScore
    }
    
    // MARK: - Form Weight Calculation
    
    private static func calculateFormWeight(tsb: Double?) -> Double {
        guard let tsb = tsb else { return 0 } // No form adjustment if no data
        
        // Map TSB to form multiplier: -30 to +30 → 0.6 to 1.4
        let clampedTSB = max(-30, min(30, tsb))
        let normalizedTSB = (clampedTSB + 30) / 60 // 0 to 1
        let formMultiplier = 0.6 + (normalizedTSB * 0.8) // 0.6 to 1.4
        
        // Convert multiplier to score adjustment (-20 to +20)
        return (formMultiplier - 1.0) * 20
    }
    
    // MARK: - TSS Penalty Calculation
    
    private static func calculateTSSPenalty(yesterdayTSS: Double) -> Double {
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
    
    // MARK: - Alcohol Detection & Compound Effects
    
    /// Apply alcohol-specific compound effect detection (Whoop-like)
    private static func applyAlcoholCompoundEffect(
        baseScore: Double,
        hrvScore: Int,
        rhrScore: Int,
        sleepScore: Int,
        inputs: RecoveryScore.RecoveryInputs
    ) -> Double {
        
        // Skip alcohol detection if sleep data is missing (unreliable)
        guard inputs.sleepScore != nil else {
            Logger.debug("🍷 Skipping alcohol detection - no sleep data available (unreliable without sleep)")
            return baseScore
        }
        
        // Use overnight HRV for alcohol detection (more accurate than latest HRV)
        let hrvForAlcoholDetection = inputs.overnightHrv ?? inputs.hrv
        let hrvBaseline = inputs.hrvBaseline
        
        // Detect alcohol patterns based on HRV and RHR combination
        _ = 100 - hrvScore // HRV penalty for future detailed analysis
        _ = 100 - rhrScore // RHR penalty for future detailed analysis
        _ = 100 - sleepScore // Sleep penalty for future detailed analysis
        
        // Alcohol detection thresholds (balanced for moderate consumption)
        let alcoholHRVThreshold = 40 // HRV score < 60 indicates potential alcohol
        let alcoholRHRThreshold = 30  // RHR score < 70 indicates potential alcohol
        let alcoholSleepThreshold = 40 // Sleep score < 60 indicates potential alcohol
        
        var alcoholPenalty: Double = 0
        
        // Calculate overnight HRV change for alcohol detection
        if let overnightHrv = hrvForAlcoholDetection, let hrvBase = hrvBaseline, hrvBase > 0 {
            let hrvChange = ((overnightHrv - hrvBase) / hrvBase) * 100
            Logger.debug("🍷 Alcohol Detection - Overnight HRV Change: \(String(format: "%.1f", hrvChange))%")
            
            // Determine alcohol severity based on HRV drop magnitude
            let alcoholSeverity: String
            if abs(hrvChange) > 40 {
                alcoholSeverity = "heavy" // >40% drop = heavy drinking
            } else if abs(hrvChange) > 30 {
                alcoholSeverity = "moderate-heavy" // 30-40% drop = 4-5+ drinks
            } else if abs(hrvChange) > 20 {
                alcoholSeverity = "moderate" // 20-30% drop = 2-3 drinks
            } else {
                alcoholSeverity = "light" // <20% drop = 1-2 drinks or none
            }
            
            Logger.debug("🍷 Alcohol Severity Assessment: \(alcoholSeverity) (HRV drop: \(String(format: "%.1f", abs(hrvChange)))%)")
            
            // Primary alcohol detection: HRV-based with graduated penalties
            if hrvChange < -35.0 {
                // Heavy drinking (>35% HRV drop)
                alcoholPenalty = 12.0
                Logger.debug("🍷 Heavy alcohol detected (>\(String(format: "%.0f", abs(hrvChange)))% HRV drop) - applying 12pt penalty")
            } else if hrvChange < -25.0 {
                // Moderate-heavy drinking (25-35% HRV drop)
                alcoholPenalty = 8.0
                Logger.debug("🍷 Moderate-heavy alcohol detected (\(String(format: "%.0f", abs(hrvChange)))% HRV drop) - applying 8pt penalty")
            } else if hrvChange < -20.0 {
                // Moderate drinking (20-25% HRV drop) - e.g., 2-3 glasses of wine
                alcoholPenalty = 5.0
                Logger.debug("🍷 Moderate alcohol detected (\(String(format: "%.0f", abs(hrvChange)))% HRV drop) - applying 5pt penalty")
            } else if hrvScore < alcoholHRVThreshold {
                // Light impact or natural HRV variation
                alcoholPenalty = 3.0
                Logger.debug("🍷 Light alcohol impact detected - applying 3pt penalty")
            }
            
            // Sleep quality mitigation: Good sleep reduces alcohol penalty
            if sleepScore >= 80 && alcoholPenalty > 0 {
                // Excellent sleep (80+) mitigates alcohol impact by 30%
                let sleepMitigation = alcoholPenalty * 0.30
                alcoholPenalty -= sleepMitigation
                Logger.debug("🍷 Sleep quality mitigation: Excellent sleep (\(sleepScore)/100) reduces penalty by \(String(format: "%.1f", sleepMitigation))pts")
            } else if sleepScore >= 65 && alcoholPenalty > 0 {
                // Good sleep (65-79) mitigates alcohol impact by 15%
                let sleepMitigation = alcoholPenalty * 0.15
                alcoholPenalty -= sleepMitigation
                Logger.debug("🍷 Sleep quality mitigation: Good sleep (\(sleepScore)/100) reduces penalty by \(String(format: "%.1f", sleepMitigation))pts")
            } else if sleepScore < alcoholSleepThreshold && alcoholPenalty > 0 {
                // Poor sleep + alcohol = compound effect (worse recovery)
                alcoholPenalty += 3.0
                Logger.debug("🍷 Alcohol + poor sleep compound effect - applying additional 3pt penalty")
            }
            
            // RHR confirmation: If RHR is also elevated, increase penalty slightly
            if rhrScore < alcoholRHRThreshold && alcoholPenalty > 0 {
                alcoholPenalty += 2.0
                Logger.debug("🍷 RHR elevation confirms alcohol impact - applying additional 2pt penalty")
            }
            
            // Cap maximum alcohol penalty at 15 points (reasonable for moderate consumption)
            alcoholPenalty = min(alcoholPenalty, 15.0)
        }
        
        // Apply alcohol penalty to base score
        let adjustedScore = baseScore - alcoholPenalty
        
        // Log alcohol detection for debugging
        if alcoholPenalty > 0 {
            Logger.debug("🍷 ========================================")
            Logger.debug("🍷 ALCOHOL COMPOUND EFFECT APPLIED:")
            Logger.debug("🍷   Base Score: \(String(format: "%.1f", baseScore))")
            Logger.debug("🍷   Alcohol Penalty: -\(String(format: "%.1f", alcoholPenalty)) points")
            Logger.debug("🍷   Adjusted Score: \(String(format: "%.1f", adjustedScore))")
            Logger.debug("🍷 ========================================")
        } else {
            Logger.debug("🍷 No alcohol detected - recovery score unchanged")
        }
        
        return adjustedScore
    }
    
    // MARK: - Helper Functions
    
    private static func scoreFromPercentageChange(_ change: Double, positiveIsGood: Bool) -> Int {
        let adjustedChange = positiveIsGood ? change : -change
        let score = 50 + (adjustedChange * 100) // 50% change = 100 points
        return max(0, min(100, Int(score)))
    }
    
    private static func determineBand(score: Double) -> RecoveryScore.RecoveryBand {
        switch score {
        case 80...100: return .optimal      // Optimal recovery - fully recovered
        case 60..<80: return .good          // Good recovery, ready to train
        case 40..<60: return .fair          // Fair recovery, moderate training
        default: return .payAttention       // Pay attention - low recovery, rest/easy day
        }
    }
}

// MARK: - Recovery Score Extensions

extension RecoveryScore {
    /// Generate AI daily brief based on recovery score and inputs
    var dailyBrief: String {
        switch band {
        case .optimal:
            return generateOptimalBrief()
        case .good:
            return generateGoodBrief()
        case .fair:
            return generateFairBrief()
        case .payAttention:
            return generatePayAttentionBrief()
        }
    }
    
    private func generateOptimalBrief() -> String {
        var brief = "Recovery is optimal"
        
        // Add specific improvements
        if let hrv = inputs.hrv, let baseline = inputs.hrvBaseline, baseline > 0 {
            let change = ((hrv - baseline) / baseline) * 100
            if change > 5 {
                brief += " — HRV +\(Int(change))%"
            }
        }
        
        if let rhr = inputs.rhr, let baseline = inputs.rhrBaseline, baseline > 0 {
            let change = ((rhr - baseline) / baseline) * 100
            if change < -2 {
                brief += ", RHR \(Int(change)) bpm"
            }
        }
        
        // Add sleep score information
        if let sleepScore = inputs.sleepScore {
            brief += " — Sleep \(sleepScore.score)/100"
            if sleepScore.score >= 80 {
                brief += " (excellent)"
            } else if sleepScore.score >= 60 {
                brief += " (good)"
            }
        }
        
        brief += ". Aim for Endurance/Tempo today."
        return brief
    }
    
    private func generateGoodBrief() -> String {
        var brief = "Recovery is good"
        
        // Add sleep score information if available
        if let sleepScore = inputs.sleepScore {
            brief += " — Sleep \(sleepScore.score)/100"
        }
        
        brief += ". Ready for normal training."
        return brief
    }
    
    private func generateFairBrief() -> String {
        var brief = "Mixed signals — take it steady"
        
        // Add sleep score information if available
        if let sleepScore = inputs.sleepScore {
            if sleepScore.score < 60 {
                brief += ". Poor sleep quality (\(sleepScore.score)/100)"
            } else if sleepScore.score < 80 {
                brief += ". Fair sleep quality (\(sleepScore.score)/100)"
            }
        }
        
        brief += ". Keep effort 50–70 TSS."
        return brief
    }
    
    private func generatePayAttentionBrief() -> String {
        var brief = "Recovery needs attention"
        
        // Add sleep score information if available
        if let sleepScore = inputs.sleepScore {
            if sleepScore.score < 40 {
                brief += " — very poor sleep (\(sleepScore.score)/100)"
            } else if sleepScore.score < 60 {
                brief += " — poor sleep quality (\(sleepScore.score)/100)"
            }
        }
        
        brief += ". Short spin or rest recommended."
        return brief
    }
}
