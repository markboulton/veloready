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
        static let intensity = "Intensity"  /// Intensity label
        static let load = "Load"  /// Load label
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
        static let timeInZones = "Time in Zones"  /// Time in zones label
        static let hrZoneDistribution = "HR Zone Distribution"  /// HR zone distribution label
        static let powerZoneDistribution = "Power Zone Distribution"  /// Power zone distribution label
        static let mockHRData = "Mock HR Data"  /// Mock HR data indicator
        
        // Zone Names - Heart Rate
        static let hrZone1 = "Zone 1 (Recovery)"  /// HR Zone 1
        static let hrZone2 = "Zone 2 (Endurance)"  /// HR Zone 2
        static let hrZone3 = "Zone 3 (Tempo)"  /// HR Zone 3
        static let hrZone4 = "Zone 4 (Threshold)"  /// HR Zone 4
        static let hrZone5 = "Zone 5 (VO2 Max)"  /// HR Zone 5
        
        // Zone Names - Power
        static let powerZone1 = "Zone 1 (Active Recovery)"  /// Power Zone 1
        static let powerZone2 = "Zone 2 (Endurance)"  /// Power Zone 2
        static let powerZone3 = "Zone 3 (Tempo)"  /// Power Zone 3
        static let powerZone4 = "Zone 4 (Threshold)"  /// Power Zone 4
        static let powerZone5 = "Zone 5 (VO2 Max)"  /// Power Zone 5
    }
    
    // MARK: - Empty States
    static let noData = "No data available"  /// No data message
    static let loadingData = "Loading activity data..."  /// Loading message
    static let syncingFromIntervals = "Syncing from Intervals.icu..."  /// Syncing message
    static let powerZonesNotAvailable = "Power zones not available"  /// No power zones message
    
    // MARK: - FTP Warnings
    enum FTPWarnings {
        static let ftpRequired = "FTP Required"  /// FTP required title
        static let setFTPMessage = "Set FTP in Settings to see TSS and Intensity"  /// Set FTP message
        static let setFTPForZones = "Set FTP in Settings to see power zones"  /// Set FTP for zones message
    }
    
    // MARK: - Date Formatting
    enum DateFormat {
        static let today = "Today at"  /// Today prefix
        static let yesterday = "Yesterday at"  /// Yesterday prefix
    }
    
    // MARK: - Workout Types
    enum WorkoutTypes {
        static let walking = "Walking"  /// Walking workout
        static let strengthTraining = "Strength Training"  /// Strength training
        static let strength = "Strength"  /// Strength (short)
        static let functionalStrength = "Functional Strength"  /// Functional strength
        static let workout = "Workout"  /// Generic workout
        static let workoutType = "Workout Type"  /// Workout type label
        static let notSpecified = "Not specified"  /// Not specified
    }
    
    // MARK: - Training Load
    enum TrainingLoad {
        static let trainingLoad = "Training Load:"  /// Training load label
        static let effort = "Effort:"  /// Effort label
        static let muscleGroups = "Muscle Groups:"  /// Muscle groups label
        static let learnMore = "Learn more"  /// Learn more button
        
        // Load intensity labels
        static let light = "Light"  /// Light intensity
        static let moderate = "Moderate"  /// Moderate intensity
        static let hard = "Hard"  /// Hard intensity
        static let veryHard = "Very Hard"  /// Very hard intensity
    }
    
    // MARK: - Heart Rate
    enum HeartRate {
        static let heartRate = "Heart Rate"  /// Heart rate label
        static let avg = "Avg:"  /// Average prefix
        static let max = "Max:"  /// Max prefix
        static let noHeartRateData = "No heart rate data"  /// No HR data message
    }
}
