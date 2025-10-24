import SwiftUI

/// Detailed view showing load score breakdown and analysis
/// Uses MVVM pattern with StrainDetailViewModel for data fetching
struct StrainDetailView: View {
    let strainScore: StrainScore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StrainDetailViewModel()
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background (light grey in light mode, black in dark mode)
            Color.background.app
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Header with main score
                    StrainHeaderSection(strainScore: strainScore)
                        .padding(.top, 60)
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                    
                    // Score breakdown
                    scoreBreakdownSection
                    
                    // Load components
                    loadComponentsSection
                    
                    // Activity summary
                    Text(StrainContent.noData)
                    
                    // Recovery modulation
                    recoveryModulationSection
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 120)
            }
            
            // Navigation gradient mask
            NavigationGradientMask()
        }
        .navigationTitle(StrainContent.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CircularBackButton(action: { dismiss() })
            }
        }
    }
    
    // MARK: - View Sections
    
    private var weeklyTrendSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklyLoadTrend,
                isEnabled: proConfig.canView7DayLoad,
                showBenefits: true
            ) {
                TrendChart(
                    title: StrainContent.trendTitle,
                    getData: { period in viewModel.getHistoricalLoadData(for: period) },
                    chartType: .bar,
                    unit: "TSS",
                    showProBadge: false
                )
            }
        }
        .padding(.horizontal, -Spacing.xl)
    }
    
    
    private var scoreBreakdownSection: some View {
        StandardCard(
            title: StrainContent.loadComponents
        ) {
            VStack(alignment: .leading, spacing: 16) {
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
    }
    
    private var loadComponentsSection: some View {
        StandardCard(
            title: StrainContent.activitySummary
        ) {
            VStack(alignment: .leading, spacing: 16) {
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
    }
    
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(StrainContent.dailyBreakdown)
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
        StandardCard(
            title: StrainContent.recoveryModulation
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(StrainContent.RecoveryModulation.recoveryFactor)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(StrainContent.RecoveryModulation.adjustsLoad)
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
    }
    
    private var recommendationsSection: some View {
        StandardCard(
            title: StrainContent.recommendations
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(generateRecommendations(), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: Icons.System.lightbulb)
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
        case .light:
            recommendations.append("Light training load - good day for recovery or easy activity.")
        case .moderate:
            recommendations.append("Moderate training load - balanced approach.")
        case .hard:
            recommendations.append("Hard training load - prioritize recovery tomorrow.")
        case .veryHard:
            recommendations.append("Very hard training load - take extra recovery time.")
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
    
    // MARK: - Data Fetching
    // All data fetching logic moved to StrainDetailViewModel
}

// MARK: - Supporting Views

struct LoadComponentRow: View {
    let title: String
    let score: Int
    let weight: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
            return ColorScale.redAccent
        case 60..<80:
            return ColorScale.amberAccent
        case 40..<60:
            return ColorScale.blueAccent
        default:
            return ColorScale.greenAccent
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
        .background(Color.background.card)
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
            band: .hard,
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
