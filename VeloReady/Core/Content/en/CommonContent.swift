import Foundation

/// Common strings shared across the app
enum CommonContent {
    // MARK: - Actions
    enum Actions {
        static let close = "Close"  /// Close button
        static let done = "Done"  /// Done button
        static let cancel = "Cancel"  /// Cancel button
        static let save = "Save"  /// Save button
        static let delete = "Delete"  /// Delete button
        static let edit = "Edit"  /// Edit button
        static let refresh = "Refresh"  /// Refresh button
        static let retry = "Retry"  /// Retry button
        static let ok = "OK"  /// OK button
        static let yes = "Yes"  /// Yes button
        static let no = "No"  /// No button
        static let continue_ = "Continue"  /// Continue button
        static let sync = "Sync"  /// Sync button
        static let connect = "Connect"  /// Connect button
        static let disconnect = "Disconnect"  /// Disconnect button
        static let reconnect = "Reconnect"  /// Reconnect button
        static let enable = "Enable"  /// Enable button
        static let disable = "Disable"  /// Disable button
        static let viewDetails = "View Details"  /// View details button
    }
    
    // MARK: - Debug
    enum Debug {
        static let title = "App Group Debug"
        static let sectionTest = "Test App Group"
        static let sectionData = "Shared Data"
        static let buttonWrite = "Write Test Data"
        static let buttonRead = "Read Test Data"
        static let statusInitial = "Ready to test"
        static let statusFailed = "Failed"
        static let statusWriteSuccess = "Write successful"
        static let statusReadSuccess = "Read successful"
        static let statusNoData = "No data found"
        static let labelScore = "Recovery Score"
        static let labelBand = "Recovery Band"
        static let messageNoData = "No shared data available"
    }
    
    // MARK: - States
    enum States {
        static let loading = "Loading..."  /// Loading state
        static let loadingData = "Loading data..."  /// Loading data
        static let syncing = "Syncing..."  /// Syncing state
        static let analyzing = "Analyzing..."  /// Analyzing state
        static let computing = "Computing..."  /// Computing state
        static let detecting = "Detecting..."  /// Detecting state
        static let calculating = "Calculating..."  /// Calculating state
        static let defaultMessage = "Loading..."  /// Default loading message
        static let noData = "No data available"  /// Empty state
        static let notEnoughData = "Not enough data"  /// Not enough data
        static let noDataFound = "No data"  /// No data found (short)
        static let error = "Something went wrong"  /// Generic error
        static let success = "Success"  /// Success state
        static let failed = "Failed"  /// Failed state
        static let connected = "Connected"  /// Connected state
        static let disconnected = "Disconnected"  /// Disconnected state
        static let enabled = "Enabled"  /// Enabled state
        static let disabled = "Disabled"  /// Disabled state
    }
    
    // MARK: - Time
    static let today = "Today"  /// Today label
    static let yesterday = "Yesterday"  /// Yesterday label
    static let thisWeek = "This Week"  /// This week label
    static let thisMonth = "This Month"  /// This month label
    
    // MARK: - Units
    enum Units {
        static let bpm = "bpm"  /// Beats per minute
        static let watts = "W"  /// Watts
        static let hours = "h"  /// Hours
        static let minutes = "m"  /// Minutes
        static let seconds = "s"  /// Seconds
        static let percent = "%"  /// Percentage
        static let kilometers = "km"  /// Kilometers
        static let miles = "mi"  /// Miles
        static let meters = "m"  /// Meters
        static let calories = "cal"  /// Calories
        static let sleepDuration = "Sleep Duration"  /// Sleep duration metric
        static let sleepTarget = "Sleep Target"  /// Sleep target metric
        static let hrvRMSSD = "HRV RMSSD"  /// HRV RMSSD metric
        static let restingHeartRate = "Resting Heart Rate"  /// Resting heart rate metric
        static let trainingLoadRatio = "Training Load Ratio"  /// Training load ratio metric
    }
    
    // MARK: - Pro Features
    static let upgradeToPro = "Upgrade to PRO"
    static let unlockAllFeatures = "Unlock all features"
    
    // MARK: - Workout & RPE
    static let workoutDetails = "Workout Details"
    static let rateEffort = "Rate your effort and select muscle groups trained"
    static let effortLevel = "Effort Level"
    static let muscleGroupsOptional = "Muscle Groups (Optional)"
    
    enum RPE {
        static let veryLight = "1 - Very Light"
        static let maximum = "10 - Maximum"
    }
    
