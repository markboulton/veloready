import SwiftUI
import HealthKit

/// Detailed view showing sleep score breakdown and analysis
/// Uses MVVM pattern with SleepDetailViewModel for data fetching
struct SleepDetailView: View {
    let sleepScore: SleepScore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SleepDetailViewModel()
    @ObservedObject var proConfig = ProFeatureConfig.shared
    @State private var sleepSamples: [SleepHypnogramChart.SleepStageSample] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background (light grey in light mode, black in dark mode)
            Color.background.app
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Header with main score
                    SleepHeaderSection(sleepScore: sleepScore)
                        .padding(.top, 60)
                    
                    // Missing data warning if no sleep duration
                    if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
                        missingSleepDataWarning
                    }
                    
                    // Health warnings card
                    HealthWarningsCardV2()
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                    
                    // Score breakdown
                    scoreBreakdownSection
                    
                    // Sleep hypnogram
                    hypnogramSection
                    
                    // Sleep metrics
                    sleepMetricsSection
                    
                    // Sleep stages
                    sleepStagesSection
                    
                    // Sleep Debt
                    sleepDebtSection
                    
                    // Sleep Consistency
                    sleepConsistencySection
                    
                    // Recommendations
                    recommendationsSection
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
        .navigationTitle(SleepContent.title)
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveToolbarBackground(.hidden, for: .navigationBar)
        .adaptiveToolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - View Sections
    
    private var missingSleepDataWarning: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(ColorPalette.neutral200)
                    .frame(width: 40, height: 40)
                Image(systemName: Icons.Health.sleepZzz)
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(SleepContent.Warnings.noSleepDataTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(SleepContent.Warnings.noSleepDataMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var weeklyTrendSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklySleepTrend,
                isEnabled: proConfig.canViewWeeklyTrends,
                showBenefits: true
            ) {
                TrendChart(
                    title: SleepContent.trendTitle,
                    getData: { period in viewModel.getHistoricalSleepData(for: period) },
                    chartType: .bar,
                    unit: "%",
                    showProBadge: false,
                    dataType: .sleep
                )
            }
        }
    }
    
    
    private var scoreBreakdownSection: some View {
        StandardCard(
            title: SleepContent.breakdownTitle
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    ScoreBreakdownRow(
                        title: SleepContent.Components.performance,
                        score: sleepScore.subScores.performance,
                        weight: SleepContent.Weights.performance,
                        description: SleepContent.ComponentDescriptions.performance
                    )
                    
                    ScoreBreakdownRow(
                        title: SleepContent.Components.efficiency,
                        score: sleepScore.subScores.efficiency,
                        weight: SleepContent.Weights.efficiency,
                        description: SleepContent.ComponentDescriptions.efficiency
                    )
                    
                    ScoreBreakdownRow(
                        title: SleepContent.Components.stageQuality,
                        score: sleepScore.subScores.stageQuality,
                        weight: SleepContent.Weights.stageQuality,
                        description: SleepContent.ComponentDescriptions.stageQuality
                    )
                    
                    ScoreBreakdownRow(
                        title: SleepContent.Components.disturbances,
                        score: sleepScore.subScores.disturbances,
                        weight: SleepContent.Weights.disturbances,
                        description: SleepContent.ComponentDescriptions.disturbances
                    )
                    
                    ScoreBreakdownRow(
                        title: SleepContent.Components.timing,
                        score: sleepScore.subScores.timing,
                        weight: SleepContent.Weights.timing,
                        description: SleepContent.ComponentDescriptions.timing
                    )
                    
                }
            }
        }
    }
    
    private var hypnogramSection: some View {
        StandardCard(
            title: SleepContent.hypnogramTitle
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if !sleepSamples.isEmpty,
                   let bedtime = sleepScore.inputs.bedtime,
                   let wakeTime = sleepScore.inputs.wakeTime {
                    SleepHypnogramChart(
                        sleepSamples: sleepSamples,
                        nightStart: bedtime,
                        nightEnd: wakeTime
                    )
                } else {
                    Text(SleepContent.Warnings.noDetailedData)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
        .task {
            await loadSleepSamples()
        }
    }
    
    private func loadSleepSamples() async {
        // Fetch sleep samples from HealthKit for hypnogram
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        // Get last night's sleep period
        let calendar = Calendar.current
        let now = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let startOfYesterday = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday),
              let endOfToday = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: endOfToday, options: .strictStartDate)
        
        let samples = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, results, _ in
                let hkSamples = results as? [HKCategorySample] ?? []
                let hypnogramSamples = hkSamples.compactMap { SleepHypnogramChart.SleepStageSample(from: $0) }
                continuation.resume(returning: hypnogramSamples)
            }
            HKHealthStore().execute(query)
        }
        
        sleepSamples = samples
    }
    
    private var sleepMetricsSection: some View {
        StandardCard(
            title: SleepContent.metricsTitle
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.lg) {
                    SleepMetricCard(
                        title: SleepContent.Metrics.duration,
                        value: sleepScore.formattedSleepDuration,
                        icon: Icons.Health.sleepFill,
                        color: ColorScale.sleepCore
                    )
                    
                    SleepMetricCard(
                        title: SleepContent.Metrics.sleepNeed,
                        value: sleepScore.formattedSleepNeed,
                        icon: Icons.System.target,
                        color: ColorScale.sleepDeep
                    )
                    
                    SleepMetricCard(
                        title: SleepContent.Metrics.efficiency,
                        value: sleepScore.formattedSleepEfficiency,
                        icon: Icons.System.percent,
                        color: ColorScale.sleepREM
                    )
                    
                    SleepMetricCard(
                        title: SleepContent.Metrics.wakeEvents,
                        value: sleepScore.formattedWakeEvents,
                        icon: Icons.Status.warningFill,
                        color: .red  // Keep red as RAG status indicator
                    )
                    
                    SleepMetricCard(
                        title: SleepContent.Metrics.deepSleep,
                        value: sleepScore.formattedDeepSleepPercentage,
                        icon: Icons.Health.heartRate,
                        color: ColorScale.sleepDeep
                    )
                }
            }
        }
    }
    
    private var sleepStagesSection: some View {
        StandardCard(
            title: SleepContent.stagesTitle
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let sleepDuration = sleepScore.inputs.sleepDuration, sleepDuration > 0 {
                    VStack(spacing: Spacing.md) {
                        if let deepDuration = sleepScore.inputs.deepSleepDuration {
                            SleepStageRow(
                                title: SleepContent.Stages.deep,
                                duration: deepDuration,
                                totalDuration: sleepDuration,
                                color: ColorScale.sleepDeep
                            )
                        }
                        
                        if let remDuration = sleepScore.inputs.remSleepDuration {
                            SleepStageRow(
                                title: SleepContent.Stages.rem,
                                duration: remDuration,
                                totalDuration: sleepDuration,
                                color: ColorScale.sleepREM
                            )
                        }
                        
                        if let coreDuration = sleepScore.inputs.coreSleepDuration {
                            SleepStageRow(
                                title: SleepContent.Stages.core,
                                duration: coreDuration,
                                totalDuration: sleepDuration,
                                color: ColorScale.sleepCore
                            )
                        }
                        
                        if let awakeDuration = sleepScore.inputs.awakeDuration {
                            SleepStageRow(
                                title: SleepContent.Stages.awake,
                                duration: awakeDuration,
                                totalDuration: sleepDuration,
                                color: ColorScale.sleepAwake
                            )
                        }
                    }
                } else {
                    Text(SleepContent.Warnings.noStageData)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        StandardCard(
            title: SleepContent.recommendationsTitle
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(generateRecommendations(), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Image(systemName: Icons.System.lightbulb)
                                .foregroundColor(ColorScale.sleepAwake)
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
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Performance recommendations
        if sleepScore.subScores.performance < 70 {
            recommendations.append("\(SleepContent.Recommendations.targetSleep) \(sleepScore.formattedSleepNeed)")
        }
        
        // Efficiency recommendations
        if sleepScore.subScores.efficiency < 70 {
            recommendations.append(SleepContent.Recommendations.improveEfficiency)
        }
        
        // Stage quality recommendations
        if sleepScore.subScores.stageQuality < 70 {
            recommendations.append(SleepContent.Recommendations.focusOnStages)
        }
        
        // Disturbance recommendations
        if sleepScore.subScores.disturbances < 70 {
            recommendations.append(SleepContent.Recommendations.reduceDisturbances)
        }
        
        // Timing recommendations
        if sleepScore.subScores.timing < 70 {
            recommendations.append(SleepContent.Recommendations.consistentTiming)
        }
        
        // Default recommendation if all scores are good
        if recommendations.isEmpty {
            recommendations.append(SleepContent.Recommendations.goodQuality)
        }
        
        return recommendations
    }
    
    // MARK: - Data Fetching
    // All data fetching logic moved to SleepDetailViewModel
    
    // MARK: - New Metrics Sections
    
    @ViewBuilder
    private var sleepDebtSection: some View {
        StandardCard(
            title: SleepContent.NewMetrics.sleepDebt
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let debt = SleepScoreService.shared.currentSleepDebt {
                HStack(spacing: Spacing.md) {
                    Image(systemName: Icons.Health.sleepZzzFill)
                        .font(.title2)
                        .foregroundColor(debt.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(debt.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(debt.band.colorToken)
                        
                        Text(SleepContent.SleepDebt.cumulativeDeficit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.1fh", debt.totalDebtHours))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(debt.band.colorToken)
                }
                
                Text(debt.band.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(SleepContent.SleepDebt.avgSleep) \(String(format: "%.1fh", debt.averageSleepDuration)) \(CommonContent.Formatting.bulletPoint) \(SleepContent.SleepDebt.need) \(String(format: "%.1fh", debt.sleepNeed))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Text(debt.band.recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                
                // Simple 7-day trend chart
                sleepDebtTrendChart()
                    .padding(.top, 12)
            } else {
                    sleepDataAvailabilityMessage(
                        requiredDays: 7,
                        metricName: SleepContent.NewMetrics.sleepDebt,
                        description: SleepContent.DataAvailability.sleepDebtDescription
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var sleepConsistencySection: some View {
        StandardCard(
            title: SleepContent.NewMetrics.consistency
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let consistency = SleepScoreService.shared.currentSleepConsistency {
                HStack(spacing: Spacing.md) {
                    Image(systemName: Icons.System.clock)
                        .font(.title2)
                        .foregroundColor(consistency.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(consistency.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(consistency.band.colorToken)
                        
                        Text(SleepContent.Consistency.circadianHealth)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(consistency.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(consistency.band.colorToken)
                }
                
                Text(consistency.band.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(SleepContent.Consistency.scheduleVariability) ±\(Int(consistency.bedtimeVariability))min \(CommonContent.Formatting.bulletPoint) \(SleepContent.Consistency.wake) ±\(Int(consistency.wakeTimeVariability))min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Text(consistency.band.recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                
                // Simple 7-day consistency chart
                sleepConsistencyTrendChart()
                    .padding(.top, 12)
            } else {
                    sleepDataAvailabilityMessage(
                        requiredDays: 7,
                        metricName: SleepContent.NewMetrics.consistency,
                        description: SleepContent.DataAvailability.consistencyDescription
                    )
                }
            }
        }
    }
    
    // MARK: - Chart Views
    
    @ViewBuilder
    private func sleepDebtTrendChart() -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        if let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) {
            let fetchRequest = DailyScores.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            if let results = try? context.fetch(fetchRequest), !results.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(SleepContent.SleepDebt.trendTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: Spacing.xs) {
                            ForEach(Array(results.enumerated()), id: \.offset) { index, dailyScore in
                                let score = dailyScore.sleepScore
                                let height = max(4, (score / 100.0) * geometry.size.height)
                                let color: Color = score >= 80 ? ColorScale.greenAccent : score >= 60 ? ColorScale.yellowAccent : ColorScale.amberAccent

                                VStack(spacing: Spacing.xs / 2) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color)
                                        .frame(height: height)

                                    if let date = dailyScore.date {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 60)

                    HStack {
                        Circle()
                            .fill(ColorScale.greenAccent)
                            .frame(width: 6, height: 6)
                        Text(SleepContent.SleepDebt.optimal)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer().frame(width: 8)

                        Circle()
                            .fill(ColorScale.yellowAccent)
                            .frame(width: 6, height: 6)
                        Text(SleepContent.SleepDebt.good)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer().frame(width: 8)

                        Circle()
                            .fill(ColorScale.amberAccent)
                            .frame(width: 6, height: 6)
                        Text(SleepContent.SleepDebt.fair)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepConsistencyTrendChart() -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        if let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) {
            let fetchRequest = DailyScores.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            if let results = try? context.fetch(fetchRequest), !results.isEmpty {
                // Use sleep scores as a proxy for consistency
                let scores = results.compactMap { $0.sleepScore }

                if !scores.isEmpty {
                    let avgScore = scores.reduce(0, +) / Double(scores.count)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(SleepContent.Consistency.patternTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Average line
                                Rectangle()
                                    .fill(ColorScale.purpleAccent.opacity(0.2))
                                    .frame(height: 1)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                                // Data points
                                ForEach(Array(results.enumerated()), id: \.offset) { index, dailyScore in
                                    let xPos = (CGFloat(index) / CGFloat(max(1, results.count - 1))) * geometry.size.width
                                    let deviation = (dailyScore.sleepScore - avgScore) / 100.0
                                    let yPos = geometry.size.height / 2 - (CGFloat(deviation) * geometry.size.height * 0.8)

                                    Circle()
                                        .fill(ColorScale.purpleAccent)
                                        .frame(width: 8, height: 8)
                                        .position(x: xPos, y: min(max(yPos, 4), geometry.size.height - 4))
                                }
                            }
                        }
                        .frame(height: 60)

                        Text(SleepContent.Consistency.deviationNote)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func sleepDataAvailabilityMessage(requiredDays: Int, metricName: String, description: String) -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())

        if let startDate = calendar.date(byAdding: .day, value: -requiredDays, to: endDate) {
            let fetchRequest = DailyScores.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)

            let availableDays = (try? context.count(for: fetchRequest)) ?? 0
            let daysRemaining = max(0, requiredDays - availableDays)

            // If we have enough data, show a refresh message instead
            if availableDays >= requiredDays {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Arrow.clockwise)
                            .foregroundColor(.secondary)

                        Text(SleepContent.DataAvailability.pullToRefresh)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text("\(SleepContent.DataAvailability.youHave) \(availableDays) \(SleepContent.DataAvailability.daysOfData) \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.System.clock)
                            .foregroundColor(.secondary)

                        Text("\(SleepContent.DataAvailability.checkBackIn) \(daysRemaining) \(daysRemaining == 1 ? SleepContent.DataAvailability.day : SleepContent.DataAvailability.days)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.xs) {
                        Text("\(availableDays) \(SleepContent.DataAvailability.of) \(requiredDays) \(SleepContent.DataAvailability.days)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ColorPalette.neutral200)
                                    .frame(height: 2)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ColorScale.purpleAccent)
                                    .frame(width: geometry.size.width * min(CGFloat(availableDays) / CGFloat(requiredDays), 1.0), height: 2)
                            }
                        }
                        .frame(height: 2)
                    }
                    .padding(.top, 4)
                }
            }
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
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
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
        case 80...100: return ColorScale.greenAccent
        case 60..<80: return ColorScale.blueAccent
        case 40..<60: return ColorScale.amberAccent
        default: return ColorScale.redAccent
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
        .background(Color.background.card)
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
            band: .optimal,
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
                hrvBaseline: 42.0,
                sleepLatency: 900 // 15 minutes
            ),
            calculatedAt: Date()
        )
        
        SleepDetailView(sleepScore: mockSleepScore)
    }
}
