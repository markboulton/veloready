import SwiftUI

/// Weekly Performance Report View - Refactored with modular components
struct WeeklyReportView: View {
    @StateObject private var viewState = WeeklyReportViewState()
    @ObservedObject private var trendsState = TrendsViewState.shared
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
                    aiSummary: viewState.aiSummary,
                    aiError: viewState.aiError,
                    isLoading: viewState.isLoadingAI,
                    weekStartDate: viewState.weekStartDate,
                    daysUntilNextReport: viewState.daysUntilNextReport
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "Header", width: geo.size.width))
                })
                
                // 2. Performance Overview (2-week trend)
                PerformanceOverviewCardV2(
                    recoveryData: trendsState.scoresData?.recovery ?? [],
                    loadData: trendsState.fitnessData?.dailyLoad ?? [],
                    sleepData: trendsState.scoresData?.sleep ?? [],
                    timeRange: .days30
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "PerformanceOverview", width: geo.size.width))
                })
                
                // 3. Fitness Trajectory (CTL/ATL/Form)
                FitnessTrajectoryComponent(
                    metrics: viewState.weeklyMetrics,
                    ctlData: viewState.ctlHistoricalData
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ComponentWidthKey.self, value: ComponentWidth(name: "FitnessTrajectory", width: geo.size.width))
                })
                
                // 3. Wellness Foundation
                if let wellness = viewState.wellnessFoundation {
                    WellnessFoundationComponent(wellness: wellness)
                }

                // 4. Recovery Capacity
                if let metrics = viewState.weeklyMetrics {
                    RecoveryCapacityComponent(metrics: metrics)
                }

                // 5. Training Load Summary
                TrainingLoadComponent(
                    metrics: viewState.weeklyMetrics,
                    zones: viewState.trainingZoneDistribution
                )

                // 6. Sleep Hypnograms with Segmented Control
                // Hide when simulating no sleep data
                if !viewState.sleepHypnograms.isEmpty && !proConfig.simulateNoSleepData {
                    SleepHypnogramComponent(
                        hypnograms: viewState.sleepHypnograms,
                        selectedDay: $selectedSleepDay
                    )
                }

                // 7. Sleep Schedule (Circadian Rhythm)
                // Hide when simulating no sleep data
                if let circadian = viewState.circadianRhythm, !proConfig.simulateNoSleepData {
                    SleepScheduleComponent(circadian: circadian)
                }

                // 8. Week-over-Week Changes
                if let metrics = viewState.weeklyMetrics {
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
            await viewState.loadWeeklyReport()
            // TrendsViewState.shared is loaded from TrendsView - no need to load again
        }
        .refreshable {
            await viewState.loadWeeklyReport()
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
