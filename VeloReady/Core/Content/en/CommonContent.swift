import Foundation

/// Common strings shared across the app
enum CommonContent {
    // MARK: - App Info
    static let appName = "VeloReady"  /// App name
    
    // MARK: - Common Actions
    enum Actions {
        static let save = "Save"  /// Save button
        static let cancel = "Cancel"  /// Cancel button
        static let delete = "Delete"  /// Delete button
        static let edit = "Edit"  /// Edit button
        static let done = "Done"  /// Done button
        static let close = "Close"  /// Close button
        static let ok = "OK"  /// OK button
        static let confirm = "Confirm"  /// Confirm button
        static let retry = "Retry"  /// Retry button
        static let refresh = "Refresh"  /// Refresh button
        static let viewDetails = "View Details"  /// View details button
        static let learnMore = "Learn More"  /// Learn more button
        static let getStarted = "Get Started"  /// Get started button
        static let skip = "Skip"  /// Skip button
        static let next = "Next"  /// Next button
        static let back = "Back"  /// Back button
        static let connect = "Connect"  /// Connect button
        static let disconnect = "Disconnect"  /// Disconnect button
        static let reconnect = "Reconnect"  /// Reconnect button
        static let signIn = "Sign In"  /// Sign in button
        static let signOut = "Sign Out"  /// Sign out button
        static let upgrade = "Upgrade"  /// Upgrade button
        static let subscribe = "Subscribe"  /// Subscribe button
        static let continueCTA = "Continue"  /// Continue button
        static let share = "Share"  /// Share button
        static let export = "Export"  /// Export button
        static let importData = "Import"  /// Import button
        static let reset = "Reset"  /// Reset button
        static let clear = "Clear"  /// Clear button
        static let apply = "Apply"  /// Apply button
        static let dismiss = "Dismiss"  /// Dismiss button
        static let enable = "Enable"  /// Enable button
        static let disable = "Disable"  /// Disable button
        static let add = "Add"  /// Add button
        static let remove = "Remove"  /// Remove button
        static let update = "Update"  /// Update button
        static let sync = "Sync"  /// Sync button
        static let download = "Download"  /// Download button
        static let upload = "Upload"  /// Upload button
        static let search = "Search"  /// Search action
        static let filter = "Filter"  /// Filter action
        static let sort = "Sort"  /// Sort action
        static let saveDetails = "Save Details"  /// Save details button
    }
    
    // MARK: - RPE
    enum RPE {
        static let veryLight = "Very Light"  /// Very light RPE
        static let light = "Light"  /// Light RPE
        static let moderate = "Moderate"  /// Moderate RPE
        static let hard = "Hard"  /// Hard RPE
        static let maximum = "Maximum"  /// Maximum RPE
        
        // Guide descriptions
        static let veryLightDesc = "Minimal effort"  /// Very light description
        static let lightDesc = "Easy, can talk freely"  /// Light description
        static let moderateDesc = "Working, can still talk"  /// Moderate description
        static let hardDesc = "Difficult, short answers"  /// Hard description
        static let maximumDesc = "Can't sustain long"  /// Maximum description
        
        // Ranges
        static let range12 = "1-2"  /// Range 1-2
        static let range34 = "3-4"  /// Range 3-4
        static let range56 = "5-6"  /// Range 5-6
        static let range78 = "7-8"  /// Range 7-8
        static let range910 = "9-10"  /// Range 9-10
    }
    
    // MARK: - Workout Details
    enum WorkoutDetails {
        static let workoutDetails = "Workout Details"
        static let rateEffort = "Rate your effort and select muscle groups trained"
        static let effortLevel = "Effort Level"
        static let muscleGroupsOptional = "Muscle Groups (Optional)"
        static let muscleGroups = "Muscle Groups"
        static let muscleGroupsDescription = "Select the muscle groups you trained during this workout"
        static let cardio = "Cardio"
        static let strengthTraining = "Strength Training"
        static let highIntensityIntervalTraining = "High-Intensity Interval Training"
        static let yoga = "Yoga"
        static let pilates = "Pilates"
        static let other = "Other"
    }
    
