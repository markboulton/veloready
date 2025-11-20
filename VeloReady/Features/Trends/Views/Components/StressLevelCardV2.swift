import SwiftUI
import Charts

/// Stress Level card using atomic ChartCard wrapper
struct StressLevelCardV2: View {
    let data: [TrendDataPoint]
    let timeRange: TrendsViewState.TimeRange
    
    private var averageStress: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avg = averageStress
        
        if avg >= 70 {
            return .init(text: "HIGH", style: .error)
        } else if avg >= 50 {
            return .init(text: "MODERATE", style: .warning)
        } else if avg >= 30 {
            return .init(text: "LOW", style: .info)
        } else {
            return .init(text: "MINIMAL", style: .success)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.stressLevel,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "\(Int(averageStress))\(CommonContent.Formatting.outOf100)",
            badge: badge,
            footerText: data.isEmpty ? nil : "Inferred from HRV, RHR, sleep, and recovery metrics"
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
            Image(systemName: Icons.Health.heartRate)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(TrendsContent.Stress.calculationRequires, style: .body, color: Color.text.secondary)
                
                VRText(TrendsContent.Stress.inferredFrom, style: .caption, color: Color.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach([
                        TrendsContent.Stress.recoveryInverted,
                        TrendsContent.Stress.hrvDeviation,
                        TrendsContent.Stress.rhrElevation,
                        TrendsContent.Stress.sleepInverted,
                        TrendsContent.Stress.trainingIntensity
                    ], id: \.self) { item in
                        HStack {
                            Text(TrendsContent.bulletPoint)
                                .font(.caption)
                                .foregroundColor(Color.text.tertiary)
                            Text(item)
                                .font(.caption)
                                .foregroundColor(Color.text.tertiary)
                        }
                    }
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(stressColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        stressColor(point.value).opacity(0.3),
                        stressColor(point.value).opacity(0.05)
                    ],
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
    
    private func stressColor(_ value: Double) -> Color {
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
    StressLevelCardV2(
        data: (0..<30).map { day in
            TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: Double.random(in: 20...80)
            )
        }.reversed(),
        timeRange: .days30
    )
    .padding()
}
