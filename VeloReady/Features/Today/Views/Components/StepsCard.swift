import SwiftUI

/// Individual Steps card for Today view
struct StepsCard: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @State private var hourlySteps: [HourlyStepData] = []
    
    init() {
        self.liveActivityService = LiveActivityService(oauthManager: IntervalsOAuthManager.shared)
    }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon and sparkline
                HStack {
                    // Grey outlined icon
                    Image(systemName: Icons.Health.steps)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.text.secondary)
                    
                    Text("Steps")
                        .font(.heading)
                        .foregroundColor(Color.text.primary)
                    
                    Spacer()
                    
                    // Sparkline aligned right
                    if !hourlySteps.isEmpty {
                        StepsSparkline(hourlySteps: hourlySteps)
                            .frame(width: 80)
                    }
                }
                
                // Steps count
                Text("\(liveActivityService.dailySteps)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.text.primary)
                
                // Distance label
                if liveActivityService.walkingDistance > 0 {
                    Text(formatDistance(liveActivityService.walkingDistance))
                        .font(.subheadline)
                        .foregroundColor(Color.text.secondary)
                }
            }
        }
        .task {
            await loadHourlySteps()
        }
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let userSettings = UserSettings.shared
        
        if userSettings.useMetricUnits {
            return String(format: "%.1f km", kilometers)
        } else {
            let miles = kilometers * 0.621371
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func loadHourlySteps() async {
        let healthKitManager = HealthKitManager.shared
        let steps = await healthKitManager.fetchTodayHourlySteps()
        
        var hourlyData: [HourlyStepData] = []
        for (hour, stepCount) in steps.enumerated() {
            hourlyData.append(HourlyStepData(hour: hour, steps: stepCount))
        }
        
        await MainActor.run {
            self.hourlySteps = hourlyData
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        StepsCard()
    }
    .background(Color.background.primary)
}
