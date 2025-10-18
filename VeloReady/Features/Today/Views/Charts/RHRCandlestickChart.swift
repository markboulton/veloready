import SwiftUI
import Charts

/// RHR candlestick chart with 7/30/60 day segmented control
struct RHRCandlestickChart: View {
    let getData: (TrendPeriod) -> [RHRDataPoint]
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var animateChart: Bool = false
    @State private var data: [RHRDataPoint] = []
    @State private var isLoading: Bool = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: TypeScale.xs))
                
                Text("RHR Trend")
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
        Logger.debug("💔 [RHR CHART] Loading data for \(selectedPeriod.days)d period")
        data = getData(selectedPeriod)
        Logger.debug("💔 [RHR CHART] Loaded \(data.count) data points")
    }
    
    private var chartView: some View {
        Chart {
            ForEach(data) { point in
                // Candlestick body (open to close)
                RectangleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Open", animateChart ? point.open : point.average),
                    yEnd: .value("Close", animateChart ? point.close : point.average),
                    width: selectedPeriod == .sevenDays ? 30 : (selectedPeriod == .thirtyDays ? 10 : 5)
                )
                .foregroundStyle(candlestickColor(point))
                
                // Wick (high to low)
                RuleMark(
                    x: .value("Day", point.date, unit: .day),
                    yStart: .value("Low", animateChart ? point.low : point.average),
                    yEnd: .value("High", animateChart ? point.high : point.average)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
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
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(candlestickColor(point))
                    }
                    
                    // Low value annotation
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Low", point.low)
                    )
                    .opacity(0)
                    .annotation(position: .bottom, spacing: 2) {
                        Text("\(Int(point.low))")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(candlestickColor(point))
                    }
                }
            }
        }
        .frame(height: 225)
        .chartXAxis {
            if selectedPeriod == .sevenDays {
                AxisMarks { value in
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
                        Text("\(intValue)bpm")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ColorPalette.chartAxisLabel)
                    }
                }
            }
        }
        .chartYScale(domain: .automatic)
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
            Image(systemName: "heart.circle.fill")
                .font(.system(size: TypeScale.lg))
                .foregroundColor(Color.text.secondary)
            
            Text("No RHR data for this period")
                .font(.system(size: TypeScale.sm, weight: .medium))
            
            Text("RHR data will appear as it's collected")
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
