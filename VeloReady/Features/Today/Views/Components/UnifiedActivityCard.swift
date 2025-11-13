import SwiftUI

struct UnifiedActivityCard: View {
    let activity: UnifiedActivity
    
    var body: some View {
        if let sourceActivity = activity.activity {
            // Activity from any source - use RideDetailSheet for full enrichment
            HapticNavigationLink(destination: RideDetailSheet(activity: sourceActivity)) {
                SharedActivityRowView(activity: activity)
            }
        } else if let stravaActivity = activity.stravaActivity {
            // Strava activity - convert to Intervals format for now
            HapticNavigationLink(destination: RideDetailSheet(activity: ActivityConverter.stravaToActivity(stravaActivity))) {
                SharedActivityRowView(activity: activity)
            }
        } else if let healthWorkout = activity.healthKitWorkout {
            // Apple Health workout - use WalkingDetailView
            HapticNavigationLink(destination: WalkingDetailView(workout: healthWorkout)) {
                SharedActivityRowView(activity: activity)
            }
        } else {
            SharedActivityRowView(activity: activity)
        }
    }
    
    // Conversion now handled by unified ActivityConverter utility
}
