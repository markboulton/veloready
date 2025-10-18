import SwiftUI
import Charts

/// HRV line chart with 7/30/60 day segmented control
struct HRVLineChart: View {
    let getData: (TrendPeriod) -> [TrendDataPoint]
    
    @State private var selectedPeriod: TrendPeriod = .sevenDays
    @State private var sweepProgress: Double = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var data: [TrendDataPoint] {
        getData(selectedPeriod)
    }
    
    private var normalizedHeights: [Double] {
        guard !data.isEmpty else { return [] }
        let maxValue = data.map(\.value).max() ?? 100
        return data.map { point in
            min(max(point.value / maxValue, 0), 1)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(ColorScale.hrvColor)
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
    }
    
    private var chartView: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                let normalizedX = Double(index) / Double(max(data.count - 1, 1))
                let normalizedHeight = index < normalizedHeights.count ? normalizedHeights[index] : 0
                
                let sweepWindow: Double = 0.3
                let pointProgress = max(0, min(1, (sweepProgress - normalizedX) / sweepWindow))
                let heightDelay = normalizedHeight * 0.2
                let delayedProgress = max(0, min(1, pointProgress - heightDelay))
                
                let animatedValue = reduceMotion ? point.value : (delayedProgress * point.value)
                
                // Line
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Value", animatedValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorScale.hrvColor, ColorScale.hrvColor.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                // Area fill
                AreaMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Value", animatedValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorScale.hrvColor.opacity(0.2), ColorScale.hrvColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .onAppear {
            if !reduceMotion {
                sweepProgress = 0
                withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.64)) {
                    sweepProgress = 1.0
                }
            }
        }
        .onChange(of: selectedPeriod) { _, _ in
            if !reduceMotion {
                sweepProgress = 0
                withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.64)) {
                    sweepProgress = 1.0
                }
            }
        }
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
