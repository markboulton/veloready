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
    
    // MARK: - States
    enum States {
        static let loading = "Loading..."  /// Loading state
        static let loadingData = "Loading data..."  /// Loading data
        static let syncing = "Syncing..."  /// Syncing state
        static let analyzing = "Analyzing..."  /// Analyzing state
        static let computing = "Computing..."  /// Computing state
        static let noData = "No data available"  /// Empty state
        static let notEnoughData = "Not enough data"  /// Not enough data
        static let noDataFound = "No data"  /// No data found (short)
        static let error = "Something went wrong"  /// Generic error
        static let success = "Success"  /// Success state
        static let failed = "Failed"  /// Failed state
        static let enabled = "Enabled"  /// Enabled state
        static let disabled = "Disabled"  /// Disabled state
        static let connected = "Connected"  /// Connected state
        static let disconnected = "Disconnected"  /// Disconnected state
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
    }
}
