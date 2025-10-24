import SwiftUI
import MapKit
import HealthKit

/// Latest Activity card using atomic CardContainer wrapper with MVVM
/// ViewModel handles all async operations (GPS, geocoding, map snapshots)
struct LatestActivityCardV2: View {
    @StateObject private var viewModel: LatestActivityCardViewModel
    @State private var isInitialLoad = true
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    
    init(activity: UnifiedActivity) {
        _viewModel = StateObject(wrappedValue: LatestActivityCardViewModel(activity: activity))
    }
    
    var body: some View {
        Group {
            if isInitialLoad && viewModel.shouldShowMap {
                // Show skeleton while initial data loads to prevent layout bounce
                SkeletonActivityCard()
            } else {
                cardContent
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
                // Mark initial load complete after data is ready
                withAnimation(.easeOut(duration: 0.2)) {
                    isInitialLoad = false
                }
            }
            checkRPEStatus()
        }
        .sheet(isPresented: $showingRPESheet) {
            if let workout = viewModel.activity.healthKitWorkout {
                RPEInputSheet(workout: workout) {
                    hasRPE = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        HapticNavigationLink(destination: destinationView) {
            CardContainer(
                header: CardHeader(
                    title: viewModel.activity.name,
                    subtitle: formattedDateAndTime,
                    subtitleIcon: viewModel.activity.type.icon,
                    badge: viewModel.activity.isIndoorRide ? .init(text: "VIRTUAL", style: .info) : nil,
                    action: .init(icon: Icons.System.chevronRight, action: {})
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Metadata row with RPE badge on right
                    HStack(alignment: .top, spacing: 0) {
                        metadataGrid
                        
                        if shouldShowRPEButton {
                            Spacer()
                            rpeSection
                        }
                    }
                    
                    // Map (if outdoor activity with GPS data or walking)
                    if viewModel.shouldShowMap || viewModel.activity.type == .walking {
                        mapSection
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isInitialLoad)
    }
    
    // MARK: - Metadata Grid (4 Columns - Activity Type Specific)
    
    private var metadataGrid: some View {
        Group {
            // Customize metrics based on activity type
            switch viewModel.activity.type {
            case .strength:
                // Strength: Duration, Calories, Avg HR (3 columns)
                HStack(spacing: Spacing.md) {
                    metricItem(
                        label: ActivityContent.Metrics.duration,
                        value: viewModel.activity.duration.map { ActivityFormatters.formatDurationDetailed($0) } ?? "—"
                    )
                    metricItem(
                        label: "CALORIES",
                        value: viewModel.activity.calories.map { "\($0)" } ?? "—"
                    )
                    metricItem(
                        label: "AVG HR",
                        value: viewModel.activity.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—"
                    )
                    Spacer()
                }
                
            case .walking:
                // Walking: Duration, Distance, Steps, Avg HR (4 columns)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: Spacing.md) {
                    metricItem(
                        label: ActivityContent.Metrics.duration,
                        value: viewModel.activity.duration.map { ActivityFormatters.formatDurationDetailed($0) } ?? "—"
                    )
                    metricItem(
                        label: ActivityContent.Metrics.distance,
                        value: viewModel.activity.distance.map { ActivityFormatters.formatDistance($0) } ?? "—"
                    )
                    metricItem(
                        label: "STEPS",
                        value: viewModel.stepsData ?? "—"
                    )
                    metricItem(
                        label: "AVG HR",
                        value: viewModel.averageHRData ?? viewModel.activity.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—"
                    )
                }
                
            case .cycling:
                // Cycling: Duration, Distance, TSS, Norm Power (4 columns)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: Spacing.md) {
                    metricItem(
                        label: ActivityContent.Metrics.duration,
                        value: viewModel.activity.duration.map { ActivityFormatters.formatDurationDetailed($0) } ?? "—"
                    )
                    metricItem(
                        label: ActivityContent.Metrics.distance,
                        value: viewModel.activity.distance.map { ActivityFormatters.formatDistance($0) } ?? "—"
                    )
                    metricItem(
                        label: ActivityContent.Metrics.tss,
                        value: viewModel.activity.tss.map { "\(Int($0))" } ?? "—"
                    )
                    metricItem(
                        label: "NORM PWR",
                        value: viewModel.activity.normalizedPower.map { "\(Int($0))W" } ?? "—"
                    )
                }
                
            default:
                // Default: Duration, Distance, TSS, Avg HR (4 columns)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: Spacing.md) {
                    metricItem(
                        label: ActivityContent.Metrics.duration,
                        value: viewModel.activity.duration.map { ActivityFormatters.formatDurationDetailed($0) } ?? "—"
                    )
                    metricItem(
                        label: ActivityContent.Metrics.distance,
                        value: viewModel.activity.distance.map { ActivityFormatters.formatDistance($0) } ?? "—"
                    )
                    if let tss = viewModel.activity.tss {
                        metricItem(
                            label: ActivityContent.Metrics.tss,
                            value: "\(Int(tss))"
                        )
                    } else {
                        Color.clear.frame(height: 0)
                    }
                    metricItem(
                        label: "AVG HR",
                        value: viewModel.activity.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—"
                    )
                }
            }
        }
    }
    
    // MARK: - Single Metric Item (Matching Ride Detail Style)
    
    private func metricItem(label: String, value: String) -> some View {
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
    }
    
    // MARK: - Formatted Date (matching SharedActivityRowView)
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy 'at' HH:mm"  // Full month name (October instead of Oct)
        let calendar = Calendar.current
        
        if calendar.isDateInToday(viewModel.activity.startDate) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Today at \(timeFormatter.string(from: viewModel.activity.startDate))"
        } else if calendar.isDateInYesterday(viewModel.activity.startDate) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Yesterday at \(timeFormatter.string(from: viewModel.activity.startDate))"
        } else {
            return formatter.string(from: viewModel.activity.startDate)
        }
    }
    
