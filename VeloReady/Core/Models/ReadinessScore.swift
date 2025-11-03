import Foundation
import SwiftUI

/// Composite readiness score combining recovery, sleep, and training load
/// Research basis: Saw et al. (2016) - Multi-factorial readiness monitoring
struct ReadinessScore: Codable {
    let score: Int // 0-100
    let band: ReadinessBand
    let components: Components
    let calculatedAt: Date
    
    struct Components: Codable {
        let recoveryScore: Int
        let sleepScore: Int? // Optional when sleep data unavailable
        let loadReadiness: Int // Inverse of strain (light load = high readiness)
        let recoveryWeight: Double // 0.4 or 0.615 (no sleep)
        let sleepWeight: Double // 0.35 or 0.0 (no sleep)
        let loadWeight: Double // 0.25 or 0.385 (no sleep)
    }
    
    enum ReadinessBand: String, CaseIterable, Codable {
        case fullyReady = "Fully Ready"
        case ready = "Ready"
        case compromised = "Compromised"
        case notReady = "Not Ready"
        
        var color: String {
            switch self {
            case .fullyReady: return "green"
            case .ready: return "yellow"
            case .compromised: return "orange"
            case .notReady: return "red"
            }
        }
        
        var colorToken: Color {
            switch self {
            case .fullyReady: return ColorScale.greenAccent
            case .ready: return ColorScale.yellowAccent
            case .compromised: return ColorScale.amberAccent
            case .notReady: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .fullyReady: return RecoveryContent.Readiness.fullyReadyDescription
            case .ready: return RecoveryContent.Readiness.readyDescription
            case .compromised: return RecoveryContent.Readiness.compromisedDescription
            case .notReady: return RecoveryContent.Readiness.notReadyDescription
            }
        }
        
        var trainingRecommendation: String {
            switch self {
            case .fullyReady: return RecoveryContent.Readiness.fullyReadyTraining
            case .ready: return RecoveryContent.Readiness.readyTraining
            case .compromised: return RecoveryContent.Readiness.compromisedTraining
            case .notReady: return RecoveryContent.Readiness.notReadyTraining
            }
        }
        
        var intensityGuidance: String {
            switch self {
            case .fullyReady: return RecoveryContent.Readiness.fullyReadyGuidance
            case .ready: return RecoveryContent.Readiness.readyGuidance
            case .compromised: return RecoveryContent.Readiness.compromisedGuidance
            case .notReady: return RecoveryContent.Readiness.notReadyGuidance
            }
        }
    }
    
    /// Calculate readiness score from recovery, sleep, and strain
    /// - Parameters:
    ///   - recoveryScore: Current recovery score (0-100)
    ///   - sleepScore: Current sleep score (0-100), optional
    ///   - strainScore: Current strain score (0-18 scale)
    static func calculate(recoveryScore: Int, sleepScore: Int?, strainScore: Double) -> ReadinessScore {
        // Convert strain (0-18) to load readiness (0-100)
        // Light load (0-5.5) = high readiness (100-70)
        // Moderate load (5.5-9) = moderate readiness (70-50)
        // Hard load (9-14) = low readiness (50-30)
        // Very hard load (14+) = very low readiness (30-0)
        let loadReadiness: Int
        switch strainScore {
        case 0..<5.5:
            loadReadiness = Int(100 - (strainScore / 5.5 * 30)) // 100-70
        case 5.5..<9.0:
            loadReadiness = Int(70 - ((strainScore - 5.5) / 3.5 * 20)) // 70-50
        case 9.0..<14.0:
            loadReadiness = Int(50 - ((strainScore - 9.0) / 5.0 * 20)) // 50-30
        default:
            loadReadiness = max(0, Int(30 - ((strainScore - 14.0) / 4.0 * 30))) // 30-0
        }
        
        // Check if sleep data is available and not simulated as unavailable
        let simulateNoSleep = UserDefaults.standard.bool(forKey: "simulateNoSleepData")
        let hasSleepData = sleepScore != nil && !simulateNoSleep
        
        // Weighted combination - rebalance when sleep unavailable
        let recoveryWeight: Double
        let sleepWeight: Double
        let loadWeight: Double
        
        if hasSleepData {
            // Normal weights (with sleep): Recovery 40%, Sleep 35%, Load 25%
            recoveryWeight = 0.4
            sleepWeight = 0.35
            loadWeight = 0.25
        } else {
            // Rebalanced weights (without sleep): Recovery 61.5%, Load 38.5%
            recoveryWeight = 0.615
            sleepWeight = 0.0
            loadWeight = 0.385
        }
        
        let weightedScore = (Double(recoveryScore) * recoveryWeight) +
                           (Double(sleepScore ?? 0) * sleepWeight) +
                           (Double(loadReadiness) * loadWeight)
        
        let finalScore = Int(weightedScore.rounded())
        let band = determineBand(score: finalScore)
        
        let components = Components(
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            loadReadiness: loadReadiness,
            recoveryWeight: recoveryWeight,
            sleepWeight: sleepWeight,
            loadWeight: loadWeight
        )
        
        return ReadinessScore(
            score: finalScore,
            band: band,
            components: components,
            calculatedAt: Date()
        )
    }
    
    private static func determineBand(score: Int) -> ReadinessBand {
        switch score {
        case 80...100: return .fullyReady
        case 60..<80: return .ready
        case 40..<60: return .compromised
        default: return .notReady
        }
    }
}