    // MARK: - Muscle Groups
    enum MuscleGroups {
        static let chest = "Chest"
        static let back = "Back"
        static let shoulders = "Shoulders"
        static let biceps = "Biceps"
        static let triceps = "Triceps"
        static let legs = "Legs"
        static let core = "Core"
        static let cardio = "Cardio"
    }
    
    // MARK: - Sports
    enum Sports {
        // Sport Descriptions
        static let cyclingDescription = "Road cycling, mountain biking, indoor training"  /// Cycling description
        static let runningDescription = "Road running, trail running, track"  /// Running description
        static let swimmingDescription = "Pool swimming, open water"  /// Swimming description
        static let triathlonDescription = "Multi-sport endurance training"  /// Triathlon description
        static let hikingDescription = "Trail hiking, mountaineering"  /// Hiking description
        static let skiingDescription = "Cross-country skiing, ski touring"  /// Skiing description
        static let rowingDescription = "Indoor rowing, on-water rowing"  /// Rowing description
        static let otherDescription = "Other endurance activities"  /// Other description
    }
    
    // MARK: - States
    enum States {
        static let loading = "Loading..."  /// Loading state
        static let loadingData = "Loading data..."  /// Loading data
        static let loadingActivityData = "Loading activity data..."  /// Loading activity data
        static let syncing = "Syncing..."  /// Syncing state
        static let analyzing = "Analyzing..."  /// Analyzing state
        static let computing = "Computing..."  /// Computing state
        static let detecting = "Detecting..."  /// Detecting state
        static let calculating = "Calculating..."  /// Calculating state
        static let defaultMessage = "Loading..."  /// Default loading message
        static let noData = "No data available"  /// Empty state
        static let notEnoughData = "Not enough data"  /// Not enough data
        static let noDataFound = "No data"  /// No data found (short)
        static let noRouteData = "No route data"  /// No route data
        static let error = "Something went wrong"  /// Generic error
        static let success = "Success"  /// Success state
        static let successSaved = "Secret saved successfully"  /// Success saved message
        static let failed = "Failed"  /// Failed state
        static let connected = "Connected"  /// Connected state
        static let disconnected = "Disconnected"  /// Disconnected state
        static let enabled = "Enabled"  /// Enabled state
        static let disabled = "Disabled"  /// Disabled state
        static let connectedSources = "Connected Sources"  /// Connected sources label
    }
    
    // MARK: - Common States (top-level for backward compatibility)
    static let loading = States.loading  /// Loading state (alias)
    static let cancel = Actions.cancel  /// Cancel action (alias)
    static let done = Actions.done  /// Done action (alias)
    
    // MARK: - Time
    static let today = "Today"  /// Today label
    static let yesterday = "Yesterday"  /// Yesterday label
    static let thisWeek = "This Week"  /// This week label
    static let thisMonth = "This Month"  /// This month label
    
    // MARK: - Time of Day
    enum TimeOfDay {
        static let am = "AM"  /// AM (morning)
        static let pm = "PM"  /// PM (afternoon/evening)
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
        static let month = "month"  /// Month (singular)
        static let months = "months"  /// Months (plural)
        static let year = "year"  /// Year (singular)
        static let years = "years"  /// Years (plural)
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
        static let count = "Count"  /// Count label
        static let average = "Avg"  /// Average abbreviation
        static let p95 = "P95"  /// 95th percentile
        static let total = "Total"  /// Total label
        static let overall = "Overall"  /// Overall label
        static let confidence = "Confidence:"  /// Confidence label
        static let riskFactors = "Risk Factors:"  /// Risk factors label
    }
    
    // MARK: - Common Formatting
    enum Formatting {
        static let bulletPoint = "•"  /// Bullet point
        static let dash = "—"  /// Em dash
        static let separator = "·"  /// Middle dot separator
        static let ellipsis = "…"  /// Ellipsis
        static let outOf100 = "/100"  /// Out of 100 suffix
        static let colon = ":"  /// Colon
        static let lessThanOrEqual = "≤"  /// Less than or equal symbol
    }
    
