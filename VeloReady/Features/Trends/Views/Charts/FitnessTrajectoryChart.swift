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
        
        Chart {
            // Today marker
            if todayIndex < data.count {
                RuleMark(x: .value("Today", data[todayIndex].date))
                    .foregroundStyle(Color.text.tertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            
            // CTL (Fitness) line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.ctl),
                    series: .value("Metric", "CTL")
                )
                .foregroundStyle(point.isFuture ? Color.gray.opacity(0.3) : Color.button.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
                
                // Point markers (only for historical data)
                if !point.isFuture {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.ctl)
                    )
                    .foregroundStyle(Color.button.primary)
                    .symbolSize(40)
                }
            }
            
            // ATL (Fatigue) line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.atl),
                    series: .value("Metric", "ATL")
                )
                .foregroundStyle(point.isFuture ? Color.gray.opacity(0.3) : Color.semantic.warning.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
                
                // Point markers (only for historical data)
                if !point.isFuture {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.atl)
                    )
                    .foregroundStyle(Color.semantic.warning)
                    .symbolSize(40)
                }
            }
            
            // TSB (Form) line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.tsb),
                    series: .value("Metric", "TSB")
                )
                .foregroundStyle(point.isFuture ? Color.gray.opacity(0.3) : ColorScale.greenAccent.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
                
                // Point markers (only for historical data)
                if !point.isFuture {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.tsb)
                    )
                    .foregroundStyle(ColorScale.greenAccent)
                    .symbolSize(40)
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
        Text("Fitness Trajectory")
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
