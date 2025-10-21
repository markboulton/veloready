import SwiftUI

/// Weekly Performance Report View - Refactored with modular components
struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyReportViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var selectedSleepDay = 0 // For segmented control
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. AI Summary Header
                WeeklyReportHeaderComponent(
                    aiSummary: viewModel.aiSummary,
                    aiError: viewModel.aiError,
                    isLoading: viewModel.isLoadingAI,
                    weekStartDate: viewModel.weekStartDate,
                    daysUntilNextReport: viewModel.daysUntilNextReport
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                
                SectionDivider()
                
                // 2. Fitness Trajectory (CTL/ATL/Form)
                FitnessTrajectoryComponent(
                    metrics: viewModel.weeklyMetrics,
                    ctlData: viewModel.ctlHistoricalData
                )
                .padding(.horizontal, Spacing.lg)
                
                SectionDivider()
                
                // 3. Wellness Foundation
                if let wellness = viewModel.wellnessFoundation {
                    WellnessFoundationComponent(wellness: wellness)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 4. Recovery Capacity
                if let metrics = viewModel.weeklyMetrics {
                    RecoveryCapacityComponent(metrics: metrics)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 5. Training Load Summary
                TrainingLoadComponent(
                    metrics: viewModel.weeklyMetrics,
                    zones: viewModel.trainingZoneDistribution
                )
                .padding(.horizontal, Spacing.lg)
                
                SectionDivider()
                
                // 6. Sleep Hypnograms with Segmented Control
                if !viewModel.sleepHypnograms.isEmpty {
                    SleepHypnogramComponent(
                        hypnograms: viewModel.sleepHypnograms,
                        selectedDay: $selectedSleepDay
                    )
                    .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 7. Sleep Schedule (Circadian Rhythm)
                if let circadian = viewModel.circadianRhythm {
                    SleepScheduleComponent(circadian: circadian)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 8. Week-over-Week Changes
                if let metrics = viewModel.weeklyMetrics {
                    WeekOverWeekComponent(metrics: metrics)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
            }
        }
        .background(Color.background.primary)
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
