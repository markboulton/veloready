import Foundation

/// Represents the current loading states for the app
enum LoadingState: Equatable {
    case initial                    // App just launched
    case fetchingHealthData         // Fetching health data
    case calculatingScores(hasHealthKit: Bool, hasSleepData: Bool)  // Computing recovery/sleep/strain
    case checkingForUpdates        // Checking for new data (generic, before contacting services)
    case contactingIntegrations(sources: [DataSource])  // Contacting external services
    case downloadingActivities(count: Int?, source: DataSource?)  // Fetching activities
    case generatingInsights        // Generating AI insights and recommendations
    case computingZones            // Computing power/HR zones
    case processingData            // Processing fetched data
    case savingToICloud            // Saving data to iCloud
    case syncingData               // Syncing to iCloud/backend (deprecated - use savingToICloud)
    case refreshingScores          // Recalculating with new data
    case offline                   // Device is offline (persistent)
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
    /// Balanced approach: Fast enough to feel snappy (0.3-0.5s), slow enough to read
    /// Total cycle time: ~2-3 seconds (down from 4-5s)
    var minimumDisplayDuration: TimeInterval {
        switch self {
        case .initial:
            return 0
        case .contactingIntegrations:
            return 0.4  // Reduced from 0.6s - still readable
        case .checkingForUpdates:
            return 0.3  // Reduced from 0.5s
        case .fetchingHealthData:
            return 0.3  // Reduced from 0.5s
        case .calculatingScores:
            return 0.4  // Reduced from 0.6s
        case .downloadingActivities:
            return 0.5  // Reduced from 0.8s - still readable with count
        case .generatingInsights:
            return 0.4  // Reduced from 0.6s
        case .computingZones:
            return 0.3  // Reduced from 0.5s
        case .processingData:
            return 0.3  // Reduced from 0.5s
        case .savingToICloud:
            return 0.4  // Reduced from 0.6s
        case .syncingData:
            return 0.3  // Reduced from 0.5s
        case .refreshingScores:
            return 0.3  // Reduced from 0.5s
        case .offline:
            return 2.0  // Persistent while offline
        case .complete:
            return 0.2  // Reduced from 0.3s - brief pause before clearing
        case .updated:
            return 2.0
        case .error:
            return 3.0
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
