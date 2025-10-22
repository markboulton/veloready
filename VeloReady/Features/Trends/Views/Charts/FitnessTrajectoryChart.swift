import SwiftUI
import Charts

/// Chart showing 7-day historical CTL/ATL/TSB + 7-day projection
/// Based on Training Load chart structure
struct FitnessTrajectoryChart: View {
    let data: [DataPoint]
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let ctl: Double
        let atl: Double
        let tsb: Double
        let isFuture: Bool // For projection styling
    }
    
    var body: some View {
        let todayIndex = data.firstIndex(where: { !$0.isFuture && Calendar.current.isDateInToday($0.date) }) ?? 6
        let futureData = data.filter { $0.isFuture }
        let maxValue = data.map { max($0.ctl, $0.atl, $0.tsb) }.max() ?? 100
        let lastHistoricalPoint = data.last(where: { !$0.isFuture })
        
        Chart {
            // Grey projection zone (behind everything)
            if !futureData.isEmpty, let firstFuture = futureData.first, let lastFuture = futureData.last {
                RectangleMark(
                    xStart: .value(TrendsContent.ChartAxis.start, firstFuture.date),
                    xEnd: .value(TrendsContent.ChartAxis.end, lastFuture.date),
                    yStart: .value(TrendsContent.ChartAxis.bottom, 0),
                    yEnd: .value(TrendsContent.ChartAxis.top, maxValue * 1.1)
                )
                .foregroundStyle(Color(.systemGray6).opacity(0.5))
            }
            
            // Today marker
            if todayIndex < data.count {
                RuleMark(x: .value(TrendsContent.ChartAxis.today, data[todayIndex].date))
                    .foregroundStyle(Color.text.tertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            
            // CTL (Fitness) line
            ForEach(data) { point in
                LineMark(
                    x: .value(TrendsContent.ChartAxis.date, point.date),
                    y: .value(TrendsContent.ChartAxis.value, point.ctl),
                    series: .value(TrendsContent.ChartAxis.metric, TrendsContent.WeeklyReport.ctlLabel)
                )
                .foregroundStyle(point.isFuture ? ColorScale.blueAccent.opacity(0.5) : Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.linear)
                
                // Point markers
                if !point.isFuture {
                    let isLatest = point.id == lastHistoricalPoint?.id
                    
                    PointMark(
                        x: .value(TrendsContent.ChartAxis.date, point.date),
                        y: .value(TrendsContent.ChartAxis.value, point.ctl)
                    )
                    .foregroundStyle(Color.clear)
                    .symbolSize(isLatest ? 100 : 64)
                    .symbol {
                        if isLatest {
                            ZStack {
                                Circle()
                                    .fill(ColorScale.blueAccent)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .stroke(Color.background.primary, lineWidth: 3)
                                    .frame(width: 10, height: 10)
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.background.primary)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .annotation(position: .top, alignment: .center) {
                        if isLatest {
                            Text("\(Int(point.ctl))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorScale.blueAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // ATL (Fatigue) line
            ForEach(data) { point in
                LineMark(
                    x: .value(TrendsContent.ChartAxis.date, point.date),
                    y: .value(TrendsContent.ChartAxis.value, point.atl),
                    series: .value(TrendsContent.ChartAxis.metric, TrendsContent.WeeklyReport.atlLabel)
                )
                .foregroundStyle(point.isFuture ? ColorScale.amberAccent.opacity(0.5) : Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.linear)
                
                // Point markers
                if !point.isFuture {
                    let isLatest = point.id == lastHistoricalPoint?.id
                    
                    PointMark(
                        x: .value(TrendsContent.ChartAxis.date, point.date),
                        y: .value(TrendsContent.ChartAxis.value, point.atl)
                    )
                    .foregroundStyle(Color.clear)
                    .symbolSize(isLatest ? 100 : 64)
                    .symbol {
                        if isLatest {
                            ZStack {
                                Circle()
                                    .fill(ColorScale.amberAccent)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .stroke(Color.background.primary, lineWidth: 3)
                                    .frame(width: 10, height: 10)
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.background.primary)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .annotation(position: .top, alignment: .center) {
                        if isLatest {
                            Text("\(Int(point.atl))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorScale.amberAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // TSB (Form) line
            ForEach(data) { point in
                LineMark(
                    x: .value(TrendsContent.ChartAxis.date, point.date),
                    y: .value(TrendsContent.ChartAxis.value, point.tsb),
                    series: .value(TrendsContent.ChartAxis.metric, TrendsContent.WeeklyReport.formLabel)
                )
                .foregroundStyle(point.isFuture ? ColorScale.greenAccent.opacity(0.5) : Color.text.tertiary)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.linear)
                
                // Point markers
                if !point.isFuture {
                    let isLatest = point.id == lastHistoricalPoint?.id
                    
                    PointMark(
                        x: .value(TrendsContent.ChartAxis.date, point.date),
                        y: .value(TrendsContent.ChartAxis.value, point.tsb)
                    )
                    .foregroundStyle(Color.clear)
                    .symbolSize(isLatest ? 100 : 64)
                    .symbol {
                        if isLatest {
                            ZStack {
                                Circle()
                                    .fill(ColorScale.greenAccent)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .stroke(Color.background.primary, lineWidth: 3)
                                    .frame(width: 10, height: 10)
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.background.primary)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .annotation(position: .bottom, alignment: .center) {
                        if isLatest {
                            Text("\(Int(point.tsb))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorScale.greenAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.text.secondary)
                }
                AxisGridLine()
                    .foregroundStyle(Color(.systemGray4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .frame(height: 200)
    }
    
}

// MARK: - Preview

#Preview {
    VStack {
        Text(TrendsContent.ChartLabels.fitnessTrajectory)
            .font(.heading)
        
        FitnessTrajectoryChart(
            data: generateMockCTLData()
        )
        .frame(height: 200)
        .padding()
    }
    .background(Color.background.primary)
}

func generateMockCTLData() -> [FitnessTrajectoryChart.DataPoint] {
    let calendar = Calendar.current
    let now = Date()
    var points: [FitnessTrajectoryChart.DataPoint] = []
    
    // 7 days historical
    for dayOffset in -6...0 {
        let date = calendar.date(byAdding: .day, value: dayOffset, to: now)!
        let ctl = 70.0 + Double(dayOffset + 6) * 0.5
        let atl = 65.0 + Double(dayOffset + 6) * 0.3
        let tsb = ctl - atl
        
        points.append(FitnessTrajectoryChart.DataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb,
            isFuture: false
        ))
    }
    
    // 7 days projection
    for dayOffset in 1...7 {
        let date = calendar.date(byAdding: .day, value: dayOffset, to: now)!
        let ctl = 73.5 + Double(dayOffset) * 0.5
        let atl = 66.8 + Double(dayOffset) * 0.3
        let tsb = ctl - atl
        
        points.append(FitnessTrajectoryChart.DataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb,
            isFuture: true
        ))
    }
    
    return points
}