    // MARK: - RPE Section
    
    private var shouldShowRPEButton: Bool {
        guard let workout = viewModel.activity.healthKitWorkout else {
            Logger.debug("❌ [RPE] No HealthKit workout for \(viewModel.activity.name)")
            return false
        }
        let isStrength = workout.workoutActivityType == .traditionalStrengthTraining ||
                        workout.workoutActivityType == .functionalStrengthTraining
        Logger.debug("✅ [RPE] \(isStrength ? "Showing" : "Hiding") RPE for \(viewModel.activity.name) - type: \(workout.workoutActivityType)")
        return isStrength
    }
    
    private var rpeSection: some View {
        RPEBadge(hasRPE: hasRPE) {
            showingRPESheet = true
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        Group {
            if viewModel.isLoadingMap {
                Rectangle()
                    .fill(Color.text.tertiary.opacity(0.1))
                    .frame(height: 300)
                    .overlay(ProgressView())
                    .cornerRadius(12)
            } else if let snapshot = viewModel.mapSnapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipped()
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - RPE Helpers
    
    private func checkRPEStatus() {
        guard let workout = viewModel.activity.healthKitWorkout else { return }
        hasRPE = WorkoutMetadataService.shared.hasMetadata(for: workout)
    }
    
    @ViewBuilder
    private func metricColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            VRText(label, style: .caption, color: Color.text.tertiary)
            VRText(value, style: .body, color: Color.text.primary)
        }
    }
    
    
    @ViewBuilder
    private var destinationView: some View {
        if let intervalsActivity = viewModel.activity.intervalsActivity {
            RideDetailSheet(activity: intervalsActivity)
        } else if let stravaActivity = viewModel.activity.stravaActivity {
            RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))
        } else if let healthWorkout = viewModel.activity.healthKitWorkout {
            WalkingDetailView(workout: healthWorkout)
        }
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
