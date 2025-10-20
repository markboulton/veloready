import SwiftUI
import Charts

/// Card displaying HRV trend with 7-day baseline
struct HRVTrendCard: View {
    let data: [TrendsViewModel.HRVTrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageHRV: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var baselineHRV: Double? {
        data.first?.baseline
    }
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.hrvTrend)
                            .font(.heading)
                            .foregroundColor(.text.primary)
                        
                        if !data.isEmpty {
                            HStack(spacing: Spacing.xs) {
                                Text("\(Int(averageHRV))ms")
                                    .font(.title)
                                    .foregroundColor(ColorScale.greenAccent)
                                
                                if let baseline = baselineHRV {
                                    Text("(\(baseline, specifier: "%.0f") \(TrendsContent.HRV.baseline))")
                                        .font(.caption)
                                        .foregroundColor(.text.secondary)
                                }
                            }
                        } else {
                            Text(TrendsContent.noDataFound)
                                .font(.body)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                }
                
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
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.HRV.noDataFound)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text("\(TrendsContent.toTrack) HRV:")
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.HRV.wearWatch)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.HRV.grantPermission)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.HRV.measureConsistently)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.HRV.baselineCalculated)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.HRV.bestIndicator)
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
            // Baseline line
            if let baseline = baselineHRV {
                RuleMark(y: .value("Baseline", baseline))
                    .foregroundStyle(Color.text.tertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Baseline")
                            .font(.caption)
                            .foregroundColor(.text.tertiary)
                            .padding(.horizontal, Spacing.xs)
                            .background(Color.background.card)
                    }
            }
            
            // HRV values
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("HRV", point.value)
                )
                .foregroundStyle(ColorScale.greenAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("HRV", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorScale.greenAccent.opacity(0.3), ColorScale.greenAccent.opacity(0.05)],
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
        .frame(height: 200)
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
        guard !data.isEmpty, let baseline = baselineHRV else {
            return "No baseline available"
        }
        
        let avg = averageHRV
        let percentDiff = ((avg - baseline) / baseline) * 100
        
        if percentDiff > 5 {
            return "HRV is \(Int(percentDiff))% above baseline. Excellent recovery and readiness."
        } else if percentDiff > -5 {
            return "HRV is stable around baseline. Good recovery state."
        } else if percentDiff > -15 {
            return "HRV is \(abs(Int(percentDiff)))% below baseline. Consider lighter training or more rest."
        } else {
            return "HRV is significantly below baseline (\(abs(Int(percentDiff)))%). Prioritize recovery."
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            HRVTrendCard(
                data: (0..<90).map { day in
                    let baseline = 65.0
                    let variation = Double.random(in: -12...12)
                    return TrendsViewModel.HRVTrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: max(40, min(90, baseline + variation)),
                        baseline: baseline
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Empty
            HRVTrendCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
