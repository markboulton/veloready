import SwiftUI
import MapKit
import Charts

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// MARK: - Main Workout Detail View

@MainActor
struct WorkoutDetailView: View {
    let activity: IntervalsActivity
    @ObservedObject var viewModel: RideDetailViewModel
    let ftp: Double?
    let maxHR: Double?
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var isLoadingMap = false
    
    private var samples: [WorkoutSample] {
        viewModel.samples
    }
    
    // Use enriched activity if available, otherwise use original
    private var displayActivity: IntervalsActivity {
        viewModel.enrichedActivity ?? activity
    }
    
    // Check if we're using calculated/enriched data (not from API)
    private var isUsingCalculatedData: Bool {
        viewModel.enrichedActivity != nil
    }
    
    // Check if this is a virtual/indoor ride
    private var isVirtualRide: Bool {
        // Check activity type for "virtual" or "indoor"
        if let type = displayActivity.type?.lowercased() {
            return type.contains("virtual") || type.contains("indoor")
        }
        return false
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: Spacing.md) {
                    // Compact Info Header - use enriched activity
                    WorkoutInfoHeader(activity: displayActivity)
                        .padding(.top, 60)
                    
                    // Show loading skeleton while fetching data
                    if viewModel.isLoading {
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, Spacing.lg)
                        
                        Text(CommonContent.States.loadingActivityData)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Skeleton placeholders
                        VStack(spacing: Spacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .shimmer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Pro features section
                    if proConfig.hasProAccess {
                        // AI Ride Summary - PRO feature (below metadata, before charts)
                        RideSummaryView(activity: displayActivity)
                        
                        // Training Load Chart - PRO feature
                        // Shows CTL/ATL/TSB trend over time with 3 intersecting lines
                        if displayActivity.tss != nil {
                            TrainingLoadChart(activity: displayActivity)
                        }
                        
                        // Intensity Chart - PRO feature
                        if displayActivity.tss != nil && displayActivity.intensityFactor != nil {
                            IntensityChart(activity: displayActivity)
                        }
                    } else {
                        // Single combined Pro upgrade card for free users
                        ProUpgradeCard(
                            content: .advancedRideAnalytics,
                            showBenefits: true,
                            learnMore: .advancedRideAnalytics
                        )
                    }
                    
                    // Charts Section - always show, charts handle empty data
                    WorkoutChartsSection(
                        samples: samples,
                        ftp: ftp,
                        maxHR: maxHR
                    )
                }
                
                    // Zone Pie Charts Section - Free and Pro versions
                    ZonePieChartSection(activity: displayActivity)
                    
                    // Interactive Map - only show if GPS data exists AND not a virtual ride
                    if !isVirtualRide && (!routeCoordinates.isEmpty || isLoadingMap) {
                        WorkoutMapSection(
                            coordinates: routeCoordinates,
                            heartRates: samples.map { $0.heartRate },
                            isLoading: isLoadingMap
                        )
                    }
                    
                    // Additional Data Section - use enriched activity
                    AdditionalDataSection(activity: displayActivity)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 120)
            }
        .background(Color.background.primary)
        .navigationTitle(activity.name ?? ActivityContent.WorkoutTypes.workout)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .task {
            Logger.debug("🎯 WorkoutDetailView: .task triggered - initial load")
            // Initial load attempt (will have empty samples)
            await loadMapSnapshot()
        }
        .onChange(of: samples.count) { _, newCount in
            Logger.debug("🎯 WorkoutDetailView: samples.count changed to \(newCount)")
            // Reload when samples count changes (especially from 0 to non-zero)
            if newCount > 0 {
                Logger.debug("🎯 WorkoutDetailView: Reloading map snapshot due to sample count change")
                Task {
                    await loadMapSnapshot()
                }
            }
        }
    }
    
    private func loadMapSnapshot() async {
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        // Extract GPS coordinates from samples
        let coordinates = extractGPSCoordinates()
        
        await MainActor.run {
            self.routeCoordinates = coordinates
        }
    }
    
    private func extractGPSCoordinates() -> [CLLocationCoordinate2D] {
        Logger.debug("🗺️ ========== EXTRACTING GPS COORDINATES ==========")
        Logger.debug("🗺️ Total samples: \(samples.count)")
        
        // Count how many samples have GPS data
        let samplesWithGPS = samples.filter { $0.latitude != nil && $0.longitude != nil }
        Logger.debug("🗺️ Samples with GPS data: \(samplesWithGPS.count)")
        
        // Show first few GPS samples for debugging
        if samplesWithGPS.count > 0 {
            Logger.debug("🗺️ First 3 GPS samples:")
            for (index, sample) in samplesWithGPS.prefix(3).enumerated() {
                Logger.debug("🗺️   [\(index)] lat=\(sample.latitude ?? 0), lng=\(sample.longitude ?? 0)")
            }
        }
        
        let coordinates: [CLLocationCoordinate2D] = samples.compactMap { sample in
            guard let lat = sample.latitude, let lng = sample.longitude else {
                return nil
            }
            
            // Don't filter out 0,0 - it might be valid data
            // Only filter if both are exactly 0
            if lat == 0 && lng == 0 {
                return nil
            }
            
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        Logger.debug("🗺️ Valid GPS coordinates extracted: \(coordinates.count)")
        
        // Check if we have valid coordinates but they're all the same (stationary workout)
        // Check if there's any movement by looking at the range of coordinates
        if !coordinates.isEmpty && coordinates.count > 10 {
            let lats = coordinates.map { $0.latitude }
            let lngs = coordinates.map { $0.longitude }
            let latRange = (lats.max() ?? 0) - (lats.min() ?? 0)
            let lngRange = (lngs.max() ?? 0) - (lngs.min() ?? 0)
            
            Logger.debug("🗺️ GPS Range Analysis:")
            Logger.debug("🗺️   - Latitude range: \(latRange)")
            Logger.debug("🗺️   - Longitude range: \(lngRange)")
            Logger.debug("🗺️   - Min lat: \(lats.min() ?? 0), Max lat: \(lats.max() ?? 0)")
            Logger.debug("🗺️   - Min lng: \(lngs.min() ?? 0), Max lng: \(lngs.max() ?? 0)")
            
            // If the total range is less than ~10 meters in both directions, it's stationary
            let isStationary = latRange < 0.0001 && lngRange < 0.0001
            
            if isStationary {
                Logger.debug("🗺️ ⚠️ Detected stationary workout - GPS range too small")
                Logger.debug("🗺️ Returning empty coordinates to hide map")
                return [] // Return empty to show "no GPS" message instead of a single point
            } else {
                Logger.debug("🗺️ ✅ Movement detected - will show map")
            }
        } else if !coordinates.isEmpty {
            Logger.debug("🗺️ ⚠️ Too few coordinates (\(coordinates.count)) for range analysis")
        }
        
        if coordinates.isEmpty {
            Logger.debug("🗺️ ❌ No valid GPS coordinates found in workout data")
        } else {
            Logger.debug("🗺️ ✅ Returning \(coordinates.count) GPS coordinates for map display")
        }
        
        Logger.debug("🗺️ ================================================")
        
        return coordinates
    }
}

