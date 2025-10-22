import SwiftUI
import Charts

/// Small sparkline showing steps over the day
struct StepsSparkline: View {
    let hourlySteps: [HourlyStepData]
    
    @State private var animationProgress: Double = 0.0
    
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
        .mask(
            // Draw line from left to right (no fade on left)
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: animationProgress),
                                .init(color: .clear, location: animationProgress)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        )
        .onScrollAppear(id: "steps-sparkline") {
            Logger.debug("🎨 [STEPS SPARKLINE] Scroll trigger fired - starting animation")
            // Draw animation from left to right - faster speed
            withAnimation(.easeOut(duration: 0.65)) {
                animationProgress = 1.0
            }
            Logger.debug("🎨 [STEPS SPARKLINE] Animation started: 0.0 → 1.0 over 0.65s")
        }
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
            Text(CommonContent.Metrics.steps)
                .font(.heading)
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
            .font(.title)
    }
    .padding()
}
