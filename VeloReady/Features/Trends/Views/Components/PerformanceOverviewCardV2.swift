import SwiftUI
import Charts

/// Performance Overview card using atomic ChartCard wrapper
/// Overlays three key metrics: Recovery, Training Load (TSS), and Sleep
/// All metrics normalized to 0-100 scale for direct comparison
struct PerformanceOverviewCardV2: View {
    let recoveryData: [TrendsViewModel.TrendDataPoint]
    let loadData: [TrendsViewModel.TrendDataPoint]
    let sleepData: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    @StateObject private var viewModel = PerformanceOverviewCardViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    
    private var showSleepData: Bool {
        !sleepData.isEmpty && !proConfig.simulateNoSleepData
    }
    
    private var hasData: Bool {
        !recoveryData.isEmpty || !loadData.isEmpty || (!sleepData.isEmpty && showSleepData)
    }
    
    private var hasPartialData: Bool {
        let dataCount = [!recoveryData.isEmpty, !loadData.isEmpty, !sleepData.isEmpty].filter { $0 }.count
        return dataCount > 0 && dataCount < 3
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.performanceOverview,
            subtitle: TrendsContent.PerformanceOverview.subtitle,
            footerText: hasData ? viewModel.generateInsight(
                recoveryData: recoveryData,
                loadData: loadData,
                sleepData: sleepData
            ) : nil
        ) {
            if hasData {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    chartView
                    legendView
                    
                    if hasPartialData {
                        partialDataMessage
                    }
                }
            } else {
                emptyStateView
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
                    TrendsContent.PerformanceOverview.gettingStarted,
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    TrendsContent.requiresData,
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.PerformanceOverview.dailyRecovery, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.PerformanceOverview.trainingActivities, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.PerformanceOverview.sleepTracking, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.PerformanceOverview.sevenDays, style: .caption, color: Color.text.tertiary)
                    }
                }
                
                VRText(
                    TrendsContent.PerformanceOverview.threeMetrics,
                    style: .caption,
                    color: Color.chart.primary
                )
                .fontWeight(.medium)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Partial Data Message
    
    private var partialDataMessage: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.System.clock)
                    .font(.caption)
                    .foregroundColor(Color.chart.primary)
                
                VRText(
                    TrendsContent.PerformanceOverview.buildingData,
                    style: .caption,
                    color: Color.text.secondary
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if recoveryData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(ColorScale.greenAccent)
                            .frame(width: 6, height: 6)
                        VRText(
                            TrendsContent.PerformanceOverview.recoveryAppears,
                            style: .caption,
                            color: Color.text.tertiary
                        )
                    }
                }
                if loadData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.workout.tss)
                            .frame(width: 6, height: 6)
                        VRText(
                            TrendsContent.PerformanceOverview.loadAppears,
                            style: .caption,
                            color: Color.text.tertiary
                        )
                    }
                }
                if sleepData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.health.sleep)
                            .frame(width: 6, height: 6)
                        VRText(
                            TrendsContent.PerformanceOverview.sleepAppears,
                            style: .caption,
                            color: Color.text.tertiary
                        )
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.chart.primary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        Chart {
            // Recovery line (green)
            ForEach(recoveryData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Recovery", point.value),
                    series: .value("Metric", "Recovery")
                )
                .foregroundStyle(ColorScale.greenAccent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // Training Load line (TSS, orange)
            ForEach(loadData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Load", point.value),
                    series: .value("Metric", "Load")
                )
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            // Sleep line (blue) - only show if sleep data available
            if showSleepData {
                ForEach(sleepData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Sleep", point.value),
                        series: .value("Metric", "Sleep")
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: Spacing.lg) {
            MetricLegendItem(
                color: ColorScale.greenAccent,
                label: "Recovery",
                value: recoveryData.last?.value,
                unit: "%"
            )
            
            MetricLegendItem(
                color: Color.orange,
                label: "Load",
                value: loadData.last?.value,
                unit: ""
            )
            
            // Only show sleep legend if sleep data available
            if showSleepData {
                MetricLegendItem(
                    color: Color.blue,
                    label: "Sleep",
                    value: sleepData.last?.value,
                    unit: "%"
                )
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
}

// MARK: - Metric Legend Item

private struct MetricLegendItem: View {
    let color: Color
    let label: String
    let value: Double?
    let unit: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                VRText(label, style: .caption, color: Color.text.secondary)
                
                if let value = value {
                    VRText("\(Int(value))\(unit)", style: .caption, color: Color.text.primary)
                        .fontWeight(.medium)
                } else {
                    VRText("--", style: .caption, color: Color.text.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With all data
            PerformanceOverviewCardV2(
                recoveryData: (0..<30).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: 70 + Double.random(in: -10...15)
                    )
                }.reversed(),
                loadData: (0..<30).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: Double.random(in: 30...80)
                    )
                }.reversed(),
                sleepData: (0..<30).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: 75 + Double.random(in: -15...10)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Partial data (only recovery and sleep)
            PerformanceOverviewCardV2(
                recoveryData: (0..<30).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: 70 + Double.random(in: -10...15)
                    )
                }.reversed(),
                loadData: [],
                sleepData: (0..<30).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: 75 + Double.random(in: -15...10)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            // Empty
            PerformanceOverviewCardV2(
                recoveryData: [],
                loadData: [],
                sleepData: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
