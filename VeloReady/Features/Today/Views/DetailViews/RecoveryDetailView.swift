import SwiftUI
import HealthKit

/// Detailed recovery view with large graph and Apple Health metrics breakdown
/// Uses MVVM pattern with RecoveryDetailViewModel for data fetching
struct RecoveryDetailView: View {
    let recoveryScore: RecoveryScore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecoveryDetailViewModel()
    @ObservedObject var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background (light grey in light mode, black in dark mode)
            Color.background.app
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Large recovery ring
                    RecoveryHeaderSection(recoveryScore: recoveryScore)
                        .padding(.top, 60)
                    
                    // Health warnings card
                    HealthWarningsCardV2()
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                    
                    // HRV Line Chart (Pro)
                    hrvLineSection
                    
                    // RHR Candlestick Chart (Pro)
                    rhrCandlestickSection
                    
                    // Sub-scores breakdown
                    subScoresSection
                    
                    // Recovery Debt
                    recoveryDebtSection
                    
                    // Readiness Score
                    readinessSection
                    
                    // Resilience Score
                    resilienceSection
                    
                    // Apple Health metrics
                    healthMetricsSection
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 120)
            }
            .refreshable {
                await viewModel.refreshData()
            }
            
            // Navigation gradient mask
            NavigationGradientMask()
        }
        .navigationTitle(RecoveryContent.title)
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
    
    // MARK: - Weekly Trend Section (Pro)
    
    private var weeklyTrendSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklyRecoveryTrend,
                isEnabled: proConfig.canViewWeeklyTrends,
                showBenefits: true
            ) {
                TrendChart(
                    title: RecoveryContent.trendTitle,
                    getData: { period in viewModel.getHistoricalRecoveryData(for: period) },
                    chartType: .bar,
                    unit: "%",
                    showProBadge: true
                )
            }
        }
        .padding(.horizontal, -Spacing.xl)
    }
    
    // MARK: - HRV Line Section (Pro)
    
    private var hrvLineSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklyRecoveryTrend,
                isEnabled: proConfig.canViewWeeklyTrends,
                showBenefits: true
            ) {
                HRVCandlestickChart(
                    getData: { period in viewModel.getHistoricalHRVCandlestickData(for: period) },
                    baseline: recoveryScore.inputs.hrvBaseline
                )
            }
        }
    }
    
    // MARK: - RHR Candlestick Section (Pro)
    
    private var rhrCandlestickSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklyRecoveryTrend,
                isEnabled: proConfig.canViewWeeklyTrends,
                showBenefits: true
            ) {
                RHRCandlestickChart(
                    getData: { period in viewModel.getHistoricalRHRData(for: period) },
                    baseline: recoveryScore.inputs.rhrBaseline
                )
            }
        }
    }
    
    // MARK: - Sub-Scores Section
    
    private var subScoresSection: some View {
        StandardCard(
            title: RecoveryContent.factorsTitle
        ) {
            VStack(spacing: 12) {
                subScoreRow(
                    title: RecoveryContent.Metrics.hrv,
                    score: recoveryScore.subScores.hrv,
                    weight: RecoveryContent.Weights.hrvWeight,
                    icon: Icons.Health.heartFill,
                    hasBaseline: recoveryScore.inputs.hrvBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.rhr,
                    score: recoveryScore.subScores.rhr,
                    weight: RecoveryContent.Weights.rhrWeight,
                    icon: Icons.Health.heartCircle,
                    hasBaseline: recoveryScore.inputs.rhrBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.sleep,
                    score: recoveryScore.subScores.sleep,
                    weight: RecoveryContent.Weights.sleepWeight,
                    icon: Icons.Health.sleepFill,
                    hasBaseline: recoveryScore.inputs.sleepBaseline != nil
                )
                
                subScoreRow(
                    title: RecoveryContent.Metrics.load,
                    score: recoveryScore.subScores.form,
                    weight: RecoveryContent.Weights.loadWeight,
                    icon: Icons.Activity.cycling,
                    hasBaseline: true
                )
            }
        }
    }
    
    private func subScoreRow(title: String, score: Int, weight: String, icon: String, hasBaseline: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if hasBaseline {
                    Text("\(RecoveryContent.HealthMetrics.weight) \(weight)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(RecoveryContent.HealthMetrics.weight) \(weight) \(CommonContent.Formatting.bulletPoint) \(RecoveryContent.HealthMetrics.calculatingBaseline)")
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
        StandardCard(
            title: RecoveryContent.appleHealthTitle
        ) {
            VStack(spacing: 12) {
                if let hrv = recoveryScore.inputs.hrv {
                    if let hrvBaseline = recoveryScore.inputs.hrvBaseline {
                        healthMetricRow(
                            title: RecoveryContent.HealthMetrics.hrvRMSSD,
                            current: String(format: "%.1f ms", hrv),
                            baseline: String(format: "%.1f ms", hrvBaseline),
                            change: calculatePercentageChange(current: hrv, baseline: hrvBaseline),
                            icon: Icons.Health.heartFill
                        )
                    } else {
                        healthMetricRowWithoutBaseline(
                            title: RecoveryContent.HealthMetrics.hrvRMSSD,
                            current: String(format: "%.1f ms", hrv),
                            icon: Icons.Health.heartFill
                        )
                    }
                }
                
                if let rhr = recoveryScore.inputs.rhr {
                    if let rhrBaseline = recoveryScore.inputs.rhrBaseline {
                        healthMetricRow(
                            title: RecoveryContent.HealthMetrics.restingHeartRate,
                            current: String(format: "%.0f \(CommonContent.Units.bpm)", rhr),
                            baseline: String(format: "%.0f \(CommonContent.Units.bpm)", rhrBaseline),
                            change: calculatePercentageChange(current: rhr, baseline: rhrBaseline),
                            icon: Icons.Health.heartCircle
                        )
                    } else {
                        healthMetricRowWithoutBaseline(
                            title: RecoveryContent.HealthMetrics.restingHeartRate,
                            current: String(format: "%.0f \(CommonContent.Units.bpm)", rhr),
                            icon: Icons.Health.heartCircle
                        )
                    }
                }
                
                if let sleep = recoveryScore.inputs.sleepDuration, let sleepBaseline = recoveryScore.inputs.sleepBaseline {
                    healthMetricRow(
                        title: RecoveryContent.HealthMetrics.sleepDuration,
                        current: formatDuration(sleep),
                        baseline: formatDuration(sleepBaseline),
                        change: calculatePercentageChange(current: sleep, baseline: sleepBaseline),
                        icon: Icons.Health.sleepFill
                    )
                }
                
                if let atl = recoveryScore.inputs.atl, let ctl = recoveryScore.inputs.ctl {
                    trainingLoadRow(atl: atl, ctl: ctl)
                }
            }
        }
    }
    
    private func healthMetricRow(title: String, current: String, baseline: String, change: Double, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(RecoveryContent.HealthMetrics.current) \(current)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("\(CommonContent.Formatting.bulletPoint) \(RecoveryContent.HealthMetrics.baseline) \(baseline)")
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
    
    private func healthMetricRowWithoutBaseline(title: String, current: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(RecoveryContent.HealthMetrics.current) \(current)")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(RecoveryContent.HealthMetrics.baselineAvailable)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
            
            Text(current)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.text.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func trainingLoadRow(atl: Double, ctl: Double) -> some View {
        HStack {
            Image(systemName: Icons.Activity.cycling)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(RecoveryContent.HealthMetrics.trainingLoadRatio)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("ATL: \(String(format: "%.0f", atl)) \(CommonContent.Formatting.bulletPoint) CTL: \(String(format: "%.0f", ctl))")
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
        case 80...100: return ColorScale.greenAccent
        case 60..<80: return ColorScale.blueAccent
        case 40..<60: return ColorScale.amberAccent
        default: return ColorScale.redAccent
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
    
    // MARK: - Data Fetching
    // All data fetching logic moved to RecoveryDetailViewModel
    
    // MARK: - New Metrics Sections
    
    @ViewBuilder
    private var recoveryDebtSection: some View {
        StandardCard(
            title: RecoveryContent.NewMetrics.recoveryDebt
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let debt = RecoveryScoreService.shared.currentRecoveryDebt {
                HStack(spacing: 12) {
                    Image(systemName: Icons.Health.boltHeart)
                        .font(.title2)
                        .foregroundColor(debt.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(debt.band.colorToken)
                        
                        Text("\(debt.consecutiveDays) \(RecoveryContent.RecoveryDebt.consecutiveDays)")
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
                    metricName: RecoveryContent.NewMetrics.recoveryDebt,
                    description: RecoveryContent.RecoveryDebt.description
                )
            }
            }
        }
    }
    
    @ViewBuilder
    private var readinessSection: some View {
        StandardCard(
            title: ReadinessContent.title
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let readiness = RecoveryScoreService.shared.currentReadinessScore {
                
                HStack(spacing: 12) {
                    Image(systemName: Icons.Activity.running)
                        .font(.title2)
                        .foregroundColor(readiness.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(readiness.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(readiness.band.colorToken)
                        
                        Text("\(RecoveryContent.Readiness.recovery) \(readiness.components.recoveryScore) \(CommonContent.Formatting.bulletPoint) \(RecoveryContent.Readiness.sleep) \(readiness.components.sleepScore) \(CommonContent.Formatting.bulletPoint) \(RecoveryContent.Readiness.load) \(readiness.components.loadReadiness)")
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
                    metricName: ReadinessContent.title,
                    description: RecoveryContent.Readiness.description
                )
            }
            }
        }
    }
    
    @ViewBuilder
    private var resilienceSection: some View {
        StandardCard(
            title: RecoveryContent.NewMetrics.resilience
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let resilience = RecoveryScoreService.shared.currentResilienceScore {
                
                HStack(spacing: 12) {
                    Image(systemName: Icons.Activity.strength)
                        .font(.title2)
                        .foregroundColor(resilience.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resilience.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(resilience.band.colorToken)
                        
                        Text(RecoveryContent.Resilience.capacityLabel)
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
                
                Text("\(RecoveryContent.Resilience.avgRecovery) \(String(format: "%.0f", resilience.averageRecovery)) \(CommonContent.Formatting.bulletPoint) \(RecoveryContent.Resilience.avgLoad) \(String(format: "%.1f", resilience.averageLoad))")
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
                    metricName: RecoveryContent.NewMetrics.resilience,
                    description: RecoveryContent.Resilience.description
                )
            }
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
                        Image(systemName: Icons.Arrow.clockwise)
                            .foregroundColor(.secondary)
                        
                        Text(RecoveryContent.DataAvailability.pullToRefresh)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(RecoveryContent.DataAvailability.youHave) \(availableDays) \(RecoveryContent.DataAvailability.daysOfData) \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: Icons.System.clock)
                        .foregroundColor(.secondary)
                    
                    Text("\(RecoveryContent.DataAvailability.checkBackIn) \(daysRemaining) \(daysRemaining == 1 ? RecoveryContent.DataAvailability.day : RecoveryContent.DataAvailability.days)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(availableDays) \(RecoveryContent.DataAvailability.of) \(requiredDays) \(RecoveryContent.DataAvailability.days)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ColorPalette.neutral200)
                                .frame(height: 2)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ColorScale.blueAccent)
                                .frame(width: geometry.size.width * min(CGFloat(availableDays) / CGFloat(requiredDays), 1.0), height: 2)
                        }
                    }
                    .frame(height: 2)
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
