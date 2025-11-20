import SwiftUI
import Charts

/// Recovery vs Power card using atomic ChartCard wrapper
/// Unique VeloReady feature: correlates health (recovery) with performance (power)
/// Shows scatter plot with correlation coefficient, trend line, and significance analysis
struct RecoveryVsPowerCardV2: View {
    let data: [TrendsDataLoader.CorrelationDataPoint]
    let correlation: CorrelationCalculator.CorrelationResult?
    let timeRange: TrendsViewState.TimeRange
    
    private var badge: CardHeader.Badge? {
        guard let correlation = correlation else { return nil }
        
        switch correlation.significance {
        case .strong:
            return .init(text: "STRONG", style: .success)
        case .moderate:
            return .init(text: "MODERATE", style: .info)
        case .weak:
            return .init(text: "WEAK", style: .warning)
        case .none:
            return .init(text: "NONE", style: .error)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.recoveryVsPower,
            subtitle: correlation.map { 
                "\($0.significance.description) correlation (r=\(CorrelationCalculator.formatCoefficient($0.coefficient)))" 
            } ?? CommonContent.States.noDataFound,
            badge: badge,
            footerText: correlation.map { generateInsight($0) }
        ) {
            if data.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    chartView
                    
                    if let correlation = correlation {
                        correlationStatsView(correlation)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.Feature.trends)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    TrendsContent.RecoveryVsPower.noData,
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    TrendsContent.RecoveryVsPower.requires,
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.RecoveryVsPower.threeWeeks, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.RecoveryVsPower.powerData, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.RecoveryVsPower.dailyRecovery, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.RecoveryVsPower.hrvSleep, style: .caption, color: Color.text.tertiary)
                    }
                }
                
                VRText(
                    TrendsContent.RecoveryVsPower.unique,
                    style: .caption,
                    color: Color.chart.primary
                )
                .fontWeight(.medium)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        Chart(data) { point in
            // Scatter points
            PointMark(
                x: .value("Recovery %", point.x),
                y: .value("Avg Power (W)", point.y)
            )
            .foregroundStyle(ColorScale.blueAccent.opacity(0.7))
            .symbolSize(60)
            
            // Trend line if correlation exists and is meaningful (>0.3)
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
                    .foregroundStyle(Color.text.tertiary.opacity(0.3))
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
                    .foregroundStyle(Color.text.tertiary.opacity(0.3))
            }
        }
        .frame(height: 220)
    }
    
    // MARK: - Correlation Stats
    
    private func correlationStatsView(_ correlation: CorrelationCalculator.CorrelationResult) -> some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(TrendsContent.Metrics.correlation, style: .caption, color: Color.text.secondary)
                
                VRText(
                    CorrelationCalculator.formatCoefficient(correlation.coefficient),
                    style: .headline,
                    color: correlationColor(correlation)
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(TrendsContent.Metrics.rSquared, style: .caption, color: Color.text.secondary)
                
                VRText(
                    "\(Int(correlation.rSquared * 100))%",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(TrendsContent.Metrics.activities, style: .caption, color: Color.text.secondary)
                
                VRText(
                    "\(correlation.sampleSize)",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    // MARK: - Helper Methods
    
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
    
    /// Calculate trend line Y value using linear regression
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
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With strong positive correlation
            RecoveryVsPowerCardV2(
                data: (0..<30).map { i in
                    let recovery = Double.random(in: 50...95)
                    let power = 150 + (recovery - 70) * 2 + Double.random(in: -20...20)
                    return TrendsDataLoader.CorrelationDataPoint(
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
            
            // Weak correlation
            RecoveryVsPowerCardV2(
                data: (0..<30).map { i in
                    let recovery = Double.random(in: 50...95)
                    let power = Double.random(in: 180...280)
                    return TrendsDataLoader.CorrelationDataPoint(
                        date: Date().addingTimeInterval(Double(-i) * 24 * 60 * 60),
                        x: recovery,
                        y: power
                    )
                },
                correlation: CorrelationCalculator.CorrelationResult(
                    coefficient: 0.18,
                    rSquared: 0.03,
                    sampleSize: 30,
                    significance: .weak,
                    trend: .positive
                ),
                timeRange: .days90
            )
            
            // Empty
            RecoveryVsPowerCardV2(
                data: [],
                correlation: nil,
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
