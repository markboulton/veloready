import Foundation

/// Content strings for the Latest Ride panel
enum LatestRideContent {
    // MARK: - Header
    static let title = "Latest Ride"  /// Panel title
    
    // MARK: - Metrics
    enum Metrics {
        static let duration = "Duration"  /// Duration label
        static let distance = "Distance"  /// Distance label
        static let normalizedPower = "NP"  /// Normalized power abbreviation
        static let calories = "Calories"  /// Calories label
        static let avgHR = "Avg HR"  /// Average heart rate abbreviation
        static let avgPower = "Avg Power"  /// Average power label
        static let maxPower = "Max Power"  /// Max power label
        static let avgSpeed = "Avg Speed"  /// Average speed label
        static let elevation = "Elevation"  /// Elevation label
        static let tss = "TSS"  /// Training stress score
    }
    
    // MARK: - Empty States
    static let noActivities = "No recent rides"  /// No activities message
    static let unnamedActivity = "Unnamed Activity"  /// Unnamed activity fallback
}
