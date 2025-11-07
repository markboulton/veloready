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
        static let loading = CommonContent.States.loading  /// Loading - from CommonContent
        static let error = "Error:"
        static let rawJSON = "Raw JSON Response"
        static let parsedData = "Parsed Data"
        static let noAthleteData = "No athlete data loaded"
        static let powerZones = "Power Zones"
        static let heartRateZones = "Heart Rate Zones"
        static let boundary = "Boundary"
        static let powerZonesNil = "❌ Power zones are NIL"
        static let hrZonesNil = "❌ Heart rate zones are NIL"
        static let recentActivities = "Recent Activities (5)"
        static let noActivities = "No activities loaded"
        static let athleteProfileJSON = "Athlete Profile JSON"
        static let activitiesJSON = "Activities JSON (first 1000 chars)"
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
        static let save = CommonContent.Actions.save  /// Save button - from CommonContent
        static let cancel = CommonContent.Actions.cancel  /// Cancel button - from CommonContent
        static let clearSecret = "Clear Secret"  /// Clear secret button
        static let configureHMACSecret = "Configure HMAC Secret"  /// Configure HMAC secret title
        static let updateSecret = "Update Secret"  /// Update secret button
        static let configureSecret = "Configure Secret"  /// Configure secret button
    }
    
    // MARK: - Sport Preferences Debug (Extended)
    enum SportPreferencesDebugExtended {
        static let primarySportPrefix = "Primary Sport: "  /// Primary sport prefix
        static let rankPrefix = "#"  /// Rank prefix
        static let testOutput = "Test Output"  /// Test output header
        static let technicalDetails = "Technical Details"  /// Technical details header
        static let codableCheck = "Codable: ✅"  /// Codable check
        static let equatableCheck = "Equatable: ✅"  /// Equatable check
        static let savedTo = "Saved to: UserDefaults"  /// Saved to label
        static let syncedTo = "Synced to: iCloud"  /// Synced to label
        static let settingsKey = "Key: UserSettings.sportPreferences"  /// Settings key
        static let setCyclingSuccess = "✅ Set cycling as primary"  /// Set cycling success
        static let setStrengthSuccess = "✅ Set strength as primary"  /// Set strength success
        static let setGeneralSuccess = "✅ Set general as primary"  /// Set general success
        static let setFullRankingSuccess = "✅ Set full ranking"  /// Set full ranking success
        static let runTestsSuccess = "✅ Check console for test results"  /// Run tests success
        static let resetDefaultsSuccess = "✅ Reset to defaults"  /// Reset defaults success
    }
    
    // MARK: - ML Debug (Extended)
    enum MLDebugExtended {
        static let totalDays = "Total Days"  /// Total days label
        static let validDays = "Valid Days"  /// Valid days label
        static let completeness = "Completeness"  /// Completeness label
        static let sufficientData = "Sufficient Data"  /// Sufficient data label
        static let yesCheck = "✅ Yes"  /// Yes with checkmark
        static let noCheck = "❌ No"  /// No with X
        static let mlEnabledCheck = "✅ Yes"  /// ML enabled check
        static let mlDisabledCheck = "❌ No"  /// ML disabled check
        static let daysCount = "days"  /// Days count suffix
        static let week1Testing = "🧪 Week 1 Testing"  /// Week 1 testing header
        static let testTrainingPipeline = "🚀 Test Training Pipeline"  /// Test training pipeline button
        static let testDescription = "Tests dataset builder + model trainer with current data"  /// Test description
        static let statusHeader = "Status"  /// Status header
        static let phase1Info = "Phase 1 Info"  /// Phase 1 info header
        static let phase1Description = "This is Phase 1: ML Infrastructure Setup"  /// Phase 1 description
        static let historicalDataCheck = "✅ Historical data aggregation from Core Data, HealthKit, Intervals.icu, and Strava"  /// Historical data check
        static let featureEngineeringCheck = "✅ Feature engineering (rolling averages, deltas, trends)"  /// Feature engineering check
        static let trainingDataStorageCheck = "✅ Training data storage in Core Data"  /// Training data storage check
        static let modelRegistryCheck = "✅ Model registry for version management"  /// Model registry check
        static let missingFeaturePrefix = "• "  /// Missing feature bullet
    }
    
    // MARK: - Service Health
    enum ServiceHealthExtended {
        static let overallStatus = "Overall Status"  /// Overall status header
        static let healthy = "Healthy"  /// Healthy status
        static let issuesDetected = "Issues Detected"  /// Issues detected status
        static let dataSourcesConnected = "data sources connected"  /// Data sources connected suffix
        static let dataSources = "Data Sources"  /// Data sources header
        static let healthKit = "HealthKit"  /// HealthKit label
        static let intervalsIcu = "Intervals.icu"  /// Intervals.icu label
        static let strava = "Strava"  /// Strava label
        static let connected = "Connected"  /// Connected status
        static let notConnected = "Not Connected"  /// Not connected status
        static let registeredViewModels = "Registered ViewModels"  /// Registered ViewModels header
        static let noViewModels = "No ViewModels registered"  /// No ViewModels message
        static let actions = "Actions"  /// Actions header
        static let clearAllCaches = "Clear All Caches"  /// Clear all caches button
        static let warmUpServices = "Warm Up Services"  /// Warm up services button
        static let refreshStatus = "Refresh Status"  /// Refresh status button
    }
    
    // MARK: - Telemetry
    enum TelemetryExtended {
        static let summary = "Summary"  /// Summary header
        static let totalUses = "Total Uses"  /// Total uses label
        static let activeComponents = "Active Components"  /// Active components label
        static let top5MostUsed = "Top 5 Most Used"  /// Top 5 most used header
        static let noUsageData = "No usage data yet"  /// No usage data message
        static let allComponents = "All Components"  /// All components header
        static let hideAllComponents = "Hide All Components"  /// Hide all components button
        static let showAllComponents = "Show All Components"  /// Show all components button
        static let actions = "Actions"  /// Actions header
        static let refresh = "Refresh"  /// Refresh button
        static let resetTelemetry = "Reset Telemetry"  /// Reset telemetry button
        static let usesPerDayFormat = "%.1f uses/day"  /// Uses per day format string
    }
    
    // MARK: - Intervals API Debug (Extended)
    enum IntervalsAPIExtended {
        static let fetchButton = "Fetch Fresh Data"  /// Fetch button text
    }
    
    // MARK: - Network Debug (Extended)
    enum NetworkDebugExtended {
        static let testResults = "Test Results:"  /// Test results label
        static let testing = "Testing..."  /// Testing status
    }
    
    // MARK: - Hub Navigation
    static let title = "DEBUG & TESTING"
    static let done = "Done"
    
    // MARK: - Logging
    enum Logging {
        static let title = "Debug Logging"
        static let enableDebug = "Enable Debug Logging"
        static let verboseEnabled = "Verbose logging enabled"
        static let disabled = "Logging disabled (optimal performance)"
        static let footer = "Enable verbose logging for debugging. Logs are DEBUG-only and never shipped to production. Toggle OFF for best performance during normal testing."
    }
    
    // MARK: - API
    enum API {
        static let title = "API Debugging"
        static let inspector = "API Data Inspector"
        static let inspectorDescription = "Debug missing activity & athlete data"
        static let footer = "Inspect raw API responses to identify missing fields and data inconsistencies"
    }
    
    // MARK: - Section Headers
    enum SectionHeaders {
        static let authStatus = "Authentication Status"
        static let testingFeatures = "Testing Features"
        static let cacheManagement = "Cache Management"
        static let aiBrief = "AI Daily Brief"
        static let oauthActions = "OAuth Actions"
    }
    
    // MARK: - Section Footers
    enum SectionFooters {
        static let testingFeatures = "These options are only available in debug builds for testing Pro features and mock data."
        static let cacheManagement = "Clear cached data to force a fresh fetch from APIs. Use with caution."
        static let aiBrief = "Manage AI brief configuration and refresh status."
        static let oauthActions = "Manage your Intervals.icu connection and authentication tokens."
    }
    
    // MARK: - Auth Status
    enum AuthStatus {
        static let healthKit = "HealthKit"
        static let intervalsICU = "Intervals.icu"
        static let authorized = "Authorized"
        static let notAuthorized = "Not Authorized"
        static let connected = "Connected"
        static let notConnected = "Not Connected"
        static let disconnected = "Disconnected"
        static let authorize = "Authorize"
        static let athlete = "Athlete:"
    }
    
    // MARK: - Testing Features
    enum TestingFeatures {
        static let showWellnessWarning = "Show Wellness Warning"
        static let wellnessWarningEnabled = "Mock wellness warning enabled"
        static let showIllnessIndicator = "Show Illness Indicator"
        static let illnessIndicatorEnabled = "Mock illness indicator enabled"
        static let simulateNoSleepData = "Simulate No Sleep Data"
        static let noSleepDataEnabled = "Sleep data missing simulation enabled"
        static let simulateNoNetwork = "Simulate No Network"
        static let noNetworkEnabled = "Network offline simulation enabled"
        static let enablePro = "Enable Pro Features"
        static let allProUnlocked = "All Pro features unlocked"
        static let showMockData = "Show Mock Data (Trends)"
        static let mockDataEnabled = "Mock data enabled for charts"
        static let subscriptionStatus = "Subscription Status"
        static let trialDaysRemaining = "Trial Days Remaining:"
        static let pro = "PRO"
        static let free = "FREE"
    }
    
    // MARK: - Cache
    enum Cache {
        static let intervalsCache = "Intervals Cache"
        static let intervalsCacheDescription = "Cached activities, wellness data, and athlete info stored in UserDefaults"
        static let clearIntervalsCache = "Clear Intervals Cache"
        static let coreDataCache = "Core Data Cache"
        static let coreDataCacheDescription = "Daily scores, baselines, and historical data stored in Core Data"
        static let clearCoreData = "Clear Core Data"
        static let cacheCleared = "Cache cleared successfully"
        static let coreDataCleared = "Core Data cleared successfully"
    }
    
    // MARK: - OAuth
    enum OAuth {
        static let signOut = "Sign Out from Intervals.icu"
        static let signIn = "Sign In to Intervals.icu"
        static let status = "Status:"
        static let signInFromLogin = "Sign in from the login screen"
        static let accessToken = "Access Token"
        static let intervalsICU = "Intervals.icu"
        static let connectIntervals = "Connect to Intervals.icu"
    }
    
    // MARK: - Alerts
    enum Alerts {
        static let clearIntervalsCacheTitle = "Clear Intervals Cache?"
        static let clearIntervalsCacheMessage = "This will clear all cached Intervals.icu data from UserDefaults."
        static let clearCoreDataTitle = "Clear Core Data?"
        static let clearCoreDataMessage = "This will delete all Core Data records. The app will need to re-fetch all data."
        static let cancel = CommonContent.Actions.cancel
        static let clear = CommonContent.Actions.clear
    }
    
    // MARK: - Monitoring
    enum Monitoring {
        static let title = "Monitoring Dashboards"
        static let cacheStats = "Cache Statistics"
    }
    
    // MARK: - Ride Summary
    enum RideSummary {
        static let title = "AI Ride Summary"
        static let status = "Ride Summary Status"
        static let loading = "Loading..."
        static let loaded = "Summary loaded"
        static let notLoaded = "Not loaded"
        static let error = "Error:"
        static let clearCache = "Clear Ride Summary Cache"
        static let copyResponse = "Copy Last Response JSON"
        static let configureSecret = "Configure HMAC Secret"
        static let overrideUser = "Override User ID"
        static let footer = "Test AI ride summary endpoint. PRO feature. Uses same HMAC secret as Daily Brief."
    }
    
    // MARK: - Score Recalculation
    enum ScoreRecalc {
        static let title = "Score Recalculation & Testing"
        static let forceRecalcRecovery = "Force Recalculate Recovery"
        static let forceRecalcStrain = "Force Recalculate Strain/Load"
        static let forceRecalcSleep = "Force Recalculate Sleep"
        static let info = "These buttons ignore the daily calculation limit and force immediate recalculation using the latest HealthKit data."
        static let usefulFor = "Useful for testing HealthKit-only mode without Intervals.icu connection."
        static let onboardingStatus = "Onboarding Status"
        static let completed = "Completed"
        static let notCompleted = "Not Completed"
        static let resetOnboarding = "Reset Onboarding"
        static let done = "Done"
        static let footer = "Force recalculation bypasses the once-per-day limit. Perfect for testing HealthKit-only mode and algorithm changes."
    }
    
    // MARK: - Strava
    enum Strava {
        static let title = "Strava"
        static let connected = "Connected"
        static let notConnected = "Not Connected"
        static let athleteID = "Athlete ID"
        static let signOut = "Sign Out from Strava"
    }
}

