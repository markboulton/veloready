import SwiftUI
import Charts

/// Simplified training load chart with smooth colored lines for Today page
struct TodayTrainingLoadChart: View {
    let data: [TrainingLoadDataPoint]
    
    var body: some View {
        Chart {
            // CTL Line (Fitness) - Blue
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("CTL", point.ctl)
                )
                .foregroundStyle(ColorScale.blueAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
                
                // Dot for today's value only
                if !point.isFuture, Calendar.current.isDateInToday(point.date) {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("CTL", point.ctl)
                    )
                    .foregroundStyle(ColorScale.blueAccent)
                    .symbolSize(80)
                    .annotation(position: .top) {
                        Text("\(Int(point.ctl))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorScale.blueAccent)
                    }
                }
            }
            
            // ATL Line (Fatigue) - Amber
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("ATL", point.atl)
                )
                .foregroundStyle(ColorScale.amberAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
                
                // Dot for today's value only
                if !point.isFuture, Calendar.current.isDateInToday(point.date) {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("ATL", point.atl)
                    )
                    .foregroundStyle(ColorScale.amberAccent)
                    .symbolSize(80)
                    .annotation(position: .top) {
                        Text("\(Int(point.atl))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorScale.amberAccent)
                    }
                }
            }
            
            // TSB Line (Form) - Green
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("TSB", point.tsb)
                )
                .foregroundStyle(ColorScale.greenAccent)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
                
                // Dot for today's value only
                if !point.isFuture, Calendar.current.isDateInToday(point.date) {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("TSB", point.tsb)
                    )
                    .foregroundStyle(ColorScale.greenAccent)
                    .symbolSize(80)
                    .annotation(position: .bottom) {
                        Text("\(Int(point.tsb))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorScale.greenAccent)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.15))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    let mockData = (-60...7).compactMap { offset -> TrainingLoadDataPoint? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        
        let ctl = 70.0 + Double(offset) * 0.3 + sin(Double(offset) / 7.0) * 5
        let atl = 65.0 + Double(offset) * 0.2 + sin(Double(offset) / 7.0) * 3
        let tsb = ctl - atl
        
        return TrainingLoadDataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb,
            isFuture: offset > 0
        )
    }
    
    TodayTrainingLoadChart(data: mockData)
        .padding()
        .background(Color.background.primary)
}
