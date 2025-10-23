import SwiftUI
import Charts

/// Weekly TSS Trend card using atomic ChartCard wrapper
struct WeeklyTSSTrendCardV2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageTSS: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
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
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(Int(averageTSS)) avg TSS",
            badge: badge,
            footerText: data.isEmpty ? nil : "Weekly training stress score totals"
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
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No TSS data", style: .body, color: Color.text.secondary)
            VRText("Track power-based rides to build TSS history", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Week", point.date),
                y: .value("TSS", point.value)
            )
            .foregroundStyle(barColor(point.value))
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
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private func barColor(_ value: Double) -> Color {
        if value > 600 {
            return ColorScale.redAccent
        } else if value > 400 {
            return ColorScale.amberAccent
        } else if value > 200 {
            return ColorScale.blueAccent
        } else {
            return ColorScale.greenAccent
        }
    }
}

#Preview {
    WeeklyTSSTrendCardV2(
        data: (0..<12).map { week in
            TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-week) * 7 * 24 * 60 * 60),
                value: Double.random(in: 150...700)
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}
