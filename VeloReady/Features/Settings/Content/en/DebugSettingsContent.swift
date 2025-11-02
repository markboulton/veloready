import Foundation

/// Content strings for Debug Settings view
enum DebugSettingsContent {
    // MARK: - Navigation
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
    
    // MARK: - AI Brief
    enum AIBrief {
        static let status = "AI Brief Status"
        static let loading = CommonContent.States.loading  /// Loading - from CommonContent
        static let loaded = "Loaded"
        static let notLoaded = "Not loaded"
        static let error = "Error:"
        static let refresh = "Refresh AI Brief"
        static let configureSecret = "Configure AI Secret"
        static let cached = "Cached"
    }
    
    // MARK: - OAuth
    enum OAuth {
        static let signOut = "Sign Out from Intervals.icu"
        static let signIn = "Sign In to Intervals.icu"
        static let status = "Status:"
        static let signInFromLogin = "Sign in from the login screen"
        static let accessToken = "Access Token"
        static let intervalsICU = "Intervals.icu"  /// Intervals.icu label
        static let connectIntervals = "Connect to Intervals.icu"  /// Connect button
    }
    
    // MARK: - Alerts
    enum Alerts {
        static let clearIntervalsCacheTitle = "Clear Intervals Cache?"
        static let clearIntervalsCacheMessage = "This will clear all cached Intervals.icu data from UserDefaults."
        static let clearCoreDataTitle = "Clear Core Data?"
        static let clearCoreDataMessage = "This will delete all Core Data records. The app will need to re-fetch all data."
        static let cancel = CommonContent.Actions.cancel  /// Cancel - from CommonContent
        static let clear = CommonContent.Actions.clear  /// Clear - from CommonContent
    }
    
    // MARK: - Monitoring
    enum Monitoring {
        static let title = "Monitoring Dashboards"  /// Monitoring section title
        static let cacheStats = "Cache Statistics"  /// Cache stats link
    }
    
    // MARK: - Ride Summary
    enum RideSummary {
        static let title = "AI Ride Summary"  /// Section title
        static let status = "Ride Summary Status"  /// Status label
        static let loading = "Loading..."  /// Loading state
        static let loaded = "Summary loaded"  /// Loaded state
        static let notLoaded = "Not loaded"  /// Not loaded state
        static let error = "Error:"  /// Error prefix
        static let clearCache = "Clear Ride Summary Cache"  /// Clear cache button
        static let copyResponse = "Copy Last Response JSON"  /// Copy response button
        static let configureSecret = "Configure HMAC Secret"  /// Configure secret button
        static let overrideUser = "Override User ID"  /// Override user button
        static let footer = "Test AI ride summary endpoint. PRO feature. Uses same HMAC secret as Daily Brief."  /// Section footer
    }
    
    // MARK: - Score Recalculation
    enum ScoreRecalc {
        static let title = "Score Recalculation & Testing"  /// Section title
        static let forceRecalcRecovery = "Force Recalculate Recovery"  /// Recovery button
        static let forceRecalcStrain = "Force Recalculate Strain/Load"  /// Strain button
        static let forceRecalcSleep = "Force Recalculate Sleep"  /// Sleep button
        static let info = "These buttons ignore the daily calculation limit and force immediate recalculation using the latest HealthKit data."  /// Info message
        static let usefulFor = "Useful for testing HealthKit-only mode without Intervals.icu connection."  /// Useful for message
        static let onboardingStatus = "Onboarding Status"  /// Onboarding status label
        static let completed = "Completed"  /// Completed status
        static let notCompleted = "Not Completed"  /// Not completed status
        static let resetOnboarding = "Reset Onboarding"  /// Reset button
        static let done = "Done"  /// Done badge
        static let footer = "Force recalculation bypasses the once-per-day limit. Perfect for testing HealthKit-only mode and algorithm changes."  /// Footer
    }
    
    // MARK: - Strava
    enum Strava {
        static let title = "Strava"  /// Strava title
        static let connected = "Connected"  /// Connected status
        static let notConnected = "Not Connected"  /// Not connected status
        static let athleteID = "Athlete ID"  /// Athlete ID label
        static let signOut = "Sign Out from Strava"  /// Sign out button
    }
    
    // MARK: - Intervals API Debug
    enum IntervalsAPI {
        static let noAthleteData = "No athlete data loaded"  /// No athlete data message
        static let powerZones = "Power Zones"  /// Power zones section
        static let heartRateZones = "Heart Rate Zones"  /// HR zones section
        static let boundary = "Boundary"  /// Boundary label
        static let powerZonesNil = "❌ Power zones are NIL"  /// Power zones nil message
        static let hrZonesNil = "❌ Heart rate zones are NIL"  /// HR zones nil message
        static let recentActivities = "Recent Activities (5)"  /// Recent activities section
        static let noActivities = "No activities loaded"  /// No activities message
        static let rawJSON = "Raw JSON Responses"  /// Raw JSON section
        static let athleteProfileJSON = "Athlete Profile JSON"  /// Athlete profile JSON label
        static let activitiesJSON = "Activities JSON (first 1000 chars)"  /// Activities JSON label
    }
    
    // MARK: - Sport Preferences Debug
    enum SportPreferences {
        static let primarySport = "Primary Sport:"  /// Primary sport label
        static let testOutput = "Test Output"  /// Test output section
        static let technicalDetails = "Technical Details"  /// Technical details section
        static let codable = "Codable: ✅"  /// Codable status
        static let equatable = "Equatable: ✅"  /// Equatable status
        static let savedTo = "Saved to: UserDefaults"  /// Saved to label
        static let syncedTo = "Synced to: iCloud"  /// Synced to label
        static let key = "Key: UserSettings.sportPreferences"  /// Key label
    }
    
    // MARK: - ML Debug
    enum MLDebug {
        static let testOutput = "Test Output"  /// Test output section
        static let technicalDetails = "Technical Details"  /// Technical details section
    }
    
    // MARK: - Debug Today
    enum DebugToday {
        static let testOutput = "Test Output"  /// Test output section
    }
    
    // MARK: - Telemetry
    enum Telemetry {
        static let testOutput = "Test Output"  /// Test output section
    }
}
