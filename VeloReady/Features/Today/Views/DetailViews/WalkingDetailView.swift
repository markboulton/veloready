import SwiftUI
import HealthKit
import MapKit
import Charts

/// Detail view for walking/strength workouts from Apple Health
struct WalkingDetailView: View {
    let workout: HKWorkout
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WalkingDetailViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header with key metrics - using shared component
                WalkingWorkoutInfoHeader(workout: workout, viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                
                // Heart Rate Chart
                if !viewModel.heartRateSamples.isEmpty {
                    heartRateChartSection
                        .padding(.bottom, 20)
                }
                
                // Map - using shared component
                WorkoutMapSection(
                    coordinates: viewModel.routeCoordinates ?? [],
                    isLoading: viewModel.isLoadingMap
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color.background.primary)
        .navigationTitle(workoutTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadWorkoutData(workout: workout)
        }
    }
    
    // MARK: - Heart Rate Chart
    
    private var heartRateChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Heart Rate")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let avg = viewModel.averageHeartRate, let max = viewModel.maxHeartRate {
                    HStack(spacing: 12) {
                        Text("Avg: \(Int(avg))")
                        Text("Max: \(Int(max))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            HeartRateChart(samples: viewModel.heartRateSamples)
                .frame(height: 200)
                .background(Color.background.primary)
        }
    }
    
    // MARK: - Helpers
    
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
    
    private var workoutType: String {
        switch workout.workoutActivityType {
        case .walking:
            return "Walking"
        case .traditionalStrengthTraining:
            return "Strength"
        case .functionalStrengthTraining:
            return "Functional Strength"
        default:
            return "Workout"
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
    
}

// MARK: - Walking Workout Info Header

struct WalkingWorkoutInfoHeader: View {
    let workout: HKWorkout
    @ObservedObject var viewModel: WalkingDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Date/Time
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.text.primary)
                
                Text(formattedDateAndTime)
                    .font(.subheadline)
                    .foregroundStyle(Color.text.secondary)
            }
            
            // Primary Metrics Grid - 3 columns like cycling
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                CompactMetricItem(
                    label: "Duration",
                    value: formatDuration(workout.duration)
                )
                
                if let distance = workout.totalDistance {
                    CompactMetricItem(
                        label: "Distance",
                        value: formatDistance(distance.doubleValue(for: .meter()))
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
        return String(format: "%.2f km", km)
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
                Text("No heart rate data")
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
                    .lineStyle(StrokeStyle(lineWidth: 2))
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
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                        }
                    }
                }
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

