import SwiftUI

/// Compact row showing steps and detailed calories below the latest ride
struct ActivityStatsRow: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @State private var hourlySteps: [HourlyStepData] = []
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Steps Panel - Full Height
            VStack(alignment: .leading, spacing: Spacing.cardContentSpacing) {
                HStack {
                    Text(ActivityContent.Metrics.steps)
                        .font(.cardTitle)
                    Spacer()
                    if !liveActivityService.isLoading && !hourlySteps.isEmpty {
                        StepsSparkline(hourlySteps: hourlySteps)
                            .frame(width: 50)
                    }
                }
                .task {
                    // Fetch real hourly steps from HealthKit
                    await loadHourlySteps()
                }
                
                if liveActivityService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatSteps(liveActivityService.dailySteps))
                            .font(.metricMedium)
                            .foregroundColor(.primary)
                        
                        if liveActivityService.walkingDistance > 0 {
                            Text(formatDistance(liveActivityService.walkingDistance))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            
            // Detailed Calories Panel
            DetailedCaloriePanel(liveActivityService: liveActivityService)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        return "\(steps)"
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
        
        // Fetch real hourly steps from HealthKit
        let steps = await healthKitManager.fetchTodayHourlySteps()
        
        // Convert to HourlyStepData
        var hourlyData: [HourlyStepData] = []
        for (hour, stepCount) in steps.enumerated() {
            hourlyData.append(HourlyStepData(hour: hour, steps: stepCount))
        }
        
        await MainActor.run {
            self.hourlySteps = hourlyData
        }
    }
}

#Preview {
    ActivityStatsRow(liveActivityService: LiveActivityService(oauthManager: IntervalsOAuthManager()))
        .padding()
}
