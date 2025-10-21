import Foundation
import HealthKit
import SwiftUI

/// Sleep Score calculation and data model
/// Implements a Whoop-like sleep scoring algorithm using Apple Health data
struct SleepScore: Codable {
    let score: Int // 0-100
    let band: SleepBand
    let subScores: SubScores
    let inputs: SleepInputs
    let calculatedAt: Date
    let illnessDetected: Bool // Whether illness indicator is present
    let illnessSeverity: String? // Severity if illness detected
    
    // Default initializer
    init(score: Int, band: SleepBand, subScores: SubScores, inputs: SleepInputs, 
         calculatedAt: Date, illnessDetected: Bool = false, illnessSeverity: String? = nil) {
        self.score = score
        self.band = band
        self.subScores = subScores
        self.inputs = inputs
        self.calculatedAt = calculatedAt
        self.illnessDetected = illnessDetected
        self.illnessSeverity = illnessSeverity
    }
    
    // Custom decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        band = try container.decode(SleepBand.self, forKey: .band)
        subScores = try container.decode(SubScores.self, forKey: .subScores)
        inputs = try container.decode(SleepInputs.self, forKey: .inputs)
        calculatedAt = try container.decode(Date.self, forKey: .calculatedAt)
        illnessDetected = try container.decodeIfPresent(Bool.self, forKey: .illnessDetected) ?? false
        illnessSeverity = try container.decodeIfPresent(String.self, forKey: .illnessSeverity)
    }
    
    private enum CodingKeys: String, CodingKey {
        case score, band, subScores, inputs, calculatedAt, illnessDetected, illnessSeverity
    }
    
    enum SleepBand: String, CaseIterable, Codable {
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
                        debugDescription: "Cannot initialize SleepBand from invalid String value \(rawValue)"
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
        
        /// Get the SwiftUI Color token for this sleep band
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
            case .optimal: return SleepContent.Bands.optimal
            case .good: return SleepContent.Bands.good
            case .fair: return SleepContent.Bands.fair
            case .payAttention: return SleepContent.Bands.payAttention
            }
        }
    }
    
    struct SubScores: Codable {
        let performance: Int // 0-100 (actual sleep / sleep need)
        let efficiency: Int // 0-100 (time asleep / time in bed)
        let stageQuality: Int // 0-100 (deep + REM percentage)
        let disturbances: Int // 0-100 (fewer disturbances = higher score)
        let timing: Int // 0-100 (consistency of bedtime/wake time)
    }
    
    struct SleepInputs: Codable {
        let sleepDuration: Double? // seconds (total sleep time)
        let timeInBed: Double? // seconds (total time in bed)
        let sleepNeed: Double? // seconds (calculated sleep need)
        let deepSleepDuration: Double? // seconds
        let remSleepDuration: Double? // seconds
        let coreSleepDuration: Double? // seconds
        let awakeDuration: Double? // seconds
        let wakeEvents: Int? // number of wake events
        let bedtime: Date? // bedtime
        let wakeTime: Date? // wake time
        let baselineBedtime: Date? // 7-day average bedtime
        let baselineWakeTime: Date? // 7-day average wake time
        let hrvOvernight: Double? // average HRV during sleep
        let hrvBaseline: Double? // 7-day average HRV
        let sleepLatency: Double? // seconds (time from in bed to first sleep)
    }
}

// MARK: - Sleep Score Calculator

class SleepScoreCalculator {
    
