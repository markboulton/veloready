import SwiftUI

/// Individual Steps card for Today view
struct StepsCard: View {
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @ObservedObject private var userSettings = UserSettings.shared
    @State private var hourlySteps: [HourlyStepData] = []
    
    var body: some View {
        StandardCard(
            icon: Icons.Health.steps,
            title: "Steps"
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Sparkline aligned right
                if !hourlySteps.isEmpty {
                    HStack {
                        Spacer()
                        StepsSparkline(hourlySteps: hourlySteps)
                            .frame(width: 160)
                    }
                }
                
                // Steps count with goal
                Text("\(formatSteps(liveActivityService.dailySteps)) / \(formatSteps(userSettings.stepGoal))")
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
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
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
