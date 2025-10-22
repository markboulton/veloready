import SwiftUI
import Charts

/// Card displaying Recovery score trend over time
struct RecoveryTrendCard: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageRecovery: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    var body: some View {
        StandardCard(
            icon: "heart.fill",
            iconColor: .health.heartRate,
            title: TrendsContent.RecoveryTrend.trackDays,
            subtitle: !data.isEmpty ? "\(Int(averageRecovery))% avg" : TrendsContent.noDataFound
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                
                // Chart
                if data.isEmpty {
                    emptyState
                } else {
                    chart
                }
                
                // Insight
                if !data.isEmpty {
                    insight
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.DataSource.intervalsICU)
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.RecoveryTrend.notEnoughHistory)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.RecoveryTrend.toTrackRecovery)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .fontWeight(.medium)
                        Text(TrendsContent.RecoveryTrend.wearWatch)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepTwo)
                            .fontWeight(.medium)
                        Text(TrendsContent.RecoveryTrend.enableHealthKit)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepThree)
                            .fontWeight(.medium)
                        Text(TrendsContent.RecoveryTrend.firstScoreAppears)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepFour)
                            .fontWeight(.medium)
                        Text(TrendsContent.RecoveryTrend.recoveryKey)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.RecoveryTrend.noData)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Recovery", point.value)
            )
            .foregroundStyle(recoveryColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 1))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Recovery", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        recoveryColor(point.value).opacity(0.3),
                        recoveryColor(point.value).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.insight)
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            Text(generateInsight())
                .font(.body)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func generateInsight() -> String {
        guard !data.isEmpty else { return "No data available" }
        
        let avg = averageRecovery
        
        if avg >= 75 {
            return "Excellent recovery average (\(Int(avg))%). Your body is responding well to training."
        } else if avg >= 60 {
            return "Good recovery average (\(Int(avg))%). You're maintaining solid readiness."
        } else if avg >= 50 {
            return "Moderate recovery average (\(Int(avg))%). Consider more rest or easier training."
        } else {
            return "Low recovery average (\(Int(avg))%). Increase rest days and prioritize sleep."
        }
    }
    
    private func recoveryColor(_ value: Double) -> Color {
        if value >= 70 {
            return ColorScale.greenAccent
        } else if value >= 50 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.redAccent
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            RecoveryTrendCard(
                data: (0..<90).map { day in
                    let base = 72.0
                    let variation = Double.random(in: -10...10)
                    return TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: max(45, min(95, base + variation))
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Empty
            RecoveryTrendCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
