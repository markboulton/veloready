import SwiftUI
import Charts

/// Small sparkline showing steps over the day
struct StepsSparkline: View {
    let hourlySteps: [HourlyStepData]
    
    var body: some View {
        Chart {
            ForEach(hourlySteps) { data in
                LineMark(
                    x: .value("Hour", data.hour),
                    y: .value("Steps", data.steps)
                )
            }
            .foregroundStyle(Color.text.tertiary)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: 0...23)
        .frame(height: 20)
    }
}

struct HourlyStepData: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Steps")
                .font(.cardTitle)
            Spacer()
            StepsSparkline(hourlySteps: [
                HourlyStepData(hour: 0, steps: 0),
                HourlyStepData(hour: 1, steps: 0),
                HourlyStepData(hour: 2, steps: 0),
                HourlyStepData(hour: 3, steps: 0),
                HourlyStepData(hour: 4, steps: 0),
                HourlyStepData(hour: 5, steps: 0),
                HourlyStepData(hour: 6, steps: 200),
                HourlyStepData(hour: 7, steps: 450),
                HourlyStepData(hour: 8, steps: 680),
                HourlyStepData(hour: 9, steps: 750),
                HourlyStepData(hour: 10, steps: 820),
                HourlyStepData(hour: 11, steps: 650),
                HourlyStepData(hour: 12, steps: 900),
                HourlyStepData(hour: 13, steps: 720),
                HourlyStepData(hour: 14, steps: 880),
                HourlyStepData(hour: 15, steps: 950),
                HourlyStepData(hour: 16, steps: 620),
                HourlyStepData(hour: 17, steps: 780),
                HourlyStepData(hour: 18, steps: 550),
                HourlyStepData(hour: 19, steps: 420),
                HourlyStepData(hour: 20, steps: 280),
                HourlyStepData(hour: 21, steps: 150),
                HourlyStepData(hour: 22, steps: 0),
                HourlyStepData(hour: 23, steps: 0)
            ])
            .frame(width: 60)
        }
        
        Text("10,850")
            .font(.metricMedium)
    }
    .padding()
}
