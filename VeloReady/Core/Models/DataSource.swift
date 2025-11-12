import Foundation
import SwiftUI

/// Represents all possible data sources for the app
enum DataSource: String, Codable, CaseIterable, Identifiable {
    case intervalsICU = "intervals_icu"
    case strava = "strava"
    // case garmin = "garmin" // Removed - not implemented
    case appleHealth = "apple_health"
    
    var id: String { rawValue }
    
    /// Display name for the source
    var displayName: String {
        switch self {
        case .intervalsICU: return "Intervals.icu"
        case .strava: return "Strava"
        case .appleHealth: return "Apple Health"
        }
    }
    
    /// Icon for the source
    var icon: String {
        switch self {
        case .intervalsICU: return Icons.DataSource.intervalsICU
        case .strava: return Icons.DataSource.strava
        case .appleHealth: return Icons.DataSource.appleHealth
        }
    }
    
    /// Primary color for the source
    var color: Color {
        switch self {
        case .intervalsICU: return .blue
        case .strava: return .orange
        case .appleHealth: return .red
        }
    }
    
    /// What type of data this source provides
    var providedDataTypes: [DataType] {
        switch self {
        case .intervalsICU:
            return [.activities, .wellness, .zones, .metrics]
        case .strava:
            return [.activities, .metrics]
        case .appleHealth:
            return [.wellness, .workouts]
        }
    }
    
    /// Description of what this source provides
    var sourceDescription: String {
        switch self {
        case .intervalsICU:
            return "Training platform with power analysis and performance metrics"
        case .strava:
            return "Activity tracking and social network for athletes"
        case .appleHealth:
            return "Health metrics, workouts, HRV, sleep, and heart rate data"
        }
    }
    
    /// Brand color for the source
    var brandColor: (red: Double, green: Double, blue: Double) {
        switch self {
        case .intervalsICU:
            return (0/255, 122/255, 255/255) // Intervals blue
        case .strava:
            return (252/255, 76/255, 2/255) // Strava orange #FC4C02
        case .appleHealth:
            return (255/255, 45/255, 85/255) // Apple Health red
        }
    }
    
    // MARK: - ML Data Usage Policies
    
    /// Whether raw data from this source can be used for ML training
    /// Based on API terms of service and data ownership policies
    var isMLIngestible: Bool {
        switch self {
        case .intervalsICU:
            return true  // ✅ API terms allow ML training on user data
        case .strava:
            return false // ❌ Cannot store/train on raw stream data per Strava TOS
        case .appleHealth:
            return true  // ✅ On-device, user-owned data - fully compliant
        }
    }
    
    /// Whether this source supports pattern-based analysis (aggregate metrics)
    /// without raw data ingestion
    var supportsPatternAnalysis: Bool {
        switch self {
        case .strava:
            return true  // ✅ Can analyze patterns from metadata (CTL, volume, intensity)
        default:
            return isMLIngestible // If ingestible, patterns are implicit
        }
    }
    
    /// Description of ML usage policy for user-facing transparency
    var mlUsageDescription: String {
        switch self {
        case .intervalsICU:
            return "Training and wellness data used for personalized ML predictions"
        case .strava:
            return "Activity patterns analyzed (not raw data) to enhance predictions"
        case .appleHealth:
            return "Health data used on-device for personalized ML training"
        }
    }
}

/// Types of data that can be provided by sources
enum DataType: String, Codable {
    case activities      // Rides, runs, etc.
    case wellness       // Sleep, HRV, RHR, recovery
    case zones          // Power zones, HR zones
    case metrics        // Performance metrics
    case workouts       // Apple Health workouts
}

/// Connection status for a data source
enum ConnectionStatus: Codable, Equatable {
    case notConnected
    case connecting
    case connected
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    var displayText: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let message): return "Error: \(message)"
        }
    }
}
