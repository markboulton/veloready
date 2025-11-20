import SwiftUI
import Charts

/// Reusable trend chart component supporting multiple chart types and time periods
struct TrendChart: View {
    let title: String
    let getData: (TrendPeriod) -> [TrendDataPoint]
    let chartType: ChartType
    let unit: String
    let showProBadge: Bool
    var dataType: DataType = .recovery // Default to recovery for backward compatibility
    var useAdaptiveYAxis: Bool = false // Use adaptive y-axis for non-percentage data (e.g., TSS)
    
    enum DataType {
        case recovery
        case sleep
        case strain
    }
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var animateChart: Bool = false
    @State private var sweepProgress: Double = 1.0  // Start at 1.0 so chart is visible immediately
    @State private var data: [TrendDataPoint] = []
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Compute normalized heights for organic timing
    private var normalizedHeights: [Double] {
        guard !data.isEmpty else { return [] }
        let maxValue = data.map(\.value).max() ?? 100
        return data.map { point in
            min(max(point.value / maxValue, 0), 1)
        }
    }
    
    // Adaptive y-axis range
    private var yAxisRange: ClosedRange<Double> {
        // Strain always uses fixed 0-18 scale
        if dataType == .strain {
            return 0...18
        }
        
        guard useAdaptiveYAxis, !data.isEmpty else { return 0...100 }
        
        let values = data.map(\.value)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        
        // Add 10% padding above and below
        let range = maxValue - minValue
        let padding = max(range * 0.1, 5.0)
        
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding
        
        return lowerBound...upperBound
    }
    
    // Y-axis values for adaptive axis
    private var yAxisValues: [Double] {
        // Strain uses fixed intervals on 0-18 scale
        if dataType == .strain {
            return [0, 6, 10, 13, 18]
        }
        
        guard useAdaptiveYAxis else { return [0, 25, 50, 75, 100] }
        
        let range = yAxisRange
        let span = range.upperBound - range.lowerBound
        let step = span / 4 // 5 values (0, 25%, 50%, 75%, 100%)
        
        return (0...4).map { i in
            range.lowerBound + (Double(i) * step)
        }
    }
    
