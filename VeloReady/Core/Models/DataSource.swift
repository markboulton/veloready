import Foundation
import SwiftUI

/// Represents all possible data sources for the app
enum DataSource: String, Codable, CaseIterable, Identifiable {
    case intervalsICU = "intervals_icu"
    case strava = "strava"
    case garmin = "garmin"
    case appleHealth = "apple_health"
    
    var id: String { rawValue }
    
    /// Display name for the source
    var displayName: String {
        switch self {
        case .intervalsICU: return "Intervals.icu"
        case .strava: return "Strava"
        case .garmin: return "Garmin"
        case .appleHealth: return "Apple Health"
        }
    }
    
    /// Icon for the source
    var icon: String {
        switch self {
        case .intervalsICU: return "chart.line.uptrend.xyaxis"
        case .strava: return "figure.outdoor.cycle"
        case .garmin: return "applewatch"
        case .appleHealth: return "heart.fill"
        }
    }
    
    /// Primary color for the source
    var color: Color {
        switch self {
        case .intervalsICU: return .blue
        case .strava: return .orange
        case .garmin: return .cyan
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
        case .garmin:
            return [.activities, .wellness, .metrics]
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
        case .garmin:
            return "Device data, activities, and advanced metrics"
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
        case .garmin:
            return (0/255, 158/255, 227/255) // Garmin cyan
        case .appleHealth:
            return (255/255, 45/255, 85/255) // Apple Health red
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
