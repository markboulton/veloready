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
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.recoveryTrend)
                            .font(.cardTitle)
                            .foregroundColor(.text.primary)
                        
                        if !data.isEmpty {
                            Text("\(Int(averageRecovery))% avg")
                                .font(.metricMedium)
                                .foregroundColor(recoveryColor(averageRecovery))
                        } else {
                            Text("No data")
                                .font(.bodySecondary)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                }
                
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text("Not enough recovery history")
                    .font(.bodySecondary)
                    .foregroundColor(.text.secondary)
                
                Text("To see recovery trends:")
                    .font(.labelSecondary)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("1.")
                            .fontWeight(.medium)
                        Text("Wear Apple Watch overnight (starting tonight)")
                    }
                    HStack {
                        Text("2.")
                            .fontWeight(.medium)
                        Text("Grant HealthKit permissions for HRV & RHR")
                    }
                    HStack {
                        Text("3.")
                            .fontWeight(.medium)
                        Text("Tomorrow: First recovery score appears")
                    }
                    HStack {
                        Text("4.")
                            .fontWeight(.medium)
                        Text("After 7 days: Trends become meaningful")
                    }
                }
                .font(.labelSecondary)
                .foregroundColor(.text.tertiary)
                
                Text("Your recovery scores are calculated daily at midnight")
                    .font(.labelSecondary)
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
                            .font(.labelSecondary)
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
                    .font(.labelSecondary)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.insight)
                .font(.labelPrimary)
                .foregroundColor(.text.secondary)
            
            Text(generateInsight())
                .font(.bodySecondary)
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
