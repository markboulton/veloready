import Foundation

struct LoadingContent {
    // MARK: - Loading States
    
    static let calculatingScores = "Calculating scores..."
    static let contactingStrava = "Contacting Strava..."
    
    static func downloadingActivities(count: Int?) -> String {
        if let count = count {
            return "Downloading \(count) activities..."
        }
        return "Downloading activities..."
    }
    
    static let processingData = "Processing data..."
    static let refreshingScores = "Refreshing scores..."
    static let complete = "Ready"
    
    // MARK: - Error States
    
    static let networkError = "Unable to connect. Tap to retry."
    static let stravaAuthError = "Strava connection expired. Tap to reconnect."
    static let stravaAPIError = "Strava temporarily unavailable."
    
    static func unknownError(_ message: String) -> String {
        return "Error: \(message). Tap to retry."
    }
    
    // MARK: - Accessibility Labels
    
    static func accessibilityLabel(for state: LoadingState) -> String {
        switch state {
        case .initial:
            return "Loading"
        case .calculatingScores:
            return "Calculating recovery and sleep scores"
        case .contactingStrava:
            return "Connecting to Strava"
        case .downloadingActivities(let count):
            if let count = count {
                return "Downloading \(count) activities from Strava"
            }
            return "Downloading activities from Strava"
        case .processingData:
            return "Processing workout data"
        case .refreshingScores:
            return "Refreshing scores with new data"
        case .complete:
            return "Loading complete"
        case .error(let error):
            switch error {
            case .network:
                return "Network error. Tap to retry."
            case .stravaAuth:
                return "Strava authentication error. Tap to reconnect."
            case .stravaAPI:
                return "Strava service unavailable"
            case .unknown(let message):
                return "Error: \(message). Tap to retry."
            }
        }
    }
}
