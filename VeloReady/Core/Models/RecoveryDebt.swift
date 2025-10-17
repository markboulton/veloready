import Foundation
import SwiftUI

/// Tracks cumulative recovery deficit over consecutive days
/// Research basis: Halson & Jeukendrup (2004) - Cumulative fatigue monitoring
struct RecoveryDebt: Codable {
    let consecutiveDays: Int
    let band: DebtBand
    let averageRecoveryScore: Double
    let calculatedAt: Date
    
    enum DebtBand: String, CaseIterable, Codable {
        case fresh = "Fresh"
        case accumulating = "Accumulating"
        case significant = "Significant"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .fresh: return "green"
            case .accumulating: return "yellow"
            case .significant: return "orange"
            case .critical: return "red"
            }
        }
        
        var colorToken: Color {
            switch self {
            case .fresh: return ColorScale.greenAccent
            case .accumulating: return ColorScale.yellowAccent
            case .significant: return ColorScale.amberAccent
            case .critical: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .fresh: return "No recovery debt - well rested"
            case .accumulating: return "Minor fatigue building - monitor closely"
            case .significant: return "Significant fatigue - reduce training load"
            case .critical: return "Critical fatigue - rest required"
            }
        }
        
        var recommendation: String {
            switch self {
            case .fresh: return "Ready for high intensity training"
            case .accumulating: return "Consider an easy day within 24-48 hours"
            case .significant: return "Schedule rest day or very light activity"
            case .critical: return "Immediate rest required to prevent overtraining"
            }
        }
    }
    
    /// Calculate recovery debt from historical recovery scores
    static func calculate(recoveryScores: [(date: Date, score: Int)]) -> RecoveryDebt {
        let threshold = 60 // Recovery score below this counts as "suboptimal"
        var consecutiveDays = 0
        var totalScore = 0.0
        var count = 0
        
        // Sort by date descending (most recent first)
        let sorted = recoveryScores.sorted { $0.date > $1.date }
        
        // Count consecutive days of suboptimal recovery
        for (_, score) in sorted {
            if score < threshold {
                consecutiveDays += 1
                totalScore += Double(score)
                count += 1
            } else {
                break // Stop at first good recovery day
            }
        }
        
        let avgScore = count > 0 ? totalScore / Double(count) : 100.0
        let band = determineBand(days: consecutiveDays)
        
        return RecoveryDebt(
            consecutiveDays: consecutiveDays,
            band: band,
            averageRecoveryScore: avgScore,
            calculatedAt: Date()
        )
    }
    
    private static func determineBand(days: Int) -> DebtBand {
        switch days {
        case 0...2: return .fresh
        case 3...4: return .accumulating
        case 5...6: return .significant
        default: return .critical
        }
    }
}
