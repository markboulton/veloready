import SwiftUI

/// Week-over-Week Changes component
struct WeekOverWeekComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics
    
    var body: some View {
        StandardCard(
            title: TrendsContent.WeeklyReport.weekOverWeek
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(spacing: Spacing.sm) {
                changeRow(
                    label: TrendsContent.WeeklyReport.recoveryLabel,
                    value: "\(Int(metrics.avgRecovery))%",
                    change: metrics.recoveryChange
                )
                changeRow(
                    label: TrendsContent.WeeklyReport.tssLabel,
                    value: "\(Int(metrics.weeklyTSS))",
                    change: nil
                )
                changeRow(
                    label: TrendsContent.WeeklyReport.timeLabel,
                    value: formatDuration(metrics.weeklyDuration),
                    change: nil
                )
                changeRow(
                    label: TrendsContent.WeeklyReport.ctlChange,
                    value: "\(Int(metrics.ctlEnd))",
                    change: metrics.ctlEnd - metrics.ctlStart
                )
                }
            }
        }
    }
    
    private func changeRow(label: String, value: String, change: Double?) -> some View {
        HStack(spacing: Spacing.xs / 2) {
            // Label column - flexible
            Text(label)
                .font(.body)
                .foregroundColor(.text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Value column - fixed width for alignment
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .trailing)
            
            // Change column - fixed width for alignment
            Group {
                if let change = change {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text("\(Int(abs(change)))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(change >= 0 ? ColorScale.greenAccent : ColorScale.redAccent)
                } else {
                    Text(CommonContent.Formatting.dash)
                        .font(.caption)
                        .foregroundColor(.text.tertiary)
                }
            }
            .frame(width: 60, alignment: .trailing)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
