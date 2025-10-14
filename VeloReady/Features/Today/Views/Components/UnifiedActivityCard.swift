import SwiftUI

struct UnifiedActivityCard: View {
    let activity: UnifiedActivity
    
    var body: some View {
        if let intervalsActivity = activity.intervalsActivity {
            // Intervals.icu cycling activity - use RideDetailSheet for full enrichment
            NavigationLink(destination: RideDetailSheet(activity: intervalsActivity)) {
                SharedActivityRowView(activity: activity)
            }
            .buttonStyle(PlainButtonStyle())
        } else if let stravaActivity = activity.stravaActivity {
            // Strava activity - convert to Intervals format for now
            NavigationLink(destination: RideDetailSheet(activity: convertStravaToIntervals(stravaActivity))) {
                SharedActivityRowView(activity: activity)
            }
            .buttonStyle(PlainButtonStyle())
        } else if let healthWorkout = activity.healthKitWorkout {
            // Apple Health workout - use WalkingDetailView
            NavigationLink(destination: WalkingDetailView(workout: healthWorkout)) {
                SharedActivityRowView(activity: activity)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            SharedActivityRowView(activity: activity)
        }
    }
    
    // Temporary converter until we create a dedicated Strava detail view
    private func convertStravaToIntervals(_ strava: StravaActivity) -> IntervalsActivity {
        IntervalsActivity(
            id: "strava_\(strava.id)",
            name: strava.name,
            description: nil,
            startDateLocal: strava.start_date_local,
            type: strava.sport_type,
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
}
