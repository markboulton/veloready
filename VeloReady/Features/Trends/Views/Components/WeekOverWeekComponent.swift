import SwiftUI

/// Week-over-Week Changes component
struct WeekOverWeekComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.weekOverWeek)
                .font(.heading)
            
            VStack(spacing: 8) {
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
    
    private func changeRow(label: String, value: String, change: Double?) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.text.secondary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text("\(Int(abs(change)))")
                        .font(.caption)
                }
                .foregroundColor(change >= 0 ? ColorScale.greenAccent : ColorScale.redAccent)
                .frame(width: 50, alignment: .trailing)
            } else {
                Text("")
                    .frame(width: 50)
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
