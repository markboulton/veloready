import SwiftUI
import Charts

/// FTP Trend card using atomic ChartCard wrapper
struct FTPTrendCardV2: View {
    let data: [TrendDataPoint]
    let timeRange: TrendsViewState.TimeRange
    
    private var currentFTP: Int {
        guard let latest = data.last else { return 0 }
        return Int(latest.value)
    }
    
    private var changeFromStart: Int {
        guard let first = data.first, let last = data.last else { return 0 }
        return Int(last.value - first.value)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let change = changeFromStart
        
        if change > 10 {
            return .init(text: "+\(change)W", style: .success)
        } else if change < -10 {
            return .init(text: "\(change)W", style: .error)
        } else if change != 0 {
            return .init(text: "\(change > 0 ? "+" : "")\(change)W", style: .info)
        }
        return nil
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.ftpTrend,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(currentFTP)W current",
            badge: badge,
            footerText: data.isEmpty ? nil : "Track your functional threshold power over time"
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
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No FTP data available", style: .body, color: Color.text.secondary)
            VRText("Connect to Intervals.icu or Strava to track FTP", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("FTP", point.value)
            )
            .foregroundStyle(ColorScale.powerColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("FTP", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [ColorScale.powerColor.opacity(0.3), ColorScale.powerColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)W")
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
    FTPTrendCardV2(
        data: (0..<90).map { day in
            let base = 285.0
            let trend = Double(day) * 0.1
            let variation = Double.random(in: -5...5)
            return TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: base + trend + variation
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}
