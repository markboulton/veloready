import SwiftUI
import HealthKit
import MapKit

/// Comprehensive activity card component for all activity types
/// Uses StandardCard styling with activity-specific metadata
struct ActivityCard: View {
    let activity: UnifiedActivity
    let showChevron: Bool
    let onTap: (() -> Void)?
    let mockMapImage: UIImage? // For preview/debug purposes
    
    @State private var hasRPE = false
    @State private var rpeValue: Double?
    @State private var showingRPESheet = false
    @State private var mapSnapshot: UIImage?
    @State private var location: String?
    
    init(
        activity: UnifiedActivity,
        showChevron: Bool = true,
        onTap: (() -> Void)? = nil,
        mockMapImage: UIImage? = nil
    ) {
        self.activity = activity
        self.showChevron = showChevron
        self.onTap = onTap
        self.mockMapImage = mockMapImage
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .onAppear {
            checkRPEStatus()
            if activity.shouldShowMap {
                loadMapSnapshot()
                loadLocation()
            }
        }
        .sheet(isPresented: $showingRPESheet) {
            if let workout = activity.healthKitWorkout {
                RPEInputSheet(workout: workout) {
                    hasRPE = true
                }
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
                .padding(.bottom, Spacing.md)
            
            // Metadata grid
            metadataGrid
            
            // Optional map
            if let mockMapImage = mockMapImage {
                mapView(image: mockMapImage)
                    .padding(.top, Spacing.md)
            } else if let mapSnapshot = mapSnapshot {
                mapView(image: mapSnapshot)
                    .padding(.top, Spacing.md)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background.card)
        )
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxl / 2)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Activity icon
            Image(systemName: activityIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.text.secondary)
            
            // Title, date, location
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.heading)
                    .foregroundColor(Color.text.primary)
                