// MARK: - Workout Info Header

struct WorkoutInfoHeader: View {
    let activity: IntervalsActivity
    @State private var locationString: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Date/Time
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name ?? "Untitled Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.text.primary)
                
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
            .onAppear {
                logActivityData()
                Task {
                    await loadLocation()
                }
            }
            
            // Primary Metrics Grid - Always show these specific metrics
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                // Duration - always show
                CompactMetricItem(
                    label: "Duration",
                    value: activity.duration != nil ? ActivityFormatters.formatDurationDetailed(activity.duration!) : "—"
                )
                
                // Distance - always show
                CompactMetricItem(
                    label: "Distance",
                    value: activity.distance != nil ? ActivityFormatters.formatDistance(activity.distance!) : "—"
                )
                
                // TSS - always show
                CompactMetricItem(
                    label: "TSS",
                    value: activity.tss != nil ? formatTSS(activity.tss!) : "—"
                )
                
                // Normalized Power - always show
                CompactMetricItem(
                    label: "Norm Power",
                    value: activity.normalizedPower != nil ? formatPower(activity.normalizedPower!) : "—"
                )
                
                // Intensity Factor - always show
                CompactMetricItem(
                    label: "Intensity",
                    value: activity.intensityFactor != nil ? formatIntensityFactor(activity.intensityFactor!) : "—"
                )
                
                // Average Speed - always show
                CompactMetricItem(
                    label: "Avg Speed",
                    value: activity.averageSpeed != nil ? ActivityFormatters.formatSpeed(activity.averageSpeed!) : "—"
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDateAndTime: String {
        // Use same parsing logic as UnifiedActivity
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: activity.startDateLocal) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        
        if let date = localFormatter.date(from: activity.startDateLocal) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return activity.startDateLocal
    }
    
    private func createGridColumns() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
    
    // MARK: - Formatting Functions
    
    private func formatIntensityFactor(_ intensityFactor: Double) -> String {
        return ActivityFormatters.formatIntensityFactor(intensityFactor)
    }
    
    private func formatTSS(_ tss: Double) -> String {
        return ActivityFormatters.formatTSS(tss)
    }
    
    private func formatPower(_ power: Double) -> String {
        return ActivityFormatters.formatPower(power)
    }
    
    private func formatCalories(_ calories: Int) -> String {
        return ActivityFormatters.formatCalories(calories)
    }
    
    // MARK: - Debug Logging (disabled for performance)
    
    private func logActivityData() {
        // Logging disabled to prevent runaway logs on ride detail pages
    }
    
    private func loadLocation() async {
        // For Intervals activities, location data is not directly available
        // Would need to be added to IntervalsActivity model from API
        // For now, return nil
        locationString = nil
    }
}

// MARK: - Compact Metric Item

struct CompactMetricItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .metricLabel()
                .lineLimit(1)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.text.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Workout Charts Section

struct MetricItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.text.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Charts Section