    // MARK: - Days of Week
    enum Days {
        static let monday = "Monday"  /// Monday
        static let tuesday = "Tuesday"  /// Tuesday
        static let wednesday = "Wednesday"  /// Wednesday
        static let thursday = "Thursday"  /// Thursday
        static let friday = "Friday"  /// Friday
        static let saturday = "Saturday"  /// Saturday
        static let sunday = "Sunday"  /// Sunday
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let average = "Avg"  /// Average abbreviation
        static let minimum = "Min"  /// Minimum abbreviation
        static let maximum = "Max"  /// Maximum abbreviation
        static let total = "Total"  /// Total label
        static let current = "Current"  /// Current label
        static let baseline = "Baseline"  /// Baseline label
        static let duration = "Duration"  /// Duration metric
        static let distance = "Distance"  /// Distance metric
        static let speed = "Speed"  /// Speed metric
        static let power = "Power"  /// Power metric
        static let heartRate = "Heart Rate"  /// Heart rate metric
        static let cadence = "Cadence"  /// Cadence metric
        static let elevation = "Elevation"  /// Elevation metric
        static let calories = "Calories"  /// Calories metric
        static let sleepDuration = "Sleep Duration"  /// Sleep duration metric
        static let sleepTarget = "Sleep Target"  /// Sleep target metric
        static let hrvRMSSD = "HRV RMSSD"  /// HRV RMSSD metric
        static let restingHeartRate = "Resting Heart Rate"  /// Resting heart rate metric
        static let trainingLoadRatio = "Training Load Ratio"  /// Training load ratio metric
    }
    
    // MARK: - Common Instructions
    enum Instructions {
        static let wearAppleWatch = "Wear Apple Watch during sleep"  /// Wear watch instruction
        static let grantPermission = "Grant permission in Settings"  /// Grant permission
        static let trackConsistently = "Track consistently for 7+ days"  /// Track consistently
        static let checkBackLater = "Check back after a few days"  /// Check back message
        static let pullToRefresh = "Pull to refresh"  /// Pull to refresh
        static let tapToEdit = "Tap to edit"  /// Tap to edit
    }
    
    // MARK: - Common Labels
    enum Labels {
        static let title = "Title"  /// Title label
        static let subtitle = "Subtitle"  /// Subtitle label
        static let description = "Description"  /// Description label
        static let status = "Status"  /// Status label
        static let lastSynced = "Last synced"  /// Last synced label
        static let lastUpdated = "Last updated"  /// Last updated label
        static let version = "Version"  /// Version label
        static let build = "Build"  /// Build label
    }
    
    // MARK: - Common Formatting
    enum Formatting {
        static let bulletPoint = "•"  /// Bullet point
        static let dash = "—"  /// Em dash
        static let separator = "·"  /// Middle dot separator
        static let ellipsis = "…"  /// Ellipsis
    }
    
    // MARK: - Time Units (Full)
    enum TimeUnits {
        static let day = "day"  /// Day (singular)
        static let days = "days"  /// Days (plural)
        static let hour = "hour"  /// Hour (singular)
        static let hours = "hours"  /// Hours (plural)
        static let minute = "minute"  /// Minute (singular)
        static let minutes = "minutes"  /// Minutes (plural)
        static let second = "second"  /// Second (singular)
        static let seconds = "seconds"  /// Seconds (plural)
        static let week = "week"  /// Week (singular)
        static let weeks = "weeks"  /// Weeks (plural)
    }
    
    // MARK: - Empty State Messages
    enum EmptyStates {
        static let noData = "No data available"  /// Generic no data
        static let notEnoughData = "Not enough data"  /// Not enough data
        static let checkBack = "Check back after a few days"  /// Check back message
        static let connectDataSource = "Connect a data source to get started"  /// Connect data source
        static let requiresSetup = "Setup required"  /// Setup required
        
        // Activities
        static let noActivities = "No Activities Yet"  /// No activities
        static let noActivitiesMessage = "Connect your data sources or sync with Apple Health to see your activities here."  /// No activities message
        static let notEnoughTrendData = "Not Enough Data"
        static let notEnoughTrendDataMessage = "We need at least 7 days of data to show trends."
        static let addActivity = "Add Activity"
        
        // Health Data
        static let healthDataUnavailable = "Health data unavailable"  /// Health data unavailable
        static let healthDataMessage = "Grant access to Apple Health to see your recovery metrics"  /// Health data message
        static let grantAccess = "Grant Access"  /// Grant access button
        