                HStack(spacing: 4) {
                    Text(formatDateTime(activity.startDate))
                        .font(.subheadline)
                        .foregroundColor(Color.text.secondary)
                    
                    if let location = location {
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                        
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // RPE Badge for strength (top-right aligned)
            if activity.type == .strength {
                RPEBadge(hasRPE: hasRPE) {
                    showingRPESheet = true
                }
            }
            
            // Optional chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.text.tertiary)
            }
        }
    }
    
    // MARK: - Metadata Grid
    
    private var metadataGrid: some View {
        Group {
            switch activity.type {
            case .cycling:
                cyclingMetadata
            case .strength:
                strengthMetadata
            case .walking, .hiking:
                walkingMetadata
            default:
                defaultMetadata
            }
        }
    }
    
    private var cyclingMetadata: some View {
        HStack(alignment: .top, spacing: 20) {
            if let duration = activity.duration {
                MetricDisplay(
                    formatDuration(duration),
                    label: "Duration",
                    size: .small
                )
            }
            
            if let distance = activity.distance {
                MetricDisplay(
                    formatDistance(distance),
                    label: "Distance",
                    size: .small
                )
            }
            
            if let tss = activity.tss {
                MetricDisplay(
                    "\(Int(tss))",
                    label: "TSS",
                    size: .small
                )
            }
            
            if let power = activity.normalizedPower {
                MetricDisplay(
                    "\(Int(power)) W",
                    label: "NP",
                    size: .small
                )
            }
            
            Spacer()
        }
    }
    
    private var strengthMetadata: some View {
        HStack(alignment: .top, spacing: 20) {
            if let duration = activity.duration {
                MetricDisplay(
                    formatDuration(duration),
                    label: "Duration",
                    size: .small
                )
            }
            
            if let calories = activity.calories {
                MetricDisplay(
                    "\(calories)",
                    label: "Calories",
                    size: .small
                )
            }
            
            // Show RPE value in metadata when set
            if let rpeValue = rpeValue {
                MetricDisplay(
                    String(format: "%.1f", rpeValue),
                    label: "RPE",
                    size: .small
                )
            }
            
            if let avgHR = activity.averageHeartRate {
                MetricDisplay(
                    "\(Int(avgHR))",
                    label: "Avg HR",
                    size: .small
                )
            }
            
            Spacer()
        }
    }
    
    private var walkingMetadata: some View {
        HStack(alignment: .top, spacing: 20) {
            if let duration = activity.duration {
                MetricDisplay(
                    formatDuration(duration),
                    label: "Duration",
                    size: .small
                )
            }
            
            if let distance = activity.distance {
                MetricDisplay(
                    formatDistance(distance),
                    label: "Distance",
                    size: .small
                )
            }
            
            // Steps - would need separate query for HealthKit
            // For now, show calories instead
            if let calories = activity.calories {
                MetricDisplay(
                    "\(calories)",
                    label: "Calories",
                    size: .small
                )
            }
            
            Spacer()
        }
    }
    
    private var defaultMetadata: some View {
        HStack(alignment: .top, spacing: 20) {
            if let duration = activity.duration {
                MetricDisplay(
                    formatDuration(duration),
                    label: "Duration",
                    size: .small
                )
            }
            
            if let calories = activity.calories {
                MetricDisplay(
                    "\(calories)",
                    label: "Calories",
                    size: .small
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Map View
    
    private func mapView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers
    
    private var activityIcon: String {
        if activity.type == .cycling && activity.isIndoorRide {
            return "figure.indoor.cycle"
        }
        return activity.type.icon
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' h:mm a"
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
    
    private func formatDistance(_ distance: Double) -> String {
        let km = distance / 1000.0
        if km >= 10 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.2f km", km)
        }
    }
    
    private func checkRPEStatus() {
        guard let workout = activity.healthKitWorkout else { return }
        hasRPE = WorkoutMetadataService.shared.hasMetadata(for: workout)
        
        // Load RPE value if it exists
        if hasRPE {
            rpeValue = WorkoutMetadataService.shared.getRPE(for: workout)
        }
    }
    
    private func loadMapSnapshot() {
        Task {
            // For Strava activities, fetch GPS coordinates
            if let stravaActivity = activity.stravaActivity {
                do {
                    let streamsDict = try await VeloReadyAPIClient.shared.fetchActivityStreams(
                        activityId: String(stravaActivity.id),
                        source: .strava
                    )
                    
                    guard let latlngStreamData = streamsDict["latlng"] else { return }
                    
                    let coordinates: [CLLocationCoordinate2D]
                    switch latlngStreamData.data {
                    case .latlng(let coords):
                        coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                            guard coord.count >= 2 else { return nil }
                            return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                        }
                    case .simple:
                        return
                    }
                    
                    if !coordinates.isEmpty {
                        await generateMapSnapshot(from: coordinates)
                    }
                } catch {
                    Logger.debug("Failed to fetch GPS coordinates: \(error)")
                }
            }
            // For HealthKit workouts with routes, would need separate implementation
        }
    }
    
    private func generateMapSnapshot(from coordinates: [CLLocationCoordinate2D]) async {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // Calculate region from coordinates
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        mapSnapshotOptions.region = MKCoordinateRegion(center: center, span: span)
        mapSnapshotOptions.size = CGSize(width: 400, height: 120)
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: mapSnapshotOptions)
        
        do {
            let snapshot = try await snapshotter.start()
            
            // Draw route on snapshot
            let image = UIGraphicsImageRenderer(size: mapSnapshotOptions.size).image { context in
                snapshot.image.draw(at: .zero)
                
                let path = UIBezierPath()
                if let firstCoord = coordinates.first {
                    let firstPoint = snapshot.point(for: firstCoord)
                    path.move(to: firstPoint)
                    
                    for coordinate in coordinates.dropFirst() {
                        let point = snapshot.point(for: coordinate)
                        path.addLine(to: point)
                    }
                }
                
                UIColor.systemBlue.setStroke()
                path.lineWidth = 3
                path.stroke()
            }
            
            await MainActor.run {
                self.mapSnapshot = image
            }
        } catch {
            Logger.debug("Failed to generate map snapshot: \(error)")
        }
    }
    
    private func loadLocation() {
        Task {
            if let stravaActivity = activity.stravaActivity {
                do {
                    let streamsDict = try await VeloReadyAPIClient.shared.fetchActivityStreams(
                        activityId: String(stravaActivity.id),
                        source: .strava
                    )
                    
                    guard let latlngStreamData = streamsDict["latlng"] else { return }
                    
                    let coordinates: [CLLocationCoordinate2D]
                    switch latlngStreamData.data {
                    case .latlng(let coords):
                        coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                            guard coord.count >= 2 else { return nil }
                            return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                        }
                    case .simple:
                        return
                    }
                    
                    if let firstCoord = coordinates.first {
                        let location = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
                        let geocoder = CLGeocoder()
                        
                        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                            await MainActor.run {
                                // Format: "City, State" or "City, Country"
                                var components: [String] = []
                                if let locality = placemark.locality {
                                    components.append(locality)
                                }
                                if let area = placemark.administrativeArea ?? placemark.country {
                                    components.append(area)
                                }
                                self.location = components.joined(separator: ", ")
                            }
                        }
                    }
                } catch {
                    Logger.debug("Failed to load location: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Outdoor Ride") {
    ScrollView {
        ActivityCard(
            activity: UnifiedActivity(
                from: IntervalsActivity(
                    id: "1",
                    name: "Morning Ride",
                    description: "Great ride through the hills",
                    startDateLocal: "2025-10-22T08:30:00",
                    type: "Ride",
                    duration: 5400, // 1h 30m
                    distance: 45200, // 45.2 km
                    elevationGain: 650,
                    averagePower: 185,
                    normalizedPower: 195,
                    averageHeartRate: 145,
                    maxHeartRate: 172,
                    averageCadence: 88,
                    averageSpeed: 28.5,
                    maxSpeed: 52.3,
                    calories: 1250,
                    fileType: "fit",
                    tss: 87.0,
                    intensityFactor: 0.82,
                    atl: 65.0,
                    ctl: 75.0,
                    icuZoneTimes: [600, 1800, 2400, 600, 0, 0, 0],
                    icuHrZoneTimes: [900, 2700, 1500, 300, 0, 0, 0]
                )
            ),
            showChevron: true,
            onTap: { print("Tapped outdoor ride") }
        )
    }
    .background(Color.background.primary)
}

#Preview("Indoor Ride") {
    ScrollView {
        ActivityCard(
            activity: UnifiedActivity(
                from: IntervalsActivity(
                    id: "2",
                    name: "2 x 20 Threshold",
                    description: "Indoor trainer session",
                    startDateLocal: "2025-10-21T18:00:00",
                    type: "VirtualRide",
                    duration: 3600, // 1h
                    distance: 1200, // 1.2 km (indoor)
                    elevationGain: 0,
                    averagePower: 210,
                    normalizedPower: 220,
                    averageHeartRate: 158,
                    maxHeartRate: 175,
                    averageCadence: 92,
                    averageSpeed: 0.33,
                    maxSpeed: 0.5,
                    calories: 950,
                    fileType: "fit",
                    tss: 95.0,
                    intensityFactor: 0.92,
                    atl: 68.0,
                    ctl: 78.0,
                    icuZoneTimes: [300, 600, 1200, 1500, 0, 0, 0],
                    icuHrZoneTimes: [600, 1200, 1200, 600, 0, 0, 0]
                )
            ),
            showChevron: true,
            onTap: { print("Tapped indoor ride") }
        )
    }
    .background(Color.background.primary)
}

#Preview("Strength Workout - No RPE") {
    ScrollView {
        // Create a mock HKWorkout for strength training
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            duration: 3600,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 350),
            totalDistance: nil,
            metadata: nil
        )
        
        ActivityCard(
            activity: UnifiedActivity(from: workout),
            showChevron: true,
            onTap: { print("Tapped strength workout") }
        )
    }
    .background(Color.background.primary)
}

