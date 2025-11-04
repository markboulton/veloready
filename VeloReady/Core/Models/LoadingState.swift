import Foundation

/// Represents the current loading state of the app
enum LoadingState: Equatable {
    case initial                    // App just launched
    case calculatingScores          // Computing recovery/sleep/strain
    case contactingStrava          // Initiating Strava API connection
    case downloadingActivities(count: Int?)  // Fetching activities
    case processingData            // Processing fetched data
    case refreshingScores          // Recalculating with new data
    case complete                  // All loading complete
    case error(LoadingError)       // Error occurred
    
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
        case .calculatingScores: return 1.0
        case .contactingStrava: return 0.8
        case .downloadingActivities: return 1.2
        case .processingData: return 1.0
        case .refreshingScores: return 0.8
        case .complete: return 0.3  // Brief "done" state before fade
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
