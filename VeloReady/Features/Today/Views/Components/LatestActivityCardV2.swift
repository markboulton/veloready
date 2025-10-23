import SwiftUI
import MapKit

/// Latest Activity card using atomic CardContainer wrapper
/// Shows most recent ride/activity with metadata and optional map
struct LatestActivityCardV2: View {
    let activity: UnifiedActivity
    @State private var locationString: String? = nil
    @State private var mapSnapshot: UIImage? = nil
    @State private var isLoadingMap = false
    
    var body: some View {
        HapticNavigationLink(destination: destinationView) {
            CardContainer(
                header: CardHeader(
                    title: activity.name,
                    subtitle: formattedDateAndTimeWithLocation,
                    action: .init(icon: Icons.System.chevronRight, action: {})
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Metadata Row 1
                    HStack(spacing: Spacing.md) {
                        if let duration = activity.duration {
                            metricColumn(
                                label: ActivityContent.Metrics.duration,
                                value: ActivityFormatters.formatDurationDetailed(duration)
                            )
                        }
                        
                        if let distance = activity.distance {
                            metricColumn(
                                label: ActivityContent.Metrics.distance,
                                value: ActivityFormatters.formatDistance(distance)
                            )
                        }
                        
                        if let tss = activity.tss {
                            metricColumn(
                                label: ActivityContent.Metrics.tss,
                                value: "\(Int(tss))"
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Metadata Row 2
                    HStack(spacing: Spacing.md) {
                        if let np = activity.normalizedPower {
                            metricColumn(
                                label: "Norm Power",
                                value: "\(Int(np))W"
                            )
                        }
                        
                        if let intensity = activity.intensityFactor {
                            metricColumn(
                                label: "Intensity",
                                value: String(format: "%.2f", intensity)
                            )
                        }
                        
                        if let avgHR = activity.averageHeartRate {
                            metricColumn(
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
                                .fill(Color.text.tertiary.opacity(0.1))
                                .frame(height: 180)
                                .overlay(ProgressView())
                                .cornerRadius(12)
                        } else if let snapshot = mapSnapshot {
                            Image(uiImage: snapshot)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(12)
                        }
                    }
                }
            }
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
    
    @ViewBuilder
    private func metricColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            VRText(label, style: .caption, color: Color.text.tertiary)
            VRText(value, style: .body, color: Color.text.primary)
        }
    }
    
    // MARK: - GPS & Location Logic (Maintained from original)
    
    private func getGPSCoordinates() async -> [CLLocationCoordinate2D]? {
        if let stravaActivity = activity.stravaActivity {
            return await fetchStravaGPSCoordinates(activityId: stravaActivity.id)
        }
        
        if let intervalsActivity = activity.intervalsActivity {
            return await fetchIntervalsGPSCoordinates(activityId: intervalsActivity.id)
        }
        
        return nil
    }
    
    private func fetchStravaGPSCoordinates(activityId: Int) async -> [CLLocationCoordinate2D]? {
        do {
            let streamsDict = try await VeloReadyAPIClient.shared.fetchActivityStreams(
                activityId: String(activityId),
                source: .strava
            )
            
            guard let latlngStreamData = streamsDict["latlng"] else { return nil }
            
            let coordinates: [CLLocationCoordinate2D]
            switch latlngStreamData.data {
            case .latlng(let coords):
                coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                }
            case .simple:
                return nil
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        do {
            let samples = try await IntervalsAPIClient.shared.fetchActivityStreams(activityId: activityId)
            
            let coordinates = samples.compactMap { sample -> CLLocationCoordinate2D? in
                guard let lat = sample.latitude, let lng = sample.longitude else { return nil }
                guard !(lat == 0 && lng == 0) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let intervalsActivity = activity.intervalsActivity {
            RideDetailSheet(activity: intervalsActivity)
        } else if let stravaActivity = activity.stravaActivity {
            RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))
        } else if let healthWorkout = activity.healthKitWorkout {
            WalkingDetailView(workout: healthWorkout)
        }
    }
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.startDate)
    }
    
    private var formattedDateAndTimeWithLocation: String {
        var result = formattedDateAndTime
        if let location = locationString {
            result += " • \(location)"
        }
        return result
    }
    
    private func loadLocation() async {
        guard let coordinates = await getGPSCoordinates() else { return }
        locationString = await LocationGeocodingService.shared.getStartLocation(from: coordinates)
    }
    
    private func loadMapSnapshot() async {
        guard activity.shouldShowMap else { return }
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        guard let coordinates = await getGPSCoordinates() else { return }
        mapSnapshot = await MapSnapshotService.shared.generateSnapshot(from: coordinates)
    }
}

#Preview {
    LatestActivityCardV2(activity: UnifiedActivity(from: IntervalsActivity(
        id: "1",
        name: "Morning Ride",
        description: "Easy spin",
        startDateLocal: "2025-10-19T07:30:00",
        type: "Ride",
        duration: 3600,
        distance: 25000,
        elevationGain: 200,
        averagePower: 180,
        normalizedPower: 190,
        averageHeartRate: 140,
        maxHeartRate: 165,
        averageCadence: 85,
        averageSpeed: 25,
        maxSpeed: 45,
        calories: 500,
        fileType: "fit",
        tss: 70,
        intensityFactor: 0.85,
        atl: 30,
        ctl: 35,
        icuZoneTimes: [600, 900, 1200, 600, 300, 0, 0],
        icuHrZoneTimes: [800, 1600, 1000, 200, 0, 0, 0]
    )))
    .padding()
}