#Preview("Walking Workout") {
    ScrollView {
        let workout = HKWorkout(
            activityType: .walking,
            start: Date().addingTimeInterval(-1800),
            end: Date(),
            duration: 1800, // 30 min
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 120),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 2400), // 2.4 km
            metadata: nil
        )
        
        ActivityCard(
            activity: UnifiedActivity(from: workout),
            showChevron: true,
            onTap: { print("Tapped walking workout") }
        )
    }
    .background(Color.background.primary)
}

#Preview("All Activity Types") {
    ScrollView {
        VStack(spacing: 0) {
            // Outdoor Ride
            ActivityCard(
                activity: UnifiedActivity(
                    from: IntervalsActivity(
                        id: "1",
                        name: "Morning Ride",
                        description: nil,
                        startDateLocal: "2025-10-22T08:30:00",
                        type: "Ride",
                        duration: 5400,
                        distance: 45200,
                        elevationGain: 650,
                        averagePower: 185,
                        normalizedPower: 195,
                        averageHeartRate: 145,
                        maxHeartRate: 172,
                        averageCadence: 88,
                        averageSpeed: 28.5,
                        maxSpeed: 52.3,
                        calories: 1250,
                        fileType: "fit",
                        tss: 87.0,
                        intensityFactor: 0.82,
                        atl: 65.0,
                        ctl: 75.0,
                        icuZoneTimes: nil,
                        icuHrZoneTimes: nil
                    )
                ),
                showChevron: true
            )
            
            // Indoor Ride
            ActivityCard(
                activity: UnifiedActivity(
                    from: IntervalsActivity(
                        id: "2",
                        name: "2 x 20 Threshold",
                        description: nil,
                        startDateLocal: "2025-10-21T18:00:00",
                        type: "VirtualRide",
                        duration: 3600,
                        distance: 1200,
                        elevationGain: 0,
                        averagePower: 210,
                        normalizedPower: 220,
                        averageHeartRate: 158,
                        maxHeartRate: 175,
                        averageCadence: 92,
                        averageSpeed: 0.33,
                        maxSpeed: 0.5,
                        calories: 950,
                        fileType: "fit",
                        tss: 95.0,
                        intensityFactor: 0.92,
                        atl: 68.0,
                        ctl: 78.0,
                        icuZoneTimes: nil,
                        icuHrZoneTimes: nil
                    )
                ),
                showChevron: true
            )
            
            // Strength
            ActivityCard(
                activity: UnifiedActivity(
                    from: HKWorkout(
                        activityType: .traditionalStrengthTraining,
                        start: Date().addingTimeInterval(-3600),
                        end: Date(),
                        duration: 3600,
                        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 350),
                        totalDistance: nil,
                        metadata: nil
                    )
                ),
                showChevron: true
            )
            
            // Walking
            ActivityCard(
                activity: UnifiedActivity(
                    from: HKWorkout(
                        activityType: .walking,
                        start: Date().addingTimeInterval(-1800),
                        end: Date(),
                        duration: 1800,
                        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 120),
                        totalDistance: HKQuantity(unit: .meter(), doubleValue: 2400),
                        metadata: nil
                    )
                ),
                showChevron: true
            )
        }
    }
    .background(Color.background.primary)
}
