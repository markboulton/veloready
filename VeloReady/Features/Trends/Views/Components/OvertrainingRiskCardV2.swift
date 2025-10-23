import SwiftUI
import Charts

/// Overtraining Risk card using atomic ChartCard wrapper
struct OvertrainingRiskCardV2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var currentRisk: Double {
        data.last?.value ?? 0
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let risk = currentRisk
        
        if risk >= 70 {
            return .init(text: "HIGH RISK", style: .error)
        } else if risk >= 50 {
            return .init(text: "ELEVATED", style: .warning)
        } else if risk >= 30 {
            return .init(text: "MODERATE", style: .info)
        } else {
            return .init(text: "LOW RISK", style: .success)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.overtrainingRisk,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(Int(currentRisk))% current risk",
            badge: badge,
            footerText: data.isEmpty ? nil : "Based on load, recovery, and consistency patterns"
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
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No risk assessment available", style: .body, color: Color.text.secondary)
            VRText("Requires training load and recovery history", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Risk", point.value)
            )
            .foregroundStyle(riskColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Risk", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        riskColor(point.value).opacity(0.3),
                        riskColor(point.value).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Warning threshold
            RuleMark(y: .value("Warning", 70))
                .foregroundStyle(ColorScale.redAccent)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
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
    
    private func riskColor(_ value: Double) -> Color {
        if value >= 70 {
            return ColorScale.redAccent
        } else if value >= 50 {
            return ColorScale.amberAccent
        } else if value >= 30 {
            return ColorScale.yellowAccent
        } else {
            return ColorScale.greenAccent
        }
    }
}

#Preview {
    OvertrainingRiskCardV2(
        data: (0..<30).map { day in
            TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: Double.random(in: 10...85)
            )
        }.reversed(),
        timeRange: .days30
    )
    .padding()
}
