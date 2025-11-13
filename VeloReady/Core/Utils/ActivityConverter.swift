import Foundation

/// Unified converter for converting external activity data sources (Strava, Wahoo, etc.) to Activity format
/// This ensures consistent handling of all activity sources throughout the app
enum ActivityConverter {
    
    /// Convert Strava activity to unified Activity format
    /// This is the single source of truth for Strava → Activity conversion
    static func stravaToActivity(_ strava: StravaActivity) -> Activity {
        Activity(
            id: "strava_\(strava.id)",
            name: strava.name,
            description: nil,
            startDateLocal: strava.start_date_local,
            type: strava.type, // Use type (VirtualRide, Ride) not sport_type for proper virtual detection
            duration: TimeInterval(strava.moving_time),
            distance: strava.distance,
            elevationGain: strava.total_elevation_gain,
            averagePower: strava.average_watts,
            normalizedPower: strava.weighted_average_watts.map { Double($0) },
            averageHeartRate: strava.average_heartrate,
            maxHeartRate: strava.max_heartrate.map { Double($0) },
            averageCadence: strava.average_cadence,
            averageSpeed: strava.average_speed,
            maxSpeed: strava.max_speed,
            calories: strava.calories.map { Int($0) },
            fileType: nil,
            tss: nil,
            intensityFactor: nil,
            atl: nil,
            ctl: nil,
            icuZoneTimes: nil,
            icuHrZoneTimes: nil
        )
    }
    
    /// Convert batch of Strava activities
    static func stravaToActivity(_ stravaActivities: [StravaActivity]) -> [Activity] {
        return stravaActivities.map { stravaToActivity($0) }
    }
    
    /// Enrich activity with calculated metrics (TSS, IF, CTL, ATL)
    /// This should be used after conversion to add computed metrics
    /// Note: Activity is a struct with let properties, so we create a new instance
    static func enrichWithMetrics(
        _ activity: Activity,
        ftp: Double?,
        historicalActivities: [Activity] = []
    ) -> Activity {
        // Calculate TSS if we have power data and FTP
        var tss: Double? = activity.tss
        var intensityFactor: Double? = activity.intensityFactor
        
        if let np = activity.normalizedPower ?? activity.averagePower,
           let ftp = ftp,
           ftp > 0,
           let duration = activity.duration {
            let if_value = np / ftp
            tss = (duration / 3600) * if_value * if_value * 100
            intensityFactor = if_value
        }
        
        // Create new activity with calculated metrics
        // Note: CTL/ATL calculation would be added here when needed
        return Activity(
            id: activity.id,
            name: activity.name,
            description: activity.description,
            startDateLocal: activity.startDateLocal,
            type: activity.type,
            duration: activity.duration,
            distance: activity.distance,
            elevationGain: activity.elevationGain,
            averagePower: activity.averagePower,
            normalizedPower: activity.normalizedPower,
            averageHeartRate: activity.averageHeartRate,
            maxHeartRate: activity.maxHeartRate,
            averageCadence: activity.averageCadence,
            averageSpeed: activity.averageSpeed,
            maxSpeed: activity.maxSpeed,
            calories: activity.calories,
            fileType: activity.fileType,
            tss: tss,
            intensityFactor: intensityFactor,
            atl: activity.atl,
            ctl: activity.ctl,
            icuZoneTimes: activity.icuZoneTimes,
            icuHrZoneTimes: activity.icuHrZoneTimes
        )
    }
}
