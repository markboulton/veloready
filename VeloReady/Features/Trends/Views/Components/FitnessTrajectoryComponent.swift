import SwiftUI

/// Fitness Trajectory component showing CTL/ATL/TSB with time range selection
struct FitnessTrajectoryComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics?
    let ctlData: [FitnessTrajectoryChart.DataPoint]?
    
    @State private var selectedTimeRange: FitnessTimeRange = .week
    @StateObject private var trainingLoadService = TrainingLoadService.shared
    
    enum FitnessTimeRange: Int, CaseIterable {
        case week = 0
        case month = 1
        case threeMonths = 2
        
        var label: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
            }
        }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    private var displayData: [FitnessTrajectoryChart.DataPoint] {
        trainingLoadService.getData(days: selectedTimeRange.days)
    }
    
    var body: some View {
        StandardCard(
            title: TrendsContent.WeeklyReport.fitnessTrajectory
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Segmented control for time range
                LiquidGlassSegmentedControl(
                    segments: FitnessTimeRange.allCases.map { timeRange in
                        SegmentItem(value: timeRange.rawValue, label: timeRange.label)
                    },
                    selection: Binding(
                        get: { selectedTimeRange.rawValue },
                        set: { if let range = FitnessTimeRange(rawValue: $0) { selectedTimeRange = range } }
                    )
                )
                
                if !displayData.isEmpty {
                // Chart showing CTL, ATL, TSB for selected time range
                FitnessTrajectoryChart(data: displayData)
                    .frame(height: 200)
                
                // Legend - colors match chart lines (values shown on last point)
                HStack(spacing: Spacing.lg) {
                    legendItem(
                        label: TrendsContent.WeeklyReport.ctlLabel,
                        color: .button.primary
                    )
                    legendItem(
                        label: TrendsContent.WeeklyReport.atlLabel,
                        color: .semantic.warning
                    )
                    legendItem(
                        label: TrendsContent.WeeklyReport.formLabel,
                        color: ColorScale.greenAccent
                    )
                }
                
                if let metrics = metrics {
                    Text(tsbInterpretation(metrics.tsb))
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                } else {
                    Text(TrendsContent.WeeklyReport.noTrainingData)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            }
        }
    }
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs / 2) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func tsbColor(_ tsb: Double) -> Color {
        switch tsb {
        case ..<(-10): return .red
        case -10..<5: return .yellow
        case 5..<25: return .green
        default: return .blue
        }
    }
    
    private func tsbInterpretation(_ tsb: Double) -> String {
        switch tsb {
        case ..<(-10): return TrendsContent.WeeklyReport.fatigued
        case -10..<5: return TrendsContent.WeeklyReport.optimalTraining
        case 5..<25: return TrendsContent.WeeklyReport.fresh
        default: return TrendsContent.WeeklyReport.veryFresh
        }
    }
}

// MARK: - Preview

#Preview {
    FitnessTrajectoryComponent(
        metrics: WeeklyReportViewModel.WeeklyMetrics(
            avgRecovery: 75,
            recoveryChange: -5,
            avgSleep: 7.2,
            sleepConsistency: 82,
            hrvTrend: "Stable",
            weeklyTSS: 486,
            weeklyDuration: 26000,
            workoutCount: 5,
            ctlStart: 70,
            ctlEnd: 74,
            atl: 68,
            tsb: 6
        ),
        ctlData: generateMockCTLData()
    )
    .padding()
    .background(Color.background.primary)
}
