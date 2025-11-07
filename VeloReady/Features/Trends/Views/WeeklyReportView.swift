import SwiftUI

/// Weekly Performance Report View - Refactored with modular components
struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyReportViewModel()
    @StateObject private var trendsViewModel = TrendsViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var selectedSleepDay = 0 // For segmented control
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.md) {
                    GeometryReader { vStackGeo in
                        Color.clear.preference(key: ViewWidthKey.self, value: vStackGeo.size.width)
                    }
                    .frame(height: 0)
                // 1. AI Summary Header
                WeeklyReportHeaderComponent(
                    aiSummary: viewModel.aiSummary,
                    aiError: viewModel.aiError,
                    isLoading: viewModel.isLoadingAI,
                    weekStartDate: viewModel.weekStartDate,
                    daysUntilNextReport: viewModel.daysUntilNextReport
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "Header", width: geo.size.width))
                })
                
                // 2. Performance Overview (2-week trend)
                PerformanceOverviewCardV2(
                    recoveryData: trendsViewModel.recoveryTrendData,
                    loadData: trendsViewModel.dailyLoadData,
                    sleepData: trendsViewModel.sleepData,
                    timeRange: .days30
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "PerformanceOverview", width: geo.size.width))
                })
                
                // 3. Fitness Trajectory (CTL/ATL/Form)
                FitnessTrajectoryComponent(
                    metrics: viewModel.weeklyMetrics,
                    ctlData: viewModel.ctlHistoricalData
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "FitnessTrajectory", width: geo.size.width))
                })
                
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
                // Hide when simulating no sleep data
                if !viewModel.sleepHypnograms.isEmpty && !proConfig.simulateNoSleepData {
                    SleepHypnogramComponent(
                        hypnograms: viewModel.sleepHypnograms,
                        selectedDay: $selectedSleepDay
                    )
                }
                
                // 7. Sleep Schedule (Circadian Rhythm)
                // Hide when simulating no sleep data
                if let circadian = viewModel.circadianRhythm, !proConfig.simulateNoSleepData {
                    SleepScheduleComponent(circadian: circadian)
                }
                
                // 8. Week-over-Week Changes
                if let metrics = viewModel.weeklyMetrics {
                    WeekOverWeekComponent(metrics: metrics)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 120)
        }
        .scrollDisabled(false) // Ensure vertical scrolling works
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.background.app)
        .task {
            await viewModel.loadWeeklyReport()
            await trendsViewModel.loadTrendData()
        }
        .refreshable {
            await viewModel.loadWeeklyReport()
        }
        }
    }
}

// MARK: - PreferenceKeys for width debugging
struct ViewWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ComponentWidth: Equatable {
    let name: String
    let width: CGFloat
}

struct ComponentWidthKey: PreferenceKey {
    static var defaultValue: ComponentWidth = ComponentWidth(name: "", width: 0)
    static func reduce(value: inout ComponentWidth, nextValue: () -> ComponentWidth) {
        let next = nextValue()
        if next.width > 0 {
            value = next
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
