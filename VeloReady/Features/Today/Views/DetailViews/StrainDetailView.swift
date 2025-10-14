import SwiftUI

/// Detailed view showing load score breakdown and analysis
struct StrainDetailView: View {
    let strainScore: StrainScore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // Header with main score
                    StrainHeaderSection(strainScore: strainScore)
                        .padding()
                    
                    SectionDivider()
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Score breakdown
                    scoreBreakdownSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Load components
                    loadComponentsSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Activity summary
                    activitySummarySection
                        .padding()
                    
                    SectionDivider()
                    
                    // Recovery modulation
                    recoveryModulationSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Recommendations
                    recommendationsSection
                        .padding()
                }
            }
        .navigationTitle(LoadContent.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - View Sections
    
    private var weeklyTrendSection: some View {
        ProFeatureGate(
            upgradeContent: .weeklyLoadTrend,
            isEnabled: proConfig.canView7DayLoad,
            showBenefits: true
        ) {
            TrendChart(
                title: LoadContent.trendTitle,
                getData: { period in getHistoricalLoadData(for: period) },
                chartType: .bar,
                unit: "TSS",
                showProBadge: true
            )
        }
    }
    
    
    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Load Components")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                LoadComponentRow(
                    title: "Cardio",
                    score: strainScore.subScores.cardioLoad,
                    weight: "50%",
                    description: "Cycling TRIMP-based load"
                )
                
                LoadComponentRow(
                    title: "Strength",
                    score: strainScore.subScores.strengthLoad,
                    weight: "25%",
                    description: "Resistance training load"
                )
                
                LoadComponentRow(
                    title: "Daily Activity",
                    score: strainScore.subScores.nonExerciseLoad,
                    weight: "25%",
                    description: "Non-workout activity"
                )
            }
        }
    }
    
    private var loadComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let cardioDuration = strainScore.inputs.cardioDurationMinutes {
                    LoadMetricCard(
                        title: "Cardio Time",
                        value: formatDuration(cardioDuration),
                        icon: "bicycle",
                        color: .blue
                    )
                }
                
                if let avgIF = strainScore.inputs.averageIntensityFactor {
                    LoadMetricCard(
                        title: "Avg Intensity",
                        value: String(format: "%.2f IF", avgIF),
                        icon: "speedometer",
                        color: .orange
                    )
                }
                
                if let steps = strainScore.inputs.dailySteps {
                    LoadMetricCard(
                        title: "Daily Steps",
                        value: "\(steps)",
                        icon: "figure.run",
                        color: .green
                    )
                }
                
                if let calories = strainScore.inputs.activeEnergyCalories {
                    LoadMetricCard(
                        title: "Active Calories",
                        value: String(format: "%.0f", calories),
                        icon: "flame.fill",
                        color: .red
                    )
                }
                
                if let strengthRPE = strainScore.inputs.strengthSessionRPE {
                    LoadMetricCard(
                        title: "Strength RPE",
                        value: String(format: "%.1f", strengthRPE),
                        icon: "dumbbell.fill",
                        color: .purple
                    )
                }
                
                if let strengthDuration = strainScore.inputs.strengthDurationMinutes {
                    LoadMetricCard(
                        title: "Strength Time",
                        value: formatDuration(strengthDuration),
                        icon: "clock.fill",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                if strainScore.inputs.cardioDailyTRIMP != nil {
                    ActivityRow(
                        title: "Cycling Load",
                        value: formatTRIMP(strainScore.inputs.cardioDailyTRIMP!),
                        subtitle: "\(Int(strainScore.inputs.cardioDurationMinutes ?? 0)) min",
                        color: .blue
                    )
                }
                
                if strainScore.inputs.strengthSessionRPE != nil {
                    ActivityRow(
                        title: "Strength Training",
                        value: "RPE \(String(format: "%.1f", strainScore.inputs.strengthSessionRPE!))",
                        subtitle: "\(Int(strainScore.inputs.strengthDurationMinutes ?? 0)) min",
                        color: .purple
                    )
                }
                
                if strainScore.inputs.dailySteps != nil {
                    ActivityRow(
                        title: "Daily Steps",
                        value: "\(strainScore.inputs.dailySteps!)",
                        subtitle: "Non-workout activity",
                        color: .green
                    )
                }
            }
        }
    }
    
    private var recoveryModulationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Modulation")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery Factor")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Adjusts load based on recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.2fx", strainScore.subScores.recoveryFactor))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(recoveryFactorColor)
            }
            .padding(.vertical, 8)
        }
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
    }
    
    // MARK: - Helper Methods
    
    private var recoveryFactorColor: Color {
        if strainScore.subScores.recoveryFactor >= 1.05 {
            return .green // Boosted by good recovery
        } else if strainScore.subScores.recoveryFactor >= 0.95 {
            return .blue // Normal
        } else {
            return .orange // Penalized by poor recovery
        }
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Load level recommendations
        switch strainScore.band {
        case .low:
            recommendations.append("Low load day - consider adding some training.")
        case .moderate:
            recommendations.append("Good balance of training and recovery.")
        case .high:
            recommendations.append("High load day - prioritize recovery tomorrow.")
        case .extreme:
            recommendations.append("Extreme load - take extra recovery time.")
        }
        
        // Component-specific recommendations
        if strainScore.subScores.cardioLoad >= 70 {
            recommendations.append("Strong cardio load - maintain aerobic fitness.")
        }
        
        if strainScore.subScores.strengthLoad >= 70 {
            recommendations.append("Intense strength work - allow muscle recovery.")
        }
        
        if strainScore.subScores.nonExerciseLoad >= 70 {
            recommendations.append("High daily activity - monitor total fatigue.")
        }
        
        // Recovery factor recommendations
        if strainScore.subScores.recoveryFactor < 0.95 {
            recommendations.append("Recovery is affecting load - prioritize sleep and nutrition.")
        } else if strainScore.subScores.recoveryFactor > 1.05 {
            recommendations.append("Good recovery - you're ready for training.")
        }
        
        return recommendations
    }
    
    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)\" \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    private func formatTRIMP(_ trimp: Double) -> String {
        if trimp >= 1000 {
            return String(format: "%.0f", trimp / 1000) + "k"
        } else {
            return String(format: "%.0f", trimp)
        }
    }
    
    // MARK: - Mock Data Generator
    
    private func getHistoricalLoadData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if ProFeatureConfig.shared.showMockDataForTesting {
            return generateMockLoadData(for: period)
        }
        #endif
        
        // TODO: Implement real historical data tracking
        // For now, return empty to show "Not enough data" message
        // Historical tracking will be added in a future update
        return []
        
        // When historical tracking is implemented, this will fetch from UserDefaults/CoreData:
        // return StrainScoreService.shared.getLastNDays(period.days)
    }
    
    private func generateMockLoadData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Generate realistic mock load data (oldest to newest)
        return (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 60...95)  // Realistic range matching recovery/sleep
            )
        }
    }
}

