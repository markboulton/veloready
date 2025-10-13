import SwiftUI

/// Detailed view showing sleep score breakdown and analysis
struct SleepDetailView: View {
    let sleepScore: SleepScore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // 1. Header with sleep ring (main score)
                    SleepHeaderSection(sleepScore: sleepScore)
                    
                    // Missing data warning if no sleep duration
                    if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
                        missingSleepDataWarning
                    }
                    
                    // 2. USP: Sleep-Recovery Index (unique graph)
                    SleepRecoveryIndexChart(sleepScore: sleepScore)
                    
                    // 3. Weekly Trend (Pro)
                    weeklyTrendSection
                    
                    // 4. Sleep Architecture: Stages with typical ranges + hypnogram
                    SleepStagesDetailChart(sleepScore: sleepScore)
                    
                    // 5. Restorative Sleep
                    RestorativeSleepChart(sleepScore: sleepScore)
                    
                    // 6. Sleep Target for Tonight
                    SleepTargetChart(sleepScore: sleepScore)
                    
                    // 7. Sleep Debt
                    SleepDebtChart(sleepScore: sleepScore)
                    
                    // Recommendations (keep at bottom)
                    recommendationsSection
                }
                .padding()
            }
        .navigationTitle(SleepContent.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - View Sections
    
    private var missingSleepDataWarning: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                Image(systemName: "moon.zzz")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No sleep data from last night")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Sleep score is unavailable. Wear your Apple Watch tonight to track sleep and get complete recovery analysis tomorrow.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemOrange).opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemOrange).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var weeklyTrendSection: some View {
        ProFeatureGate(
            featureName: SleepContent.weeklyTrendFeature,
            featureDescription: SleepContent.weeklyTrendDescription,
            isEnabled: proConfig.canViewWeeklyTrends
        ) {
            TrendChart(
                title: SleepContent.trendTitle,
                getData: { period in getHistoricalSleepData(for: period) },
                chartType: .bar,
                unit: "%",
                showProBadge: true
            )
        }
    }
    
    
    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SleepContent.breakdownTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ScoreBreakdownRow(
                    title: SleepContent.Components.performance,
                    score: sleepScore.subScores.performance,
                    weight: SleepContent.Weights.performance,
                    description: "Actual sleep vs. sleep need"
                )
                
                ScoreBreakdownRow(
                    title: SleepContent.Components.efficiency,
                    score: sleepScore.subScores.efficiency,
                    weight: SleepContent.Weights.efficiency,
                    description: "Time asleep vs. time in bed"
                )
                
                ScoreBreakdownRow(
                    title: SleepContent.Components.stageQuality,
                    score: sleepScore.subScores.stageQuality,
                    weight: SleepContent.Weights.stageQuality,
                    description: "Deep + REM sleep percentage"
                )
                
                ScoreBreakdownRow(
                    title: SleepContent.Components.disturbances,
                    score: sleepScore.subScores.disturbances,
                    weight: SleepContent.Weights.disturbances,
                    description: "Number of wake events"
                )
                
                ScoreBreakdownRow(
                    title: SleepContent.Components.timing,
                    score: sleepScore.subScores.timing,
                    weight: SleepContent.Weights.timing,
                    description: "Bedtime/wake time consistency"
                )
                
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var sleepMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SleepContent.metricsTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SleepMetricCard(
                    title: SleepContent.Metrics.duration,
                    value: sleepScore.formattedSleepDuration,
                    icon: "moon.fill",
                    color: .blue
                )
                
                SleepMetricCard(
                    title: "Sleep Need",
                    value: sleepScore.formattedSleepNeed,
                    icon: "target",
                    color: .green
                )
                
                SleepMetricCard(
                    title: SleepContent.Metrics.efficiency,
                    value: sleepScore.formattedSleepEfficiency,
                    icon: "percent",
                    color: .orange
                )
                
                SleepMetricCard(
                    title: "Wake Events",
                    value: sleepScore.formattedWakeEvents,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                SleepMetricCard(
                    title: "Deep Sleep",
                    value: sleepScore.formattedDeepSleepPercentage,
                    icon: "waveform.path.ecg",
                    color: .indigo
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var sleepStagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let sleepDuration = sleepScore.inputs.sleepDuration, sleepDuration > 0 {
                VStack(spacing: 12) {
                    if let deepDuration = sleepScore.inputs.deepSleepDuration {
                        SleepStageRow(
                            title: "Deep Sleep",
                            duration: deepDuration,
                            totalDuration: sleepDuration,
                            color: .indigo
                        )
                    }
                    
                    if let remDuration = sleepScore.inputs.remSleepDuration {
                        SleepStageRow(
                            title: "REM Sleep",
                            duration: remDuration,
                            totalDuration: sleepDuration,
                            color: .purple
                        )
                    }
                    
                    if let coreDuration = sleepScore.inputs.coreSleepDuration {
                        SleepStageRow(
                            title: "Core Sleep",
                            duration: coreDuration,
                            totalDuration: sleepDuration,
                            color: .blue
                        )
                    }
                    
                    if let awakeDuration = sleepScore.inputs.awakeDuration {
                        SleepStageRow(
                            title: "Awake",
                            duration: awakeDuration,
                            totalDuration: sleepDuration,
                            color: .orange
                        )
                    }
                }
            } else {
                Text("No sleep stage data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(generateRecommendations(), id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(ColorPalette.yellow)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Performance recommendations
        if sleepScore.subScores.performance < 70 {
            recommendations.append("Try to get closer to your sleep target of \(sleepScore.formattedSleepNeed)")
        }
        
        // Efficiency recommendations
        if sleepScore.subScores.efficiency < 70 {
            recommendations.append("Improve sleep efficiency by reducing time spent awake in bed")
        }
        
        // Stage quality recommendations
        if sleepScore.subScores.stageQuality < 70 {
            recommendations.append("Focus on getting more deep and REM sleep through better sleep hygiene")
        }
        
        // Disturbance recommendations
        if sleepScore.subScores.disturbances < 70 {
            recommendations.append("Reduce sleep disturbances by creating a more comfortable sleep environment")
        }
        
        // Timing recommendations
        if sleepScore.subScores.timing < 70 {
            recommendations.append("Maintain consistent bedtime and wake times for better sleep quality")
        }
        
        // Default recommendation if all scores are good
        if recommendations.isEmpty {
            recommendations.append("Great sleep quality! Keep up the good sleep habits.")
        }
        
        return recommendations
    }
    
    // MARK: - Mock Data Generator
    
    private func getHistoricalSleepData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if ProFeatureConfig.shared.showMockDataForTesting {
            return generateMockSleepData(for: period)
        }
        #endif
        
        // TODO: Implement real historical data tracking
        // For now, return empty to show "Not enough data" message
        // Historical tracking will be added in a future update
        return []
        
        // When historical tracking is implemented, this will fetch from UserDefaults/CoreData:
        // return SleepScoreService.shared.getLastNDays(period.days)
    }
    
    private func generateMockSleepData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Generate realistic mock sleep data (oldest to newest)
        return (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 70...95)
            )
        }
    }
}

