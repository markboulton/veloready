import Foundation

/// Content strings for Settings feature
enum SettingsContent {
    // MARK: - Navigation
    static let title = "Settings"  /// Navigation title
    
    // MARK: - Sections
    static let profileSection = "Profile"  /// Profile section
    static let sleepSection = "Sleep"  /// Sleep section
    static let trainingSection = "Training"  /// Training section
    static let personalizationSection = "Personalization"  /// Personalization section
    static let integrationsSection = "Integrations"  /// Integrations section
    static let appearanceSection = "Appearance"  /// Appearance section
    static let displaySection = "Display"  /// Display section
    static let notificationsSection = "Notifications"  /// Notifications section
    static let dataSyncSection = "Data & Sync"  /// Data & Sync section
    static let accountSection = "Account"  /// Account section
    static let helpSupportSection = "Help & Support"  /// Help & Support section
    static let developerSection = "Developer"  /// Developer section
    static let aboutSection = "About"  /// About section
    static let debugSection = "DEBUG & TESTING"  /// Debug section (DEBUG only)
    
    // MARK: - Profile
    enum Profile {
        static let user = "VeloReady User"  /// Default user name
        static let tagline = "Cycling Performance Tracker"  /// App tagline
        static let tapToEdit = "Tap to edit profile"
        static let title = "Profile"
        static let name = "Name"
        static let email = "Email"
        static let weight = "Weight"
        static let height = "Height"
        static let dateOfBirth = "Date of Birth"
        static let gender = "Gender"
        static let male = "Male"
        static let female = "Female"
        static let notAuthorized = "Not Authorized"
        static let status = "Status"
        static let provides = "Provides"
        static let connectedSources = "Connected Sources"
    }
    
    // MARK: - iCloud
    enum iCloud {
        static let title = "iCloud Sync"
        static let status = "Status"
        static let lastSync = "Last Sync"
        static let lastSynced = "Last Synced"
        static let never = "Never"
        static let syncNow = "Sync Now"
        static let restoreFromCloud = "Restore from iCloud"
        static let whatSyncs = "What Syncs"
        static let userSettings = "User Settings"
        static let strengthData = "Strength Exercise Data"
        static let dailyScores = "Daily Scores"
        static let workoutMetadata = "Workout Metadata"
        static let readyToSync = "Ready to sync"  /// Ready to sync message
        static let notAvailable = "iCloud not available"  /// Not available message
        static let footer = "Automatically sync your settings, workout data, and strength exercise logs to iCloud."  /// iCloud footer
    }
    
    // MARK: - Cache
    enum Cache {
        static let statistics = "Cache Statistics"
        static let totalSize = "Total Size"
        static let itemsCached = "Items Cached"
        static let lastUpdated = "Last Updated"
        static let clearAll = "Clear All Caches"
        static let hitRate = "Hit Rate"
        static let cacheHits = "Cache Hits"
        static let cacheMisses = "Cache Misses"
        static let deduplicated = "Deduplicated"
        static let targetHitRate = "Target: >85% hit rate after warm-up"
    }
    
    // MARK: - Feedback
    enum Feedback {
        static let title = "Send Feedback"
        static let type = "Feedback Type"
        static let bugReport = "Bug Report"
        static let featureRequest = "Feature Request"
        static let general = "General Feedback"
        static let yourFeedback = "Your Feedback"
        static let send = "Send"
        static let sendFeedback = "Send Feedback"
        static let includeLogs = "Include diagnostic logs"
        static let includeDeviceInfo = "Include device information"
        static let logsFooter = "Logs help us diagnose issues faster. No personal data is included."
        static let deviceInfo = "Device Information"
        static let navigationTitle = "Send Feedback"
        static let cancel = "Cancel"
        static let subject = "VeloReady Feedback"
        static let mailNotAvailable = "Mail Not Available"
        static let ok = "OK"
        static let mailNotAvailableMessage = "Please configure a mail account in Settings or email us at support@veloready.app"
        static let feedbackSent = "Feedback Sent"
        static let thankYou = "Thank you for your feedback!"
        static let describeIssue = "Describe your issue or suggestion..."
        static let subtitle = "Report issues or suggest improvements"
        static let footer = "Send feedback, report bugs, or get help. Your feedback includes diagnostic logs to help us resolve issues faster."  /// Feedback footer
    }
    
