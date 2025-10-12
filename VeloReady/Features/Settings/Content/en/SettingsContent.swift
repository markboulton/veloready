import Foundation

/// Content strings for Settings feature
enum SettingsContent {
    // MARK: - Navigation
    static let title = "Settings"  /// Navigation title
    
    // MARK: - Sections
    static let profileSection = "Profile"  /// Profile section
    static let sleepSection = "Sleep"  /// Sleep section
    static let trainingSection = "Training"  /// Training section
    static let displaySection = "Display"  /// Display section
    static let notificationsSection = "Notifications"  /// Notifications section
    static let aboutSection = "About"  /// About section
    static let debugSection = "Debug & Testing"  /// Debug section (DEBUG only)
    
    // MARK: - Profile
    enum Profile {
        static let user = "RideReady User"  /// Default user name
        static let tagline = "Cycling Performance Tracker"  /// App tagline
    }
    
    // MARK: - Sleep Settings
    enum Sleep {
        static let title = "Sleep Settings"  /// Sleep settings title
        static let targetTitle = "Sleep Target"  /// Sleep target title
        static let targetDescription = "Set your ideal sleep duration. This affects your sleep score calculation."  /// Target description
        static let hoursLabel = "Hours:"  /// Hours label
        static let minutesLabel = "Minutes:"  /// Minutes label
        static let totalLabel = "Total:"  /// Total label
        static let componentsTitle = "Sleep Score Components"  /// Components title
        static let componentsDescription = "Your sleep score is calculated using these weighted components from your Apple Health data."  /// Components description
    }
    
    // MARK: - Training Zones
    enum TrainingZones {
        static let title = "HR and Power Zones"  /// Training zones title
        static let subtitle = "Sync from Intervals.icu"  /// Subtitle
        static let description = "Sync your heart rate and power zones from Intervals.icu for training analysis."  /// Description
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
    }
    
    // MARK: - About
    enum About {
        static let title = "About RideReady"  /// About title
        static let version = "Version 1.0.0"  /// Version string
        static let helpTitle = "Help & Support"  /// Help title
        static let helpDescription = "Get help and report issues"  /// Help description
    }
    
    // MARK: - Debug (DEBUG only)
    enum Debug {
        static let title = "Debug & Testing"  /// Debug title
        static let description = "These options are only available in debug builds for testing Pro features."  /// Debug description
        static let enablePro = "Enable Pro Features (Testing)"  /// Enable Pro toggle
        static let proUnlocked = "✅ All Pro features unlocked for testing"  /// Pro unlocked message
        static let subscriptionStatus = "Subscription Status:"  /// Subscription status label
        static let trialDaysRemaining = "Trial Days Remaining:"  /// Trial days label
        static let statusFree = "Free"  /// Free status
        static let statusPro = "Pro"  /// Pro status
    }
}