// MARK: - Supporting Views

struct ScoreBreakdownRow: View {
    let title: String
    let score: Int
    let weight: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(weight)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(score)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
        }
        .padding(.vertical, 4)
    }
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct SleepMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SleepStageRow: View {
    let title: String
    let duration: Double
    let totalDuration: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int((duration / totalDuration) * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

struct SleepDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSleepScore = SleepScore(
            score: 85,
            band: .excellent,
            subScores: SleepScore.SubScores(
                performance: 90,
                efficiency: 85,
                stageQuality: 80,
                disturbances: 90,
                timing: 85
            ),
            inputs: SleepScore.SleepInputs(
                sleepDuration: 28800, // 8 hours
                timeInBed: 32400, // 9 hours
                sleepNeed: 28800, // 8 hours
                deepSleepDuration: 4320, // 1.2 hours
                remSleepDuration: 5760, // 1.6 hours
                coreSleepDuration: 17280, // 4.8 hours
                awakeDuration: 3600, // 1 hour
                wakeEvents: 2,
                bedtime: Date(),
                wakeTime: Date(),
                baselineBedtime: Date(),
                baselineWakeTime: Date(),
                hrvOvernight: 45.0,
                hrvBaseline: 42.0
            ),
            calculatedAt: Date()
        )
        
        SleepDetailView(sleepScore: mockSleepScore)
    }
}