    // MARK: - About
    enum About {
        static let title = "About"
        static let version = "Version"
        static let build = "Build"
        static let privacyPolicy = "Privacy Policy"
        static let termsOfService = "Terms of Service"
        static let acknowledgments = "Acknowledgments"
        static let helpTitle = "Help & Support"  /// Help title
        static let helpDescription = "Get help and report issues"  /// Help description
    }
    
    // MARK: - Debug
    enum Debug {
        static let title = "Debug"
        static let subtitle = "Developer tools and diagnostics"
        static let clearCache = "Clear Cache"
        static let resetData = "Reset Data"
        static let showDebugInfo = "Show Debug Info"
        static let developerFooter = "Developer tools for testing and diagnostics"  /// Developer footer
        static let deviceIdPrefix = "Device ID: "  /// Device ID prefix
    }
    
    // MARK: - Appearance
    enum Appearance {
        static let title = "Appearance"
        static let displayPreferences = "Display Preferences"
        static let theme = "Theme"
        static let light = "Light"
        static let dark = "Dark"
        static let automatic = "Automatic"
        static let unitsTimeFormat = "Units & time format"  /// Units and time format subtitle
        static let footer = "Customize the app's appearance and display settings"  /// Appearance footer
    }
    
    // MARK: - Sleep Settings
    enum Sleep {
        static let title = "Sleep Settings"  /// Sleep settings title
        static let targetTitle = "Sleep Target"  /// Sleep target title
        static let targetDescription = "Set your ideal sleep duration. This affects your sleep score calculation."  /// Target description
        static let footer = "Configure your sleep preferences and targets for better recovery tracking."
        static let hoursLabel = "Hours:"  /// Hours label
        static let minutesLabel = "Minutes:"  /// Minutes label
        static let totalLabel = "Total:"  /// Total label
        static let componentsTitle = "Sleep Score Components"  /// Components title
        static let componentsDescription = "Your sleep score is calculated using these weighted components from your Apple Health data."  /// Components description
    }
    
    // MARK: - Training Zones
    enum TrainingZones {
        // Adaptive Zones (PRO)
        static let adaptiveZonesTitle = "Adaptive Zones"
        static let adaptiveZonesSubtitle = "Adaptive FTP, W', VO2max & Zones"
        static let adaptiveZonesFooter = "Adaptive Zones uses sports science to compute your FTP, W', and training zones from your performance data."
        
        // Standard Zones (FREE)
        static let title = "HR and Power Zones"  /// Training zones title
        static let subtitle = "Sync from Intervals.icu"  /// Subtitle
        static let description = "Sync your heart rate and power zones from Intervals.icu for training analysis."  /// Description
        static let standardZonesSubtitle = "Coggan zones based on FTP and Max HR"
        static let standardZonesFooter = "Set your FTP and Max HR to generate Coggan training zones. Upgrade to PRO for adaptive zones computed from your performance data."
        
        static let intervalsSync = "Intervals.icu Zones"  /// Intervals sync title
        static let syncButton = "Sync Zones"  /// Sync button
        static let syncDescription = "Tap 'Sync Zones' to import your zones from Intervals.icu"  /// Sync description
        static let athleteLabel = "Athlete:"  /// Athlete label
        static let ftpLabel = "FTP:"  /// FTP label
        static let maxHRLabel = "Max HR:"  /// Max HR label
        static let lastSyncLabel = "Last synced:"  /// Last sync label
        static let currentBoundaries = "Current Zone Boundaries"  /// Current boundaries title
        static let heartRateZones = "Heart Rate Zones:"  /// HR zones label
        static let powerZones = "Power Zones:"  /// Power zones label
        static let zoneLabel = "Zone"  /// Zone label prefix
        static let heartRateZonesTitle = "Heart Rate Zones"  /// HR zones section title
        static let heartRateZonesDescription = "Set your heart rate zone boundaries. These can be imported from Intervals.icu."  /// HR zones description
        static let powerZonesTitle = "Power Zones"  /// Power zones section title
        static let powerZonesDescription = "Set your power zone boundaries. These can be imported from Intervals.icu."  /// Power zones description
        static let zoneSource = "Zone Source"
        static let intervals = "Intervals.icu"
        static let manual = "Manual"
        static let coggan = "Coggan"
        static let zoneConfiguration = "Zone Configuration"
        static let cogganParameters = "Coggan Zone Parameters"
        static let cogganDescription = "Zones will be calculated using standard Coggan percentages from these values."
        static let heartRateZonesLabel = "Heart Rate Zones:"
        static let powerZonesLabel = "Power Zones:"
        static let zone = "Zone"
        static let zone1Max = "Zone 1 Max:"
        static let zone2Max = "Zone 2 Max:"
        static let zone3Max = "Zone 3 Max:"
        static let zone4Max = "Zone 4 Max:"
        static let zone5Max = "Zone 5 Max:"
        static let syncZones = "Sync Zones"
        static let tapSyncMessage = "Tap 'Sync Zones' to import your zones from Intervals.icu"
        static let lastSynced = "Last synced:"
        static let sourceIntervals = "Source: Intervals.icu"
        static let sourceManual = "Source: Manual"
        static let sourceComputed = "Source: Computed"
    }
    
