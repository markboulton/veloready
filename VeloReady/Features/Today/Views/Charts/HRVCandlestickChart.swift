import SwiftUI
import Charts

/// HRV candlestick chart with 7/30/60 day segmented control
struct HRVCandlestickChart: View {
    let getData: (TrendPeriod) -> [HRVDataPoint]
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var animateChart: Bool = false
    @State private var data: [HRVDataPoint] = []
    @State private var isLoading: Bool = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.red)
                    .font(.system(size: TypeScale.xs))
                
                Text("HRV Trend")
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                Spacer()
                
                ProBadge()
            }
            
            // Period selector
            SegmentedControl(
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
                summaryStats
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadData()
        }
    }
    
    private func loadData() {
        Logger.debug("❤️ [HRV CHART] Loading data for \(selectedPeriod.days)d period")
        data = getData(selectedPeriod)
        Logger.debug("❤️ [HRV CHART] Loaded \(data.count) data points")
    }
    
    private var chartView: some View {
        Chart {
            ForEach(data) { point in
                // Candlestick body (open to close)
                RectangleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Open", animateChart ? point.open : point.average),
                    yEnd: .value("Close", animateChart ? point.close : point.average),
                    width: selectedPeriod == .sevenDays ? 35 : (selectedPeriod == .thirtyDays ? 10 : 5)
                )
                .foregroundStyle(candlestickColor(point))
                
                // Wick (high to low)
                RuleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Low", animateChart ? point.low : point.average),
                    yEnd: .value("High", animateChart ? point.high : point.average)
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(candlestickColor(point).opacity(0.6))
                
                // For 7-day view: Annotate high and low values
                if selectedPeriod == .sevenDays && animateChart {
                    // High value annotation
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("High", point.high)
                    )
                    .opacity(0)
                    .annotation(position: .top, spacing: 2) {
                        Text("\(Int(point.high))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Low value annotation
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Low", point.low)
                    )
                    .opacity(0)
                    .annotation(position: .bottom, spacing: 2) {
                        Text("\(Int(point.low))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(height: 225)
        .chartXAxis {
            if selectedPeriod == .sevenDays {
                // Show all 7 days with grid lines
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else if selectedPeriod == .thirtyDays {
                AxisMarks(values: .stride(by: .day, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            } else {
                AxisMarks(values: .stride(by: .day, count: 12)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)ms")
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
    
    private func candlestickColor(_ point: HRVDataPoint) -> Color {
        // All red - consistent color for HRV
        return .red
    }
    
    private var summaryStats: some View {
        HStack(spacing: Spacing.xl) {
            StatItem(
                label: "Average",
                value: String(format: "%.0f", averageHRV),
                unit: "ms"
            )
            
            StatItem(
                label: "Lowest",
                value: String(format: "%.0f", lowestHRV),
                unit: "ms"
            )
            
            StatItem(
                label: "Highest",
                value: String(format: "%.0f", highestHRV),
                unit: "ms"
            )
            
            Spacer()
        }
        .font(.system(size: TypeScale.xs))
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: TypeScale.lg))
                .foregroundColor(Color.text.secondary)
            
            Text("No HRV data for this period")
                .font(.system(size: TypeScale.sm, weight: .medium))
            
            Text("HRV data will appear as it's collected")
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var averageHRV: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.average).reduce(0, +) / Double(data.count)
    }
    
    private var lowestHRV: Double {
        data.map(\.low).min() ?? 0
    }
    
    private var highestHRV: Double {
        data.map(\.high).max() ?? 0
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        let minValue = lowestHRV
        let maxValue = highestHRV
        // Start at 10% below lowest value
        let yMin = max(0, minValue * 0.9)
        let yMax = maxValue * 1.05  // Add 5% padding at top
        return yMin...yMax
    }
}

// MARK: - Data Model

struct HRVDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double   // Day start HRV
    let close: Double  // Day end HRV
    let high: Double   // Highest HRV
    let low: Double    // Lowest HRV
    let average: Double // Average for animation baseline
}
