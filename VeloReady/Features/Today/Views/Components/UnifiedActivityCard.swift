import SwiftUI

struct UnifiedActivityCard: View {
    let activity: UnifiedActivity
    
    var body: some View {
        if let intervalsActivity = activity.intervalsActivity {
            // Intervals.icu cycling activity - use RideDetailSheet for full enrichment
            NavigationLink(destination: RideDetailSheet(activity: intervalsActivity)) {
                SharedActivityRowView(activity: activity)
            }
        } else if let stravaActivity = activity.stravaActivity {
            // Strava activity - convert to Intervals format for now
            NavigationLink(destination: RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))) {
                SharedActivityRowView(activity: activity)
            }
        } else if let healthWorkout = activity.healthKitWorkout {
            // Apple Health workout - use WalkingDetailView
            NavigationLink(destination: WalkingDetailView(workout: healthWorkout)) {
                SharedActivityRowView(activity: activity)
            }
        } else {
            SharedActivityRowView(activity: activity)
        }
    }
    
    // Conversion now handled by unified ActivityConverter utility
}
