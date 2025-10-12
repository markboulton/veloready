import Foundation

/// Common strings shared across the app
enum CommonContent {
    // MARK: - Actions
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
    static let continue_ = "Continue"  /// Continue button (underscore to avoid keyword)
    
    // MARK: - States
    static let loading = "Loading..."  /// Loading state
    static let noData = "No data available"  /// Empty state
    static let error = "Something went wrong"  /// Generic error
    static let success = "Success"  /// Success state
    static let failed = "Failed"  /// Failed state
    
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
    }
}