    // MARK: - Units
    enum Units {
        static let bpm = "bpm"  /// Beats per minute
        static let watts = "W"  /// Watts
        static let hours = "h"  /// Hours
        static let minutes = "m"  /// Minutes
        static let seconds = "s"  /// Seconds
        static let milliseconds = "ms"  /// Milliseconds
        static let percent = "%"  /// Percentage
        static let kilometers = "km"  /// Kilometers
        static let miles = "mi"  /// Miles
        static let meters = "m"  /// Meters
        static let calories = "cal"  /// Calories
        static let rpm = "rpm"  /// Revolutions per minute (cadence)
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let average = "Average"  /// Average metric
        static let minimum = "Minimum"  /// Minimum metric
        static let maximum = "Maximum"  /// Maximum metric
        static let baseline = "Baseline"  /// Baseline metric
        static let sleepDuration = "Sleep Duration"  /// Sleep duration metric
        static let sleepTarget = "Sleep Target"  /// Sleep target metric
        static let sleepQuality = "Sleep Quality"  /// Sleep quality metric
        static let hrvRMSSD = "HRV RMSSD"  /// HRV RMSSD metric
        static let restingHeartRate = "Resting Heart Rate"  /// Resting heart rate metric
        static let trainingLoadRatio = "Training Load Ratio"  /// Training load ratio metric
        static let trainingLoad = "Training Load"  /// Training load metric
        static let deepSleep = "Deep Sleep"  /// Deep sleep metric
        static let steps = "Steps"  /// Steps metric
    }
    
    // MARK: - Sleep Stages
    enum Stages {
        static let deep = "Deep"  /// Deep sleep stage
        static let rem = "REM"  /// REM sleep stage
        static let core = "Core"  /// Core sleep stage
        static let light = "Light"  /// Light sleep stage
        static let awake = "Awake"  /// Awake stage
    }
    
    // MARK: - Readiness Components
    enum ReadinessComponents {
        static let recovery = "Recovery"  /// Recovery component
        static let recoveryUpper = "RECOVERY"  /// Recovery (uppercase)
        static let sleep = "Sleep"  /// Sleep component
        static let load = "Load"  /// Load component
        static let strain = "Strain"  /// Strain component
        static let hrv = "HRV"  /// HRV component
        static let rhr = "RHR"  /// RHR component
    }
    
    // MARK: - Debt Metrics
    enum DebtMetrics {
        static let recoveryDebt = "Recovery Debt"  /// Recovery debt title
        static let sleepDebt = "Sleep Debt"  /// Sleep debt title
        static let daysLabel = "days"  /// Days label for debt
    }
    
    // MARK: - Instructions
    enum Instructions {
        static let wearAppleWatch = "Wear your Apple Watch while sleeping"  /// Wear watch instruction
        static let trackConsistently = "Track consistently for 7+ days"  /// Track consistently instruction
        static let grantPermissions = "Grant all health permissions"  /// Grant permissions instruction
        static let connectDataSource = "Connect a data source"  /// Connect data source instruction
    }
    
    // MARK: - Pro Features
    static let upgradeToPro = "Upgrade to PRO"
    static let unlockAllFeatures = "Unlock all features"
    static let pro = "PRO"  /// PRO badge text
    
    // MARK: - Workout & RPE (top-level for easy access)
    static let workoutDetails = "Workout Details"  /// Workout details title
    static let rateEffort = "Rate your effort and select muscle groups worked"  /// Rate effort description
    static let effortLevel = "Effort Level"  /// Effort level label
    static let muscleGroupsOptional = "Muscle Groups (Optional)"  /// Muscle groups label
    static let workoutTypeOptional = "Workout Type (Optional)"  /// Workout type label
    
    // MARK: - Intensity Levels
    enum Intensity {
        static let low = "Low Intensity"  /// Low intensity
        static let high = "High Intensity"  /// High intensity
    }
    
    // MARK: - Badges
    enum Badges {
        static let pro = "PRO"  /// PRO badge
        static let new = "NEW"  /// NEW badge
        static let beta = "BETA"  /// BETA badge
        static let comingSoon = "COMING SOON"  /// Coming soon badge
        static let bestValue = "BEST VALUE"  /// Best value badge
        static let popular = "POPULAR"  /// Popular badge
        static let excellent = "Excellent"  /// Excellent badge
        static let good = "Good"  /// Good badge
        static let fair = "Fair"  /// Fair badge
        static let poor = "Poor"  /// Poor badge
        static let low = "Low"  /// Low badge
        static let medium = "Medium"  /// Medium badge
        static let high = "High"  /// High badge
        
