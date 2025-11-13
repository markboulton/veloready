import Foundation
import HealthKit

/// Unified activity model that can represent both Intervals.icu and Apple Health workouts
struct UnifiedActivity: Identifiable {
    let id: String
    let name: String
    let startDate: Date
    let type: ActivityType
    let rawType: String? // Raw type string from Intervals.icu (e.g., "VirtualRide", "Ride")
    let source: ActivitySource
    let duration: TimeInterval?
    let distance: Double? // meters
    let calories: Int?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let averagePower: Double?
    let normalizedPower: Double?
    let tss: Double?
    let intensityFactor: Double?
    
    // For navigation to detail view (raw source data)
    let activity: Activity?  // The universal activity model (from any source)
    let stravaActivity: StravaActivity?  // Raw Strava response (if applicable)
    let healthKitWorkout: HKWorkout?  // HealthKit workout (if applicable)
    
    enum ActivitySource {
        case intervalsICU
        case strava
        case appleHealth
        
        var displayName: String {
            switch self {
            case .intervalsICU: return "Intervals.icu"
            case .strava: return "Strava"
            case .appleHealth: return "Apple Health"
            }
        }
    }
    
    enum ActivityType: String {
        case cycling = "Cycling"
        case running = "Running"
        case walking = "Walking"
        case hiking = "Hiking"
        case swimming = "Swimming"
        case strength = "Strength"
        case yoga = "Yoga"
        case hiit = "HIIT"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .cycling: return Icons.Activity.cycling
            case .running: return Icons.Activity.running
            case .walking: return Icons.Activity.walking
            case .hiking: return Icons.Activity.hiking
            case .swimming: return Icons.Activity.swimming
            case .strength: return Icons.Activity.strength
            case .yoga: return Icons.Activity.yoga
            case .hiit: return Icons.Activity.hiit
            case .other: return Icons.Activity.other
            }
        }
        
        var color: String {
            switch self {
            case .cycling: return "blue"
            case .running: return "green"
            case .walking: return "orange"
            case .hiking: return "brown"
            case .swimming: return "cyan"
            case .strength: return "red"
            case .yoga: return "purple"
            case .hiit: return "pink"
            case .other: return "gray"
            }
        }
    }
    
    // MARK: - Initializers
    
    /// Create from Activity (universal model)
    init(from sourceActivity: Activity) {
        self.id = sourceActivity.id
        self.name = sourceActivity.name ?? "Unnamed Activity"
        self.startDate = Self.parseDate(sourceActivity.startDateLocal) ?? Date()
        self.type = Self.mapActivityType(sourceActivity.type)
        self.rawType = sourceActivity.type // Store raw type for badge display
        self.source = .intervalsICU  // Default to Intervals.icu, can be overridden
        self.duration = sourceActivity.duration
        self.distance = sourceActivity.distance
        self.calories = sourceActivity.calories
        self.averageHeartRate = sourceActivity.averageHeartRate
        self.maxHeartRate = sourceActivity.maxHeartRate
        self.averagePower = sourceActivity.averagePower
        self.normalizedPower = sourceActivity.normalizedPower
        self.tss = sourceActivity.tss
        self.intensityFactor = sourceActivity.intensityFactor
        self.activity = sourceActivity
        self.stravaActivity = nil
        self.healthKitWorkout = nil
    }
    
    /// Create from Strava activity
    init(from stravaActivity: StravaActivity) {
        self.id = "strava_\(stravaActivity.id)"
        self.name = stravaActivity.name
        self.startDate = Self.parseDate(stravaActivity.start_date_local) ?? Date()
        self.type = Self.mapStravaType(stravaActivity.sport_type)
        self.rawType = stravaActivity.sport_type
        self.source = .strava
        self.duration = TimeInterval(stravaActivity.moving_time)
        self.distance = stravaActivity.distance
        self.calories = stravaActivity.calories.map { Int($0) }
        self.averageHeartRate = stravaActivity.average_heartrate
        self.maxHeartRate = stravaActivity.max_heartrate.map { Double($0) }
        self.averagePower = stravaActivity.average_watts
        self.normalizedPower = stravaActivity.weighted_average_watts.map { Double($0) }
        self.tss = nil // Strava doesn't provide TSS directly
        self.intensityFactor = nil // Strava doesn't provide IF directly
        self.activity = nil
        self.stravaActivity = stravaActivity
        self.healthKitWorkout = nil
    }
    
    /// Create from Apple Health workout
    init(from workout: HKWorkout) {
        self.id = workout.uuid.uuidString
        self.name = Self.generateWorkoutName(workout)
        self.startDate = workout.startDate
        self.type = Self.mapHealthKitType(workout.workoutActivityType)
        self.rawType = nil // Apple Health doesn't have detailed type strings
        self.source = .appleHealth
        self.duration = workout.duration
        self.distance = workout.totalDistance?.doubleValue(for: .meter())
        
        // Use new iOS 18+ API for active energy burned
        let calories: Int
        if #available(iOS 18.0, *), 
           let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let energyStatistics = workout.statistics(for: energyType),
           let totalEnergy = energyStatistics.sumQuantity() {
            calories = Int(totalEnergy.doubleValue(for: .kilocalorie()))
        } else {
            calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
        }
        self.calories = calories
        
        self.averageHeartRate = nil // Would need separate query
        self.maxHeartRate = nil
        self.averagePower = nil
        self.normalizedPower = nil
        self.tss = nil
        self.intensityFactor = nil
        self.activity = nil
        self.stravaActivity = nil
        self.healthKitWorkout = workout
    }
    
    // MARK: - Helper Methods
    
    private static func parseDate(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    private static func mapActivityType(_ type: String?) -> ActivityType {
        guard let type = type?.lowercased() else { return .other }
        
        if type.contains("ride") || type.contains("cycling") {
            return .cycling
        } else if type.contains("run") {
            return .running
        } else if type.contains("walk") {
            return .walking
        } else if type.contains("swim") {
            return .swimming
        } else if type.contains("strength") {
            return .strength
        }
        return .other
    }
    
    private static func mapStravaType(_ type: String?) -> ActivityType {
        guard let type = type?.lowercased() else { return .other }
        
        if type.contains("ride") || type.contains("cycling") || type == "mountainbikeride" || type == "gravelride" {
            return .cycling
        } else if type.contains("run") {
            return .running
        } else if type.contains("walk") || type == "hike" {
            return .walking
        } else if type.contains("swim") {
            return .swimming
        } else if type.contains("weighttraining") || type.contains("strength") {
            return .strength
        } else if type.contains("yoga") {
            return .yoga
        }
        return .other
    }
    
    private static func mapHealthKitType(_ type: HKWorkoutActivityType) -> ActivityType {
        switch type {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .swimming:
            return .swimming
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .strength
        case .yoga:
            return .yoga
        case .highIntensityIntervalTraining:
            return .hiit
        default:
            return .other
        }
    }
    
    private static func generateWorkoutName(_ workout: HKWorkout) -> String {
        let type = mapHealthKitType(workout.workoutActivityType)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: workout.startDate)
        
        return "\(type.rawValue) at \(timeString)"
    }
    
    // MARK: - Indoor Ride Detection
    
    /// Determines if this activity is an indoor/virtual ride
    /// Uses multiple heuristics: type, distance, speed, elevation
    var isIndoorRide: Bool {
        // Check raw type first - most reliable indicator
        if let rawType = rawType?.lowercased() {
            if rawType.contains("virtual") || rawType.contains("indoor") {
                return true
            }
        }
        
        // For cycling activities, check for indoor indicators
        guard type == .cycling else { return false }
        
        // FIX: Made distance/speed heuristics more conservative
        // Only mark as indoor if BOTH conditions are met (not just one)
        // This prevents outdoor rides with GPS from being marked as indoor
        if let duration = duration, let distance = distance {
            let durationMinutes = duration / 60.0
            let distanceKm = distance / 1000.0
            let avgSpeed = (distance / duration) * 3.6 // m/s to km/h
            
            // Very low distance AND very low speed (both required)
            // Rides like "4x9" intervals may have low distance but should show map if they have GPS
            if durationMinutes > 30 && distanceKm < 1.0 && avgSpeed < 3.0 {
                return true
            }
        }
        
        // Check activity source - only if extremely minimal distance (< 500m)
        // Reduced from 1000m to be less aggressive
        if let sourceActivity = activity,
           sourceActivity.source?.uppercased() == "STRAVA",
           let distance = sourceActivity.distance,
           distance < 500 { // Less than 500m
            return true
        }
        
        return false
    }
    
    /// Whether this activity should show a map
    var shouldShowMap: Bool {
        // Don't show map for indoor rides
        guard !isIndoorRide else { return false }
        
        // Don't show map for non-outdoor activities
        guard type == .cycling || type == .running || type == .walking || type == .hiking else {
            return false
        }
        
        // Check if activity has GPS coordinates from any source
        // Strava and Activity models with coordinates should show maps
        if stravaActivity != nil || activity != nil {
            // Has data source that typically includes GPS - show map
            return true
        }
        
        // For HealthKit workouts, check if they have routes (GPS data)
        if let workout = healthKitWorkout {
            // HealthKit workouts with routes should show maps
            // Note: We can't check workout.workoutRoutes here as it requires async query
            // So we use distance as a proxy - activities with distance likely have GPS
            if let distance = distance, distance > 100 { // At least 100m
                return true
            }
        }
        
        // For activities without clear GPS indicators, require meaningful distance
        guard let distance = distance, distance > 100 else {
            return false
        }
        
        return true
    }
    
    /// Whether elevation data is reliable for this activity
    var hasReliableElevation: Bool {
        // Indoor rides have unreliable elevation
        guard !isIndoorRide else { return false }
        
        // Need to be an outdoor activity type
        guard type == .cycling || type == .running || type == .walking || type == .hiking else {
            return false
        }
        
        return true
    }
}
