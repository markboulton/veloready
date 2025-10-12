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
    
    // For navigation to detail view
    let intervalsActivity: IntervalsActivity?
    let stravaActivity: StravaActivity?
    let healthKitWorkout: HKWorkout?
    
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
            case .cycling: return "bicycle"
            case .running: return "figure.run"
            case .walking: return "figure.walk"
            case .hiking: return "figure.hiking"
            case .swimming: return "figure.pool.swim"
            case .strength: return "dumbbell.fill"
            case .yoga: return "figure.mind.and.body"
            case .hiit: return "flame.fill"
            case .other: return "figure.mixed.cardio"
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
    
    /// Create from Intervals.icu activity
    init(from intervalsActivity: IntervalsActivity) {
        self.id = intervalsActivity.id
        self.name = intervalsActivity.name ?? "Unnamed Ride"
        self.startDate = Self.parseDate(intervalsActivity.startDateLocal) ?? Date()
        self.type = Self.mapIntervalsType(intervalsActivity.type)
        self.rawType = intervalsActivity.type // Store raw type for badge display
        self.source = .intervalsICU
        self.duration = intervalsActivity.duration
        self.distance = intervalsActivity.distance
        self.calories = intervalsActivity.calories
        self.averageHeartRate = intervalsActivity.averageHeartRate
        self.maxHeartRate = intervalsActivity.maxHeartRate
        self.averagePower = intervalsActivity.averagePower
        self.normalizedPower = intervalsActivity.normalizedPower
        self.tss = intervalsActivity.tss
        self.intensityFactor = intervalsActivity.intensityFactor
        self.intervalsActivity = intervalsActivity
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
        self.intervalsActivity = nil
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
        self.intervalsActivity = nil
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
    
    private static func mapIntervalsType(_ type: String?) -> ActivityType {
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
}