// MARK: - Supporting Views

struct LoadComponentRow: View {
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
        case 80...:
            return .red
        case 60..<80:
            return .orange
        case 40..<60:
            return .blue
        default:
            return .green
        }
    }
}

struct LoadMetricCard: View {
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
    }
}

struct ActivityRow: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct StrainDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStrainScore = StrainScore(
            score: 68,
            band: .high,
            subScores: StrainScore.SubScores(
                cardioLoad: 75,
                strengthLoad: 45,
                nonExerciseLoad: 35,
                recoveryFactor: 0.95
            ),
            inputs: StrainScore.StrainInputs(
                continuousHRData: nil, // TODO: Implement continuous HR data collection
                dailyTRIMP: nil, // TODO: Calculate from continuous HR data
                cardioDailyTRIMP: 2800,
                cardioDurationMinutes: 120,
                averageIntensityFactor: 0.82,
                workoutTypes: ["Cycling", "Running"],
                strengthSessionRPE: 8.0,
                strengthDurationMinutes: 45,
                strengthVolume: nil,
                strengthSets: 12,
                muscleGroupsTrained: [.legs, .core],
                isEccentricFocused: false,
                dailySteps: 12000,
                activeEnergyCalories: 580,
                nonWorkoutMETmin: nil,
                hrvOvernight: 45.0,
                hrvBaseline: 42.0,
                rmrToday: 58.0,
                rmrBaseline: 60.0,
                sleepQuality: 85,
                userFTP: 250.0,
                userMaxHR: 180.0,
                userRestingHR: 55.0,
                userBodyMass: 75.0
            ),
            calculatedAt: Date()
        )
        
        StrainDetailView(strainScore: mockStrainScore)
    }
}
