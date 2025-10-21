import SwiftUI

/// Fitness Trajectory component showing CTL/ATL/TSB over 7 days
struct FitnessTrajectoryComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics?
    let ctlData: [FitnessTrajectoryChart.DataPoint]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.fitnessTrajectory)
                .font(.heading)
                .padding(.top, Spacing.xxl)
            
            if let metrics = metrics, let ctlData = ctlData {
                // Chart showing CTL, ATL, TSB over 7 days
                FitnessTrajectoryChart(data: ctlData)
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
                
                Text(tsbInterpretation(metrics.tsb))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            } else {
                Text(TrendsContent.WeeklyReport.noTrainingData)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
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
