import SwiftUI
import Charts

/// HRV line chart with 7/30/60 day segmented control
struct HRVLineChart: View {
    let getData: (TrendPeriod) -> [TrendDataPoint]
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var data: [TrendDataPoint] = []
    
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
    
    private var chartView: some View {
        Chart {
            ForEach(data) { point in
                // Line - RED, 1px, no gradient, no animation
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            
            // Average line - 1px dashed
            if averageValue > 0 {
                RuleMark(y: .value("Average", averageValue))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.red.opacity(0.5))
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
                        Text("\(intValue)ms")
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
    }
    
    private func loadData() {
        Logger.debug("❤️ [HRV CHART] Loading data for \(selectedPeriod.days)d period")
        data = getData(selectedPeriod)
        Logger.debug("❤️ [HRV CHART] Loaded \(data.count) data points")
    }
    
    private var summaryStats: some View {
        HStack(spacing: Spacing.xl) {
            StatItem(
                label: "Average",
                value: String(format: "%.0f", averageValue),
                unit: "ms"
            )
            
            StatItem(
                label: "Minimum",
                value: String(format: "%.0f", minValue),
                unit: "ms"
            )
            
            StatItem(
                label: "Maximum",
                value: String(format: "%.0f", maxValue),
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
}
