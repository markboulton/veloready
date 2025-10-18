import SwiftUI

/// Recovery Capacity component showing key recovery metrics
struct RecoveryCapacityComponent: View {
    let metrics: WeeklyReportViewModel.WeeklyMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.recoveryCapacity)
                .font(.heading)
            
            HStack(alignment: .top, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.avgRecovery)
                        .metricLabel()
                    HStack(spacing: 4) {
                        Text("\(Int(metrics.avgRecovery))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.health.heartRate)
                        if metrics.recoveryChange != 0 {
                            Image(systemName: metrics.recoveryChange > 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(metrics.recoveryChange > 0 ? ColorScale.greenAccent : ColorScale.redAccent)
                            Text("\(Int(abs(metrics.recoveryChange)))%")
                                .font(.caption)
                                .foregroundColor(metrics.recoveryChange > 0 ? ColorScale.greenAccent : ColorScale.redAccent)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.hrvTrend)
                        .metricLabel()
                    Text(metrics.hrvTrend)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.sleepLabel)
                        .metricLabel()
                    Text(String(format: "%.1fh", metrics.avgSleep))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Text(recoveryCapacityMessage(metrics: metrics))
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func recoveryCapacityMessage(metrics: WeeklyReportViewModel.WeeklyMetrics) -> String {
        if metrics.avgRecovery >= 75 {
            return TrendsContent.WeeklyReport.excellentCapacity
        } else if metrics.avgRecovery >= 65 {
            return TrendsContent.WeeklyReport.goodCapacity
        } else if metrics.avgRecovery >= 55 {
            return TrendsContent.WeeklyReport.adequateCapacity
        } else {
            return TrendsContent.WeeklyReport.lowCapacity
        }
    }
}
