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
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.weeklyTSS)
                            .font(.cardTitle)
                            .foregroundColor(.text.primary)
                        
                        if !data.isEmpty {
                            HStack(spacing: Spacing.xs) {
                                Text("\(Int(averageTSS))")
                                    .font(.metricMedium)
                                    .foregroundColor(.workout.tss)
                                
                                Text("TSS/week avg")
                                    .font(.labelPrimary)
                                    .foregroundColor(.text.secondary)
                            }
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text("No training data yet")
                    .font(.bodySecondary)
                    .foregroundColor(.text.secondary)
                
                Text("To see weekly training load:")
                    .font(.labelSecondary)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("•")
                        Text("Complete cycling workouts")
                    }
                    HStack {
                        Text("•")
                        Text("Upload to Intervals.icu")
                    }
                    HStack {
                        Text("•")
                        Text("TSS auto-calculated from power")
                    }
                    HStack {
                        Text("•")
                        Text("Track for 2+ weeks to see trends")
                    }
                }
                .font(.labelSecondary)
                .foregroundColor(.text.tertiary)
                
                Text("TSS = Training Stress Score (workout intensity × duration)")
                    .font(.labelSecondary)
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
                            .font(.labelSecondary)
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
                            .font(.labelSecondary)
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
                    Text("Total TSS")
                        .font(.labelPrimary)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(Int(totalTSS))")
                        .font(.metricSmall)
                        .foregroundColor(.text.primary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Weeks")
                        .font(.labelPrimary)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(data.count)")
                        .font(.metricSmall)
                        .foregroundColor(.text.primary)
                }
            }
            
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
