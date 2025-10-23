import SwiftUI
import Charts

/// Training Load Trend card using atomic ChartCard wrapper
struct TrainingLoadTrendCardV2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageLoad: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avg = averageLoad
        
        if avg > 150 {
            return .init(text: "VERY HIGH", style: .error)
        } else if avg > 100 {
            return .init(text: "HIGH", style: .warning)
        } else if avg > 50 {
            return .init(text: "MODERATE", style: .info)
        } else {
            return .init(text: "LOW", style: .success)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.trainingLoad,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(Int(averageLoad)) avg load",
            badge: badge,
            footerText: data.isEmpty ? nil : "Chronic training load based on TSS over time"
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No training load data", style: .body, color: Color.text.secondary)
            VRText("Track rides with power to build load history", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Load", point.value)
            )
            .foregroundStyle(loadColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Load", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        loadColor(point.value).opacity(0.3),
                        loadColor(point.value).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private func loadColor(_ value: Double) -> Color {
        if value > 150 {
            return ColorScale.redAccent
        } else if value > 100 {
            return ColorScale.amberAccent
        } else if value > 50 {
            return ColorScale.blueAccent
        } else {
            return ColorScale.greenAccent
        }
    }
}

#Preview {
    TrainingLoadTrendCardV2(
        data: (0..<90).map { day in
            let base = 80.0
            let variation = Double.random(in: -20...40)
            return TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: max(0, base + variation)
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}
