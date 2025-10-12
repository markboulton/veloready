import SwiftUI
import Charts

/// Reusable trend chart component supporting multiple chart types and time periods
struct TrendChart: View {
    let title: String
    let getData: (TrendPeriod) -> [TrendDataPoint]
    let chartType: ChartType
    let unit: String
    let showProBadge: Bool
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var animateChart: Bool = false
    @State private var sweepProgress: Double = 1.0  // Start at 1.0 so chart is visible immediately
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var data: [TrendDataPoint] {
        getData(selectedPeriod)
    }
    
    // Compute normalized heights for organic timing
    private var normalizedHeights: [Double] {
        guard !data.isEmpty else { return [] }
        let maxValue = data.map(\.value).max() ?? 100
        return data.map { point in
            min(max(point.value / maxValue, 0), 1)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with title and optional Pro badge
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color.text.secondary)
                    .font(.system(size: TypeScale.xs))
                
                Text(title)
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                Spacer()
                
                if showProBadge {
                    ProBadge()
                }
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
        .padding(Spacing.cardPadding)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.cardCornerRadius)
    }
    
    private var periodSelector: some View {
        SegmentedControl(
            segments: TrendPeriod.allCases.map { period in
                SegmentItem(value: period, label: period.label)
            },
            selection: $selectedPeriod
        )
    }
    
    private var chartView: some View {
        Chart {
            // Main chart marks based on type
            ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                let normalizedX = Double(index) / Double(max(data.count - 1, 1))
                let normalizedHeight = index < normalizedHeights.count ? normalizedHeights[index] : 0
                
                // Calculate sweep progress for this point
                let sweepWindow: Double = 0.3 // 30% of total animation
                let pointProgress = max(0, min(1, (sweepProgress - normalizedX) / sweepWindow))
                
                // Add height-based delay (taller peaks take longer)
                let heightDelay = normalizedHeight * 0.2
                let delayedProgress = max(0, min(1, pointProgress - heightDelay))
                
                switch chartType {
                case .bar:
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", animateChart ? point.value : 0)
                    )
                    .foregroundStyle(colorForValue(point.value))
                    .cornerRadius(4)
                    .annotation(position: .top, alignment: .center) {
                        if selectedPeriod == .sevenDays {
                            Text("\(Int(point.value))\(unit)")
                                .font(.system(size: TypeScale.xxs, weight: .semibold))
                                .foregroundColor(Color.text.primary)
                                .opacity(animateChart ? 1.0 : 0)
                        }
                    }
                    
                case .line:
                    let animatedValue = reduceMotion ? point.value : (delayedProgress * point.value)
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", animatedValue)
                    )
                    .foregroundStyle(colorForValue(point.value))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                case .area:
                    let animatedValue = reduceMotion ? point.value : (delayedProgress * point.value)
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", animatedValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [colorForValue(point.value).opacity(0.3), colorForValue(point.value).opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .frame(height: 225)
        .chartXAxis {
            if selectedPeriod == .sevenDays {
                // 7 days: Show all weekday abbreviations, aligned to center of bars
                AxisMarks(preset: .aligned) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.text.tertiary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: TypeScale.xxs))
                }
            } else if selectedPeriod == .thirtyDays {
                // 30 days: Show ~5 date labels (every 6 days)
                AxisMarks(values: .stride(by: .day, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.text.tertiary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: TypeScale.xxs))
                }
            } else {
                // 60 days: Show ~5 date labels (every 12 days)
                AxisMarks(values: .stride(by: .day, count: 12)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.text.tertiary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: TypeScale.xxs))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.text.tertiary)
                AxisValueLabel()
                    .font(.system(size: TypeScale.xxs))
            }
        }
        .chartYScale(domain: 0...100)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .onAppear {
            if !reduceMotion {
                // Bar charts use simple animation
                if chartType == .bar {
                    animateChart = false
                    withAnimation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.28)) {
                        animateChart = true
                    }
                } else {
                    // Line/Area charts use sweep animation - reset to 0 then animate
                    sweepProgress = 0
                    withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.64)) {
                        sweepProgress = 1.0
                    }
                }
            }
        }
        .onChange(of: selectedPeriod) { _ in
            if reduceMotion {
                animateChart = true
                sweepProgress = 1.0
            } else {
                if chartType == .bar {
                    animateChart = false
                    withAnimation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.28)) {
                        animateChart = true
                    }
                } else {
                    sweepProgress = 0
                    withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.64)) {
                        sweepProgress = 1.0
                    }
                }
            }
        }
    }
    
    // MARK: - Color Coding
    
    private func colorForValue(_ value: Double) -> Color {
        // Color based on score level - using solid color tokens
        switch value {
        case 80...:
            return ColorScale.greenAccent  // Excellent
        case 60..<80:
            return ColorScale.blueAccent  // Good
        case 40..<60:
            return ColorScale.amberAccent  // Fair
        default:
            return ColorScale.redAccent  // Poor
        }
    }
    
    private var summaryStats: some View {
        HStack(spacing: Spacing.xl) {
            StatItem(
                label: ChartContent.Stats.average,
                value: String(format: "%.0f", averageValue),
                unit: unit
            )
            
            StatItem(
                label: ChartContent.Stats.minimum,
                value: String(format: "%.0f", minValue),
                unit: unit
            )
            
            StatItem(
                label: ChartContent.Stats.maximum,
                value: String(format: "%.0f", maxValue),
                unit: unit
            )
            
            Spacer()
            
            trendIndicator
        }
        .font(.system(size: TypeScale.xs))
    }
    
    private var trendIndicator: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: trendDirection)
                .foregroundColor(trendColor)
                .font(.system(size: TypeScale.xxs))
            Text(trendPercentage)
                .foregroundColor(trendColor)
            Text(trendText)
                .foregroundColor(trendColor)
        }
        .font(.system(size: TypeScale.xs, weight: .semibold))
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: TypeScale.lg))
                .foregroundColor(Color.text.secondary)
            Text(ChartContent.EmptyState.noData)
                .font(.system(size: TypeScale.sm))
                .foregroundColor(Color.text.secondary)
            Text(ChartContent.EmptyState.checkBack)
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.tertiary)
        }
        .frame(height: 225)
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
        let changePercent = trendChangePercent
        
        if changePercent > 5 {
            return "arrow.up.right"
        } else if changePercent < -5 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        let changePercent = trendChangePercent
        
        if changePercent > 5 {
            return Color.status.authenticated
        } else if changePercent < -5 {
            return Color.status.warning
        } else {
            return Color.text.secondary
        }
    }
    
    private var trendText: String {
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

// MARK: - Chart Type

enum ChartType {
    case bar
    case line
    case area
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            Text(label)
                .font(.system(size: TypeScale.xxs))
                .foregroundColor(Color.text.secondary)
            HStack(spacing: Spacing.xs / 2) {
                Text(value)
                    .font(.system(size: TypeScale.xs, weight: .semibold))
                Text(unit)
                    .font(.system(size: TypeScale.xxs))
                    .foregroundColor(Color.text.secondary)
            }
        }
    }
}

// MARK: - Data Models

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum TrendPeriod: CaseIterable {
    case sevenDays
    case thirtyDays
    case sixtyDays
    
    var label: String {
        switch self {
        case .sevenDays: return ChartContent.Period.sevenDays
        case .thirtyDays: return ChartContent.Period.thirtyDays
        case .sixtyDays: return ChartContent.Period.sixtyDays
        }
    }
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .sixtyDays: return 60
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TrendChart(
            title: "Recovery Score",
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
            title: "Heart Rate",
            getData: { period in
                (0..<period.days).map { dayIndex in
                    let daysAgo = period.days - 1 - dayIndex
                    return TrendDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                        value: Double.random(in: 50...80)
                    )
                }
            },
            chartType: .line,
            unit: "bpm",
            showProBadge: false
        )
    }
    .padding()
}
