import SwiftUI
import HealthKit
import MapKit
import Charts

/// Unified activity detail view for both Intervals.icu cycling and Apple Health workouts
struct ActivityDetailView: View {
    let activityData: UnifiedActivityData
    @StateObject private var viewModel: ActivityDetailViewModel
    
    init(activityData: UnifiedActivityData) {
        self.activityData = activityData
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activityData: activityData))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // Header with key metrics - gradient shows through
                    ActivityInfoHeader(activityData: activityData, viewModel: viewModel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    
                    // Charts Section with solid background
                    if !viewModel.chartSamples.isEmpty {
                        VStack(spacing: 0) {
                            chartsSection
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.black
                                .ignoresSafeArea(edges: .horizontal)
                        )
                    }
                    
                    // Map Section - Interactive with solid background
                    // Only show for outdoor activities with route data
                    if !viewModel.routeCoordinates.isEmpty && activityData.shouldShowMap {
                        VStack(spacing: 0) {
                            InteractiveWorkoutMapSection(
                                coordinates: viewModel.routeCoordinates,
                                isLoading: viewModel.isLoadingMap
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.black
                                .ignoresSafeArea(edges: .horizontal)
                        )
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        .background(Color.background.primary)
        .navigationTitle(activityData.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        switch activityData.type {
        case .cycling:
            // Power and HR charts for cycling
            if activityData.intervalsActivity?.id != nil {
                WorkoutChartsSection(
                    samples: viewModel.workoutSamples,
                    ftp: viewModel.ftp,
                    maxHR: activityData.intervalsActivity?.maxHeartRate
                )
            }
        case .walking, .strength:
            // HR chart only for walking/strength
            if !viewModel.heartRateSamples.isEmpty {
                heartRateChartSection
            }
        }
    }
    
    private var heartRateChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(ActivityContent.HeartRate.heartRate)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let avg = viewModel.averageHeartRate, let max = viewModel.maxHeartRate {
                    HStack(spacing: 12) {
                        Text("\(ActivityContent.HeartRate.avg) \(Int(avg))")
                        Text("\(ActivityContent.HeartRate.max) \(Int(max))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            HeartRateChart(samples: viewModel.heartRateSamples)
                .frame(height: 200)
        }
    }
}

// MARK: - Unified Activity Data Model

enum ActivityType {
    case cycling
    case walking
    case strength
    
    var displayName: String {
        switch self {
        case .cycling: return ActivityContent.ActivityTypes.cycling
        case .walking: return ActivityContent.ActivityTypes.walking
        case .strength: return ActivityContent.ActivityTypes.strength
        }
    }
}

struct UnifiedActivityData {
    let type: ActivityType
    let title: String
    let startDate: Date
    let duration: TimeInterval
    let distance: Double?
    let calories: Int?
    
    // Source-specific data
    let intervalsActivity: IntervalsActivity?
    let healthKitWorkout: HKWorkout?
    
    // Indoor ride detection
    var isIndoorRide: Bool {
        // Check Intervals activity type
        if let intervalsType = intervalsActivity?.type?.lowercased() {
            if intervalsType.contains(ActivityContent.IndoorDetection.virtual) || intervalsType.contains(ActivityContent.IndoorDetection.indoor) {
                return true
            }
        }
        
        // For cycling, check for indoor indicators
        guard type == .cycling else { return false }
        
        // Very low distance (<2km) for rides over 20 minutes suggests indoor
        if let distance = distance {
            let durationMinutes = duration / 60.0
            let distanceKm = distance / 1000.0
            
            if durationMinutes > 20 && distanceKm < 2.0 {
                return true
            }
            
            // Very low average speed (<5 km/h) suggests indoor/trainer
            let avgSpeed = (distance / duration) * 3.6 // m/s to km/h
            if avgSpeed < 5.0 {
                return true
            }
        }
        
        return false
    }
    
    var shouldShowMap: Bool {
        return !isIndoorRide && type == .cycling && (distance ?? 0) > 100
    }
    
    // Convenience initializers
    static func fromIntervals(_ activity: IntervalsActivity) -> UnifiedActivityData {
        UnifiedActivityData(
            type: .cycling,
            title: activity.name ?? ActivityContent.ActivityTypes.untitledWorkout,
            startDate: parseDate(activity.startDateLocal) ?? Date(),
            duration: activity.duration ?? 0,
            distance: activity.distance,
            calories: activity.calories,
            intervalsActivity: activity,
            healthKitWorkout: nil
        )
    }
    
    static func fromHealthKit(_ workout: HKWorkout) -> UnifiedActivityData {
        let type: ActivityType = {
            switch workout.workoutActivityType {
            case .walking:
                return .walking
            case .traditionalStrengthTraining, .functionalStrengthTraining:
                return .strength
            default:
                return .walking
            }
        }()
        
        return UnifiedActivityData(
            type: type,
            title: generateTitle(for: workout),
            startDate: workout.startDate,
            duration: workout.duration,
            distance: workout.totalDistance?.doubleValue(for: .meter()),
            calories: Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0),
            intervalsActivity: nil,
            healthKitWorkout: workout
        )
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    private static func generateTitle(for workout: HKWorkout) -> String {
        switch workout.workoutActivityType {
        case .walking:
            return ActivityContent.WorkoutTypes.walking
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return ActivityContent.WorkoutTypes.strengthTraining
        default:
            return ActivityContent.WorkoutTypes.workout
        }
    }
}

// MARK: - Activity Info Header

struct ActivityInfoHeader: View {
    let activityData: UnifiedActivityData
    @ObservedObject var viewModel: ActivityDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Date/Time
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(ActivityContent.Details.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.text.primary)
                    
                    // Type badge
                    if let rawType = activityData.intervalsActivity?.type {
                        ActivityTypeBadge(rawType, size: .small)
                    } else {
                        ActivityTypeBadge(activityData.type.displayName, size: .small)
                    }
                }
                
                Text(ActivityContent.Details.dateAndTime)
                    .font(.subheadline)
                    .foregroundStyle(Color.text.secondary)
            }
            
            // Primary Metrics Grid
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                // Duration (all types)
                CompactMetricItem(
                    label: ActivityContent.Metrics.duration,
                    value: formatDuration(activityData.duration)
                )
                
                // Distance (if available)
                if let distance = activityData.distance {
                    CompactMetricItem(
                        label: ActivityContent.Metrics.distance,
                        value: formatDistance(distance)
                    )
                }
                
                // Type-specific metrics
                switch activityData.type {
                case .cycling:
                    cyclingMetrics
                case .walking, .strength:
                    healthKitMetrics
                }
            }
        }
    }
    
    @ViewBuilder
    private var cyclingMetrics: some View {
        if let activity = activityData.intervalsActivity {
            if let intensityFactor = activity.intensityFactor {
                CompactMetricItem(
                    label: ActivityContent.Metrics.intensity,
                    value: String(format: "%.2f", intensityFactor)
                )
            }
            
            if let tss = activity.tss {
                CompactMetricItem(
                    label: ActivityContent.Metrics.tss,
                    value: String(format: "%.0f", tss)
                )
            }
            
            if let normalizedPower = activity.normalizedPower {
                CompactMetricItem(
                    label: ActivityContent.MetricLabelsExtended.np,
                    value: "\(Int(normalizedPower))w"
                )
            }
            
            if let calories = activity.calories {
                CompactMetricItem(
                    label: ActivityContent.Metrics.calories,
                    value: "\(calories)"
                )
            }
        }
    }
    
    @ViewBuilder
    private var healthKitMetrics: some View {
        if let calories = activityData.calories {
            CompactMetricItem(
                label: "Calories",
                value: "\(calories)"
            )
        }
        
        if viewModel.steps > 0 {
            CompactMetricItem(
                label: ActivityContent.Metrics.steps,
                value: "\(viewModel.steps)"
            )
        }
        
        if let avgHR = viewModel.averageHeartRate {
            CompactMetricItem(
                label: ActivityContent.MetricLabelsExtended.avgHR,
                value: "\(Int(avgHR))"
            )
        }
        
        if let maxHR = viewModel.maxHeartRate {
            CompactMetricItem(
                label: ActivityContent.MetricLabelsExtended.maxHR,
                value: "\(Int(maxHR))"
            )
        }
    }
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activityData.startDate)
    }
    
    private func createGridColumns() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.2f \(CommonContent.Units.kilometers)", km)
    }
}

// MARK: - Interactive Map Section

struct InteractiveWorkoutMapSection: View {
    let coordinates: [CLLocationCoordinate2D]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                ZStack {
                    Color(.systemGray6)
                        .frame(height: UIScreen.main.bounds.width - 32) // Square
                    ProgressView()
                }
            } else if !coordinates.isEmpty {
                InteractiveMapView(coordinates: coordinates)
                    .frame(height: UIScreen.main.bounds.width - 32) // Square
            } else {
                ZStack {
                    Color(.systemGray6)
                        .frame(height: UIScreen.main.bounds.width - 32) // Square
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(ActivityContent.Map.noGPSData)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
