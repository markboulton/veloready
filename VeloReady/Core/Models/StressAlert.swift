import Foundation

/// Stress alert model for elevated stress detection
/// Follows the same pattern as WellnessAlert and IllnessIndicator
struct StressAlert: Identifiable {
    let id = UUID()
    let severity: Severity
    let acuteStress: Int  // 0-100
    let chronicStress: Int  // 0-100
    let trend: Trend
    let contributors: [StressContributor]
    let recommendation: String
    let detectedAt: Date
    
    /// Severity level of stress alert
    enum Severity: String {
        case elevated = "Elevated"  // 61-80
        case high = "High"          // 81-100
        
        var color: Color {
            switch self {
            case .elevated:
                return ColorScale.amberAccent
            case .high:
                return ColorScale.redAccent
            }
        }
        
        var icon: String {
            switch self {
            case .elevated:
                return Icons.Status.warningFill
            case .high:
                return Icons.Status.errorFill
            }
        }
    }
    
    /// Trend direction of stress over time
    enum Trend {
        case increasing
        case stable
        case decreasing
        
        var description: String {
            switch self {
            case .increasing:
                return "Increasing"
            case .stable:
                return "Stable"
            case .decreasing:
                return "Decreasing"
            }
        }
        
        var icon: String {
            switch self {
            case .increasing:
                return "arrow.up.right"
            case .stable:
                return "arrow.forward"
            case .decreasing:
                return "arrow.down.right"
            }
        }
    }
    
    /// Banner message for Today view
    var bannerMessage: String {
        switch severity {
        case .elevated:
            return StressContent.Banner.elevated
        case .high:
            return StressContent.Banner.high
        }
    }
    
    /// Whether this alert is significant enough to show
    var isSignificant: Bool {
        return chronicStress >= 61 || acuteStress >= 71
    }
}

/// Individual contributor to stress score
struct StressContributor: Identifiable {
    let id = UUID()
    let name: String
    let type: ContributorType
    let value: Int  // 0-100 score
    let points: Int  // Points contributed to overall stress
    let description: String
    let status: Status
    
    enum ContributorType {
        case trainingLoad
        case sleepQuality
        case hrv
        case temperature
        case recovery
        case strain
        
        var icon: String {
            switch self {
            case .trainingLoad:
                return Icons.Activity.cycling
            case .sleepQuality:
                return Icons.Health.sleepFill
            case .hrv:
                return Icons.Health.heartFill
            case .temperature:
                return Icons.Health.thermometer
            case .recovery:
                return Icons.Health.recovery
            case .strain:
                return Icons.Activity.strength
            }
        }
        
        var label: String {
            switch self {
            case .trainingLoad:
                return StressContent.Contributors.trainingLoad
            case .sleepQuality:
                return StressContent.Contributors.sleepQuality
            case .hrv:
                return StressContent.Contributors.hrv
            case .temperature:
                return StressContent.Contributors.temperature
            case .recovery:
                return StressContent.Contributors.recovery
            case .strain:
                return StressContent.Contributors.strain
            }
        }
    }
    
    enum Status {
        case optimal
        case good
        case elevated
        case high
        
        var color: Color {
            switch self {
            case .optimal:
                return ColorScale.greenAccent
            case .good:
                return ColorScale.blueAccent
            case .elevated:
                return ColorScale.amberAccent
            case .high:
                return ColorScale.redAccent
            }
        }
        
        var label: String {
            switch self {
            case .optimal:
                return "Optimal"
            case .good:
                return "Good"
            case .elevated:
                return "Elevated"
            case .high:
                return "High"
            }
        }
    }
}

// MARK: - Recovery Factor

/// Individual factor that makes up recovery score
/// Used in the new RecoveryFactorsCard
struct RecoveryFactor: Identifiable {
    let id = UUID()
    let type: FactorType
    let value: Int  // 0-100 score
    let status: Status
    let weight: Double  // 0.0-1.0
    
    enum FactorType {
        case stress
        case hrv
        case rhr
        case sleep
        case form
        
        var label: String {
            switch self {
            case .stress:
                return StressContent.RecoveryFactors.stress
            case .hrv:
                return RecoveryContent.Metrics.hrv
            case .rhr:
                return RecoveryContent.Metrics.rhr
            case .sleep:
                return RecoveryContent.Metrics.sleep
            case .form:
                return RecoveryContent.Metrics.load
            }
        }
        
        var icon: String {
            switch self {
            case .stress:
                return Icons.Health.brain
            case .hrv:
                return Icons.Health.heartFill
            case .rhr:
                return Icons.Health.heartCircle
            case .sleep:
                return Icons.Health.sleepFill
            case .form:
                return Icons.Activity.cycling
            }
        }
    }
    
    enum Status {
        case optimal
        case good
        case fair
        case low
        case high  // For stress specifically
        
        var color: Color {
            switch self {
            case .optimal:
                return ColorScale.greenAccent
            case .good:
                return ColorScale.blueAccent
            case .fair:
                return ColorScale.amberAccent
            case .low, .high:
                return ColorScale.redAccent
            }
        }
        
        /// Label customized for the factor type
        func label(for type: FactorType) -> String {
            switch type {
            case .stress:
                // Stress uses inverted labels (low is good, high is bad)
                switch self {
                case .optimal:
                    return "Low"
                case .good:
                    return "Moderate"
                case .fair:
                    return "Elevated"
                case .high, .low:
                    return "High"
                }
            default:
                // Other metrics use normal labels
                switch self {
                case .optimal:
                    return "Optimal"
                case .good:
                    return "Good"
                case .fair:
                    return "Fair"
                case .low:
                    return "Low"
                case .high:
                    return "High"
                }
            }
        }
    }
}

import SwiftUI

