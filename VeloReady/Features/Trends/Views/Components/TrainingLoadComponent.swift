import SwiftUI

/// Training Load Summary component
struct TrainingLoadComponent: View {
    let metrics: WeeklyReportDataLoader.WeeklyMetrics?
    let zones: WeeklyReportDataLoader.TrainingZoneDistribution?
    
    var body: some View {
        StandardCard(
            title: TrendsContent.WeeklyReport.trainingLoadSummary
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let metrics = metrics {
                // Weekly totals
                HStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.WeeklyReport.totalTSS)
                            .metricLabel()
                        Text("\(Int(metrics.weeklyTSS))")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.WeeklyReport.trainingTime)
                            .metricLabel()
                        Text(formatDuration(metrics.weeklyDuration))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.WeeklyReport.workouts)
                            .metricLabel()
                        Text("\(metrics.workoutCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, Spacing.sm)
            }
            
            if let zones = zones {
                Divider()
                    .padding(.vertical, Spacing.md)
                
                // Training days breakdown
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(TrendsContent.WeeklyReport.trainingPattern)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: Spacing.md) {
                        dayTypePill(TrendsContent.WeeklyReport.optimalDays, count: zones.optimalDays, color: .green)
                        dayTypePill(TrendsContent.WeeklyReport.hardDays, count: zones.overreachingDays, color: .orange)
                        dayTypePill(TrendsContent.WeeklyReport.easyRestDays, count: zones.restoringDays, color: .blue)
                    }
                    
                    Text(trainingPatternMessage(zones: zones))
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                .padding(.bottom, Spacing.sm)
                
                Divider()
                    .padding(.vertical, Spacing.md)
                
                // Intensity distribution
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(TrendsContent.WeeklyReport.intensityDistribution)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    intensityBar(
                        label: TrendsContent.WeeklyReport.easyZone,
                        percent: zones.zoneEasyPercent,
                        color: .green
                    )
                    intensityBar(
                        label: TrendsContent.WeeklyReport.tempoZone,
                        percent: zones.zoneTempoPercent,
                        color: .orange
                    )
                    intensityBar(
                        label: TrendsContent.WeeklyReport.hardZone,
                        percent: zones.zoneHardPercent,
                        color: .red
                    )
                    
                    HStack(spacing: Spacing.xs) {
                        Text(TrendsContent.WeeklyReport.polarization)
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                        Text("\(Int(zones.polarizationScore))/100")
                            .font(.caption)
                            .fontWeight(.medium)
                        if zones.polarizationScore >= 80 {
                            Image(systemName: Icons.Status.successFill)
                                .font(.caption)
                                .foregroundColor(ColorScale.greenAccent)
                        }
                        Text(zones.polarizationScore >= 80 ? TrendsContent.WeeklyReport.wellPolarized : TrendsContent.WeeklyReport.couldBePolarized)
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                }
            }
            }
        }
    }
    
    private func dayTypePill(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func trainingPatternMessage(zones: WeeklyReportDataLoader.TrainingZoneDistribution) -> String {
        if zones.optimalDays >= 4 {
            return TrendsContent.WeeklyReport.goodBalance
        } else if zones.overreachingDays > zones.optimalDays {
            return TrendsContent.WeeklyReport.highStress
        } else {
            return TrendsContent.WeeklyReport.lightWeek
        }
    }
    
    private func intensityBar(label: String, percent: Double, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
                .frame(width: 90, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ColorPalette.neutral200)
                    
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(width: geometry.size.width * (percent / 100))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
            
            Text("\(Int(percent))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
