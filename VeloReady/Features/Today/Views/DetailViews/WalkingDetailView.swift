import SwiftUI
import HealthKit
import MapKit
import Charts

/// Detail view for walking/strength workouts from Apple Health
struct WalkingDetailView: View {
    let workout: HKWorkout
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WalkingDetailViewModel()
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    @State private var showingTrainingLoadInfo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with key metrics - using shared component
                WalkingWorkoutInfoHeader(workout: workout, viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                
                // Full-width divider
                Rectangle()
                    .fill(ColorScale.divider)
                    .frame(height: 1)
                    .padding(.bottom, 24)
                
                // Heart Rate Chart
                if !viewModel.heartRateSamples.isEmpty {
                    heartRateChartSection
                }
                
                // Divider between HR chart and workout type (only for strength workouts)
                if isStrengthWorkout && !viewModel.heartRateSamples.isEmpty {
                    Rectangle()
                        .fill(ColorScale.divider)
                        .frame(height: 1)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
                
                // Workout Type section - only for strength workouts
                if isStrengthWorkout {
                    workoutTypeSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                
                // Map - only for walking workouts
                if !isStrengthWorkout {
                    WorkoutMapSection(
                        coordinates: viewModel.routeCoordinates ?? [],
                        isLoading: viewModel.isLoadingMap
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.background.primary)
        .navigationTitle(workoutTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRPESheet) {
            RPEInputSheet(workout: workout) {
                // Refresh state after saving
                checkRPEStatus()
            }
        }
        .task {
            await viewModel.loadWorkoutData(workout: workout)
            checkRPEStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutMetadataDidUpdate)) { notification in
            // Refresh when metadata is updated
            if let workoutUUID = notification.userInfo?["workoutUUID"] as? String,
               workoutUUID == workout.uuid.uuidString {
                checkRPEStatus()
            }
        }
        .sheet(isPresented: $showingTrainingLoadInfo) {
            TrainingLoadInfoSheet()
        }
    }
    
    // MARK: - Heart Rate Chart
    
    private var heartRateChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: Icons.Health.heart)
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
    
    // MARK: - Workout Type Section
    
    private var workoutTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ActivityContent.WorkoutTypes.workoutType)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // RPE Badge button
                RPEBadge(hasRPE: hasRPE) {
                    showingRPESheet = true
                }
            }
            
            // Display RPE and muscle groups
            let rpe = WorkoutMetadataService.shared.getRPE(for: workout)
            let muscleGroups = WorkoutMetadataService.shared.getMuscleGroups(for: workout)
            
            let _ = print("🟣 WorkoutTypeSection rendering - RPE: \(rpe?.description ?? "nil"), Muscle Groups: \(muscleGroups?.map { $0.rawValue } ?? [])")
            
            if rpe != nil || muscleGroups != nil {
                VStack(alignment: .leading, spacing: 6) {
                    // Calculate and show training load
                    if let rpe = rpe {
                        let trainingLoad = StrainScoreCalculator.calculateWorkoutLoad(
                            duration: workout.duration,
                            rpe: rpe,
                            muscleGroups: muscleGroups,
                            isEccentricFocused: false
                        )
                        
                        let simplifiedLoad = trainingLoad / 100.0
                        let loadLabel = trainingLoadLabel(trainingLoad)
                        
                        HStack(spacing: 4) {
                            Text(ActivityContent.TrainingLoad.trainingLoad)
                                .font(.subheadline)
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.1f, %@", simplifiedLoad, loadLabel))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.text.primary)
                            
                            Spacer()
                            
                            Button(action: { showingTrainingLoadInfo = true }) {
                                Image(systemName: Icons.Status.info)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Show RPE if available
                    if let rpe = rpe {
                        HStack(spacing: 4) {
                            Text(ActivityContent.TrainingLoad.effort)
                                .font(.subheadline)
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.1f RPE", rpe))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.text.primary)
                        }
                    }
                    
                    // Show muscle groups if available
                    if let muscleGroups = muscleGroups, !muscleGroups.isEmpty {
                        let _ = print("🟣 Rendering \(muscleGroups.count) muscle groups")
                        
                        // Separate specific muscle groups from workout types
                        let specificMuscles = muscleGroups.filter { 
                            $0.category == .specificMuscle 
                        }
                        let workoutTypes = muscleGroups.filter { 
                            $0.category == .movementPattern || $0.category == .compound || $0.category == .metabolic
                        }
                        
                        // Show specific muscle groups
                        if !specificMuscles.isEmpty {
                            HStack(spacing: 4) {
                                Text(ActivityContent.TrainingLoad.muscleGroups)
                                    .font(.subheadline)
                                    .foregroundColor(Color.text.secondary)
                                Text(specificMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.text.primary)
                            }
                        }
                        
                        // Show workout types
                        if !workoutTypes.isEmpty {
                            HStack(spacing: 4) {
                                Text("\(ActivityContent.WorkoutTypes.workoutType):")
                                    .font(.subheadline)
                                    .foregroundColor(Color.text.secondary)
                                Text(workoutTypes.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.text.primary)
                            }
                        }
                    }
                }
            } else {
                let _ = print("🟣 Showing 'Not specified'")
                Text(ActivityContent.WorkoutTypes.notSpecified)
                    .font(.subheadline)
                    .foregroundColor(Color.text.tertiary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var workoutTitle: String {
        switch workout.workoutActivityType {
        case .walking:
            return ActivityContent.WorkoutTypes.walking
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return ActivityContent.WorkoutTypes.strengthTraining
        default:
            return ActivityContent.WorkoutTypes.workout
        }
    }
    
    private var workoutType: String {
        switch workout.workoutActivityType {
        case .walking:
            return ActivityContent.WorkoutTypes.walking
        case .traditionalStrengthTraining:
            return ActivityContent.WorkoutTypes.strength
        case .functionalStrengthTraining:
            return ActivityContent.WorkoutTypes.functionalStrength
        default:
            return ActivityContent.WorkoutTypes.workout
        }
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .walking:
            return "figure.walk"
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "dumbbell.fill"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    private var isStrengthWorkout: Bool {
        return workout.workoutActivityType == .traditionalStrengthTraining ||
               workout.workoutActivityType == .functionalStrengthTraining
    }
    
    private func checkRPEStatus() {
        hasRPE = WorkoutMetadataService.shared.hasMetadata(for: workout)
    }
    
    private func trainingLoadLabel(_ load: Double) -> String {
        // Label based on training load intensity
        // Research-based thresholds for strength training load
        switch load {
        case 0..<1500:
            return ActivityContent.TrainingLoad.light
        case 1500..<3000:
            return ActivityContent.TrainingLoad.moderate
        case 3000..<4500:
            return ActivityContent.TrainingLoad.hard
        default:
            return ActivityContent.TrainingLoad.veryHard
        }
    }
    
}

// MARK: - Walking Workout Info Header

struct WalkingWorkoutInfoHeader: View {
    let workout: HKWorkout
    @ObservedObject var viewModel: WalkingDetailViewModel
    @State private var showingRPESheet = false
    @State private var storedRPE: Double?
    @State private var locationString: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Date/Time
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutTitle)
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
            
            // Primary Metrics Grid - 3 columns like cycling
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                CompactMetricItem(
                    label: "Duration",
                    value: ActivityFormatters.formatDuration(workout.duration)
                )
                
                if let distance = workout.totalDistance {
                    CompactMetricItem(
                        label: "Distance",
                        value: ActivityFormatters.formatDistance(distance.doubleValue(for: .meter()))
                    )
                }
                
                if let calories = workout.totalEnergyBurned {
                    CompactMetricItem(
                        label: "Calories",
                        value: "\(Int(calories.doubleValue(for: .kilocalorie())))"
                    )
                }
                
                if viewModel.steps > 0 {
                    CompactMetricItem(
                        label: "Steps",
                        value: "\(viewModel.steps)"
                    )
                }
                
                if let avgHR = viewModel.averageHeartRate {
                    CompactMetricItem(
                        label: "Avg HR",
                        value: "\(Int(avgHR))"
                    )
                }
                
                if let maxHR = viewModel.maxHeartRate {
                    CompactMetricItem(
                        label: "Max HR",
                        value: "\(Int(maxHR))"
                    )
                }
                
                // RPE for strength workouts
                if isStrengthWorkout, let rpe = storedRPE {
                    CompactMetricItem(
                        label: "RPE",
                        value: String(format: "%.1f", rpe)
                    )
                }
            }
            
        }
        .onAppear {
            loadRPE()
            Task {
                await loadLocation()
            }
        }
        .sheet(isPresented: $showingRPESheet) {
            RPEInputSheet(workout: workout) {
                loadRPE()
            }
        }
    }
    
    private var workoutTitle: String {
        switch workout.workoutActivityType {
        case .walking:
            return "Walking"
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "Strength Training"
        default:
            return "Workout"
        }
    }
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startDate)
    }
    
    private func createGridColumns() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
    
    private var isStrengthWorkout: Bool {
        return workout.workoutActivityType == .traditionalStrengthTraining ||
               workout.workoutActivityType == .functionalStrengthTraining
    }
    
    private func loadRPE() {
        storedRPE = WorkoutMetadataService.shared.getRPE(for: workout)
    }
    
    private func loadLocation() async {
        if let location = await ActivityLocationService.shared.getHealthKitLocation(workout) {
            await MainActor.run {
                locationString = location
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Heart Rate Chart

struct HeartRateChart: View {
    let samples: [(time: TimeInterval, heartRate: Double)]
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var yAxisRange: ClosedRange<Double> {
        guard !samples.isEmpty else { return 60...180 }
        
        let hrValues = samples.map { $0.heartRate }
        let minHR = hrValues.min() ?? 60
        let maxHR = hrValues.max() ?? 180
        
        // Add 10% padding
        let padding = (maxHR - minHR) * 0.1
        let lowerBound = max(40, minHR - padding)
        let upperBound = min(220, maxHR + padding)
        
        return lowerBound...upperBound
    }
    
    var body: some View {
        if samples.isEmpty {
            ZStack {
                Color(.systemGray6)
                Text(ActivityContent.HeartRate.noHeartRateData)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            Chart {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                    LineMark(
                        x: .value("Time", sample.time),
                        y: .value("HR", sample.heartRate)
                    )
                    .foregroundStyle(Color.workout.heartRate)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: .stride(by: timeStride())) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel {
                        if let timeValue = value.as(Double.self) {
                            Text(formatChartTime(timeValue))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue) \(CommonContent.Units.bpm))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartBackground { _ in
                Color.clear
            }
            .padding(.horizontal, 16)
            .chartYScale(domain: yAxisRange)
            .chartXScale(domain: (samples.first?.time ?? 0)...(samples.last?.time ?? 0))
        }
    }
    
    private func timeStride() -> Double {
        guard let duration = samples.last?.time else { return 300 }
        
        // Choose stride based on total duration - use round numbers
        if duration <= 600 { return 120 }      // ≤10 min: every 2 min
        if duration <= 1800 { return 300 }     // ≤30 min: every 5 min
        if duration <= 3600 { return 600 }     // ≤1 hour: every 10 min
        if duration <= 7200 { return 1200 }    // ≤2 hours: every 20 min
        return 1800                             // >2 hours: every 30 min
    }
    
    private func formatChartTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

