import SwiftUI
import Charts

/// Chart showing CTL, ATL, and TSB progression over time
/// Same style as ride detail chart
struct FitnessTrajectoryChart: View {
    let data: [DataPoint]
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let ctl: Double
        let atl: Double
        let tsb: Double
    }
    
    var body: some View {
        Chart {
            // CTL (Fitness) - Blue line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("CTL", point.ctl)
                )
                .foregroundStyle(Color.workout.power)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .symbolSize(30)
                .interpolationMethod(.catmullRom)
            }
            
            // ATL (Fatigue) - Orange line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("ATL", point.atl)
                )
                .foregroundStyle(Color.workout.tss)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .symbolSize(30)
                .interpolationMethod(.catmullRom)
            }
            
            // TSB (Form) - Area fill showing fresh vs fatigued
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    yStart: .value("Zero", 0),
                    yEnd: .value("TSB", point.tsb)
                )
                .foregroundStyle(
                    point.tsb > 0 ?
                    Color.green.opacity(0.2).gradient :
                    Color.red.opacity(0.2).gradient
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.text.tertiary.opacity(0.2))
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: TypeScale.xxs))
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.text.tertiary.opacity(0.2))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))")
                            .font(.system(size: TypeScale.xxs))
                            .foregroundStyle(Color.text.secondary)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8) {
            HStack(spacing: Spacing.md) {
                legendItem(color: .workout.power, label: "CTL (Fitness)")
                legendItem(color: .workout.tss, label: "ATL (Fatigue)")
                legendItem(color: .green, label: "TSB (Form)")
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: TypeScale.xxs))
                .foregroundColor(.text.secondary)
        }
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
    
    return (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: now)!
        let ctl = 70.0 + Double(dayOffset) * 0.5
        let atl = 65.0 + Double(dayOffset) * 0.3
        let tsb = ctl - atl
        
        return FitnessTrajectoryChart.DataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb
        )
    }
}