struct WorkoutChartsSection: View {
    let samples: [WorkoutSample]
    let ftp: Double?
    let maxHR: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Always show charts - they will handle empty data gracefully
            WorkoutDetailCharts(
                samples: samples,
                ftp: ftp,
                maxHR: maxHR
            )
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Map Section

struct WorkoutMapSection: View {
    let coordinates: [CLLocationCoordinate2D]
    let heartRates: [Double]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                ZStack {
                    Color.background.secondary
                        .frame(height: 300)
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.button.primary)
                }
            } else if !coordinates.isEmpty {
                InteractiveMapView(coordinates: coordinates, heartRates: heartRates)
                    .frame(height: 300)
            } else {
                ZStack {
                    Color.background.secondary
                        .frame(height: 300)
                    VStack(spacing: 8) {
                        Image(systemName: Icons.System.map)
                            .font(.title2)
                            .foregroundStyle(Color.text.tertiary)
                        Text(CommonContent.States.noRouteData)
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCornerRadius))
    }
}

// MARK: - Additional Data Section

struct AdditionalDataSection: View {
    let activity: IntervalsActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonContent.Sections.additionalData)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.text.primary)
            
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                // Calories
                if let calories = activity.calories {
                    CompactMetricItem(
                        label: "Calories",
                        value: formatCalories(calories)
                    )
                }
                
                // Average Power (not shown at top)
                if let avgPower = activity.averagePower {
                    CompactMetricItem(
                        label: "Avg Power",
                        value: formatPower(avgPower)
                    )
                }
                
                // Max Heart Rate
                if let maxHR = activity.maxHeartRate {
                    CompactMetricItem(
                        label: "Max HR",
                        value: formatHeartRate(maxHR)
                    )
                }
                
                // Average Heart Rate
                if let avgHR = activity.averageHeartRate {
                    CompactMetricItem(
                        label: "Avg HR",
                        value: formatHeartRate(avgHR)
                    )
                }
                
                // Average Cadence
                if let avgCadence = activity.averageCadence {
                    CompactMetricItem(
                        label: "Avg Cadence",
                        value: formatCadence(avgCadence)
                    )
                }
                
                // Max Speed
                if let maxSpeed = activity.maxSpeed {
                    CompactMetricItem(
                        label: "Max Speed",
                        value: ActivityFormatters.formatSpeed(maxSpeed)
                    )
                }
                
                // Elevation Gain
                if let elevation = activity.elevationGain {
                    CompactMetricItem(
                        label: "Elevation",
                        value: formatElevation(elevation)
                    )
                }
                
                // ATL (Acute Training Load)
                if let atl = activity.atl {
                    CompactMetricItem(
                        label: "ATL (7d)",
                        value: formatLoad(atl)
                    )
                }
                
                // CTL (Chronic Training Load)
                if let ctl = activity.ctl {
                    CompactMetricItem(
                        label: "CTL (42d)",
                        value: formatLoad(ctl)
                    )
                }
            }
        }
    }
    
    private func createGridColumns() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
    
    private func formatCalories(_ calories: Int) -> String {
        return String(format: "%d \(CommonContent.Units.calories)", calories)
    }
    
    private func formatPower(_ power: Double) -> String {
        return String(format: "%.0f \(CommonContent.Units.watts)", power)
    }
    
    private func formatHeartRate(_ hr: Double) -> String {
        return String(format: "%.0f \(CommonContent.Units.bpm)", hr)
    }
    
    private func formatCadence(_ cadence: Double) -> String {
        return String(format: "%.0f \(CommonContent.Units.rpm)", cadence)
    }
    
    
    private func formatElevation(_ elevation: Double) -> String {
        let userSettings = UserSettings.shared
        
        if userSettings.useMetricUnits {
            return String(format: "%.0f m", elevation)
        } else {
            // Convert meters to feet: multiply by 3.281
            let feet = elevation * 3.281
            return String(format: "%.0f ft", feet)
        }
    }
    
    private func formatLoad(_ load: Double) -> String {
        return String(format: "%.1f", load)
    }
}

// MARK: - Preview

#Preview {
    WorkoutDetailView(
        activity: IntervalsActivity(
            id: "preview-activity",
            name: "Morning Training Ride",
            description: "Great morning session with intervals",
            startDateLocal: "2024-01-15T08:30:00Z",
            type: "Ride",
            duration: 5420, // 1h 30m 20s
            distance: 45200, // 45.2 km
            elevationGain: 680,
            averagePower: 245,
            normalizedPower: 268,
            averageHeartRate: 152,
            maxHeartRate: 178,
            averageCadence: 88,
            averageSpeed: 32.4,
            maxSpeed: 54.2,
            calories: 1240,
            fileType: "fit",
            tss: 156,
            intensityFactor: 0.82,
            atl: 45.2,
            ctl: 62.8,
            icuZoneTimes: [120, 450, 890, 1200, 800, 150, 0],
            icuHrZoneTimes: [200, 600, 1100, 1500, 900, 120, 0]
        ),
        viewModel: RideDetailViewModel(),
        ftp: 325,
        maxHR: 185
    )
}
