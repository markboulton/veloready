import SwiftUI
import Charts

/// Card displaying inferred stress level from physiological signals
struct StressLevelCard: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var averageStress: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.stressLevel)
                            .font(.heading)
                            .foregroundColor(.text.primary)
                        
                        if !data.isEmpty {
                            Text("\(Int(averageStress))/100")
                                .font(.title)
                                .foregroundColor(stressColor(averageStress))
                        } else {
                            Text(TrendsContent.noDataFound)
                                .font(.body)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Chart
                if data.isEmpty {
                    emptyState
                } else {
                    chart
                }
                
                // Insight
                if !data.isEmpty {
                    insight
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.Stress.calculationRequires)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.Stress.inferredFrom)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.Stress.recoveryInverted)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.Stress.hrvDeviation)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.Stress.rhrElevation)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.Stress.sleepInverted)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.Stress.trainingIntensity)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.Stress.appearsOnce)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.sm)
                
                Text(TrendsContent.Stress.uniqueAssessment)
                    .font(.caption2)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, 2)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(stressColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 1))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        stressColor(point.value).opacity(0.3),
                        stressColor(point.value).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.Stress.avgStress)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(Int(averageStress))")
                        .font(.heading)
                        .foregroundColor(stressColor(averageStress))
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.Stress.level)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    Text(stressLabel(averageStress))
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
            }
            
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
        let avg = averageStress
        
        if avg < 30 {
            return "Low stress levels. Your body is handling training well with good recovery."
        } else if avg < 50 {
            return "Moderate stress. Normal training stress with adequate recovery."
        } else if avg < 70 {
            return "Elevated stress detected. Consider easier training, more sleep, or stress management."
        } else {
            return "High stress levels. Multiple signals indicate strain. Prioritize recovery and reduce training intensity."
        }
    }
    
    private func stressColor(_ value: Double) -> Color {
        if value < 30 {
            return ColorScale.greenAccent
        } else if value < 50 {
            return ColorScale.blueAccent
        } else if value < 70 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.redAccent
        }
    }
    
    private func stressLabel(_ value: Double) -> String {
        if value < 30 {
            return "Low"
        } else if value < 50 {
            return "Moderate"
        } else if value < 70 {
            return "Elevated"
        } else {
            return "High"
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            StressLevelCard(
                data: (0..<90).map { day in
                    TrendsViewModel.TrendDataPoint(
                        date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                        value: Double.random(in: 20...70)
                    )
                }.reversed(),
                timeRange: .days90
            )
            
            StressLevelCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
