import SwiftUI
import Charts

/// HRV Trend card using atomic ChartCard wrapper
struct HRVTrendCardV2: View {
    let data: [HRVTrendDataPoint]
    let timeRange: TrendsViewState.TimeRange
    
    private var averageHRV: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var baselineHRV: Double? {
        data.first?.baseline
    }
    
    private var subtitleText: String {
        if data.isEmpty {
            return TrendsContent.noDataFound
        }
        var text = "\(Int(averageHRV))\(TrendsContent.Units.ms)"
        if let baseline = baselineHRV {
            text += " (\(Int(baseline)) baseline)"
        }
        return text
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty, let baseline = baselineHRV else { return nil }
        let percentChange = ((averageHRV - baseline) / baseline) * 100
        
        if percentChange > 10 {
            return .init(text: "IMPROVING", style: .success)
        } else if percentChange < -10 {
            return .init(text: "DECLINING", style: .warning)
        } else {
            return .init(text: "STABLE", style: .info)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.hrvTrend,
            subtitle: subtitleText,
            badge: badge,
            footerText: data.isEmpty ? nil : "Measured \(data.count) times"
        ) {
            if data.isEmpty {
                // Empty state
                VStack(spacing: Spacing.md) {
                    Image(systemName: Icons.Health.heartRate)
                        .font(.system(size: 40))
                        .foregroundColor(Color.text.tertiary)
                    
                    VRText(TrendsContent.HRV.noDataFound, style: .body, color: Color.text.secondary)
                }
                .frame(height: 120)
            } else {
                // Actual chart from original card
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("HRV", point.value)
                        )
                        .foregroundStyle(ColorScale.hrvColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("HRV", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorScale.hrvColor.opacity(0.3), ColorScale.hrvColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        if let baseline = point.baseline {
                            RuleMark(y: .value("Baseline", baseline))
                                .foregroundStyle(ColorScale.chartAxis)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
