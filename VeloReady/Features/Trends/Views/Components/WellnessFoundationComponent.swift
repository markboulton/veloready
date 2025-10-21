import SwiftUI

/// Wellness Foundation component with radar chart
struct WellnessFoundationComponent: View {
    let wellness: WeeklyReportViewModel.WellnessFoundation
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.wellnessFoundation)
                .font(.heading)
                .padding(.top, Spacing.xxl)
            
            // Use single color - health purple with minimal fill
            RadarChart(
                dataPoints: [
                    .init(label: TrendsContent.WeeklyReport.sleepMetric, value: wellness.sleepQuality, icon: "moon.fill"),
                    .init(label: TrendsContent.WeeklyReport.recoveryMetric, value: wellness.recoveryCapacity, icon: "heart.fill"),
                    .init(label: TrendsContent.WeeklyReport.hrvMetric, value: wellness.hrvStatus, icon: "waveform.path.ecg"),
                    .init(label: TrendsContent.WeeklyReport.lowStressMetric, value: 100 - wellness.stressLevel, icon: "brain.head.profile"),
                    .init(label: TrendsContent.WeeklyReport.consistentMetric, value: wellness.consistency, icon: "calendar"),
                    .init(label: TrendsContent.WeeklyReport.fuelingMetric, value: wellness.nutrition, icon: "fork.knife")
                ],
                maxValue: 100,
                fillColor: Color.health.hrv.opacity(0.08),
                strokeColor: Color.health.hrv
            )
            .frame(height: 280)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(TrendsContent.WeeklyReport.overallScore) \(Int(wellness.overallScore))/100")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(wellnessInterpretation(wellness: wellness))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func wellnessInterpretation(wellness: WeeklyReportViewModel.WellnessFoundation) -> String {
        var insights: [String] = []
        
        if wellness.sleepQuality < 70 {
            insights.append(TrendsContent.WeeklyReport.sleepNeedsAttention)
        }
        if wellness.stressLevel > 70 {
            insights.append(TrendsContent.WeeklyReport.stressElevated)
        }
        if wellness.consistency < 70 {
            insights.append(TrendsContent.WeeklyReport.consistencyImprove)
        }
        
        if insights.isEmpty {
            return TrendsContent.WeeklyReport.strongFoundation
        } else {
            return insights.joined(separator: ". ") + "."
        }
    }
}

// MARK: - Preview

#Preview {
    WellnessFoundationComponent(
        wellness: WeeklyReportViewModel.WellnessFoundation(
            sleepQuality: 85,
            recoveryCapacity: 75,
            hrvStatus: 70,
            stressLevel: 30,
            consistency: 82,
            nutrition: 65,
            overallScore: 76
        )
    )
    .padding()
    .background(Color.background.primary)
}
