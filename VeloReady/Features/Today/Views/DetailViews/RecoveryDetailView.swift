import SwiftUI
import HealthKit

/// Detailed recovery view with large graph and Apple Health metrics breakdown
struct RecoveryDetailView: View {
    let recoveryScore: RecoveryScore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Large recovery ring
                    RecoveryHeaderSection(recoveryScore: recoveryScore)
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                    
                    // Sub-scores breakdown
                    subScoresSection
                    
                    // Apple Health metrics
                    healthMetricsSection
                }
                .padding()
            }
        .navigationTitle(RecoveryContent.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Weekly Trend Section (Pro)
    
    private var weeklyTrendSection: some View {
        ProFeatureGate(
            featureName: RecoveryContent.weeklyTrendFeature,
            featureDescription: RecoveryContent.weeklyTrendDescription,
            isEnabled: proConfig.canViewWeeklyTrends
        ) {
            TrendChart(
                title: RecoveryContent.trendTitle,
                getData: { period in getHistoricalRecoveryData(for: period) },
                chartType: .bar,
                unit: "%",
                showProBadge: true
            )
        }
    }
    
    // MARK: - Sub-Scores Section
    
    private var subScoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(RecoveryContent.factorsTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                subScoreRow(
                    title: RecoveryContent.Metrics.hrv,
                    score: recoveryScore.subScores.hrv,
                    weight: RecoveryContent.Weights.hrvWeight,
                    icon: "heart.fill",
                    color: ColorScale.greenAccent,
                    hasBaseline: recoveryScore.inputs.hrvBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.rhr,
                    score: recoveryScore.subScores.rhr,
                    weight: RecoveryContent.Weights.rhrWeight,
                    icon: "heart.circle.fill",
                    color: .red,
                    hasBaseline: recoveryScore.inputs.rhrBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.sleep,
                    score: recoveryScore.subScores.sleep,
                    weight: RecoveryContent.Weights.sleepWeight,
                    icon: "moon.fill",
                    color: .blue,
                    hasBaseline: recoveryScore.inputs.sleepBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.load,
                    score: recoveryScore.subScores.form,
                    weight: RecoveryContent.Weights.loadWeight,
                    icon: "bicycle",
                    color: .orange,
                    hasBaseline: true
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func subScoreRow(title: String, score: Int, weight: String, icon: String, color: Color, hasBaseline: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if hasBaseline {
                    Text("Weight: \(weight)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Weight: \(weight) • Calculating baseline...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(score)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(hasBaseline ? colorForScore(score) : .secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apple Health Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let hrv = recoveryScore.inputs.hrv {
                    if let hrvBaseline = recoveryScore.inputs.hrvBaseline {
                        healthMetricRow(
                            title: "HRV (RMSSD)",
                            current: String(format: "%.1f ms", hrv),
                            baseline: String(format: "%.1f ms", hrvBaseline),
                            change: calculatePercentageChange(current: hrv, baseline: hrvBaseline),
                            icon: "heart.fill",
                            color: ColorScale.greenAccent
                        )
                    } else {
                        healthMetricRowWithoutBaseline(
                            title: "HRV (RMSSD)",
                            current: String(format: "%.1f ms", hrv),
                            icon: "heart.fill",
                            color: ColorScale.greenAccent
                        )
                    }
                }
                
                if let rhr = recoveryScore.inputs.rhr {
                    if let rhrBaseline = recoveryScore.inputs.rhrBaseline {
                        healthMetricRow(
                            title: "Resting Heart Rate",
                            current: String(format: "%.0f bpm", rhr),
                            baseline: String(format: "%.0f bpm", rhrBaseline),
                            change: calculatePercentageChange(current: rhr, baseline: rhrBaseline),
                            icon: "heart.circle.fill",
                            color: .red
                        )
                    } else {
                        healthMetricRowWithoutBaseline(
                            title: "Resting Heart Rate",
                            current: String(format: "%.0f bpm", rhr),
                            icon: "heart.circle.fill",
                            color: .red
                        )
                    }
                }
                
                if let sleep = recoveryScore.inputs.sleepDuration, let sleepBaseline = recoveryScore.inputs.sleepBaseline {
                    healthMetricRow(
                        title: "Sleep Duration",
                        current: formatDuration(sleep),
                        baseline: formatDuration(sleepBaseline),
                        change: calculatePercentageChange(current: sleep, baseline: sleepBaseline),
                        icon: "moon.fill",
                        color: .blue
                    )
                }
                
                if let atl = recoveryScore.inputs.atl, let ctl = recoveryScore.inputs.ctl {
                    trainingLoadRow(atl: atl, ctl: ctl)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func healthMetricRow(title: String, current: String, baseline: String, change: Double, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Current: \(current)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("• Baseline: \(baseline)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(format: "%+.0f%%", change))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(change >= 0 ? Color.semantic.success : Color.semantic.error)
        }
        .padding(.vertical, 4)
    }
    
    private func healthMetricRowWithoutBaseline(title: String, current: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Current: \(current)")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text("Baseline will be available after 7 days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
            
            Text(current)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
    
    private func trainingLoadRow(atl: Double, ctl: Double) -> some View {
        HStack {
            Image(systemName: "bicycle")
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Training Load Ratio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("ATL: \(String(format: "%.0f", atl)) • CTL: \(String(format: "%.0f", ctl))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let ratio = atl / ctl
            Text(String(format: "%.2f", ratio))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ratio < 1.0 ? Color.semantic.success : ratio < 1.5 ? Color.semantic.warning : Color.semantic.error)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Functions
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        switch band {
        case .green: return .green
        case .amber: return .orange
        case .red: return .red
        }
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 70...100: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }
    
    private func calculatePercentageChange(current: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return ((current - baseline) / baseline) * 100
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Mock Data Generator
    
    private func getHistoricalRecoveryData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Check if mock data is enabled for testing
        #if DEBUG
        if ProFeatureConfig.shared.showMockDataForTesting {
            return generateMockRecoveryData(for: period)
        }
        #endif
        
        // TODO: Implement real historical data tracking
        // For now, return empty to show "Not enough data" message
        // Historical tracking will be added in a future update
        return []
        
        // When historical tracking is implemented, this will fetch from UserDefaults/CoreData:
        // return RecoveryScoreService.shared.getLastNDays(period.days)
    }
    
    private func generateMockRecoveryData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Generate realistic mock recovery data (oldest to newest)
        return (0..<period.days).map { dayIndex in
            let daysAgo = period.days - 1 - dayIndex
            return TrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                value: Double.random(in: 60...85)
            )
        }
    }
}

// MARK: - Preview

struct RecoveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockInputs = RecoveryScore.RecoveryInputs(
            hrv: 45.2,
            overnightHrv: 35.8, // Lower overnight HRV for alcohol detection demo
            hrvBaseline: 42.8,
            rhr: 58.0,
            rhrBaseline: 61.2,
            sleepDuration: 28800, // 8 hours
            sleepBaseline: 25200,  // 7 hours
            respiratoryRate: nil,
            respiratoryBaseline: nil,
            atl: 80.0,
            ctl: 100.0,
            recentStrain: nil,
            sleepScore: nil
        )
        
        let mockScore = RecoveryScoreCalculator.calculate(inputs: mockInputs)
        
        RecoveryDetailView(recoveryScore: mockScore)
    }
}
