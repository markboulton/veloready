import SwiftUI
import Charts

/// Overlay comparison chart for Recovery, Training Load (TSS), and Sleep
/// Shows all three key metrics normalized on the same chart
struct PerformanceOverviewCard: View {
    let recoveryData: [TrendsViewModel.TrendDataPoint]
    let loadData: [TrendsViewModel.TrendDataPoint]  // TSS normalized
    let sleepData: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var hasData: Bool {
        !recoveryData.isEmpty || !loadData.isEmpty || !sleepData.isEmpty
    }
    
    private var hasPartialData: Bool {
        // True if we have some but not all metrics
        let dataCount = [!recoveryData.isEmpty, !loadData.isEmpty, !sleepData.isEmpty].filter { $0 }.count
        return dataCount > 0 && dataCount < 3
    }
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.Cards.performanceOverview)
                        .font(.heading)
                        .foregroundColor(.text.primary)
                    
                    Text(TrendsContent.PerformanceOverview.subtitle)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                
                // Chart
                if hasData {
                    chart
                    legend
                    
                    // Show partial data message if not all metrics available
                    if hasPartialData {
                        partialDataMessage
                    }
                    
                    insights
                } else {
                    emptyState
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.PerformanceOverview.gettingStarted)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.requiresData)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.PerformanceOverview.dailyRecovery)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.PerformanceOverview.trainingActivities)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.PerformanceOverview.sleepTracking)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.PerformanceOverview.sevenDays)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.PerformanceOverview.threeMetrics)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    private var partialDataMessage: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                
                Text(TrendsContent.PerformanceOverview.buildingData)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if recoveryData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(ColorScale.greenAccent)
                            .frame(width: 6, height: 6)
                        Text(TrendsContent.PerformanceOverview.recoveryAppears)
                            .font(.caption)
                            .foregroundColor(.text.tertiary)
                    }
                }
                if loadData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.workout.tss)
                            .frame(width: 6, height: 6)
                        Text(TrendsContent.PerformanceOverview.loadAppears)
                            .font(.caption)
                            .foregroundColor(.text.tertiary)
                    }
                }
                if sleepData.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.health.sleep)
                            .frame(width: 6, height: 6)
                        Text(TrendsContent.PerformanceOverview.sleepAppears)
                            .font(.caption)
                            .foregroundColor(.text.tertiary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.chart.primary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    private var chart: some View {
        Chart {
            // Recovery line (green)
            ForEach(recoveryData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Recovery", point.value),
                    series: .value("Metric", "Recovery")
                )
                .foregroundStyle(ColorScale.greenAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            
            // Training Load line (normalized TSS, orange)
            ForEach(loadData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Load", point.value),
                    series: .value("Metric", "Load")
                )
                .foregroundStyle(Color.workout.tss)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            
            // Sleep line (blue)
            ForEach(sleepData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Sleep", point.value),
                    series: .value("Metric", "Sleep")
                )
                .foregroundStyle(Color.health.sleep)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
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
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 200)
    }
    
    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            LegendItem(
                color: .recovery.green,
                label: "Recovery",
                value: recoveryData.last?.value,
                unit: "%"
            )
            
            LegendItem(
                color: .workout.tss,
                label: "Load",
                value: loadData.last?.value,
                unit: ""
            )
            
            LegendItem(
                color: .health.sleep,
                label: "Sleep",
                value: sleepData.last?.value,
                unit: "%"
            )
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    private var insights: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.insight)
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            Text(generateInsight())
                .font(.body)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func generateInsight() -> String {
        guard let lastRecovery = recoveryData.last?.value,
              let lastLoad = loadData.last?.value,
              let lastSleep = sleepData.last?.value else {
            return "Track consistently to see patterns between these key metrics."
        }
        
        // Analyze balance
        if lastRecovery > 75 && lastLoad < 50 && lastSleep > 75 {
            return "You're well-recovered with light training load. Good opportunity for a hard session."
        } else if lastRecovery < 60 && lastLoad > 70 {
            return "High training load with low recovery. Consider reducing intensity or taking a rest day."
        } else if lastSleep < 60 && lastRecovery < 70 {
            return "Poor sleep is affecting recovery. Prioritize sleep to improve adaptation to training."
        } else if lastLoad > 80 && lastRecovery > 70 {
            return "High training load but maintaining good recovery. Your fitness is improving."
        } else {
            return "Monitor these three metrics daily to optimize your training balance."
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double?
    let unit: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                if let value = value {
                    Text("\(Int(value))\(unit)")
                        .font(.caption)
                        .foregroundColor(.text.primary)
                        .fontWeight(.medium)
                } else {
                    Text("--")
                        .font(.caption)
                        .foregroundColor(.text.tertiary)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            PerformanceOverviewCard(
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
            
            // Empty
            PerformanceOverviewCard(
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