    // Height of colored top indicator in data units (represents ~2-3px visually)
    private var topIndicatorHeight: Double {
        // Chart height: 225pt
        // Target visual height: 2.5pt (approximately 2-3px)
        // Calculate data units needed for 2.5pt visual height
        
        if dataType == .strain {
            // Strain: 0-18 scale, so 1 unit = 225/18 = 12.5pt
            // 2.5pt / 12.5pt = 0.2 units
            return 0.2
        } else {
            // Recovery/Sleep: 0-100 scale, so 1 unit = 225/100 = 2.25pt
            // 2.5pt / 2.25pt = 1.1 units
            return 1.1
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with title and optional Pro badge
            HStack {
                Image(systemName: Icons.DataSource.intervalsICU)
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
                
                // Show progress indicator if we have partial data
                if data.count < selectedPeriod.days {
                    partialDataIndicator
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadData()
        }
    }
    
    private var periodSelector: some View {
        LiquidGlassSegmentedControl(
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
                    // Very dark grey bar - fully opaque
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", animateChart ? point.value : 0)
                    )
                    .foregroundStyle(ColorPalette.neutral300)

                    // Top 2-3px colored indicator (height adjusted per data scale)
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        yStart: .value("Start", max(0, point.value - topIndicatorHeight)),
                        yEnd: .value("End", point.value)
                    )
                    .foregroundStyle(colorForValue(point.value))
                    .annotation(position: .top, alignment: .center) {
                        if selectedPeriod == .sevenDays {
                            Text("\(Int(point.value))")
                                .font(.system(size: TypeScale.xxs, weight: .semibold))
                                .foregroundColor(colorForValue(point.value))
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
                    .lineStyle(StrokeStyle(lineWidth: 1))
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
                // 7 days: Show all weekday abbreviations - use stride to force all days
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.neutral300)
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else if selectedPeriod == .thirtyDays {
                // 30 days: Show ~5 date labels (every 6 days)
                AxisMarks(values: .stride(by: .day, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.neutral300)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else {
                // 60 days: Show ~5 date labels (every 12 days)
                AxisMarks(values: .stride(by: .day, count: 12)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.neutral300)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine()
                    .foregroundStyle(ColorPalette.neutral300)
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        let intValue = Int(doubleValue)
                        // Strain shows plain numbers, recovery/sleep show percentages
                        if dataType == .strain || useAdaptiveYAxis {
                            Text("\(intValue)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ColorPalette.chartAxisLabel)
                        } else {
                            Text("\(intValue)\(CommonContent.Units.percent))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ColorPalette.chartAxisLabel)
                        }
                    }
                }
            }
        }
        .chartYScale(domain: yAxisRange)
        .chartXScale(domain: .automatic(includesZero: false))
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
    }
    
    private func loadData() {
        Logger.debug("📊 [TREND CHART] Loading data for \(selectedPeriod.days)d period")
        data = getData(selectedPeriod)
        Logger.debug("📊 [TREND CHART] Loaded \(data.count) data points")
    }
    
    // MARK: - Color Coding
    
    private func colorForValue(_ value: Double) -> Color {
        // Strain uses 0-18 scale with band-specific colors
        if dataType == .strain {
            switch value {
            case 0..<6:
                return ColorScale.greenAccent    // Light (0-6)
            case 6..<10:
                return ColorScale.yellowAccent   // Moderate (6-10)
            case 10..<13:
                return ColorScale.amberAccent    // Hard (10-13)
            default:
                return ColorScale.redAccent      // Very Hard (13-18)
            }
        }
        
        // Recovery/Sleep use 0-100 scale
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
        .fixedSize(horizontal: true, vertical: false) // Prevent wrapping
    }
    
    private var emptyState: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(selectedPeriod.days - 1), to: endDate) else {
            return AnyView(
                VStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.DataSource.intervalsICU)
                        .font(.system(size: TypeScale.lg))
                        .foregroundColor(Color.text.secondary)
                    Text(ChartContent.EmptyState.noData)
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            )
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        let predicateFormat = dataType == .recovery ?
            "date >= %@ AND date <= %@ AND recoveryScore > 0" :
            "date >= %@ AND date <= %@ AND sleepScore > 0"
        fetchRequest.predicate = NSPredicate(
            format: predicateFormat,
            startDate as NSDate,
            endDate as NSDate
        )
        
        let availableDays = (try? context.count(for: fetchRequest)) ?? 0
        let daysRemaining = max(0, selectedPeriod.days - availableDays)
        
        // If we have enough data but getData returns empty, show a different message
        if availableDays >= selectedPeriod.days {
            return AnyView(
                VStack(spacing: Spacing.md) {
                    Image(systemName: Icons.DataSource.intervalsICU)
                        .font(.system(size: TypeScale.lg))
                        .foregroundColor(Color.text.secondary)
                    
                    Text(CommonContent.EmptyStates.dataAvailableButEmpty)
                        .font(.system(size: TypeScale.sm, weight: .medium))
                    
                    Text("\(CommonContent.EmptyStates.pullToRefreshTrend) \(selectedPeriod.days)-day trend")
                        .font(.system(size: TypeScale.xs))
                        .foregroundColor(Color.text.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            )
        }
        
        return AnyView(
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.System.clock)
                        .foregroundColor(Color.text.secondary)
                    
                    Text("\(CommonContent.EmptyStates.checkBackIn) \(daysRemaining) \(daysRemaining == 1 ? CommonContent.TimeUnits.day : CommonContent.TimeUnits.days)")
                        .font(.system(size: TypeScale.sm, weight: .medium))
                }
                
                Text("\(CommonContent.EmptyStates.collectingData) \(selectedPeriod.days)-day trend")
                    .font(.system(size: TypeScale.xs))
                    .foregroundColor(Color.text.secondary)
                
                HStack(spacing: Spacing.xs) {
                    Text("\(availableDays) \(CommonContent.EmptyStates.ofDays) \(selectedPeriod.days) \(CommonContent.TimeUnits.days)")
                        .font(.system(size: TypeScale.xxs, weight: .medium))
                        .foregroundColor(Color.text.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ColorPalette.neutral200)
                                .frame(height: 2)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ColorScale.blueAccent)
                                .frame(width: geometry.size.width * min(CGFloat(availableDays) / CGFloat(selectedPeriod.days), 1.0), height: 2)
                        }
                    }
                    .frame(height: 2)
                }
                .padding(.top, 4)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        )
    }
    
    private var partialDataIndicator: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(selectedPeriod.days - 1), to: endDate) else {
            return AnyView(EmptyView())
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        let predicateFormat = dataType == .recovery ?
            "date >= %@ AND date <= %@ AND recoveryScore > 0" :
            "date >= %@ AND date <= %@ AND sleepScore > 0"
        fetchRequest.predicate = NSPredicate(
            format: predicateFormat,
            startDate as NSDate,
            endDate as NSDate
        )
        
        let availableDays = (try? context.count(for: fetchRequest)) ?? data.count
        let daysRemaining = max(0, selectedPeriod.days - availableDays)
        
        return AnyView(
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: Icons.System.clock)
                        .font(.system(size: TypeScale.xxs))
                        .foregroundColor(Color.text.tertiary)
                    
                    Text("\(availableDays) \(CommonContent.EmptyStates.ofDays) \(selectedPeriod.days) \(CommonContent.TimeUnits.days)")
                        .font(.system(size: TypeScale.xxs, weight: .medium))
                        .foregroundColor(Color.text.secondary)
                    
                    Spacer()
                    
                    if daysRemaining > 0 {
                        Text("\(daysRemaining) \(daysRemaining == 1 ? CommonContent.TimeUnits.day : CommonContent.TimeUnits.days) \(CommonContent.EmptyStates.daysRemaining)")
                            .font(.system(size: TypeScale.xxs))
                            .foregroundColor(Color.text.tertiary)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ColorPalette.neutral200)
                            .frame(height: 2)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ColorScale.blueAccent)
                            .frame(width: geometry.size.width * min(CGFloat(availableDays) / CGFloat(selectedPeriod.days), 1.0), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .padding(.top, Spacing.sm)
        )
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
    VStack(spacing: Spacing.md) {
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