        // Preview badges
        static let small = "Small"  /// Small size
        static let mediumSize = "Medium"  /// Medium size
        static let large = "Large"  /// Large size
        static let ready = "Ready"  /// Ready badge
        static let warning = "Warning"  /// Warning badge
        static let error = "Error"  /// Error badge
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
        
        // Error
        static let errorPrefix = "Error: "  /// Error prefix
    }
    
    // MARK: - Wellness & Illness Detection
    enum WellnessAlerts {
        static let keyMetricsElevated = "Key metrics elevated"  /// Key metrics elevated alert
        static let bodyStressDetected = "Body stress signals detected"  /// Body stress detected
        static let unusualPatterns = "Unusual patterns detected"  /// Unusual patterns
        static let monitorHealth = "Monitor your health"  /// Monitor health
        static let restRecommended = "Rest recommended"  /// Rest recommended
        static let seekMedicalAdvice = "Consider medical advice"  /// Seek medical advice
    }
    
    // MARK: - Illness Indicators
    enum IllnessIndicators {
        // Severity levels
        static let lowSeverity = "Low"  /// Low severity
        static let moderateSeverity = "Moderate"  /// Moderate severity
        static let highSeverity = "High"  /// High severity
        
        // Signal types
        static let hrvDrop = "HRV Drop"  /// HRV drop signal
        static let elevatedRHR = "Elevated RHR"  /// Elevated RHR signal
        static let respiratoryChange = "Respiratory Change"  /// Respiratory change
        static let sleepDisruption = "Sleep Disruption"  /// Sleep disruption
        static let activityDrop = "Activity Drop"  /// Activity drop
        static let temperatureElevation = "Temperature Elevation"  /// Temperature elevation
        
        // Status messages
        static let analyzing = "Analyzing health patterns..."  /// Analyzing
        static let detected = "Detected"  /// Detected status
        static let monitoring = "Monitoring"  /// Monitoring status
        static let normal = "Normal"  /// Normal status
    }
    
    // MARK: - AI Brief
    enum AIBrief {
        static let enableInstructions = "To enable AI Brief:"  /// Enable instructions header
        static let hmacSecret = "HMAC Secret:"  /// HMAC secret label
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
        
        // Metrics
        static let noMetrics = "No Metrics"  /// No metrics
        static let noMetricsMessage = "Connect a data source to see your performance metrics"  /// No metrics message
        
        // Sleep
        static let noSleepData = "No sleep data"  /// No sleep data
        static let noSleepDataMessage = "Wear your Apple Watch while sleeping to track sleep quality"  /// No sleep message
        
        // Actions
        static let connectButton = "Connect Data Source"  /// Connect button
        static let availableSources = "Available sources:"  /// Available sources label
        
        // Charts
        static let dataAvailableButEmpty = "Data available but chart is empty"  /// Chart empty message
        static let pullToRefreshTrend = "Pull to refresh to load"  /// Pull to refresh trend
        static let checkBackIn = "Check back in"  /// Check back in prefix
        static let collectingData = "Collecting data to show"  /// Collecting data prefix
        static let ofDays = "of"  /// Of (for "X of Y days")
        static let daysRemaining = "remaining"  /// Remaining suffix
    }
    
    // MARK: - Error Messages
    enum Errors {
        // Generic
        static let genericTitle = "Something went wrong"  /// Generic error title
        static let genericMessage = "Please try again later"  /// Generic error message
        static let unknownError = "An unknown error occurred"  /// Unknown error
        static let tryAgain = "Please try again"  /// Try again message
        static let connectionError = "Connection Error"  /// Connection error title
        
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
    
    // MARK: - Map Annotations
    enum MapAnnotations {
        static let start = "Start"  /// Route start annotation
        static let end = "End"  /// Route end annotation
        static let routePoint = "RoutePoint"  /// Route point identifier
    }
    
