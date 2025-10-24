import SwiftUI
import MapKit

/// Latest Activity card using atomic CardContainer wrapper with MVVM
/// ViewModel handles all async operations (GPS, geocoding, map snapshots)
struct LatestActivityCardV2: View {
    @StateObject private var viewModel: LatestActivityCardViewModel
    @State private var isInitialLoad = true
    
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
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        HapticNavigationLink(destination: destinationView) {
            CardContainer(
                header: CardHeader(
                    title: titleWithIcon,
                    subtitle: viewModel.formattedDateAndTimeWithLocation,
                    action: .init(icon: Icons.System.chevronRight, action: {})
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Single metadata row with equal spacing
                    metadataRow
                    
                    // Map (if outdoor activity with GPS data or walking)
                    if viewModel.shouldShowMap || viewModel.activity.type == .walking {
                        mapSection
                    }
                    
                    // Virtual badge for indoor rides
                    if viewModel.isVirtualRide {
                        virtualBadge
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Title with Activity Icon
    
    private var titleWithIcon: String {
        let icon = activityTypeIcon
        return "\(icon) \(viewModel.activity.name)"
    }
    
    private var activityTypeIcon: String {
        switch viewModel.activity.type {
        case .cycling:
            return "🚴"
        case .running:
            return "🏃"
        case .walking:
            return "🚶"
        case .swimming:
            return "🏊"
        case .strength:
            return "💪"
        default:
            return "⚽"
        }
    }
    
    // MARK: - Metadata Row (Single Line with Equal Spacing)
    
    private var metadataRow: some View {
        HStack(spacing: 0) {
            metricItem(
                label: ActivityContent.Metrics.duration,
                value: viewModel.activity.duration.map { ActivityFormatters.formatDurationDetailed($0) } ?? "—"
            )
            
            Spacer()
            
            metricItem(
                label: ActivityContent.Metrics.distance,
                value: viewModel.activity.distance.map { ActivityFormatters.formatDistance($0) } ?? "—"
            )
            
            Spacer()
            
            metricItem(
                label: ActivityContent.Metrics.tss,
                value: viewModel.activity.tss.map { "\(Int($0))" } ?? "—"
            )
            
            Spacer()
            
            if let np = viewModel.activity.normalizedPower {
                metricItem(
                    label: "NORM PWR",
                    value: "\(Int(np))W"
                )
            } else if let avgHR = viewModel.activity.averageHeartRate {
                metricItem(
                    label: "AVG HR",
                    value: "\(Int(avgHR)) bpm"
                )
            } else if let intensity = viewModel.activity.intensityFactor {
                metricItem(
                    label: "INTENSITY",
                    value: String(format: "%.2f", intensity)
                )
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
    
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        Group {
            if viewModel.isLoadingMap {
                Rectangle()
                    .fill(Color.text.tertiary.opacity(0.1))
                    .frame(height: 180)
                    .overlay(ProgressView())
                    .cornerRadius(12)
                    .onAppear {
                        Logger.debug("🗺️ [Activity Card] Map loading started")
                    }
            } else if let snapshot = viewModel.mapSnapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .clipped()
                    .cornerRadius(12)
                    .onAppear {
                        Logger.debug("🗺️ [Activity Card] Map snapshot loaded, size: \(snapshot.size)")
                    }
            }
        }
    }
    
    // MARK: - Virtual Badge
    
    private var virtualBadge: some View {
        HStack {
            Image(systemName: Icons.System.waveform)
                .font(.caption)
            VRText("VIRTUAL", style: .caption, color: Color.text.primary)
                .metricLabel()
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(ColorScale.amberAccent.opacity(0.1))
        .cornerRadius(Spacing.cardCornerRadius)
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
