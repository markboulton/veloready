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
        static let bmr = "BMR"  /// Basal Metabolic Rate
        static let athleticProfile = "Athletic Profile"  /// Athletic profile section
        static let editProfile = "Edit Profile"  /// Edit profile title
        static let editProfileLabel = "Edit Profile"  /// Edit profile label
        static let age = "Age"  /// Age label
        static let namePlaceholder = "Name"  /// Name placeholder
        static let emailPlaceholder = "Email"  /// Email placeholder
        static let strava = "Strava"  /// Strava label
        static let noConnectedServices = "No connected services"  /// No services message
        static let connectedServicesSection = "Connected Services"  /// Connected services section
        static let connectedServicesFooter = "Connect services in Data Sources settings to sync your activities and metrics."  /// Connected services footer
        static let navigationTitle = "Profile"  /// Navigation title
        static let personalInformation = "Personal Information"  /// Personal info section
        static let personalInfoFooter = "This information is stored locally on your device."  /// Personal info footer
        static let athleticInfoFooter = "Used for calculating BMR and other metrics."  /// Athletic info footer
        static let connectedServicesEditFooter = "Connect services in Data Sources settings."  /// Edit footer
        static let editNavigationTitle = "Edit Profile"  /// Edit navigation title
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
        static let notAvailable = "Not Available"  /// Not available status
        static let footer = "Automatically sync your settings, workout data, and strength exercise logs to iCloud."  /// iCloud footer
        static let autoSyncDescription = "iCloud automatically syncs your settings, workout data, and strength exercise logs across all your devices."  /// Auto sync description
        static let actions = "Actions"  /// Actions section header
        static let actionsFooter = "Manually sync your data to iCloud or restore from your iCloud backup."  /// Actions footer
        static let encryptionFooter = "All data is encrypted and stored securely in your private iCloud account."  /// Encryption footer
        static let syncError = "Sync Error"  /// Sync error label
        
        // Not Available Section
        static let notAvailableTitle = "iCloud Not Available"  /// Not available title
        static let enableInstructions = "To enable iCloud sync:"  /// Enable instructions
        static let step1 = "1. Open Settings app"  /// Step 1
        static let step2 = "2. Tap your name at the top"  /// Step 2
        static let step3 = "3. Tap iCloud"  /// Step 3
        static let step4 = "4. Enable iCloud Drive"  /// Step 4
        static let step5 = "5. Ensure VeloReady has iCloud access"  /// Step 5
        
        // Alerts
        static let restoreConfirmMessage = "This will replace your current local data with data from iCloud. Your current data will be overwritten. Are you sure?"  /// Restore confirmation
        static let restoreSuccessTitle = "Restore Successful"  /// Restore success title
        static let restoreSuccessMessage = "Your data has been successfully restored from iCloud."  /// Restore success message
        static let restoreFailedTitle = "Restore Failed"  /// Restore failed title
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
        static let clearMessage = "This will clear all cached data. The app will re-fetch data as needed."  /// Clear cache message
        
        // Stream Cache
        static let streamCache = "Stream Cache"  /// Stream cache section
        static let totalActivities = "Total Activities"  /// Total activities label
        static let totalSamples = "Total Samples"  /// Total samples label
        
        // Performance
        static let performanceMetrics = "Performance Metrics"  /// Performance section
        static let avgLabel = "Avg"  /// Average label
        static let p95Label = "P95"  /// P95 label
        static let countLabel = "Count"  /// Count label
        static let msUnit = "ms"  /// Milliseconds unit
        
        // Memory
        static let memory = "Memory"  /// Memory section
        static let appMemory = "App Memory"  /// App memory label
        static let cacheLimit = "Cache Limit"  /// Cache limit label
        static let cacheLimitValue = "50 MB"  /// Cache limit value
        static let cacheEntries = "Cache Entries"  /// Cache entries label
        static let cacheEntriesValue = "200 max"  /// Cache entries value
        
        // Actions
        static let printStats = "Print Stats to Console"  /// Print stats button
        static let resetStats = "Reset Statistics"  /// Reset stats button
        static let cancel = "Cancel"  /// Cancel button
        static let clear = "Clear"  /// Clear button
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
        
        // Zone Source Descriptions
        static let intervalsDescription = "Sync zones from Intervals.icu. Tap 'Sync Zones' above to import."
        static let manualDescription = "Edit zone boundaries manually below."
        static let cogganDescriptionShort = "Use standard Coggan zones. Set your FTP and Max HR below."
        
        // Picker Labels
        static let zoneSourcePicker = "Zone Source"  /// Picker accessibility label
        
        // TextField Placeholders
        static let ftpPlaceholder = "FTP"  /// FTP placeholder
        static let maxHRPlaceholder = "Max HR"  /// Max HR placeholder
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
        static let title = "Athlete Zones"  /// Athlete zones title
        static let subtitle = "Power and heart rate zones"  /// Subtitle
        static let athleteProfile = "Athlete Profile"  /// Athlete profile title
        static let athlete = "Athlete:"  /// Athlete label
        static let unknownAthlete = "Unknown"  /// Unknown athlete
        static let ftp = "FTP"  /// FTP label
        static let maxHR = "Max HR"  /// Max HR label
        static let save = "Save"  /// Save button
        static let cancel = "Cancel"  /// Cancel button
        static let edit = "Edit"  /// Edit button
        static let zone = "Zone"  /// Zone label
        static let max = "Max"  /// Max label
        static let computedFromData = "Computed from your performance data"  /// Computed from data
        static let powerAdaptiveFooter = "Zones anchored to FTP detected from sustained efforts. Automatically updates as your fitness changes."  /// Power adaptive footer
        static let hrAdaptiveFooter = "Zones anchored to lactate threshold detected from sustained efforts. Automatically updates as your fitness changes."  /// HR adaptive footer
        
        // Zone Sources
        static let coggan = "Coggan"  /// Coggan zones
        static let manual = "Manual"  /// Manual zones
        static let adaptive = "Adaptive"  /// Adaptive zones
        static let zoneSource = "Zone Source"  /// Zone source label
        static let powerSource = "Power Source"  /// Power source label
        static let hrSource = "HR Source"  /// HR source label
        static let heartRateTrainingZones = "Heart Rate Training Zones"  /// HR zones title
        static let powerTrainingZones = "Power Training Zones"  /// Power zones title
        
        // Units
        static let watts = "W"  /// Watts unit
        static let bpm = "bpm"  /// BPM unit
        static let dash = "-"  /// Dash separator
        
        // Zone descriptions
        static let zonesAnchored = "Zones anchored to lactate threshold"  /// Zones anchored description
        static let detectedFrom = "detected from sustained efforts."  /// Detected from description
        static let noHRZones = "No HR zones available"  /// No HR zones message
        static let noPowerZones = "No power zones available"  /// No power zones message
        
        // Actions
        static let resetToAdaptive = "Reset to Adaptive Zones"  /// Reset button
        static let resetConfirmTitle = "Reset to Adaptive Zones?"  /// Reset confirmation title
        static let resetConfirmMessage = "This will reset your zones to adaptive computation based on your performance data."  /// Reset confirmation message
        
        // Zone sources
        static let intervals = "Intervals"  /// Intervals source
        
        // Footer messages
        static let freeFooter = "FREE tier: Edit FTP and Max HR to adjust your Coggan zones. Upgrade to PRO for adaptive zones computed from your performance data."  /// Free tier footer
        static let adaptiveFooter = "Adaptive zones are computed from your performance data using modern sports science algorithms. Values update automatically as your fitness changes."  /// Adaptive footer
        static let cogganFooter = "Coggan zones use the standard 7-zone model. Edit FTP or Max HR above to adjust all zones proportionally."  /// Coggan footer
        static let manualFooter = "Manual mode allows full control. Edit FTP, Max HR, and individual zone boundaries."  /// Manual footer
        static let legacyFooter = "Legacy mode - switch to Coggan or Manual for better control."  /// Legacy footer
        static let hrCogganFooter = "Standard Coggan 7-zone model based on Max HR. Zones update automatically when you change Max HR."  /// HR Coggan footer
        static let hrManualFooter = "Tap any zone boundary to edit. Changes are saved automatically."  /// HR manual footer
        static let hrLegacyFooter = "Legacy mode - switch to Coggan or Manual to customize zones."  /// HR legacy footer
        static let powerCogganFooter = "Standard Coggan 7-zone model based on FTP. Zones update automatically when you change FTP."  /// Power Coggan footer
        static let powerManualFooter = "Tap any zone boundary to edit. Changes are saved automatically."  /// Power manual footer
        static let powerLegacyFooter = "Legacy mode - switch to Coggan or Manual to customize zones."  /// Power legacy footer
        
        // Zone Names - Power
        static let powerZone1 = "Active Recovery"  /// Power Zone 1
        static let powerZone2 = "Endurance"  /// Power Zone 2
        static let powerZone3 = "Tempo"  /// Power Zone 3
        static let powerZone4 = "Lactate Threshold"  /// Power Zone 4
        static let powerZone5 = "VO2 Max"  /// Power Zone 5
        static let powerZone6 = "Anaerobic"  /// Power Zone 6
        static let powerZone7 = "Neuromuscular"  /// Power Zone 7
        
        // Zone Names - Heart Rate
        static let hrZone1 = "Recovery"  /// HR Zone 1
        static let hrZone2 = "Aerobic"  /// HR Zone 2
        static let hrZone3 = "Tempo"  /// HR Zone 3
        static let hrZone4 = "Lactate Threshold"  /// HR Zone 4
        static let hrZone5 = "VO2 Max"  /// HR Zone 5
        static let hrZone6 = "Anaerobic"  /// HR Zone 6
        static let hrZone7 = "Maximum"  /// HR Zone 7
    }
    
    // MARK: - Debug Settings
    enum DebugSettings {
        static let proFeaturesUnlocked = " All Pro features unlocked for testing"  /// Pro unlocked message
        static let mockDataEnabled = " Mock data enabled for weekly trend charts"  /// Mock data message
        static let subscriptionStatus = "Subscription Status:"  /// Subscription status label
        static let trialDaysRemaining = "Trial Days Remaining:"  /// Trial days label
        static let pro = "Pro"  /// Pro status
        static let free = "Free"  /// Free status
        static let enableProTesting = "Enable Pro Features (Testing)"  /// Enable pro testing toggle
        static let showMockData = "Show Mock Data (Weekly Trends)"  /// Show mock data toggle
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
        
        // Percentages
        static let performancePercent = "40%"  /// Performance weight
        static let efficiencyPercent = "15%"  /// Efficiency weight
        static let stageQualityPercent = "20%"  /// Stage quality weight
        static let disturbancesPercent = "10%"  /// Disturbances weight
        static let timingPercent = "10%"  /// Timing weight
        static let latencyPercent = "5%"  /// Latency weight
    }
    
    // MARK: - Data Sources
    enum DataSources {
        static let title = "Data Sources"  /// Data sources title
        static let subtitle = "Connect your training platforms"  /// Subtitle
        static let connect = CommonContent.Actions.connect
        static let disconnect = CommonContent.Actions.disconnect
        static let reconnect = CommonContent.Actions.reconnect
        static let status = "Status"  /// Status label
        static let provides = "Provides"  /// Provides label
        static let overview = "Overview"  /// Overview section
        static let connectWarning = "Connect at least one activity source to track your rides"  /// Connect warning
        static let dataPriority = "Data Priority"  /// Data priority title
        static let priorityDescription = "When multiple sources provide the same data, the higher priority source will be used."  /// Priority description
        static let priorityOrder = "Priority Order"  /// Priority order section
        static let priorityFooter = "When multiple sources provide the same data, VeloReady uses the highest priority source. For example, if both Intervals.icu and Strava have today's ride, the Intervals.icu version will be used because it includes power analysis and training metrics. Drag to reorder (coming soon)."  /// Priority footer
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
        static let description = "Uses machine learning to personalize your recovery score based on your unique patterns"  /// Description
        static let statusSection = "Status"  /// Status section
        static let trainingData = "Training Data"  /// Training data label
        static let modelStatus = "Model Status"  /// Model status label
        static let ready = "Ready"  /// Ready status
        static let notReady = "Not Ready"  /// Not ready status
        static let daysUntilReady = "Days Until Ready"  /// Days until ready label
        static let howItWorks = "How It Works"  /// How it works section
        static let howItWorksDescription = "Personalized recovery uses machine learning trained on YOUR data to provide more accurate recovery predictions."  /// How it works description
        static let requires30Days = "• Requires 30 days of data"  /// Requires 30 days
        static let learnsPatterns = "• Learns your unique patterns"  /// Learns patterns
        static let updatesWeekly = "• Updates weekly"  /// Updates weekly
        static let fallbackStandard = "• Falls back to standard if unavailable"  /// Fallback standard
        static let personalizedRecovery = "Personalized Recovery"  /// Personalized recovery toggle
        static let mlPersonalizationHeader = "ML Personalization"  /// ML personalization header label
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
    
    // MARK: - Theme
    enum Theme {
        static let title = "Theme"  /// Theme settings title
        static let appearance = "Appearance"  /// Appearance section header
        static let footer = "Choose how VeloReady looks. Auto matches your device's appearance settings."  /// Theme footer
    }
    
    // MARK: - Monitoring
    enum Monitoring {
        static let dashboards = "Monitoring Dashboards"  /// Monitoring section
        static let cacheStats = "Cache Statistics"  /// Cache stats link
    }
    
    // MARK: - Ride Summary
    enum RideSummary {
        static let status = "Ride Summary Status"  /// Status label
        static let loading = "Loading..."  /// Loading state
        static let loaded = "Summary loaded"  /// Loaded state
        static let notLoaded = "Not loaded"  /// Not loaded state
        static let error = "Error:"  /// Error prefix
        static let clearCache = "Clear Ride Summary Cache"  /// Clear cache button
        static let copyResponse = "Copy Last Response JSON"  /// Copy response button
        static let configureSecret = "Configure HMAC Secret"  /// Configure secret button
        static let overrideUser = "Override User ID"  /// Override user button
        static let sectionTitle = "AI Ride Summary"  /// Section title
        static let footer = "Test AI ride summary endpoint. PRO feature. Uses same HMAC secret as Daily Brief."  /// Section footer
        static let overrideUserNavigationTitle = "Override User ID"  /// Override user ID navigation title
        
        // User Override View
        static let userIDOverrideHeader = "User ID Override"  /// User ID override section header
        static let userIDOverrideFooter = "Override the X-User header for testing different user accounts. This affects both AI Brief and Ride Summary."  /// User ID override footer
        static let currentValuesHeader = "Current Values"  /// Current values section header
        static let currentValuesFooter = "'Current User ID' is what will be sent in requests. 'Actual User ID' is the device's anonymous ID."  /// Current values footer
        static let currentUserID = "Current User ID"  /// Current user ID label
        static let actualUserID = "Actual User ID"  /// Actual user ID label
        static let resetToDefault = "Reset to Default"  /// Reset to default button
        static let overrideUserIDToggle = "Override User ID"  /// Override user ID toggle
        static let saveOverride = "Save Override"  /// Save override button
        static let overrideSaved = "Override saved"  /// Override saved message
        static let userIDPlaceholder = "User ID"  /// User ID placeholder
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
    
    // MARK: - OAuth Actions
    enum OAuthActions {
        static let title = "OAuth Actions"  /// Section title
        static let intervalsICU = "Intervals.icu"  /// Intervals.icu label
        static let strava = "Strava"  /// Strava label
        static let signOut = "Sign Out from Intervals.icu"  /// Sign out button
        static let signOutStrava = "Sign Out from Strava"  /// Sign out Strava button
        static let connectIntervals = "Connect to Intervals.icu"  /// Connect button
        static let status = "Status:"  /// Status label
        static let accessToken = "Access Token"  /// Access token label
        static let oauthActionsFooter = "Connect or disconnect from Intervals.icu and Strava for testing"  /// OAuth actions footer
    }
    
    // MARK: - Monitoring
    enum MonitoringDashboards {
        static let header = "Monitoring"  /// Monitoring section header
        static let footer = "Real-time monitoring of app services and component usage"  /// Monitoring footer
        static let serviceHealth = "Service Health"  /// Service health title
        static let serviceHealthDesc = "Monitor service status and connections"  /// Service health description
        static let componentTelemetry = "Component Telemetry"  /// Component telemetry title
        static let componentTelemetryDesc = "Track component usage statistics"  /// Component telemetry description
        static let sportPreferences = "Sport Preferences"  /// Sport preferences title
        static let sportPreferencesDesc = "Test sport preferences and AI integration"  /// Sport preferences description
        static let cacheStatistics = "Cache Statistics"  /// Cache statistics title
        static let cacheStatisticsDesc = "Monitor cache performance and hit rates"  /// Cache statistics description
        static let mlInfrastructure = "ML Infrastructure"  /// ML infrastructure title
        static let mlInfrastructureDesc = "Machine learning data and model status"  /// ML infrastructure description
        static let appGroupTest = "App Group Test"  /// App group test title
        static let appGroupTestDesc = "Test widget data sharing"  /// App group test description
    }
}


