import SwiftUI
import MapKit

/// Latest Activity card using atomic CardContainer wrapper with MVVM
/// ViewModel handles all async operations (GPS, geocoding, map snapshots)
struct LatestActivityCardV2: View {
    @StateObject private var viewModel: LatestActivityCardViewModel
    
    init(activity: UnifiedActivity) {
        _viewModel = StateObject(wrappedValue: LatestActivityCardViewModel(activity: activity))
    }
    
    var body: some View {
        HapticNavigationLink(destination: destinationView) {
            CardContainer(
                header: CardHeader(
                    title: viewModel.activity.name,
                    subtitle: viewModel.formattedDateAndTimeWithLocation,
                    action: .init(icon: Icons.System.chevronRight, action: {})
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Metadata Row 1
                    HStack(spacing: Spacing.md) {
                        if let duration = viewModel.activity.duration {
                            metricColumn(
                                label: ActivityContent.Metrics.duration,
                                value: ActivityFormatters.formatDurationDetailed(duration)
                            )
                        }
                        
                        if let distance = viewModel.activity.distance {
                            metricColumn(
                                label: ActivityContent.Metrics.distance,
                                value: ActivityFormatters.formatDistance(distance)
                            )
                        }
                        
                        if let tss = viewModel.activity.tss {
                            metricColumn(
                                label: ActivityContent.Metrics.tss,
                                value: "\(Int(tss))"
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Metadata Row 2
                    HStack(spacing: Spacing.md) {
                        if let np = viewModel.activity.normalizedPower {
                            metricColumn(
                                label: "Norm Power",
                                value: "\(Int(np))W"
                            )
                        }
                        
                        if let intensity = viewModel.activity.intensityFactor {
                            metricColumn(
                                label: "Intensity",
                                value: String(format: "%.2f", intensity)
                            )
                        }
                        
                        if let avgHR = viewModel.activity.averageHeartRate {
                            metricColumn(
                                label: "Avg HR",
                                value: "\(Int(avgHR)) bpm"
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Map (if outdoor activity with GPS data)
                    if viewModel.shouldShowMap {
                        if viewModel.isLoadingMap {
                            Rectangle()
                                .fill(Color.text.tertiary.opacity(0.1))
                                .frame(height: 180)
                                .overlay(ProgressView())
                                .cornerRadius(12)
                        } else if let snapshot = viewModel.mapSnapshot {
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
                await viewModel.loadData()
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
