import Foundation

struct LoadingContent {
    // MARK: - Loading States
    
    static let fetchingHealthData = "Fetching health data..."
    static let checkingForUpdates = "Checking for new data..."
    
    static func calculatingScores(hasHealthKit: Bool, hasSleepData: Bool) -> String {
        if !hasHealthKit {
            return "Calculating scores (limited data)..."
        } else if !hasSleepData {
            return "Calculating scores (no sleep data)..."
        }
        return "Calculating scores..."
    }
    
    static func contactingIntegrations(sources: [LoadingState.DataSource]) -> String {
        if sources.isEmpty {
            return "Loading data..."
        } else if sources.count == 1 {
            return "Contacting \(sources[0].rawValue)..."
        } else if sources.count == 2 {
            return "Contacting \(sources[0].rawValue) & \(sources[1].rawValue)..."
        } else {
            return "Syncing integrations..."
        }
    }
    
    static func downloadingActivities(count: Int?, source: LoadingState.DataSource?) -> String {
        if let count = count {
            if let source = source {
                return "Downloading \(count) \(source.rawValue) activities..."
            }
            return "Downloading \(count) activities..."
        }
        if let source = source {
            return "Downloading \(source.rawValue) activities..."
        }
        return "Downloading activities..."
    }
    
    static let generatingInsights = "Generating insights..."
    static let computingZones = "Computing power zones..."
    static let processingData = "Processing data..."
    static let savingToICloud = "Saving to iCloud..."
    static let syncingData = "Syncing to iCloud..."
    static let refreshingScores = "Refreshing scores..."
    static let complete = "Ready"
    
    static func updated(at date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
    
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
        case .fetchingHealthData:
            return "Fetching health data from Apple Health"
        case .checkingForUpdates:
            return "Checking for new data from connected services"
        case .calculatingScores(let hasHealthKit, let hasSleepData):
            if !hasHealthKit {
                return "Calculating scores with limited data due to missing Health app permissions"
            } else if !hasSleepData {
                return "Calculating recovery and strain scores. Sleep score unavailable due to no sleep data"
            }
            return "Calculating recovery, sleep, and strain scores"
        case .contactingIntegrations(let sources):
            let sourceNames = sources.map { $0.rawValue }.joined(separator: ", ")
            if sources.isEmpty {
                return "Loading data"
            } else if sources.count == 1 {
                return "Connecting to \(sourceNames)"
            } else {
                return "Connecting to \(sourceNames)"
            }
        case .downloadingActivities(let count, let source):
            let sourceName = source?.rawValue ?? "external services"
            if let count = count {
                return "Downloading \(count) activities from \(sourceName)"
            }
            return "Downloading activities from \(sourceName)"
        case .generatingInsights:
            return "Generating personalized insights and recommendations using AI"
        case .computingZones:
            return "Computing power and heart rate zones"
        case .processingData:
            return "Processing workout data"
        case .savingToICloud:
            return "Saving data to iCloud for backup"
        case .syncingData:
            return "Syncing data to iCloud"
        case .refreshingScores:
            return "Refreshing scores with new data"
        case .complete:
            return "Loading complete"
        case .updated(let date):
            return "Updated \(RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date()))"
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
