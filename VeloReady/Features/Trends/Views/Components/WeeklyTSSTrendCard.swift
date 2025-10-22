import SwiftUI
import Charts

/// Card displaying Weekly TSS (Training Stress Score) trend
struct WeeklyTSSTrendCard: View {
    let data: [TrendsViewModel.WeeklyTSSDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageTSS: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.tss).reduce(0, +) / Double(data.count)
    }
    
    private var totalTSS: Double {
        data.map(\.tss).reduce(0, +)
    }
    
    var body: some View {
        StandardCard(
            icon: "chart.bar.fill",
            iconColor: .workout.tss,
            title: TrendsContent.Cards.weeklyTSS,
            subtitle: !data.isEmpty ? "\(Int(averageTSS)) weekly TSS" : CommonContent.States.noDataFound
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
            Image(systemName: Icons.System.chartBarXAxis)
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.TrainingLoad.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.TrainingLoad.toTrackLoad)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.WeeklyTSS.completeCyclingWorkouts)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.WeeklyTSS.uploadToIntervals)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.WeeklyTSS.tssAutoCalculated)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.WeeklyTSS.trackForTrends)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.WeeklyTSS.tssDefinition)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Week", point.weekStart, unit: .weekOfYear),
                y: .value("TSS", point.tss)
            )
            .foregroundStyle(barColor(point.tss))
            .cornerRadius(4)
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.WeeklyTSS.totalTSS)
                        .metricLabel()
                    
                    Text("\(Int(totalTSS))")
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(CommonContent.TimeUnits.weeks)
                        .metricLabel()
                    
                    Text("\(data.count)")
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
            }
            
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
        
        let avg = averageTSS
        
        if avg > 600 {
            return "High training volume (\(Int(avg)) TSS/week). Ensure adequate recovery to avoid overtraining."
        } else if avg > 400 {
            return "Solid training load (\(Int(avg)) TSS/week). Good balance of volume and intensity."
        } else if avg > 200 {
            return "Moderate training volume (\(Int(avg)) TSS/week). Room to increase volume if building fitness."
        } else {
            return "Low training volume (\(Int(avg)) TSS/week). Consider increasing workload gradually."
        }
    }
    
    private func barColor(_ tss: Double) -> Color {
        if tss > 600 {
            return ColorScale.redAccent
        } else if tss > 400 {
            return ColorScale.amberAccent
        } else if tss > 200 {
            return ColorScale.blueAccent
        } else {
            return ColorScale.greenAccent
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            WeeklyTSSTrendCard(
                data: (0..<12).map { week in
                    let base = 450.0
                    let variation = Double.random(in: -100...150)
                    return TrendsViewModel.WeeklyTSSDataPoint(
                        weekStart: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                        tss: max(100, base + variation)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Empty
            WeeklyTSSTrendCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
