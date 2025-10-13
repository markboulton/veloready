import SwiftUI

struct UnifiedActivityCard: View {
    let activity: UnifiedActivity
    
    var body: some View {
        if let intervalsActivity = activity.intervalsActivity {
            // Intervals.icu cycling activity - use RideDetailSheet for full enrichment
            NavigationLink(destination: RideDetailSheet(activity: intervalsActivity)) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else if let stravaActivity = activity.stravaActivity {
            // Strava activity - convert to Intervals format for now
            NavigationLink(destination: RideDetailSheet(activity: convertStravaToIntervals(stravaActivity))) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else if let healthWorkout = activity.healthKitWorkout {
            // Apple Health workout
            NavigationLink(destination: ActivityDetailView(activityData: .fromHealthKit(healthWorkout))) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // Type badge with pastel colors
                    if let rawType = activity.rawType {
                        ActivityTypeBadge(rawType, size: .small)
                    } else {
                        ActivityTypeBadge(activity.type.rawValue, size: .small)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(formatDate(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = activity.duration {
                        Text("•").foregroundColor(.secondary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distance = activity.distance {
                        Text("•").foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", distance / 1000.0)) km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Show chevron for all tappable activities
            if activity.intervalsActivity != nil || activity.stravaActivity != nil || activity.healthKitWorkout != nil {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
