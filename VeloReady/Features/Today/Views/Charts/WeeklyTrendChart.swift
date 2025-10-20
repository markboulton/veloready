import SwiftUI
import Charts

/// Legacy name for TrendChart - use TrendChart instead
typealias WeeklyTrendChart = TrendChart

/// Reusable trend chart component for Pro features with multiple time periods (DEPRECATED - use TrendChart)
struct WeeklyTrendChart_Legacy: View {
    let title: String
    let getData: (TrendPeriod) -> [TrendDataPoint]
    let color: Color
    let unit: String
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    
    private var data: [TrendDataPoint] {
        getData(selectedPeriod)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and Pro badge
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ProBadge()
            }
            
            // Period selector
            periodSelector
            
            // Chart or empty state
            if data.isEmpty {
                emptyState
            } else {
                chartView
                summaryStats
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var periodSelector: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background container
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 36)
                
                // Animated selection indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width / 3 - 4, height: 32)
                    .offset(x: selectedPeriodOffset(containerWidth: geometry.size.width))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPeriod)
                
                // Period buttons
                HStack(spacing: 0) {
                    ForEach(TrendPeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation {
                                selectedPeriod = period
                            }
                        }) {
                            Text(period.label)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedPeriod == period ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
        .frame(height: 36)
    }
    
    private func selectedPeriodOffset(containerWidth: CGFloat) -> CGFloat {
        let buttonWidth = containerWidth / 3
        switch selectedPeriod {
        case .sevenDays:
            return 2
        case .thirtyDays:
            return buttonWidth + 2
        case .sixtyDays:
            return buttonWidth * 2 + 2
        }
    }
    
    private var chartView: some View {
        Chart {
            // Bar marks
            ForEach(data) { point in
                BarMark(
                    x: .value(ChartContent.Axis.day, point.date, unit: .day),
                    y: .value(ChartContent.Axis.value, point.value)
                )
                .foregroundStyle(colorForValue(point.value))
                .cornerRadius(4)
                .annotation(position: .top, alignment: .center) {
                    if selectedPeriod == .sevenDays {
                        Text("\(Int(point.value))\(CommonContent.Units.percent))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Trend line for 30 and 60 day views
            if selectedPeriod != .sevenDays {
                ForEach(data) { point in
                    LineMark(
                        x: .value(ChartContent.Axis.day, point.date, unit: .day),
                        y: .value(ChartContent.Axis.value, point.value)
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)  // Smooth curve
                }
            }
        }
        .frame(height: 225)  // Increased by 25% (180 * 1.25 = 225)
        .chartXAxis {
            if selectedPeriod == .sevenDays {
                // 7 days: Show all weekday abbreviations
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.chartGridLine)
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else if selectedPeriod == .thirtyDays {
                // 30 days: Show ~5 date labels (every 6-7 days)
                AxisMarks(values: .stride(by: .day, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.chartGridLine)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else {
                // 60 days: Show ~5 date labels (every 12 days)
                AxisMarks(values: .stride(by: .day, count: 12)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.chartGridLine)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                    .foregroundStyle(ColorPalette.chartGridLine)
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ColorPalette.chartAxisLabel)
            }
        }
        .chartYScale(domain: 0...100)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
    }
    
    // MARK: - Color Coding
    
    private func colorForValue(_ value: Double) -> Color {
        // Color bars based on score level
        switch value {
        case 80...:
            return Color.semantic.success  // Excellent
        case 60..<80:
            return ColorPalette.yellow  // Good
        case 40..<60:
            return Color.semantic.warning  // Fair
        default:
            return Color.semantic.error  // Poor
        }
    }
    
    private var summaryStats: some View {
        HStack(spacing: 20) {
            StatItem(
                label: ChartContent.Summary.avgShort,
                value: String(format: "%.0f", averageValue),
                unit: unit
            )
            
            StatItem(
                label: ChartContent.Summary.minShort,
                value: String(format: "%.0f", minValue),
                unit: unit
            )
            
            StatItem(
                label: ChartContent.Summary.maxShort,
                value: String(format: "%.0f", maxValue),
                unit: unit
            )
            
            Spacer()
            
            trendIndicator
        }
        .font(.caption)
    }
    
    private var trendIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: trendDirection)
                .foregroundColor(trendColor)
            Text(trendText)
                .foregroundColor(trendColor)
            Text(trendPercentage)
                .foregroundColor(trendColor)
        }
        .font(.caption)
        .fontWeight(.semibold)
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(ChartContent.WeeklyTrend.notEnoughData)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(ChartContent.WeeklyTrend.checkBackLater)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var averageValue: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var minValue: Double {
        data.map(\.value).min() ?? 0
    }
    
    private var maxValue: Double {
        data.map(\.value).max() ?? 0
    }
    
    // MARK: - Trend Calculation
    
    private var trendDirection: String {
        guard data.count >= 2 else { return ChartContent.TrendIcons.minus }
        let changePercent = trendChangePercent
        
        if changePercent > 5 {
            return ChartContent.TrendIcons.arrowUpRight
        } else if changePercent < -5 {
            return ChartContent.TrendIcons.arrowDownRight
        } else {
            return ChartContent.TrendIcons.arrowRight
        }
    }
    
    private var trendColor: Color {
        guard data.count >= 2 else { return .secondary }
        let changePercent = trendChangePercent
        
        if changePercent > 5 {
            return .green
        } else if changePercent < -5 {
            return .red
        } else {
            return .orange
        }
    }
    
    private var trendText: String {
        guard data.count >= 2 else { return ChartContent.Trend.stable }
        let changePercent = trendChangePercent
        
        if changePercent > 5 {
            return ChartContent.Trend.improving
        } else if changePercent < -5 {
            return ChartContent.Trend.declining
        } else {
            return ChartContent.Trend.stable
        }
    }
    
    private var trendPercentage: String {
        guard data.count >= 2 else { return "" }
        let changePercent = abs(trendChangePercent)
        return String(format: "%.0f%%", changePercent)
    }
    
    private var trendChangePercent: Double {
        guard data.count >= 2 else { return 0 }
        
        // Compare first third vs last third of data for stable trend calculation
        let segmentSize = max(data.count / 3, 1)
        let olderSegment = data.prefix(segmentSize)
        let recentSegment = data.suffix(segmentSize)
        
        let olderAvg = olderSegment.map(\.value).reduce(0, +) / Double(olderSegment.count)
        let recentAvg = recentSegment.map(\.value).reduce(0, +) / Double(recentSegment.count)
        
        guard olderAvg > 0 else { return 0 }
        
        return ((recentAvg - olderAvg) / olderAvg) * 100
    }
}

// Components moved to TrendChart.swift

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TrendChart(
            title: ChartContent.ChartTitles.recoveryScore,
            getData: { period in
                (0..<period.days).map { dayIndex in
                    let daysAgo = period.days - 1 - dayIndex
                    return TrendDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                        value: Double.random(in: 60...85)
                    )
                }
            },
            chartType: .bar,
            unit: "%",
            showProBadge: true
        )
        
        TrendChart(
            title: ChartContent.ChartTitles.sleepScore,
            getData: { _ in [] },
            chartType: .bar,
            unit: "%",
            showProBadge: true
        )
    }
    .padding()
}
