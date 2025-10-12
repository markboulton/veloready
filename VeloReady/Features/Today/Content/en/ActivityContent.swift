import Foundation

/// Content strings for Activity/Workout details
enum ActivityContent {
    // MARK: - Navigation
    static let title = "Activity Details"  /// Navigation title
    static let rideTitle = "Ride Details"  /// Ride details title
    static let walkingTitle = "Walking Details"  /// Walking details title
    
    // MARK: - Metrics
    enum Metrics {
        static let distance = "Distance"  /// Distance label
        static let duration = "Duration"  /// Duration label
        static let averageSpeed = "Avg Speed"  /// Average speed label
        static let maxSpeed = "Max Speed"  /// Max speed label
        static let averagePower = "Avg Power"  /// Average power label
        static let maxPower = "Max Power"  /// Max power label
        static let normalizedPower = "Normalized Power"  /// Normalized power label
        static let averageHeartRate = "Avg Heart Rate"  /// Average HR label
        static let maxHeartRate = "Max Heart Rate"  /// Max HR label
        static let averageCadence = "Avg Cadence"  /// Average cadence label
        static let maxCadence = "Max Cadence"  /// Max cadence label
        static let elevation = "Elevation"  /// Elevation label
        static let calories = "Calories"  /// Calories label
        static let tss = "TSS"  /// TSS label
        static let intensityFactor = "Intensity Factor"  /// IF label
        static let steps = "Steps"  /// Steps label
    }
    
    // MARK: - Charts
    enum Charts {
        static let power = "Power"  /// Power chart
        static let heartRate = "Heart Rate"  /// Heart rate chart
        static let speed = "Speed"  /// Speed chart
        static let cadence = "Cadence"  /// Cadence chart
        static let elevation = "Elevation"  /// Elevation chart
        static let selectMetric = "Select Metric"  /// Select metric label
    }
    
    // MARK: - Map
    enum Map {
        static let route = "Route"  /// Route label
        static let startPoint = "Start"  /// Start point label
        static let endPoint = "End"  /// End point label
        static let noGPSData = "No GPS data available"  /// No GPS message
    }
    
    // MARK: - Zones
    enum Zones {
        static let powerZones = "Power Zones"  /// Power zones label
        static let heartRateZones = "Heart Rate Zones"  /// HR zones label
        static let zone1 = "Zone 1"  /// Zone 1 label
        static let zone2 = "Zone 2"  /// Zone 2 label
        static let zone3 = "Zone 3"  /// Zone 3 label
        static let zone4 = "Zone 4"  /// Zone 4 label
        static let zone5 = "Zone 5"  /// Zone 5 label
        static let timeInZone = "Time in Zone"  /// Time in zone label
    }
    
    // MARK: - Empty States
    static let noData = "No data available"  /// No data message
    static let loadingData = "Loading activity data..."  /// Loading message
    static let syncingFromIntervals = "Syncing from Intervals.icu..."  /// Syncing message
}
