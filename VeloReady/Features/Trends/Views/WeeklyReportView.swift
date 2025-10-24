import SwiftUI

// MARK: - Gesture Modifier to Constrain Scrolling
extension View {
    /// Constrains scrolling to vertical only by intercepting horizontal drag gestures
    func verticalScrollOnly() -> some View {
        self.gesture(
            DragGesture()
                .onChanged { _ in }
                .onEnded { _ in }
        )
    }
}

/// Weekly Performance Report View - Refactored with modular components
struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyReportViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var selectedSleepDay = 0 // For segmented control
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.md) {
                // 1. AI Summary Header
                WeeklyReportHeaderComponent(
                    aiSummary: viewModel.aiSummary,
                    aiError: viewModel.aiError,
                    isLoading: viewModel.isLoadingAI,
                    weekStartDate: viewModel.weekStartDate,
                    daysUntilNextReport: viewModel.daysUntilNextReport
                )
                
                // 2. Fitness Trajectory (CTL/ATL/Form)
                FitnessTrajectoryComponent(
                    metrics: viewModel.weeklyMetrics,
                    ctlData: viewModel.ctlHistoricalData
                )
                
                // 3. Wellness Foundation
                if let wellness = viewModel.wellnessFoundation {
                    WellnessFoundationComponent(wellness: wellness)
                }
                
                // 4. Recovery Capacity
                if let metrics = viewModel.weeklyMetrics {
                    RecoveryCapacityComponent(metrics: metrics)
                }
                
                // 5. Training Load Summary
                TrainingLoadComponent(
                    metrics: viewModel.weeklyMetrics,
                    zones: viewModel.trainingZoneDistribution
                )
                
                // 6. Sleep Hypnograms with Segmented Control
                if !viewModel.sleepHypnograms.isEmpty {
                    SleepHypnogramComponent(
                        hypnograms: viewModel.sleepHypnograms,
                        selectedDay: $selectedSleepDay
                    )
                }
                
                // 7. Sleep Schedule (Circadian Rhythm)
                if let circadian = viewModel.circadianRhythm {
                    SleepScheduleComponent(circadian: circadian)
                }
                
                // 8. Week-over-Week Changes
                if let metrics = viewModel.weeklyMetrics {
                    WeekOverWeekComponent(metrics: metrics)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 120)
        }
        .background(Color.background.app)
        .gesture(
            DragGesture()
                .onChanged { _ in }
                .onEnded { _ in }
        )
        .task {
            await viewModel.loadWeeklyReport()
        }
        .refreshable {
            await viewModel.loadWeeklyReport()
        }
    }
}

// MARK: - Preview

struct WeeklyReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeeklyReportView()
                .navigationTitle(TrendsContent.WeeklyReport.title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
