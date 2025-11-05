import Foundation

/// Represents the current loading states for the app
enum LoadingState: Equatable {
    case initial                    // App just launched
    case fetchingHealthData         // Fetching health data
    case calculatingScores(hasHealthKit: Bool, hasSleepData: Bool)  // Computing recovery/sleep/strain
    case checkingForUpdates        // Checking for new data (generic, before contacting services)
    case contactingIntegrations(sources: [DataSource])  // Contacting external services
    case downloadingActivities(count: Int?, source: DataSource?)  // Fetching activities
    case computingZones            // Computing power/HR zones
    case processingData            // Processing fetched data
    case syncingData               // Syncing to iCloud/backend
    case refreshingScores          // Recalculating with new data
    case complete                  // All loading complete
    case updated(Date)             // Updated at specific time (persistent)
    case error(LoadingError)       // Error occurred
    
    /// Data sources for integrations
    enum DataSource: String, Equatable, CaseIterable {
        case strava = "Strava"
        case intervalsIcu = "Intervals.icu"
        case wahoo = "Wahoo"
        case appleHealth = "Apple Health"
    }
    
    enum LoadingError: Equatable {
        case network               // Network unavailable
        case stravaAuth           // Strava auth expired
        case stravaAPI            // Strava API error
        case unknown(String)      // Other errors
    }
    
    /// Minimum time this state should be visible (for readability)
    var minimumDisplayDuration: TimeInterval {
        switch self {
        case .initial: return 0.5
        case .fetchingHealthData: return 0.8
        case .calculatingScores: return 1.0
        case .checkingForUpdates: return 0.6
        case .contactingIntegrations: return 0.8
        case .downloadingActivities: return 1.2
        case .computingZones: return 1.0
        case .processingData: return 1.0
        case .syncingData: return 0.8
        case .refreshingScores: return 0.8
        case .complete: return 0.3  // Brief "done" state before fade
        case .updated: return 0  // Persistent, no minimum
        case .error: return 0  // Stays until dismissed
        }
    }
    
    /// Whether this state can be skipped if already complete
    var canSkip: Bool {
        switch self {
        case .complete: return true
        default: return false
        }
    }
}
