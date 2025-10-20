import SwiftUI
import Charts

/// Training Load chart for Trends tab - shows 90-day CTL/ATL/TSB evolution
struct TrainingLoadTrendCard: View {
    let activities: [IntervalsActivity]
    let timeRange: TrendsViewModel.TimeRange
    
    private var chartData: [LoadDataPoint] {
        generateLoadTrend(activities: activities, days: timeRange.days)
    }
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.Cards.trainingLoad)
                        .font(.heading)
                        .foregroundColor(.text.primary)
                    
                    if let latest = chartData.last {
                        HStack(spacing: Spacing.xs) {
                            Text("TSB:")
                                .font(.caption)
                                .foregroundColor(.text.secondary)
                            
                            Text(String(format: "%.1f", latest.tsb))
                                .font(.title)
                                .foregroundColor(tsbColor(latest.tsb))
                        }
                    } else {
                        Text(TrendsContent.noDataFound)
                            .font(.body)
                            .foregroundColor(.text.secondary)
                    }
                }
                
                // Chart
                if chartData.isEmpty {
                    emptyState
                } else {
                    chart
                    legend
                    insight
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.TrainingLoad.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.TrainingLoad.toTrackLoad)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.TrainingLoad.completeWorkouts)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.TrainingLoad.syncIntervals)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.TrainingLoad.calculateCTL)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.TrainingLoad.recordWorkouts)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.TrainingLoad.fitnessKey)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .padding(.top, Spacing.sm)
                
                Text(TrendsContent.TrainingLoad.fatigueKey)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                
                Text(TrendsContent.TrainingLoad.balanceKey)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart {
            // CTL (Fitness) line - blue
            ForEach(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("CTL", point.ctl),
                    series: .value("Metric", "CTL")
                )
                .foregroundStyle(ColorScale.blueAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            
            // ATL (Fatigue) line - orange
            ForEach(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("ATL", point.atl),
                    series: .value("Metric", "ATL")
                )
                .foregroundStyle(ColorScale.amberAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            
            // TSB (Form) area - green with shading
            ForEach(chartData) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Zero", 0),
                    yEnd: .value("TSB", point.tsb)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ColorScale.greenAccent.opacity(0.3),
                            ColorScale.greenAccent.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("TSB", point.tsb),
                    series: .value("Metric", "TSB")
                )
                .foregroundStyle(ColorScale.greenAccent)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }
            
            // Zero line for TSB reference
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
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
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 200)
    }
    
    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            LegendItem(
                color: ColorScale.blueAccent,
                label: "CTL (Fitness)",
                value: chartData.last?.ctl
            )
            
            LegendItem(
                color: ColorScale.amberAccent,
                label: "ATL (Fatigue)",
                value: chartData.last?.atl
            )
            
            LegendItem(
                color: ColorScale.greenAccent,
                label: "TSB (Form)",
                value: chartData.last?.tsb
            )
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    private var insight: some View {
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
        guard let latest = chartData.last else {
            return "No training load data available"
        }
        
        let tsb = latest.tsb
        let ctl = latest.ctl
        let atl = latest.atl
        
        if tsb < -30 {
            return "Heavy fatigue (TSB \(Int(tsb))). High training stress with inadequate recovery. Consider a recovery week."
        } else if tsb < -10 {
            return "Moderate fatigue (TSB \(Int(tsb))). You're training hard but managing load. Monitor recovery closely."
        } else if tsb > 25 {
            return "Very fresh (TSB +\(Int(tsb))). Low recent training stress. Good time for hard workouts or races."
        } else if tsb >= 0 {
            return "Balanced form (TSB +\(Int(tsb))). Fitness (\(Int(ctl))) and fatigue (\(Int(atl))) in good equilibrium."
        } else {
            return "Slight fatigue (TSB \(Int(tsb))). Normal training load. Fitness building with manageable fatigue."
        }
    }
    
    private func generateLoadTrend(activities: [IntervalsActivity], days: Int) -> [LoadDataPoint] {
        var data: [LoadDataPoint] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        // Parse activity dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        var activitiesWithDates: [(date: Date, ctl: Double, atl: Double)] = []
        for activity in activities {
            guard let activityDate = dateFormatter.date(from: activity.startDateLocal),
                  let ctl = activity.ctl,
                  let atl = activity.atl else { continue }
            activitiesWithDates.append((activityDate, ctl, atl))
        }
        
        // Sort by date
        activitiesWithDates.sort { $0.date < $1.date }
        
        // Generate daily data points
        var currentDate = startDate
        while currentDate <= endDate {
            // Find most recent activity on or before this date
            let dayEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
            
            if let mostRecent = activitiesWithDates.last(where: { $0.date < dayEnd }) {
                let tsbValue = mostRecent.ctl - mostRecent.atl
                
                data.append(LoadDataPoint(
                    date: currentDate,
                    ctl: mostRecent.ctl,
                    atl: mostRecent.atl,
                    tsb: tsbValue,
                    isRide: false,
                    isFuture: false
                ))
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return data
    }
    
    private func tsbColor(_ tsb: Double) -> Color {
        if tsb < -30 {
            return Color.semantic.error
        } else if tsb < -10 {
            return Color.semantic.warning
        } else if tsb > 25 {
            return Color.chart.primary
        } else {
            return Color.semantic.success
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double?
    
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
                    Text(String(format: "%.1f", value))
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
            TrainingLoadTrendCard(
                activities: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
