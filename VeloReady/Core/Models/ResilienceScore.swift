import Foundation
import SwiftUI

/// Tracks individual recovery capacity relative to training load over 30 days
/// Research basis: Buchheit (2014) - Individual recovery capacity monitoring
struct ResilienceScore: Codable {
    let score: Int // 0-100
    let band: ResilienceBand
    let averageRecovery: Double
    let averageLoad: Double
    let recoveryEfficiency: Double // Recovery per unit of load
    let calculatedAt: Date
    
    enum ResilienceBand: String, CaseIterable, Codable {
        case high = "High"
        case good = "Good"
        case moderate = "Moderate"
        case low = "Low"
        
        var color: String {
            switch self {
            case .high: return "green"
            case .good: return "yellow"
            case .moderate: return "orange"
            case .low: return "red"
            }
        }
        
        var colorToken: Color {
            switch self {
            case .high: return ColorScale.greenAccent
            case .good: return ColorScale.yellowAccent
            case .moderate: return ColorScale.amberAccent
            case .low: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .high: return "Excellent recovery capacity"
            case .good: return "Good recovery capacity"
            case .moderate: return "Moderate recovery capacity"
            case .low: return "Limited recovery capacity"
            }
        }
        
        var recommendation: String {
            switch self {
            case .high: return "You handle training load well - can push harder"
            case .good: return "Good recovery - maintain current training approach"
            case .moderate: return "Recovery is adequate - monitor closely"
            case .low: return "Recovery struggling - reduce training volume or intensity"
            }
        }
    }
    
    /// Calculate resilience from 30-day recovery and load history
    /// - Parameters:
    ///   - recoveryScores: Array of (date, recovery score) for last 30 days
    ///   - strainScores: Array of (date, strain score) for last 30 days
    static func calculate(recoveryScores: [(date: Date, score: Int)], strainScores: [(date: Date, score: Double)]) -> ResilienceScore {
        guard recoveryScores.count >= 14, strainScores.count >= 14 else {
            // Not enough data - return moderate
            return ResilienceScore(
                score: 50,
                band: .moderate,
                averageRecovery: 0,
                averageLoad: 0,
                recoveryEfficiency: 0,
                calculatedAt: Date()
            )
        }
        
        // Calculate averages
        let avgRecovery = recoveryScores.map { Double($0.score) }.reduce(0, +) / Double(recoveryScores.count)
        let avgLoad = strainScores.map { $0.score }.reduce(0, +) / Double(strainScores.count)
        
        // Calculate recovery efficiency: how well recovery holds up relative to load
        // High resilience = high recovery despite high load
        // Low resilience = low recovery even with moderate load
        
        // Normalize load to 0-100 scale (strain is 0-18)
        let normalizedLoad = (avgLoad / 18.0) * 100.0
        
        // Recovery efficiency = recovery score / normalized load
        // Higher is better (good recovery relative to load)
        let efficiency = normalizedLoad > 0 ? avgRecovery / normalizedLoad : 1.0
        
        // Calculate resilience score
        // Factors:
        // 1. Average recovery (40%)
        // 2. Recovery efficiency (40%)
        // 3. Consistency (20%) - lower std dev is better
        
        let recoveryStdDev = standardDeviation(recoveryScores.map { Double($0.score) })
        let consistencyScore = max(0, 100 - (recoveryStdDev * 2)) // Lower SD = higher score
        
        // Efficiency score: scale 0.5-2.0 efficiency to 0-100
        let efficiencyScore = min(100, max(0, (efficiency - 0.5) / 1.5 * 100))
        
        let weightedScore = (avgRecovery * 0.4) + (efficiencyScore * 0.4) + (consistencyScore * 0.2)
        let finalScore = Int(weightedScore.rounded())
        let band = determineBand(score: finalScore)
        
        return ResilienceScore(
            score: finalScore,
            band: band,
            averageRecovery: avgRecovery,
            averageLoad: avgLoad,
            recoveryEfficiency: efficiency,
            calculatedAt: Date()
        )
    }
    
    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private static func determineBand(score: Int) -> ResilienceBand {
        switch score {
        case 80...100: return .high
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .low
        }
    }
}
