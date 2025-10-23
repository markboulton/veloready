import SwiftUI
import Charts

/// Weekly TSS Trend card using atomic ChartCard wrapper
/// Shows weekly Training Stress Score totals as bar chart
/// Color-coded by load: red (>600), amber (>400), blue (>200), green (≤200)
struct WeeklyTSSTrendCardV2: View {
    let data: [TrendsViewModel.WeeklyTSSDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageTSS: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.tss).reduce(0, +) / Double(data.count)
    }
    
    private var totalTSS: Double {
        data.map(\.tss).reduce(0, +)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avg = averageTSS
        
        if avg > 600 {
            return .init(text: "VERY HIGH", style: .error)
        } else if avg > 400 {
            return .init(text: "HIGH", style: .warning)
        } else if avg > 200 {
            return .init(text: "MODERATE", style: .info)
        } else {
            return .init(text: "LOW", style: .success)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.weeklyTSS,
            subtitle: !data.isEmpty ? "\(Int(averageTSS)) weekly TSS" : CommonContent.States.noDataFound,
            badge: badge,
            footerText: !data.isEmpty ? generateInsight() : nil
        ) {
            if data.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    chartView
                    summaryStatsView
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.System.chartBarXAxis)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    TrendsContent.TrainingLoad.noData,
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    TrendsContent.TrainingLoad.toTrackLoad,
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.WeeklyTSS.completeCyclingWorkouts, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.WeeklyTSS.uploadToIntervals, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.WeeklyTSS.tssAutoCalculated, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.WeeklyTSS.trackForTrends, style: .caption, color: Color.text.tertiary)
                    }
                }
                
                VRText(
                    TrendsContent.WeeklyTSS.tssDefinition,
                    style: .caption,
                    color: Color.chart.primary
                )
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
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
                    .foregroundStyle(Color.text.tertiary.opacity(0.3))
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
    
    // MARK: - Summary Stats
    
    private var summaryStatsView: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    TrendsContent.WeeklyTSS.totalTSS,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    "\(Int(totalTSS))",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    CommonContent.TimeUnits.weeks,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    "\(data.count)",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    // MARK: - Helper Methods
    
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
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With varied data
            WeeklyTSSTrendCardV2(
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
            
            // High load
            WeeklyTSSTrendCardV2(
                data: (0..<8).map { week in
                    TrendsViewModel.WeeklyTSSDataPoint(
                        weekStart: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                        tss: Double.random(in: 500...750)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Low load
            WeeklyTSSTrendCardV2(
                data: (0..<8).map { week in
                    TrendsViewModel.WeeklyTSSDataPoint(
                        weekStart: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                        tss: Double.random(in: 100...250)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Empty
            WeeklyTSSTrendCardV2(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
