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
        static let loading = "Loading..."
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
    }
    
    // MARK: - Alerts
    enum Alerts {
        static let clearIntervalsCacheTitle = "Clear Intervals Cache?"
        static let clearIntervalsCacheMessage = "This will clear all cached Intervals.icu data from UserDefaults."
        static let clearCoreDataTitle = "Clear Core Data?"
        static let clearCoreDataMessage = "This will delete all Core Data records. The app will need to re-fetch all data."
        static let cancel = "Cancel"
        static let clear = "Clear"
    }
}