    /// Calculate sleep score from inputs using Whoop-like algorithm
    static func calculate(inputs: SleepScore.SleepInputs) -> SleepScore {
        let subScores = calculateSubScores(inputs: inputs)
        
        // Reweighted formula to prioritize quality over duration and timing:
        // Performance 30%, Stage Quality 32%, Efficiency 22%, Disturbances 14%, Timing 2%
        // Timing reduced to 2% as it's less critical than sleep quality metrics
        let performanceFactor = Double(subScores.performance) * 0.30
        let efficiencyFactor = Double(subScores.efficiency) * 0.22
        let stageQualityFactor = Double(subScores.stageQuality) * 0.32
        let disturbancesFactor = Double(subScores.disturbances) * 0.14
        let timingFactor = Double(subScores.timing) * 0.02
        
        let finalScore = max(0, min(100, performanceFactor + efficiencyFactor + stageQualityFactor + disturbancesFactor + timingFactor))
        let band = determineBand(score: finalScore)
        
        // Check for illness indicator
        let illnessDetected = IllnessDetectionService.shared.currentIndicator != nil
        let illnessSeverity = IllnessDetectionService.shared.currentIndicator?.severity.rawValue
        
        // Log calculation with new weights
        Logger.debug("💤 SLEEP SCORE CALCULATION (NEW WEIGHTS):")
        Logger.debug("   Sub-scores: Perf=\(subScores.performance), Quality=\(subScores.stageQuality), Eff=\(subScores.efficiency), Disturb=\(subScores.disturbances), Timing=\(subScores.timing)")
        Logger.debug("   Weighted:   Perf=\(String(format: "%.1f", performanceFactor)) (30%), Quality=\(String(format: "%.1f", stageQualityFactor)) (32%), Eff=\(String(format: "%.1f", efficiencyFactor)) (22%), Disturb=\(String(format: "%.1f", disturbancesFactor)) (14%), Timing=\(String(format: "%.1f", timingFactor)) (2%)")
        Logger.debug("   Final Score: \(Int(finalScore)) (\(band.rawValue) - \(band.color.uppercased()))")
        
        if subScores.stageQuality < 60 || subScores.disturbances < 75 {
            Logger.debug("   ⚠️ Poor sleep quality detected - likely alcohol impact")
        }
        
        if illnessDetected {
            Logger.debug("   ⚠️ Illness detected: \(illnessSeverity ?? "unknown") - Sleep disruption may be illness-related")
        }
        
        return SleepScore(
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
    
    private static func calculateSubScores(inputs: SleepScore.SleepInputs) -> SleepScore.SubScores {
        let performanceScore = calculatePerformanceScore(inputs: inputs)
        let efficiencyScore = calculateEfficiencyScore(inputs: inputs)
        let stageQualityScore = calculateStageQualityScore(inputs: inputs)
        let disturbancesScore = calculateDisturbancesScore(inputs: inputs)
        let timingScore = calculateTimingScore(inputs: inputs)
        
        return SleepScore.SubScores(
            performance: performanceScore,
            efficiency: efficiencyScore,
            stageQuality: stageQualityScore,
            disturbances: disturbancesScore,
            timing: timingScore
        )
    }
    
    private static func calculatePerformanceScore(inputs: SleepScore.SleepInputs) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              let sleepNeed = inputs.sleepNeed,
              sleepNeed > 0 else { return 50 }
        
        // Performance = (actual sleep / sleep need) * 100, capped at 100
        let ratio = sleepDuration / sleepNeed
        let score = min(100, ratio * 100)
        return max(0, Int(score))
    }
    
    private static func calculateEfficiencyScore(inputs: SleepScore.SleepInputs) -> Int {
        guard let sleepDuration = inputs.sleepDuration,
              let timeInBed = inputs.timeInBed,
              timeInBed > 0 else { return 50 }
        
        // Efficiency = (time asleep / time in bed) * 100
        let efficiency = sleepDuration / timeInBed
        let score = efficiency * 100
        return max(0, min(100, Int(score)))
    }
    
    private static func calculateStageQualityScore(inputs: SleepScore.SleepInputs) -> Int {
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
            let score = 50 + ((deepRemPercentage - 0.30) * 500) // Scale 30%-40% to 50-100
            return max(50, Int(score))
        } else {
            // Poor stage distribution
            let score = deepRemPercentage * 166.67 // Scale 0%-30% to 0-50
            return max(0, Int(score))
        }
    }
    
    private static func calculateDisturbancesScore(inputs: SleepScore.SleepInputs) -> Int {
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
    
    private static func calculateTimingScore(inputs: SleepScore.SleepInputs) -> Int {
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
    
    // MARK: - Helper Functions
    
    private static func determineBand(score: Double) -> SleepScore.SleepBand {
        switch score {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .payAttention
        }
    }
}

// MARK: - Sleep Score Extensions

extension SleepScore {
    /// Generate AI daily brief based on sleep score and inputs
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
        var brief = "Optimal sleep quality"
        
        if let sleepDuration = inputs.sleepDuration {
            let hours = sleepDuration / 3600
            brief += " — \(String(format: "%.1f", hours)) hours"
        }
        
        if subScores.stageQuality >= 80 {
            brief += " with great deep/REM sleep"
        }
        
        brief += ". Ready for intense training!"
        return brief
    }
    
    private func generateGoodBrief() -> String {
        return "Good sleep quality. You're ready for moderate to high intensity training."
    }
    
    private func generateFairBrief() -> String {
        return "Fair sleep quality. Consider lighter training or focus on recovery."
    }
    
    private func generatePayAttentionBrief() -> String {
        return "Sleep needs attention. Rest day recommended or very light activity only."
    }
    
    /// Formatted score for display
    var formattedScore: String {
        return "\(score)"
    }
    
    /// Color for the score band
    var bandColor: String {
        return band.color
    }
    
    /// Description of the sleep band
    var bandDescription: String {
        return band.description
    }
    
    /// Detailed breakdown of sub-scores
    var scoreBreakdown: String {
        return "Performance: \(subScores.performance), Efficiency: \(subScores.efficiency), Quality: \(subScores.stageQuality), Disturbances: \(subScores.disturbances), Timing: \(subScores.timing)"
    }
}
