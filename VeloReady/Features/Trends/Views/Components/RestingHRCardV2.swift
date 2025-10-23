import SwiftUI
import Charts

/// Resting Heart Rate card using atomic ChartCard wrapper
struct RestingHRCardV2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageRHR: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var baselineRHR: Double {
        52.0  // TODO: Calculate personal baseline
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let deviation = averageRHR - baselineRHR
        
        if deviation > 5 {
            return .init(text: "ELEVATED", style: .error)
        } else if deviation > 2 {
            return .init(text: "SLIGHTLY HIGH", style: .warning)
        } else if deviation < -3 {
            return .init(text: "EXCELLENT", style: .success)
        } else {
            return .init(text: "STABLE", style: .info)
        }
    }
    
    private var subtitleText: String {
        guard !data.isEmpty else { return TrendsContent.noDataFound }
        return "\(Int(averageRHR)) \(TrendsContent.Units.bpm) avg"
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.restingHR,
            subtitle: subtitleText,
            badge: badge,
            footerText: data.isEmpty ? nil : generateInsight()
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
            Image(systemName: Icons.Health.heartCircleOutline)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(TrendsContent.RestingHR.noData, style: .body, color: Color.text.secondary)
                
                VRText(TrendsContent.RestingHR.toTrackRHR, style: .caption, color: Color.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                        Text(TrendsContent.RestingHR.wearWatch)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                        Text(TrendsContent.RestingHR.grantPermission)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                        Text(TrendsContent.RestingHR.trackDays)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                        Text(TrendsContent.RestingHR.lowerBetter)
                            .font(.caption)
                            .foregroundColor(Color.text.tertiary)
                    }
                }
                
                Text(TrendsContent.RestingHR.elevationIndicates)
                    .font(.caption)
                    .foregroundColor(ColorScale.blueAccent)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart {
            // Baseline reference
            RuleMark(y: .value("Baseline", baselineRHR))
                .foregroundStyle(Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(TrendsContent.RestingHR.baseline)
                        .font(.caption)
                        .foregroundColor(Color.text.tertiary)
                        .padding(.horizontal, Spacing.xs)
                        .background(Color.background.card)
                }
            
            // RHR values
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("RHR", point.value)
                )
                .foregroundStyle(ColorScale.pinkAccent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("RHR", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorScale.pinkAccent.opacity(0.3), ColorScale.pinkAccent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
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
    
    private func generateInsight() -> String {
        guard !data.isEmpty else { return "No data available" }
        
        let avg = averageRHR
        let deviation = avg - baselineRHR
        
        if abs(deviation) < 2 {
            return "RHR is stable at baseline (\(Int(avg)) bpm). Good cardiovascular consistency."
        } else if deviation > 5 {
            return "RHR is elevated +\(Int(deviation)) bpm above baseline. May indicate stress, overtraining, or illness."
        } else if deviation < -3 {
            return "RHR is \(Int(abs(deviation))) bpm below baseline. Excellent adaptation to training."
        } else if deviation > 2 {
            return "RHR slightly elevated. Monitor for additional stress or recovery issues."
        } else {
            return "RHR within normal range. Continue monitoring daily trends."
        }
    }
}

#Preview("With Data") {
    RestingHRCardV2(
        data: (0..<90).map { day in
            let baseline = 52.0
            let variation = Double.random(in: -4...8)
            return TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: max(45, min(75, baseline + variation))
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}

#Preview("Empty") {
    RestingHRCardV2(
        data: [],
        timeRange: .days90
    )
    .padding()
}