    // MARK: - Display Settings
    enum Display {
        static let title = "Display Preferences"  /// Display title
        static let subtitle = "Units, time format, and visibility"  /// Subtitle
        static let description = "Customize how information is displayed in the app."  /// Description
        static let visibilityTitle = "Visibility"  /// Visibility section
        static let visibilityDescription = "Choose which metrics to display on the main screen."  /// Visibility description
        static let showSleepScore = "Show Sleep Score"  /// Show sleep score toggle
        static let showRecoveryScore = "Show Recovery Score"  /// Show recovery score toggle
        static let showHealthData = "Show Health Data"  /// Show health data toggle
        static let unitsTitle = "Units & Format"  /// Units section
        static let unitsDescription = "Configure how measurements and time are displayed."  /// Units description
        static let metricUnits = "Metric Units"  /// Metric units toggle
        static let use24Hour = "24-Hour Time"  /// 24-hour time toggle
        static let calorieGoalsTitle = "Calorie Goals"  /// Calorie goals section
        static let calorieGoalsDescription = "Set your daily calorie goal. Use BMR (Basal Metabolic Rate) or set a custom target."  /// Calorie goals description
        static let useBMR = "Use BMR as Calorie Goal"  /// Use BMR toggle
        static let dailyGoal = "Daily Calorie Goal"  /// Daily goal label
        static let caloriesLabel = "Calories:"  /// Calories label
    }
    
    // MARK: - Notifications
    enum Notifications {
        static let title = "Notifications"  /// Notifications title
        static let subtitle = "Sleep reminders and recovery alerts"  /// Subtitle
        static let description = "Manage sleep reminders and recovery notifications."  /// Description
        static let sleepReminders = "Sleep Reminders"  /// Sleep reminders toggle
        static let sleepRemindersDescription = "Get reminded when it's time to wind down for bed."  /// Sleep reminders description
        static let reminderTime = "Reminder Time"  /// Reminder time label
        static let recoveryAlerts = "Recovery Alerts"  /// Recovery alerts toggle
        static let recoveryAlertsDescription = "Get notified when your recovery score indicates you should rest."  /// Recovery alerts description
        static let permission = "Notification Permission"
        static let enable = "Enable"
        static let permissionFooter = "VeloReady needs notification permission to send reminders and alerts. Tap Enable to grant permission."
        static let permissionDenied = "Permission Denied"
        static let openSettings = "Open Settings"
        static let permissionDeniedMessage = "Notification permission was denied. You can enable it in Settings > VeloReady > Notifications."
    }
    
    // MARK: - Athlete Zones
    enum AthleteZones {
        static let ftp = "FTP"  /// FTP label
        static let maxHR = "Max HR"  /// Max HR label
        static let computedFromData = "Computed from performance data"  /// Computed message
        static let athlete = "Athlete:"  /// Athlete label
        static let unknownAthlete = "Unknown"  /// Unknown athlete
    }
    
    // MARK: - Debug Settings
    enum DebugSettings {
        static let proFeaturesUnlocked = " All Pro features unlocked for testing"  /// Pro unlocked message
        static let mockDataEnabled = " Mock data enabled for weekly trend charts"  /// Mock data message
        static let subscriptionStatus = "Subscription Status:"  /// Subscription status label
        static let trialDaysRemaining = "Trial Days Remaining:"  /// Trial days label
        static let pro = "Pro"  /// Pro status
        static let free = "Free"  /// Free status
    }
    
