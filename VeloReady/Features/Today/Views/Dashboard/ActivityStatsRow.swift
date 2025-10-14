import SwiftUI

/// Compact row showing steps and detailed calories below the latest ride
struct ActivityStatsRow: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @State private var hourlySteps: [HourlyStepData] = []
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Steps Panel - Full Height
                VStack(alignment: .leading, spacing: Spacing.cardContentSpacing) {
                    HStack {
                        Text(ActivityContent.Metrics.steps)
                            .font(.heading)
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
                        LoadingStateView(size: .small)
                    } else {
                        MetricDisplay(
                            formatSteps(liveActivityService.dailySteps),
                            label: liveActivityService.walkingDistance > 0 ? formatDistance(liveActivityService.walkingDistance) : nil,
                            size: .medium
                        )
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(leading: 0)
                
                // 2px Vertical Divider
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 2)
                
                // Detailed Calories Panel
                DetailedCaloriePanel(liveActivityService: liveActivityService)
                    .frame(maxWidth: .infinity)
            }
            
            SectionDivider(topPadding: 0)
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
