import Foundation

/// Content strings for Debug views
enum DebugContent {
    // MARK: - Navigation Titles
    enum Navigation {
        static let apiDebug = "API Debug"  /// API debug navigation title
        static let mlDebug = "ML Debug"  /// ML debug navigation title
        static let sportPreferencesDebug = "Sport Preferences Debug"  /// Sport preferences debug title
        static let serviceHealth = "Service Health"  /// Service health title
        static let componentTelemetry = "Component Telemetry"  /// Component telemetry title
        static let healthDataDebug = "Health Data Debug"  /// Health data debug title
        static let networkDebug = "Network Debug"  /// Network debug title
        static let oauthDebug = "OAuth Debug"  /// OAuth debug title
        static let certificateBypass = "Certificate Bypass"  /// Certificate bypass title
        static let networkWorkaround = "Network Workaround"  /// Network workaround title
        static let instructions = "Instructions"  /// Instructions title
        static let oauthTest = "OAuth Test"  /// OAuth test title
    }
    
    // MARK: - Intervals API Debug
    enum IntervalsAPI {
        static let title = "Intervals.icu API Inspector"
        static let inspectResponses = "Inspect raw API responses to debug missing data"
        static let fetchFresh = "Fetch Fresh Data"
        static let fetching = "Fetching data..."
        static let athleteProfile = "Athlete Profile"
        static let basicInfo = "Basic Information"
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
        static let infrastructureStatus = "ML Infrastructure Status"
        static let mlEnabled = "ML Enabled"
        static let currentModel = "Current Model"
        static let none = "None"
        static let trainingData = "Training Data"
        static let lastProcessing = "Last Processing"
        static let never = "Never"
        static let dataQuality = "Data Quality"
        static let missingFeatures = "Missing Features:"
        static let actions = "Actions"
        static let processHistorical = "Process Historical Data (90 days)"
        static let checkQuality = "Check Data Quality"
        static let disable = "Disable ML"
        static let enable = "Enable ML"
        static let personalization = "ML Personalization"
        static let status = "Status:"
        static let enabled = "Enabled"
        static let disabled = "Disabled"
        static let dataPoints = "Data Points:"
        static let lastTrained = "Last Trained:"
        static let predictions = "Recent Predictions"
        static let noPredictions = "No predictions yet"
    }
    
    // MARK: - Sport Preferences Debug
    enum SportPreferences {
        static let title = "Sport Preferences Debug"
        static let currentPrefs = "Current Sport Preferences"
        static let testActions = "Test Actions"
        static let setCycling = "Set Cycling Primary"
        static let setStrength = "Set Strength Primary"
        static let setGeneral = "Set General Primary"
        static let setFullRanking = "Set Full Ranking (Cycling → Strength → General)"
        static let runTests = "Run Unit Tests"
        static let resetDefaults = "Reset to Defaults"
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
        static let debugMode = "Debug Mode Active"
        static let usingRealData = "Using Real Data from HealthKit and Intervals.icu"
        static let recentActivities = "Recent Activities"
        static let activityData = "Activity data displayed in main Today view"
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
    
    // MARK: - Network Debug
    enum NetworkDebug {
        static let testBasicConnectivity = "Test Basic Connectivity"  /// Test basic connectivity button
        static let testIntervalsDNS = "Test intervals.icu DNS"  /// Test DNS button
        static let testIntervalsHTTPS = "Test intervals.icu HTTPS"  /// Test HTTPS button
        static let testOAuthEndpoint = "Test OAuth Endpoint"  /// Test OAuth button
        static let testAPIEndpoint = "Test API Endpoint"  /// Test API button
    }
    
    // MARK: - OAuth Test
    enum OAuthTest {
        static let testOAuthURLGeneration = "Test OAuth URL Generation"  /// Test URL generation button
        static let testTokenExchangeEndpoint = "Test Token Exchange Endpoint"  /// Test token exchange button
        static let testAPIEndpoints = "Test API Endpoints"  /// Test API endpoints button
        static let testFullOAuthFlow = "Test Full OAuth Flow"  /// Test full flow button
    }
    
    // MARK: - OAuth Debug Actions
    enum OAuthDebugActions {
        static let testIntervalsConnection = "Test intervals.icu Connection"  /// Test connection button
        static let testOAuthTokenExchange = "Test OAuth Token Exchange"  /// Test token exchange button
        static let testCallbackURL = "Test Callback URL"  /// Test callback button
    }
    
    // MARK: - Health Data Debug
    enum HealthDataDebug {
        static let requestHealthKitAuthorization = "Request HealthKit Authorization"  /// Request authorization button
        static let refreshAuthorizationStatus = "Refresh Authorization Status"  /// Refresh status button
        static let openSettings = "Open Settings"  /// Open settings button
    }
    
    // MARK: - AI Brief Secret Config
    enum AIBriefSecretConfig {
        static let save = "Save"  /// Save button
        static let cancel = "Cancel"  /// Cancel button
        static let clearSecret = "Clear Secret"  /// Clear secret button
        static let configureHMACSecret = "Configure HMAC Secret"  /// Configure HMAC secret title
    }
}

