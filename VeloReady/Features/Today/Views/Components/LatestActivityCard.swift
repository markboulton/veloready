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
        VStack(spacing: 0) {
            NavigationLink(destination: destinationView) {
                VStack(alignment: .leading, spacing: 0) {
                    // Content (header + activity details in one container)
                    VStack(alignment: .leading, spacing: Spacing.md) {
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
                        }
                        .padding(.top, Spacing.xxl) // Standard 40px top padding
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
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 180)
                                    .padding(.top, Spacing.md)
                                    .overlay(
                                        ProgressView()
                                    )
                            } else if let snapshot = mapSnapshot {
                                Image(uiImage: snapshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 180)
                                    .clipped()
                                    .padding(.top, Spacing.md)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.md)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md / 2)
            
            // Full-width divider at bottom (40px top, 0 bottom - next section provides top padding)
            SectionDivider(topPadding: Spacing.xxl, bottomPadding: 0)
        }
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
        do {
            Logger.debug("🗺️ Fetching Strava GPS coordinates for activity \(activityId)")
            
            // Fetch streams from backend API (includes latlng)
            let streamsDict = try await VeloReadyAPIClient.shared.fetchActivityStreams(
                activityId: String(activityId),
                source: .strava
            )
            
            // Extract latlng stream
            guard let latlngStreamData = streamsDict["latlng"] else {
                Logger.debug("🗺️ No latlng stream found in Strava data")
                return nil
            }
            
            // Convert StreamDataRaw to coordinates
            let coordinates: [CLLocationCoordinate2D]
            switch latlngStreamData.data {
            case .latlng(let coords):
                coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                }
            case .simple:
                Logger.debug("🗺️ Latlng stream has wrong format (simple instead of latlng)")
                return nil
            }
            
            Logger.debug("🗺️ ✅ Fetched \(coordinates.count) GPS coordinates from Strava")
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            Logger.error("🗺️ Failed to fetch Strava GPS coordinates: \(error)")
            return nil
        }
    }
    
    /// Fetch GPS coordinates from Intervals activity streams
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        do {
            Logger.debug("🗺️ Fetching Intervals GPS coordinates for activity \(activityId)")
            
            // Fetch streams from Intervals API
            let samples = try await IntervalsAPIClient.shared.fetchActivityStreams(activityId: activityId)
            
            // Extract GPS coordinates from samples
            let coordinates = samples.compactMap { sample -> CLLocationCoordinate2D? in
                guard let lat = sample.latitude, let lng = sample.longitude else { return nil }
                // Filter out invalid GPS (0,0)
                guard !(lat == 0 && lng == 0) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            Logger.debug("🗺️ ✅ Fetched \(coordinates.count) GPS coordinates from Intervals")
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            Logger.error("🗺️ Failed to fetch Intervals GPS coordinates: \(error)")
            return nil
        }
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
