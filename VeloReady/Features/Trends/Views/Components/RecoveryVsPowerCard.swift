import SwiftUI
import Charts

/// Card displaying Recovery vs Power correlation (scatter plot)
/// This is a unique VeloReady feature - no other app correlates health + performance
struct RecoveryVsPowerCard: View {
    let data: [TrendsViewModel.CorrelationDataPoint]
    let correlation: CorrelationCalculator.CorrelationResult?
    let timeRange: TrendsViewModel.TimeRange
    
    var body: some View {
        StandardCard(
            icon: "arrow.triangle.2.circlepath",
            iconColor: .blue,
            title: TrendsContent.Cards.recoveryVsPower,
            subtitle: correlation.map { "\($0.significance.description) correlation (r=\(CorrelationCalculator.formatCoefficient($0.coefficient)))" } ?? CommonContent.States.noDataFound
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                
                // Chart
                if data.isEmpty {
                    emptyState
                } else {
                    chart
                }
                
                // Correlation Stats
                if let correlation = correlation {
                    correlationStats(correlation)
                }
                
                // Insight
                if let correlation = correlation {
                    insight(correlation)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.Feature.trends)
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.RecoveryVsPower.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.RecoveryVsPower.requires)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.RecoveryVsPower.threeWeeks)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.RecoveryVsPower.powerData)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.RecoveryVsPower.dailyRecovery)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.RecoveryVsPower.hrvSleep)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.RecoveryVsPower.unique)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart(data) { point in
            PointMark(
                x: .value("Recovery %", point.x),
                y: .value("Avg Power (W)", point.y)
            )
            .foregroundStyle(ColorScale.blueAccent.opacity(0.7))
            .symbolSize(60)
            
            // Trend line if correlation exists
            if let correlation = correlation, abs(correlation.coefficient) > 0.3 {
                LineMark(
                    x: .value("Recovery %", point.x),
                    y: .value("Power", trendLineY(x: point.x))
                )
                .foregroundStyle(correlationColor(correlation))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)\(TrendsContent.Units.percent)")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)\(TrendsContent.Units.watts)")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 220)
    }
    
    private func correlationStats(_ correlation: CorrelationCalculator.CorrelationResult) -> some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(TrendsContent.Metrics.correlation)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text(CorrelationCalculator.formatCoefficient(correlation.coefficient))
                    .font(.heading)
                    .foregroundColor(correlationColor(correlation))
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(TrendsContent.Metrics.rSquared)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text("\(Int(correlation.rSquared * 100))%")
                    .font(.heading)
                    .foregroundColor(.text.primary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(TrendsContent.Metrics.activities)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text("\(correlation.sampleSize)")
                    .font(.heading)
                    .foregroundColor(.text.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    private func insight(_ correlation: CorrelationCalculator.CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.uniqueInsight)
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            Text(generateInsight(correlation))
                .font(.body)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func generateInsight(_ correlation: CorrelationCalculator.CorrelationResult) -> String {
        let r = correlation.coefficient
        let rSquared = correlation.rSquared
        let variancePercent = Int(rSquared * 100)
        
        switch correlation.significance {
        case .strong:
            if r > 0 {
                return "Strong positive correlation (r=\(CorrelationCalculator.formatCoefficient(r))). Recovery explains \(variancePercent)% of your power variability. Train hard on high-recovery days!"
            } else {
                return "Strong negative correlation. This is unusual - check if data is accurate."
            }
            
        case .moderate:
            if r > 0 {
                return "Moderate correlation (r=\(CorrelationCalculator.formatCoefficient(r))). Recovery accounts for \(variancePercent)% of power variance. Schedule key workouts when recovered."
            } else {
                return "Moderate negative correlation. Consider other factors affecting performance."
            }
            
        case .weak:
            return "Weak correlation (r=\(CorrelationCalculator.formatCoefficient(r))). Recovery has minimal impact on your power. Other factors like sleep, nutrition, or training may be more important."
            
        case .none:
            return "No significant correlation found. Your power output appears independent of recovery score. This could indicate consistent performance or data quality issues."
        }
    }
    
    private func correlationColor(_ correlation: CorrelationCalculator.CorrelationResult) -> Color {
        switch correlation.significance {
        case .strong:
            return Color.semantic.success
        case .moderate:
            return Color.chart.primary
        case .weak:
            return Color.semantic.warning
        case .none:
            return Color.text.tertiary
        }
    }
    
    // Calculate trend line Y value using linear regression
    private func trendLineY(x: Double) -> Double {
        guard correlation != nil, data.count >= 2 else { return 0 }
        
        let xValues = data.map(\.x)
        let yValues = data.map(\.y)
        
        let meanX = xValues.reduce(0, +) / Double(xValues.count)
        let meanY = yValues.reduce(0, +) / Double(yValues.count)
        
        var numerator = 0.0
        var denominator = 0.0
        
        for i in 0..<data.count {
            numerator += (xValues[i] - meanX) * (yValues[i] - meanY)
            denominator += (xValues[i] - meanX) * (xValues[i] - meanX)
        }
        
        let slope = denominator != 0 ? numerator / denominator : 0
        let intercept = meanY - slope * meanX
        
        return slope * x + intercept
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With strong correlation
            RecoveryVsPowerCard(
                data: (0..<30).map { i in
                    let recovery = Double.random(in: 50...95)
                    let power = 150 + (recovery - 70) * 2 + Double.random(in: -20...20)
                    return TrendsViewModel.CorrelationDataPoint(
                        date: Date().addingTimeInterval(Double(-i) * 24 * 60 * 60),
                        x: recovery,
                        y: power
                    )
                },
                correlation: CorrelationCalculator.CorrelationResult(
                    coefficient: 0.72,
                    rSquared: 0.52,
                    sampleSize: 30,
                    significance: .strong,
                    trend: .positive
                ),
                timeRange: .days90
            )
            
            // Empty
            RecoveryVsPowerCard(
                data: [],
                correlation: nil,
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
