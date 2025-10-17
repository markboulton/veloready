import SwiftUI
import HealthKit

/// Detailed recovery view with large graph and Apple Health metrics breakdown
struct RecoveryDetailView: View {
    let recoveryScore: RecoveryScore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // Large recovery ring
                    RecoveryHeaderSection(recoveryScore: recoveryScore)
                        .padding()
                    
                    SectionDivider()
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sub-scores breakdown
                    subScoresSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Recovery Debt
                    recoveryDebtSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Readiness Score
                    readinessSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Resilience Score
                    resilienceSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Apple Health metrics
                    healthMetricsSection
                        .padding()
                }
            }
        .refreshable {
            await RecoveryScoreService.shared.forceRefreshRecoveryScore()
        }
        .navigationTitle(RecoveryContent.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Weekly Trend Section (Pro)
    
    private var weeklyTrendSection: some View {
        ProFeatureGate(
            upgradeContent: .weeklyRecoveryTrend,
            isEnabled: proConfig.canViewWeeklyTrends,
            showBenefits: true
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
                    color: ColorScale.redAccent,
                    hasBaseline: recoveryScore.inputs.rhrBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.sleep,
                    score: recoveryScore.subScores.sleep,
                    weight: RecoveryContent.Weights.sleepWeight,
                    icon: "moon.fill",
                    color: recoveryScore.inputs.sleepScore?.band.colorToken ?? ColorScale.yellowAccent,
                    hasBaseline: recoveryScore.inputs.sleepBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.load,
                    score: recoveryScore.subScores.form,
                    weight: RecoveryContent.Weights.loadWeight,
                    icon: "bicycle",
                    color: ColorScale.amberAccent,
                    hasBaseline: true
                )
            }
        }
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
                            color: ColorScale.redAccent
                        )
                    } else {
                        healthMetricRowWithoutBaseline(
                            title: "Resting Heart Rate",
                            current: String(format: "%.0f bpm", rhr),
                            icon: "heart.circle.fill",
                            color: ColorScale.redAccent
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
        case .optimal: return ColorScale.greenAccent
        case .good: return ColorScale.yellowAccent
        case .fair: return ColorScale.amberAccent
        case .payAttention: return ColorScale.redAccent
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
        
        // Fetch real data from Core Data
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate) else {
            return []
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND recoveryScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest) else {
            return []
        }
        
        return results.compactMap { dailyScore in
            guard let date = dailyScore.date else { return nil }
            return TrendDataPoint(
                date: date,
                value: dailyScore.recoveryScore
            )
        }
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
    
    // MARK: - New Metrics Sections
    
    @ViewBuilder
    private var recoveryDebtSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(RecoveryContent.NewMetrics.recoveryDebt)
                .font(.headline)
                .fontWeight(.semibold)
            
            if let debt = RecoveryScoreService.shared.currentRecoveryDebt {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.title2)
                        .foregroundColor(debt.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(debt.band.colorToken)
                        
                        Text("\(debt.consecutiveDays) consecutive days below 60")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(debt.consecutiveDays)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(debt.band.colorToken)
                }
                
                Text(debt.band.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(debt.band.recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            } else {
                // Check data availability
                dataAvailabilityMessage(
                    requiredDays: 7,
                    metricName: "Recovery Debt",
                    description: "Tracks consecutive days of suboptimal recovery to prevent overtraining"
                )
            }
        }
    }
    
    @ViewBuilder
    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ReadinessContent.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            if let readiness = RecoveryScoreService.shared.currentReadinessScore {
                
                HStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(readiness.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(readiness.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(readiness.band.colorToken)
                        
                        Text("Recovery \(readiness.components.recoveryScore) • Sleep \(readiness.components.sleepScore) • Load \(readiness.components.loadReadiness)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(readiness.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(readiness.band.colorToken)
                }
                
                Text(readiness.band.trainingRecommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(readiness.band.intensityGuidance)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                dataAvailabilityMessage(
                    requiredDays: 1,
                    metricName: "Readiness",
                    description: "Combines recovery, sleep, and training load for actionable training guidance"
                )
            }
        }
    }
    
    @ViewBuilder
    private var resilienceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(RecoveryContent.NewMetrics.resilience)
                .font(.headline)
                .fontWeight(.semibold)
            
            if let resilience = RecoveryScoreService.shared.currentResilienceScore {
                
                HStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundColor(resilience.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resilience.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(resilience.band.colorToken)
                        
                        Text("30-day recovery capacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(resilience.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(resilience.band.colorToken)
                }
                
                Text(resilience.band.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Avg Recovery: \(String(format: "%.0f", resilience.averageRecovery)) • Avg Load: \(String(format: "%.1f", resilience.averageLoad))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Text(resilience.band.recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            } else {
                dataAvailabilityMessage(
                    requiredDays: 30,
                    metricName: "Resilience",
                    description: "Analyzes your recovery capacity relative to training load over 30 days"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func dataAvailabilityMessage(requiredDays: Int, metricName: String, description: String) -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -requiredDays, to: endDate) else {
            return AnyView(EmptyView())
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND recoveryScore > 0", startDate as NSDate, endDate as NSDate)
        
        let availableDays = (try? context.count(for: fetchRequest)) ?? 0
        let daysRemaining = max(0, requiredDays - availableDays)
        
        // If we have enough data, show a refresh message instead
        if availableDays >= requiredDays {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                        
                        Text("Pull to refresh")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("You have \(availableDays) days of data. \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    
                    Text("Check back in \(daysRemaining) \(daysRemaining == 1 ? "day" : "days")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(availableDays) of \(requiredDays) days")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ColorScale.blueAccent)
                                .frame(width: geometry.size.width * min(CGFloat(availableDays) / CGFloat(requiredDays), 1.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.top, 4)
            }
        )
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
