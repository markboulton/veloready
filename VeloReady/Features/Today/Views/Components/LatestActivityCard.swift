import SwiftUI
import MapKit

/// Latest activity card showing the most recent ride/activity with full detail
/// Matches the ride detail page header format with metadata rows and optional map
struct LatestActivityCard: View {
    let activity: UnifiedActivity
    @State private var locationString: String? = nil
    @State private var mapSnapshot: UIImage? = nil
    @State private var isLoadingMap = false
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: activity.type.icon)
                        .foregroundStyle(Color.text.secondary)
                        .font(.system(size: 16))
                    
                    Text(TodayContent.latestActivity)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.text.primary)
                    
                    Spacer()
                    
                    Image(systemName: Icons.System.chevronRight)
                        .foregroundStyle(Color.text.tertiary)
                        .font(.caption)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)
                
                // Divider
                Divider()
                    .padding(.horizontal, Spacing.md)
                
                // Activity Content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Title and Date/Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.text.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            Text(formattedDateAndTime)
                                .font(.subheadline)
                                .foregroundStyle(Color.text.secondary)
                            
                            if let location = locationString {
                                Text(CommonContent.Formatting.separator)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.text.secondary)
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.text.secondary)
                            }
                        }
                    }
                    
                    // Metadata Row 1
                    HStack(spacing: Spacing.md) {
                        if let duration = activity.duration {
                            CompactMetricItem(
                                label: ActivityContent.Metrics.duration,
                                value: ActivityFormatters.formatDurationDetailed(duration)
                            )
                        }
                        
                        if let distance = activity.distance {
                            CompactMetricItem(
                                label: ActivityContent.Metrics.distance,
                                value: ActivityFormatters.formatDistance(distance)
                            )
                        }
                        
                        if let tss = activity.tss {
                            CompactMetricItem(
                                label: ActivityContent.Metrics.tss,
                                value: "\(Int(tss))"
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Metadata Row 2
                    HStack(spacing: Spacing.md) {
                        if let np = activity.normalizedPower {
                            CompactMetricItem(
                                label: "Norm Power",
                                value: "\(Int(np))W"
                            )
                        }
                        
                        if let intensity = activity.intensityFactor {
                            CompactMetricItem(
                                label: "Intensity",
                                value: String(format: "%.2f", intensity)
                            )
                        }
                        
                        if let avgHR = activity.averageHeartRate {
                            CompactMetricItem(
                                label: "Avg HR",
                                value: "\(Int(avgHR)) bpm"
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Map (if outdoor activity with GPS data)
                    if activity.shouldShowMap {
                        if isLoadingMap {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 180)
                                .overlay(
                                    ProgressView()
                                )
                        } else if let snapshot = mapSnapshot {
                            Image(uiImage: snapshot)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                await loadLocation()
                if activity.shouldShowMap {
                    await loadMapSnapshot()
                }
            }
        }
    }
    
    // MARK: - GPS Coordinate Extraction
    
    /// Extract GPS coordinates from the activity
    private func getGPSCoordinates() async -> [CLLocationCoordinate2D]? {
        // For Strava activities, we need to fetch stream data
        if let stravaActivity = activity.stravaActivity {
            return await fetchStravaGPSCoordinates(activityId: stravaActivity.id)
        }
        
        // For Intervals activities, we need to fetch stream data
        if let intervalsActivity = activity.intervalsActivity {
            return await fetchIntervalsGPSCoordinates(activityId: intervalsActivity.id)
        }
        
        // For HealthKit workouts, we'd need to query route data
        // This is more complex and would require HKWorkoutRoute queries
        return nil
    }
    
    /// Fetch GPS coordinates from Strava activity streams
    private func fetchStravaGPSCoordinates(activityId: Int) async -> [CLLocationCoordinate2D]? {
        // Check if we have cached stream data
        let cacheKey = "strava_stream_\(activityId)"
        
        // Try to get from RideDetailViewModel's cache
        // For now, return nil - this would require accessing the stream cache
        // or making an API call to fetch the stream data
        Logger.debug("🗺️ Would fetch Strava GPS coordinates for activity \(activityId)")
        return nil
    }
    
    /// Fetch GPS coordinates from Intervals activity streams
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        // Similar to Strava, would need to fetch stream data
        Logger.debug("🗺️ Would fetch Intervals GPS coordinates for activity \(activityId)")
        return nil
    }
    
    // MARK: - Destination View
    
    @ViewBuilder
    private var destinationView: some View {
        if let intervalsActivity = activity.intervalsActivity {
            RideDetailSheet(activity: intervalsActivity)
        } else if let stravaActivity = activity.stravaActivity {
            // Convert Strava to Intervals format for detail view
            RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))
        } else if let healthWorkout = activity.healthKitWorkout {
            if activity.type == .walking || activity.type == .hiking {
                WalkingDetailView(workout: healthWorkout)
            } else {
                // For other HealthKit workouts, show walking detail view as fallback
                WalkingDetailView(workout: healthWorkout)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.startDate)
    }
    
    // MARK: - Helper Methods
    
    private func loadLocation() async {
        // Get GPS coordinates from the activity
        guard let coordinates = await getGPSCoordinates() else { return }
        
        // Geocode the start location
        locationString = await LocationGeocodingService.shared.getStartLocation(from: coordinates)
    }
    
    private func loadMapSnapshot() async {
        guard activity.shouldShowMap else { return }
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        // Get GPS coordinates from the activity
        guard let coordinates = await getGPSCoordinates() else {
            Logger.debug("🗺️ No GPS coordinates available for map")
            return
        }
        
        // Generate map snapshot
        mapSnapshot = await MapSnapshotService.shared.generateSnapshot(from: coordinates)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        // Cycling activity with power data
        LatestActivityCard(activity: UnifiedActivity(from: IntervalsActivity(
            id: "1",
            name: "5 x 3 mixed",
            description: "Mixed intervals",
            startDateLocal: "2025-10-19T15:44:29",
            type: "Ride",
            duration: 3187,
            distance: 18048.7,
            elevationGain: 3,
            averagePower: 145.7,
            normalizedPower: 171.0,
            averageHeartRate: 133.6,
            maxHeartRate: 163.0,
            averageCadence: 76.0,
            averageSpeed: 20.4,
            maxSpeed: 35.2,
            calories: 450,
            fileType: "fit",
            tss: 65.2,
            intensityFactor: 0.86,
            atl: 26.1,
            ctl: 27.0,
            icuZoneTimes: [761, 31, 653, 613, 695, 25, 124],
            icuHrZoneTimes: [931, 1753, 649, 159, 0, 0, 0]
        )))
        
        // Indoor/virtual ride (no map)
        LatestActivityCard(activity: UnifiedActivity(from: IntervalsActivity(
            id: "2",
            name: "Zwift - Watopia",
            description: "Virtual ride",
            startDateLocal: "2025-10-18T18:00:00",
            type: "VirtualRide",
            duration: 3600,
            distance: 500, // Very low distance indicates indoor
            elevationGain: 0,
            averagePower: 200.0,
            normalizedPower: 210.0,
            averageHeartRate: 145.0,
            maxHeartRate: 170.0,
            averageCadence: 90.0,
            averageSpeed: 0.5,
            maxSpeed: 1.0,
            calories: 600,
            fileType: "fit",
            tss: 85.0,
            intensityFactor: 0.90,
            atl: 30.0,
            ctl: 35.0,
            icuZoneTimes: [300, 600, 1200, 900, 600, 0, 0],
            icuHrZoneTimes: [400, 1400, 1200, 600, 0, 0, 0]
        )))
    }
    .padding()
    .background(Color.background.secondary)
}
