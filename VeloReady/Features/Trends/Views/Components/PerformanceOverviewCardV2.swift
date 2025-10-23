import SwiftUI
import Charts

/// Performance Overview card using atomic ChartCard wrapper
struct PerformanceOverviewCardV2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averagePerformance: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avg = averagePerformance
        
        if avg >= 80 {
            return .init(text: "EXCELLENT", style: .success)
        } else if avg >= 60 {
            return .init(text: "GOOD", style: .info)
        } else if avg >= 40 {
            return .init(text: "MODERATE", style: .warning)
        } else {
            return .init(text: "LOW", style: .error)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.performanceOverview,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(Int(averagePerformance))% avg",
            badge: badge,
            footerText: data.isEmpty ? nil : "Composite of FTP, power, and efficiency metrics"
        ) {
            if data.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No performance data", style: .body, color: Color.text.secondary)
            VRText("Requires power-based training history", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Performance", point.value)
            )
            .foregroundStyle(ColorScale.powerColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Performance", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [ColorScale.powerColor.opacity(0.3), ColorScale.powerColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
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
}

#Preview {
    PerformanceOverviewCardV2(
        data: (0..<90).map { day in
            let base = 65.0
            let trend = Double(day) * 0.15
            let variation = Double.random(in: -10...10)
            return TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: max(0, min(100, base + trend + variation))
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}
