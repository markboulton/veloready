import Foundation

/// Content strings for the Latest Ride panel
enum LatestRideContent {
    // MARK: - Header
    static let title = "Latest Ride"  /// Panel title
    
    // MARK: - Metrics (use ActivityContent)
    enum Metrics {
        static let duration = ActivityContent.Metrics.duration
        static let distance = ActivityContent.Metrics.distance
        static let normalizedPower = "NP"  /// Normalized power abbreviation
        static let calories = ActivityContent.Metrics.calories
        static let avgHR = "Avg HR"  /// Average heart rate abbreviation
        static let avgPower = ActivityContent.Metrics.averagePower
        static let maxPower = ActivityContent.Metrics.maxPower
        static let avgSpeed = ActivityContent.Metrics.averageSpeed
        static let elevation = ActivityContent.Metrics.elevation
        static let tss = ActivityContent.Metrics.tss
    }
    
    // MARK: - Empty States
    static let noActivities = "No recent rides"  /// No activities message (specific to rides)
    static let unnamedActivity = "Unnamed Activity"  /// Unnamed activity fallback
}
