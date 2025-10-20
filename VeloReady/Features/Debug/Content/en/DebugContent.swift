import Foundation

/// Content strings for Debug views
enum DebugContent {
    // MARK: - Intervals API Debug
    enum IntervalsAPI {
        static let title = "Intervals API Debug"
        static let athleteData = "Athlete Data"
        static let activitiesData = "Activities Data"
        static let wellnessData = "Wellness Data"
        static let fetchAthlete = "Fetch Athlete"
        static let fetchActivities = "Fetch Activities (Last 30 Days)"
        static let fetchWellness = "Fetch Wellness (Last 30 Days)"
        static let noData = "No data fetched yet"
        static let loading = "Loading..."
        static let error = "Error:"
        static let rawJSON = "Raw JSON Response"
        static let parsedData = "Parsed Data"
    }
    
    // MARK: - ML Debug
    enum ML {
        static let title = "ML Debug"
        static let personalization = "ML Personalization"
        static let status = "Status:"
        static let enabled = "Enabled"
        static let disabled = "Disabled"
        static let dataPoints = "Data Points:"
        static let lastTrained = "Last Trained:"
        static let never = "Never"
        static let predictions = "Recent Predictions"
        static let noPredictions = "No predictions yet"
    }
    
    // MARK: - Sport Preferences Debug
    enum SportPreferences {
        static let title = "Sport Preferences Debug"
        static let currentSport = "Current Sport:"
        static let cycling = "Cycling"
        static let running = "Running"
        static let changeSport = "Change Sport"
        static let features = "Sport-Specific Features"
        static let cyclingFeatures = "Cycling features enabled"
        static let runningFeatures = "Running features enabled"
    }
    
    // MARK: - Debug Today
    enum Today {
        static let title = "Debug Today View"
        static let forceRefresh = "Force Refresh All Data"
        static let clearCache = "Clear All Caches"
        static let resetScores = "Reset All Scores"
        static let simulateData = "Simulate Mock Data"
        static let dataStatus = "Data Status"
        static let lastRefresh = "Last Refresh:"
        static let cacheSize = "Cache Size:"
    }
    
    // MARK: - AI Brief Config
    enum AIBrief {
        static let title = "AI Brief Config"
        static let secretKey = "Secret Key"
        static let enterKey = "Enter OpenAI API Key"
        static let save = "Save Key"
        static let testBrief = "Test Brief Generation"
        static let generating = "Generating..."
        static let success = "Brief generated successfully"
    }
    
    // MARK: - Telemetry
    enum Telemetry {
        static let title = "Telemetry Dashboard"
        static let events = "Recent Events"
        static let noEvents = "No events logged"
        static let clearEvents = "Clear All Events"
    }
    
    // MARK: - Service Health
    enum ServiceHealth {
        static let title = "Service Health"
        static let allHealthy = "All services healthy"
        static let checkHealth = "Check Health"
    }
}
