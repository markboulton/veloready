import SwiftUI

/// Fitness Trajectory component showing CTL/ATL/TSB over 7 days
struct FitnessTrajectoryComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics?
    let ctlData: [FitnessTrajectoryChart.DataPoint]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.fitnessTrajectory)
                .font(.heading)
            
            if let metrics = metrics, let ctlData = ctlData {
                // Chart showing CTL, ATL, TSB over 7 days
                FitnessTrajectoryChart(data: ctlData)
                    .frame(height: 200)
                
                // Current values
                HStack(spacing: Spacing.lg) {
                    metricPill(
                        label: TrendsContent.WeeklyReport.ctlLabel,
                        value: "\(Int(metrics.ctlEnd))",
                        change: metrics.ctlEnd - metrics.ctlStart,
                        color: .workout.power
                    )
                    metricPill(
                        label: TrendsContent.WeeklyReport.atlLabel,
                        value: "\(Int(metrics.atl))",
                        change: nil,
                        color: .workout.tss
                    )
                    metricPill(
                        label: TrendsContent.WeeklyReport.formLabel,
                        value: "\(Int(metrics.tsb))",
                        change: nil,
                        color: tsbColor(metrics.tsb)
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
    
    private func metricPill(label: String, value: String, change: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                if let change = change, change != 0 {
                    Text(change > 0 ? "+\(Int(change))" : "\(Int(change))")
                        .font(.caption)
                        .foregroundColor(change > 0 ? .green : .red)
                }
            }
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
