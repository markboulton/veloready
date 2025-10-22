import SwiftUI
import Charts

/// Card displaying Resting Heart Rate trend
struct RestingHRCard: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageRHR: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var baselineRHR: Double {
        52.0  // TODO: Calculate personal baseline
    }
    
    var body: some View {
        StandardCard(
            icon: "heart.fill",
            iconColor: .health.heartRate,
            title: TrendsContent.Cards.restingHR,
            subtitle: !data.isEmpty ? "\(Int(averageRHR)) \(TrendsContent.Units.bpm) avg" : TrendsContent.noDataFound
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
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
            Image(systemName: Icons.Health.heartCircleOutline)
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.RestingHR.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.RestingHR.toTrackRHR)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.RestingHR.wearWatch)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.RestingHR.grantPermission)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.RestingHR.trackDays)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.RestingHR.lowerBetter)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.RestingHR.elevationIndicates)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart {
            // Baseline reference
            RuleMark(y: .value("Baseline", baselineRHR))
                .foregroundStyle(Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(TrendsContent.RestingHR.baseline)
                        .font(.caption)
                        .foregroundColor(.text.tertiary)
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
                .lineStyle(StrokeStyle(lineWidth: 1))
                
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
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.insight)
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            Text(generateInsight())
                .font(.body)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func generateInsight() -> String {
        guard !data.isEmpty else { return "No data available" }
        
        let avg = averageRHR
        let deviation = avg - baselineRHR
        _ = (deviation / baselineRHR) * 100 // Calculate percent deviation for future use
        
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

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            RestingHRCard(
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
            
            // Empty
            RestingHRCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