    // MARK: - Sleep Components
    enum SleepComponents {
        static let performance = "Performance"  /// Performance component
        static let efficiency = "Efficiency"  /// Efficiency component
        static let stageQuality = "Stage Quality"  /// Stage quality component
        static let disturbances = "Disturbances"  /// Disturbances component
        static let timing = "Timing"  /// Timing component
        static let latency = "Latency"  /// Latency component
        static let scoreCalculation = "Score Calculation"  /// Score calculation header
    }
    
    
    // MARK: - Data Sources
    enum DataSources {
        static let title = "Data Sources"  /// Data sources title
        static let subtitle = "Manage connected apps and services"  /// Subtitle
        static let intervalsConnected = "Connected to Intervals.icu"  /// Intervals connected
        static let stravaConnected = "Connected to Strava"  /// Strava connected
        static let healthKitEnabled = "HealthKit Enabled"  /// HealthKit enabled
        static let connect = CommonContent.Actions.connect
        static let disconnect = CommonContent.Actions.disconnect
        static let reconnect = CommonContent.Actions.reconnect
        static let status = "Status"  /// Status label
    }
    
    // MARK: - iCloud
    enum iCloudSettings {
        static let title = "iCloud Sync"  /// iCloud title
        static let enabled = "iCloud sync enabled"  /// Enabled message
        static let disabled = "iCloud sync disabled"  /// Disabled message
        static let syncNow = "Sync Now"  /// Sync now button
        static let lastSync = CommonContent.Labels.lastSynced
        static let restore = "Restore from iCloud"  /// Restore button
        static let footer = "Automatically sync your settings, workout data, and strength exercise logs to iCloud."  /// Footer
    }
    
    // MARK: - ML Personalization
    enum MLPersonalization {
        static let title = "ML Personalization"  /// ML title
        static let enabled = CommonContent.States.enabled
        static let disabled = CommonContent.States.disabled
        static let dataCollected = "Data collected:"  /// Data collected label
        static let days = CommonContent.TimeUnits.days
        static let footer = "Machine learning personalization for more accurate recovery predictions"  /// Footer
    }
    
    enum MLPersonalizationSettings {
        static let title = "ML Personalization"  /// ML title
        static let enabled = CommonContent.States.enabled
        static let disabled = CommonContent.States.disabled
        static let dataCollected = "Data collected:"  /// Data collected label
        static let days = CommonContent.TimeUnits.days
        static let footer = "Machine learning personalization for more accurate recovery predictions"  /// Footer
    }
    
    // MARK: - Feedback
    enum FeedbackSettings {
        static let title = "Feedback"  /// Feedback title
        static let subtitle = "Report issues or suggest improvements"  /// Subtitle
        static let sendFeedback = "Send Feedback"  /// Send button
        static let reportBug = "Report Bug"  /// Report bug button
        static let requestFeature = "Request Feature"  /// Request feature button
        static let footer = "Send feedback, report bugs, or get help. Your feedback includes diagnostic logs to help us resolve issues faster."  /// Footer
    }
    
    // MARK: - About
    enum AboutSettings {
        static let title = "About VeloReady"  /// About title
        static let version = CommonContent.Labels.version
        static let build = CommonContent.Labels.build
        static let privacyPolicy = "Privacy Policy"  /// Privacy policy
        static let termsOfService = "Terms of Service"  /// Terms of service
        static let licenses = "Open Source Licenses"  /// Licenses
        static let helpTitle = "Help & Support"  /// Help title
        static let helpDescription = "Get help and report issues"  /// Help description
    }
    
    // MARK: - Account
    enum Account {
        static let signOut = "Sign Out from Intervals.icu"  /// Sign out button
        static let signOutSubtitle = "Disconnect your account and remove access"  /// Sign out subtitle
        static let deleteData = "Delete All Local Data"  /// Delete data button
        static let deleteDataTitle = "Delete All Data"  /// Delete data title
        static let deleteDataMessage = "This will delete all cached activities, scores, and metrics from this device. This action cannot be undone. Your data on connected services will not be affected."  /// Delete message
        static let deleteDataFooter = "Delete all cached activities, metrics, and scores from this device. Your data on connected services will not be affected."  /// Delete footer
        static let delete = CommonContent.Actions.delete
    }
}