        // Wellness
        static let noWellnessData = "No Wellness Data"  /// No wellness data
        static let noWellnessDataMessage = "Connect Apple Health or another source to track sleep, HRV, and recovery"  /// No wellness message
        
        // Training Zones
        static let noTrainingZones = "No Training Zones"  /// No training zones
        static let noTrainingZonesMessage = "Connect a training platform to sync your power and heart rate zones"  /// No zones message
        
        // Sleep
        static let noSleepData = "No sleep data"  /// No sleep data
        static let noSleepDataMessage = "Wear your Apple Watch while sleeping to track sleep quality"  /// No sleep message
        
        // Recovery
        static let noRecoveryData = "No recovery data"  /// No recovery data
        static let noRecoveryDataMessage = "Complete your first workout to see recovery metrics"  /// No recovery message
    }
    
    // MARK: - Badges
    enum Badges {
        static let pro = "PRO"  /// PRO badge
        static let new = "NEW"  /// NEW badge
        static let beta = "BETA"  /// BETA badge
        static let comingSoon = "COMING SOON"  /// Coming soon badge
        static let bestValue = "BEST VALUE"  /// Best value badge
        static let popular = "POPULAR"  /// Popular badge
        static let recommended = "RECOMMENDED"  /// Recommended badge
        
        // Status Badges
        static let ready = "Ready"  /// Ready status
        static let excellent = "Excellent"  /// Excellent status
        static let good = "Good"  /// Good status
        static let fair = "Fair"  /// Fair status
        static let poor = "Poor"  /// Poor status
        static let high = "High"  /// High status
        static let moderate = "Moderate"  /// Moderate status
        static let low = "Low"  /// Low status
    }
    
    // MARK: - Data Sources
    enum DataSources {
        // Strava
        static let stravaConnect = "Connect with Strava"  /// Strava connect
        static let stravaDisconnect = "Disconnect from Strava"  /// Strava disconnect
        static let stravaConnecting = "Connecting..."  /// Strava connecting
        static let stravaName = "Strava"  /// Strava name
        
        // Intervals.icu
        static let intervalsConnect = "Connect with Intervals.icu"  /// Intervals connect
        static let intervalsDisconnect = "Disconnect from Intervals.icu"  /// Intervals disconnect
        static let intervalsName = "Intervals.icu"  /// Intervals name
    }
    
    // MARK: - Error Messages
    enum Errors {
        // Generic
        static let genericTitle = "Something went wrong"  /// Generic error title
        static let genericMessage = "Please try again later"  /// Generic error message
        static let unknownError = "An unknown error occurred"  /// Unknown error
        static let tryAgain = "Please try again"  /// Try again message
        
        // Network
        static let networkTitle = "Connection Error"  /// Network error title
        static let networkMessage = "Please check your internet connection"  /// Network error message
        static let networkUnavailable = "No internet connection"  /// Network unavailable
        static let requestFailed = "Request failed. Please try again."  /// Request failed
        static let timeout = "Request timed out"  /// Timeout error
        
        // Authentication
        static let authFailed = "Authentication failed"  /// Auth failed
        static let tokenExpired = "Session expired. Please log in again."  /// Token expired
        static let unauthorized = "Unauthorized access"  /// Unauthorized
        
        // Data
        static let dataLoadFailed = "Failed to load data"  /// Data load failed
        static let dataSaveFailed = "Failed to save data"  /// Data save failed
        static let dataNotFound = "Data not found"  /// Data not found
        static let invalidData = "Invalid data format"  /// Invalid data
        
        // HealthKit
        static let healthKitUnavailable = "Health data is not available"  /// HealthKit unavailable
        static let healthKitPermissionDenied = "Health data access denied"  /// Permission denied
        static let healthKitReadFailed = "Failed to read health data"  /// Read failed
        
        // API
        static let apiError = "API error occurred"  /// API error
        static let serverError = "Server error. Please try again later."  /// Server error
        static let rateLimitExceeded = "Too many requests. Please wait."  /// Rate limit
        
        // Sync
        static let syncFailed = "Sync failed"  /// Sync failed
        static let conflictDetected = "Data conflict detected"  /// Conflict detected
        
        // Permissions
        static let permissionTitle = "Permission Required"  /// Permission title
        static let permissionMessage = "This feature requires additional permissions"  /// Permission message
    }
    
}
