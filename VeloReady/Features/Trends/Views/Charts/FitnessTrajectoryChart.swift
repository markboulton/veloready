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
            // CTL (Fitness) - Soft blue line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("CTL", point.ctl)
                )
                .foregroundStyle(ColorPalette.powerMetric)
                .lineStyle(RefinedChartMarks.lineStyle())
                .interpolationMethod(.catmullRom)
            }
            
            // ATL (Fatigue) - Amber line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("ATL", point.atl)
                )
                .foregroundStyle(ColorPalette.tssMetric)
                .lineStyle(RefinedChartMarks.lineStyle())
                .interpolationMethod(.catmullRom)
            }
            
            // TSB (Form) - Very subtle area fill
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    yStart: .value("Zero", 0),
                    yEnd: .value("TSB", point.tsb)
                )
                .foregroundStyle(
                    point.tsb > 0 ?
                    ColorPalette.recoveryExcellent.opacity(0.08) :
                    ColorPalette.recoveryPoor.opacity(0.08)
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                    .foregroundStyle(ColorPalette.chartGridLine)
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ColorPalette.chartAxisLabel)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(ColorPalette.chartGridLine)
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ColorPalette.chartAxisLabel)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8) {
            HStack(spacing: Spacing.md) {
                legendItem(color: ColorPalette.powerMetric, label: "CTL (Fitness)")
                legendItem(color: ColorPalette.tssMetric, label: "ATL (Fatigue)")
                legendItem(color: ColorPalette.recoveryExcellent, label: "TSB (Form)")
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ColorPalette.labelSecondary)
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
