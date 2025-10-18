import SwiftUI
import Charts

/// Stacked area chart for compositional data
/// Perfect for showing sleep stage distribution over time
struct StackedAreaChart: View {
    let data: [DayData]
    let categories: [Category]
    let yAxisMax: Double
    
    struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let values: [String: Double] // category name -> value
    }
    
    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
        let label: String
    }
    
    init(
        data: [DayData],
        categories: [Category],
        yAxisMax: Double = 9.0
    ) {
        self.data = data
        self.categories = categories
        self.yAxisMax = yAxisMax
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Chart
            Chart {
                ForEach(categories) { category in
                    ForEach(data) { dayData in
                        AreaMark(
                            x: .value("Date", dayData.date, unit: .day),
                            y: .value("Hours", dayData.values[category.name] ?? 0)
                        )
                        .foregroundStyle(category.color)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
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
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ColorPalette.chartAxisLabel)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yAxisMax)
            .frame(height: 180)
            
            // Legend
            HStack(spacing: Spacing.md) {
                ForEach(categories) { category in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(category.color)
                            .frame(width: 12, height: 12)
                        Text(category.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Card(style: .flat) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sleep Architecture (7 days)")
                .font(.heading)
            
            StackedAreaChart(
                data: generateMockSleepData(),
                categories: [
                    .init(name: "awake", color: Color.red.opacity(0.6), label: "Awake (5%)"),
                    .init(name: "core", color: Color.blue.opacity(0.5), label: "Core (48%)"),
                    .init(name: "rem", color: Color.purple.opacity(0.6), label: "REM (28%)"),
                    .init(name: "deep", color: Color.indigo.opacity(0.7), label: "Deep (19%)")
                ],
                yAxisMax: 9.0
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Deep: 1.3h avg")
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("(target: 1.2h)")
                        .foregroundColor(.text.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("REM: 1.9h avg")
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("(target: 1.8h)")
                        .foregroundColor(.text.secondary)
                }
                .font(.caption)
                
                Text("Quality consistent - supporting training adaptations well.")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    .padding()
    .background(Color.background.primary)
}

func generateMockSleepData() -> [StackedAreaChart.DayData] {
    let calendar = Calendar.current
    return (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: Date())!
        return StackedAreaChart.DayData(
            date: date,
            values: [
                "deep": Double.random(in: 1.1...1.5),
                "rem": Double.random(in: 1.7...2.1),
                "core": Double.random(in: 3.2...3.8),
                "awake": Double.random(in: 0.2...0.5)
            ]
        )
    }
}
