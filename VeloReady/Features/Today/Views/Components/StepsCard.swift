import SwiftUI

/// Individual Steps card for Today view
struct StepsCard: View {
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @ObservedObject private var userSettings = UserSettings.shared
    @State private var hourlySteps: [HourlyStepData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header with sparkline
            HStack(alignment: .center, spacing: Spacing.sm) {
                Image(systemName: Icons.Health.steps)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.text.secondary)
                
                Text("Steps")
                    .font(.heading)
                    .foregroundColor(Color.text.primary)
                
                Spacer()
                
                // Sparkline aligned with header
                if !hourlySteps.isEmpty {
                    StepsSparkline(hourlySteps: hourlySteps)
                        .frame(width: 160, height: 24)
                }
            }
            .padding(.bottom, Spacing.md)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Steps count with goal - current bold, target regular grey
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(formatSteps(liveActivityService.dailySteps))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.text.primary)
                    
                    Text(" / ")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Text(formatSteps(userSettings.stepGoal))
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Distance label
                if liveActivityService.walkingDistance > 0 {
                    Text(formatDistance(liveActivityService.walkingDistance))
                        .font(.subheadline)
                        .foregroundColor(Color.text.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.08))
        )
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxl / 2)
        .onAppear {
            Logger.debug("📊 [SPARKLINE] StepsCard .onAppear triggered")
            Task {
                await loadHourlySteps()
            }
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
    VStack(spacing: 0) {
        StepsCard()
    }
    .background(Color.background.primary)
}
