import SwiftUI

/// Simple Training Load summary showing CTL, ATL, and TSB (Form)
/// Works with Strava-calculated values
struct TrainingLoadSummaryView: View {
    let activity: IntervalsActivity
    
    private var ctl: Double { activity.ctl ?? 0 }
    private var atl: Double { activity.atl ?? 0 }
    private var tsb: Double { ctl - atl }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header
            Text(CommonContent.Metrics.trainingLoad)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Three metrics in a row
            HStack(spacing: Spacing.xs) {
                // CTL (Fitness)
                TrainingLoadMetric(
                    title: "Fitness",
                    subtitle: "CTL (42d)",
                    value: ctl,
                    color: .blue,
                    icon: "figure.strengthtraining.traditional"
                )
                
                // ATL (Fatigue)
                TrainingLoadMetric(
                    title: "Fatigue",
                    subtitle: "ATL (7d)",
                    value: atl,
                    color: .orange,
                    icon: "bolt.fill"
                )
                
                // TSB (Form)
                TrainingLoadMetric(
                    title: "Form",
                    subtitle: "TSB",
                    value: tsb,
                    color: tsbColor,
                    icon: "star.fill"
                )
            }
            
            // Explanation
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(CommonContent.Sections.whatThisMeans)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(formExplanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    private var tsbColor: Color {
        if tsb > 10 { return .green }
        if tsb > 0 { return .blue }
        if tsb > -10 { return .orange }
        return .red
    }
    
    private var formExplanation: String {
        if tsb > 10 {
            return "You're fresh and ready to perform! Your fitness is high and fatigue is low. Great time for hard efforts or racing."
        } else if tsb > 0 {
            return "You're in good form with balanced fitness and fatigue. You can handle moderate training loads."
        } else if tsb > -10 {
            return "You're carrying some fatigue but building fitness. Consider easier days or recovery to freshen up."
        } else {
            return "You're significantly fatigued. Prioritize recovery and easy training to avoid overtraining."
        }
    }
}

struct TrainingLoadMetric: View {
    let title: String
    let subtitle: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Value
            Text(String(format: "%.1f", value))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // Subtitle
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.background.card)
        .cornerRadius(8)
    }
}

#Preview {
    TrainingLoadSummaryView(
        activity: IntervalsActivity(
            id: "test",
            name: "Test Ride",
            description: nil,
            startDateLocal: "2025-10-15T10:00:00",
            type: "Ride",
            duration: 3600,
            distance: 30000,
            elevationGain: 500,
            averagePower: 200,
            normalizedPower: 210,
            averageHeartRate: 150,
            maxHeartRate: 180,
            averageCadence: 85,
            averageSpeed: 30,
            maxSpeed: 50,
            calories: 800,
            fileType: nil,
            tss: 100,
            intensityFactor: 0.85,
            atl: 45.0,
            ctl: 60.0,
            icuZoneTimes: nil,
            icuHrZoneTimes: nil
        )
    )
    .padding()
}
