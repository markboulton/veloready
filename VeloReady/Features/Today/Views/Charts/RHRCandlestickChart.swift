import SwiftUI
import Charts

/// RHR candlestick chart with 7/30/60 day segmented control
struct RHRCandlestickChart: View {
    let getData: (TrendPeriod) -> [RHRDataPoint]
    let baseline: Double? // RHR baseline for zone display
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var animateChart: Bool = false
    @State private var data: [RHRDataPoint] = []
    @State private var isLoading: Bool = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: Icons.Health.heartCircle)
                    .foregroundColor(.secondary)
                    .font(.system(size: TypeScale.xs))
                
                Text(ChartContent.RHR.rhrTrend)
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                Spacer()
            }
            
            // Period selector
            LiquidGlassSegmentedControl(
                segments: TrendPeriod.allCases.map { period in
                    SegmentItem(value: period, label: period.label)
                },
                selection: $selectedPeriod
            )
            
            // Chart
            if data.isEmpty {
                emptyState
            } else {
                chartView
                legendView
                summaryStats
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadData()
        }
    }
    
    private func loadData() {
        Logger.debug("💔 [RHR CHART] Loading data for \(selectedPeriod.days)d period")
        data = getData(selectedPeriod)
        Logger.debug("💔 [RHR CHART] Loaded \(data.count) data points")
    }
    
    private var chartView: some View {
        let isToday: (RHRDataPoint) -> Bool = { point in
            Calendar.current.isDateInToday(point.date)
        }
        
        return Chart {
            ForEach(data) { point in
                let isTodayPoint = isToday(point)
                let color = isTodayPoint ? ColorScale.blueAccent : ColorPalette.neutral200
                
                // Candlestick body (open to close)
                RectangleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Open", animateChart ? point.open : point.average),
                    yEnd: .value("Close", animateChart ? point.close : point.average),
                    width: selectedPeriod == .sevenDays ? 35 : (selectedPeriod == .thirtyDays ? 10 : 5)
                )
                .foregroundStyle(color)
                
                // Wick (high to low)
                RuleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Low", animateChart ? point.low : point.average),
                    yEnd: .value("High", animateChart ? point.high : point.average)
                )
                .lineStyle(StrokeStyle(lineWidth: isTodayPoint ? 2 : 1))
                .foregroundStyle(isTodayPoint ? 
                    LinearGradient(
                        colors: [colorForRHRValue(point.high), colorForRHRValue(point.low)],
                        startPoint: .top,
                        endPoint: .bottom
                    ) : 
                    LinearGradient(
                        colors: [Color.text.primary, Color.text.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // For 7-day view: Annotate high and low values
                if selectedPeriod == .sevenDays && animateChart {
                    // High value annotation
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("High", point.high)
                    )
                    .opacity(0)
                    .annotation(position: .top, spacing: Spacing.sm) {
                        Text("\(Int(point.high))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isTodayPoint ? colorForRHRValue(point.high) : Color.text.primary)
                    }
                    
                    // Low value annotation
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Low", point.low)
                    )
                    .opacity(0)
                    .annotation(position: .bottom, spacing: Spacing.sm) {
                        Text("\(Int(point.low))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isTodayPoint ? colorForRHRValue(point.low) : Color.text.primary)
                    }
                }
            }
            
            // Baseline zone (if available)
            if let baseline = baseline, animateChart {
                RectangleMark(
                    yStart: .value("Baseline Low", baseline - 3),
                    yEnd: .value("Baseline High", baseline + 3)
                )
                .foregroundStyle(ColorPalette.neutral300.opacity(0.15))
            }
        }
        .frame(height: 225)
        .chartXAxis {
            if selectedPeriod == .sevenDays {
                // Show all 7 days with grid lines
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.neutral300)
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else if selectedPeriod == .thirtyDays {
                AxisMarks(values: .stride(by: .day, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.neutral300)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else {
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
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(ColorPalette.neutral300)
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)\(CommonContent.Units.bpm))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ColorPalette.chartAxisLabel)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisDomain)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        // Run on background thread
        let newData = await Task.detached(priority: .userInitiated) {
            getData(selectedPeriod)
        }.value
        
        data = newData
        isLoading = false
        
        // Animate after data loads
        if !reduceMotion {
            animateChart = false
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.4)) {
                animateChart = true
            }
        } else {
            animateChart = true
        }
    }
    
    private func candlestickColor(_ point: RHRDataPoint) -> Color {
        // All red - lower is better, higher is worse, but keep consistent red
        return .red
    }
    
    private var summaryStats: some View {
        HStack(spacing: Spacing.xl) {
            StatItem(
                label: "Average",
                value: String(format: "%.0f", averageRHR),
                unit: "bpm"
            )
            
            StatItem(
                label: "Lowest",
                value: String(format: "%.0f", lowestRHR),
                unit: "bpm"
            )
            
            StatItem(
                label: "Highest",
                value: String(format: "%.0f", highestRHR),
                unit: "bpm"
            )
            
            Spacer()
        }
        .font(.system(size: TypeScale.xs))
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.Health.heartCircle)
                .font(.system(size: TypeScale.lg))
                .foregroundColor(Color.text.secondary)
            
            Text(ChartContent.RHR.noDataForPeriod)
                .font(.system(size: TypeScale.sm, weight: .medium))
            
            Text(ChartContent.RHR.dataWillAppear)
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var averageRHR: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.average).reduce(0, +) / Double(data.count)
    }
    
    private var lowestRHR: Double {
        data.map(\.low).min() ?? 0
    }
    
    private var highestRHR: Double {
        data.map(\.high).max() ?? 0
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        let minValue = lowestRHR
        let maxValue = highestRHR
        // Start at 10% below lowest value (no one has 0 heart rate)
        let yMin = max(0, minValue * 0.9)
        let yMax = maxValue * 1.05  // Add 5% padding at top
        return yMin...yMax
    }
    
    // Color coding for RHR values based on baseline
    private func colorForRHRValue(_ value: Double) -> Color {
        guard let baseline = baseline else {
            return Color(white: 0.6) // Grey if no baseline
        }
        
        let percentDiff = ((value - baseline) / baseline) * 100
        
        // For RHR: lower is better
        if abs(percentDiff) <= 5 {
            // Within 5% of baseline = Balanced (Green)
            return ColorScale.greenAccent
        } else if percentDiff > 5 && percentDiff <= 10 {
            // 5-10% above baseline = Unbalanced (Amber)
            return ColorScale.amberAccent
        } else if percentDiff > 10 {
            // >10% above baseline = Low/Out of ordinary (Red)
            return ColorScale.redAccent
        } else {
            // Below baseline is good for RHR, but unusual = Amber
            return ColorScale.amberAccent
        }
    }
    
    private var legendView: some View {
        HStack(spacing: Spacing.md) {
            legendItem(color: ColorScale.greenAccent, label: "Balanced")
            legendItem(color: ColorScale.amberAccent, label: "Unbalanced")
            legendItem(color: ColorScale.redAccent, label: "Low")
            legendItem(color: Color(white: 0.5), label: "Baseline")
            Spacer()
        }
        .font(.system(size: 10))
        .padding(.vertical, Spacing.xs)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(Color.text.secondary)
        }
    }
}

// MARK: - Data Model

struct RHRDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double   // Day start RHR
    let close: Double  // Day end RHR
    let high: Double   // Highest RHR
    let low: Double    // Lowest RHR
    let average: Double // Average for animation baseline
}
