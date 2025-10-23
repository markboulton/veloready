import SwiftUI

/// Steps card using atomic components
/// Maintains sparkline functionality while using MetricStatCard pattern
struct StepsCardV2: View {
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @ObservedObject private var userSettings = UserSettings.shared
    @State private var hourlySteps: [HourlyStepData] = []
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: CommonContent.Metrics.steps,
                subtitle: formattedProgress
            ),
            style: .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Main metric
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Health.steps)
                        .font(.title)
                        .foregroundColor(Color.text.secondary)
                    
                    CardMetric(
                        value: formatSteps(liveActivityService.dailySteps),
                        label: goalText,
                        size: .large
                    )
                }
                
                // Sparkline (if data available)
                if !hourlySteps.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText("Today's Activity", style: .caption, color: Color.text.secondary)
                        
                        StepsSparkline(hourlySteps: hourlySteps)
                            .frame(height: 32)
                    }
                }
                
                // Distance
                if liveActivityService.walkingDistance > 0 {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(Color.text.secondary)
                        VRText(formatDistance(liveActivityService.walkingDistance), style: .caption, color: Color.text.secondary)
                    }
                }
            }
        }
        .onAppear {
            Logger.debug("📊 [SPARKLINE] StepsCardV2 .onAppear triggered")
            Task {
                await loadHourlySteps()
            }
        }
    }
    
    private var formattedProgress: String {
        let percentage = userSettings.stepGoal > 0
            ? Int((Double(liveActivityService.dailySteps) / Double(userSettings.stepGoal)) * 100)
            : 0
        return "\(percentage)% of goal"
    }
    
    private var goalText: String {
        "\(formatSteps(userSettings.stepGoal)) goal"
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        if userSettings.useMetricUnits {
            return String(format: "%.1f %@", kilometers, CommonContent.Units.kilometers)
        } else {
            let miles = kilometers * 0.621371
            return String(format: "%.1f %@", miles, CommonContent.Units.miles)
        }
    }
    
    private func loadHourlySteps() async {
        Logger.debug("📊 [SPARKLINE] Loading hourly steps...")
        let healthKitManager = HealthKitManager.shared
        let steps = await healthKitManager.fetchTodayHourlySteps()
        Logger.debug("📊 [SPARKLINE] Fetched \(steps.count) hours of data")
        
        var hourlyData: [HourlyStepData] = []
        for (hour, stepCount) in steps.enumerated() {
            hourlyData.append(HourlyStepData(hour: hour, steps: stepCount))
        }
        
        await MainActor.run {
            self.hourlySteps = hourlyData
            Logger.debug("📊 [SPARKLINE] Set hourlySteps count: \(self.hourlySteps.count)")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        StepsCardV2()
    }
    .padding()
    .background(Color.background.primary)
}