    // MARK: - Tab Navigation
    enum TabLabels {
        static let today = "Today"  /// Today tab label
        static let activities = "Activities"  /// Activities tab label
        static let trends = "Trends"  /// Trends tab label
        static let weeklyTrends = "Weekly Trends"  /// Weekly trends label
        static let reports = "Reports"  /// Reports tab label
        static let settings = "Settings"  /// Settings tab label
    }
    
    // MARK: - Sections
    enum Sections {
        static let additionalData = "Additional Data"  /// Additional data section
        static let healthData = "Health Data"  /// Health data section
        static let wellnessData = "Wellness Data"  /// Wellness data section
        static let whatThisMeans = "What This Means"  /// What this means section
    }
    
    // MARK: - Preview & Examples
    enum Preview {
        static let periodSelector = "Period Selector"  /// Period selector preview
        static let viewType = "View Type"  /// View type preview
        static let timeRange = "Time Range"  /// Time range preview
        static let buttonVariants = "Button Variants"  /// Button variants preview
        static let buttonSizes = "Button Sizes"  /// Button sizes preview
        static let buttonsWithIcons = "Buttons with Icons"  /// Buttons with icons preview
        static let buttonStates = "Button States"  /// Button states preview
        static let badgeVariants = "Badge Variants"  /// Badge variants preview
        static let badgeSizes = "Badge Sizes"  /// Badge sizes preview
        static let badgesWithIcons = "Badges with Icons"  /// Badges with icons preview
        static let elevatedCard = "Elevated Card"  /// Elevated card preview
        static let flatCard = "Flat Card"  /// Flat card preview
        static let outlinedCard = "Outlined Card"  /// Outlined card preview
        static let customPadding = "Custom Padding"  /// Custom padding preview
        static let flowLayoutExample = "Flow Layout Example"  /// Flow layout example
        static let elevatedCardDesc = "This card has a white background with a subtle shadow"  /// Elevated card description
        static let flatCardDesc = "This card has a gray background with no shadow"  /// Flat card description
        static let outlinedCardDesc = "This card has a border with transparent background"  /// Outlined card description
        static let trendContentPlaceholder = "Trend content here"  /// Trend content placeholder
        static let placeholderText = "Placeholder text to maintain consistent height during loading. This ensures the layout doesn't jump when content loads."  /// Placeholder text
        static let useCases = "Use Cases"  /// Use cases section
    }
    
    // MARK: - Debug & Testing
    enum Debug {
        static let debugMode = "Debug Mode"  /// Debug mode label
        static let testData = "Test Data"  /// Test data label
        static let mockData = "Mock Data"  /// Mock data label
        static let clearCache = "Clear Cache"  /// Clear cache action
        static let resetDefaults = "Reset to Defaults"  /// Reset defaults action
        static let viewLogs = "View Logs"  /// View logs action
        static let exportLogs = "Export Logs"  /// Export logs action
        
        // HealthKit Debug
        static let healthKitIntegration = "HealthKit Integration"  /// HealthKit integration title
        static let testingHealthKit = "Testing HealthKit authorization"  /// Testing description
        static let authorizationStatus = "Authorization Status"  /// Authorization status
        static let authorizationDetails = "Authorization Details"  /// Authorization details
        static let error = "Error"  /// Error label
        static let healthDataDisplayed = "Health data displayed in main Today view"  /// Health data displayed
        static let wellnessDataDisplayed = "Wellness data displayed in main Today view"  /// Wellness data displayed
        
        // App Group Debug
        static let title = "App Group Debug"  /// App group debug title
        static let statusInitial = "Ready to test"  /// Initial status
        static let statusWriteSuccess = "✅ Write successful"  /// Write success
        static let statusReadSuccess = "✅ Read successful"  /// Read success
        static let statusFailed = "❌ Failed - check App Group configuration"  /// Failed status
        static let statusNoData = "No data in shared container"  /// No data status
        static let buttonWrite = "Write Test Data"  /// Write button
        static let buttonRead = "Read Test Data"  /// Read button
        static let labelScore = "Recovery Score:"  /// Score label
        static let labelBand = "Recovery Band:"  /// Band label
        static let messageNoData = "No recovery data in shared container"  /// No data message
    }
    
}
