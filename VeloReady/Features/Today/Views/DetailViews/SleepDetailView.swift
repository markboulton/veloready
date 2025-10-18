import SwiftUI
import HealthKit

/// Detailed view showing sleep score breakdown and analysis
struct SleepDetailView: View {
    let sleepScore: SleepScore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proConfig = ProFeatureConfig.shared
    @State private var sleepSamples: [SleepHypnogramChart.SleepStageSample] = []
    
    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // Header with main score
                    SleepHeaderSection(sleepScore: sleepScore)
                        .padding()
                    
                    // Missing data warning if no sleep duration
                    if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
                        missingSleepDataWarning
                            .padding()
                    }
                    
                    SectionDivider()
                    
                    // Weekly Trend (Pro)
                    weeklyTrendSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Score breakdown
                    scoreBreakdownSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sleep hypnogram
                    hypnogramSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sleep metrics
                    sleepMetricsSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sleep stages
                    sleepStagesSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sleep Debt
                    sleepDebtSection
                        .padding()
                    
                    SectionDivider()
                    
                    // Sleep Consistency
                    sleepConsistencySection
                        .padding()
                    
                    SectionDivider()
                    
                    // Recommendations
                    recommendationsSection
                        .padding()
                }
            }
        .refreshable {
            await SleepScoreService.shared.calculateSleepScore()
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemOrange).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var weeklyTrendSection: some View {
        ProFeatureGate(
            upgradeContent: .weeklySleepTrend,
            isEnabled: proConfig.canViewWeeklyTrends,
            showBenefits: true
        ) {
            TrendChart(
                title: SleepContent.trendTitle,
                getData: { period in getHistoricalSleepData(for: period) },
                chartType: .bar,
                unit: "%",
                showProBadge: true,
                dataType: .sleep
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
    }
    
    private var hypnogramSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !sleepSamples.isEmpty,
               let bedtime = sleepScore.inputs.bedtime,
               let wakeTime = sleepScore.inputs.wakeTime {
                SleepHypnogramChart(
                    sleepSamples: sleepSamples,
                    nightStart: bedtime,
                    nightEnd: wakeTime
                )
            } else {
                Text("No detailed sleep stage data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
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
                    color: ColorScale.sleepCore
                )
                
                SleepMetricCard(
                    title: "Sleep Need",
                    value: sleepScore.formattedSleepNeed,
                    icon: "target",
                    color: ColorScale.sleepDeep
                )
                
                SleepMetricCard(
                    title: SleepContent.Metrics.efficiency,
                    value: sleepScore.formattedSleepEfficiency,
                    icon: "percent",
                    color: ColorScale.sleepREM
                )
                
                SleepMetricCard(
                    title: "Wake Events",
                    value: sleepScore.formattedWakeEvents,
                    icon: "exclamationmark.triangle.fill",
                    color: .red  // Keep red as RAG status indicator
                )
                
                SleepMetricCard(
                    title: "Deep Sleep",
                    value: sleepScore.formattedDeepSleepPercentage,
                    icon: "waveform.path.ecg",
                    color: ColorScale.sleepDeep
                )
            }
        }
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
                            color: ColorScale.sleepDeep
                        )
                    }
                    
                    if let remDuration = sleepScore.inputs.remSleepDuration {
                        SleepStageRow(
                            title: "REM Sleep",
                            duration: remDuration,
                            totalDuration: sleepDuration,
                            color: ColorScale.sleepREM
                        )
                    }
                    
                    if let coreDuration = sleepScore.inputs.coreSleepDuration {
                        SleepStageRow(
                            title: "Core Sleep",
                            duration: coreDuration,
                            totalDuration: sleepDuration,
                            color: ColorScale.sleepCore
                        )
                    }
                    
                    if let awakeDuration = sleepScore.inputs.awakeDuration {
                        SleepStageRow(
                            title: "Awake",
                            duration: awakeDuration,
                            totalDuration: sleepDuration,
                            color: ColorScale.sleepAwake
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
        Logger.debug("💤 [SLEEP CHART] Fetching data for period: \(period.days) days")
        
        // Check if mock data is enabled for testing
        #if DEBUG
        if ProFeatureConfig.shared.showMockDataForTesting {
            Logger.debug("💤 [SLEEP CHART] Using mock data")
            return generateMockSleepData(for: period)
        }
        #endif
        
        // Fetch real data from Core Data
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate) else {
            Logger.error("💤 [SLEEP CHART] Failed to calculate start date")
            return []
        }
        
        Logger.debug("💤 [SLEEP CHART] Date range: \(startDate) to \(endDate)")
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest) else {
            Logger.error("💤 [SLEEP CHART] Core Data fetch failed")
            return []
        }
        
        Logger.debug("💤 [SLEEP CHART] Fetched \(results.count) days with sleep data")
        
        let dataPoints = results.compactMap { dailyScore -> TrendDataPoint? in
            guard let date = dailyScore.date else { return nil }
            return TrendDataPoint(
                date: date,
                value: dailyScore.sleepScore
            )
        }
        
        Logger.debug("💤 [SLEEP CHART] Returning \(dataPoints.count) data points for \(period.days)-day view")
        if period.days >= 30 {
            Logger.debug("💤 [SLEEP CHART] Sample dates: \(dataPoints.prefix(3).map { $0.date })")
        }
        
        return dataPoints
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
    
    // MARK: - New Metrics Sections
    
    @ViewBuilder
    private var sleepDebtSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SleepContent.NewMetrics.sleepDebt)
                .font(.headline)
                .fontWeight(.semibold)
            
            if let debt = SleepScoreService.shared.currentSleepDebt {
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title2)
                        .foregroundColor(debt.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(debt.band.colorToken)
                        
                        Text("7-day cumulative deficit")
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
                
                Text("Avg sleep: \(String(format: "%.1fh", debt.averageSleepDuration)) • Need: \(String(format: "%.1fh", debt.sleepNeed))")
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
                    metricName: "Sleep Debt",
                    description: "Tracks cumulative sleep deficit to identify recovery needs"
                )
            }
        }
    }
    
    @ViewBuilder
    private var sleepConsistencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SleepContent.NewMetrics.consistency)
                .font(.headline)
                .fontWeight(.semibold)
            
            if let consistency = SleepScoreService.shared.currentSleepConsistency {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(consistency.band.colorToken)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(consistency.band.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(consistency.band.colorToken)
                        
                        Text("Circadian rhythm health")
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
                
                Text("Bedtime: ±\(Int(consistency.bedtimeVariability))min • Wake: ±\(Int(consistency.wakeTimeVariability))min")
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
                    metricName: "Sleep Consistency",
                    description: "Measures circadian rhythm health via sleep schedule variability"
                )
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
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return AnyView(EmptyView())
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest), !results.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("7-Day Sleep Quality Trend")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(results.enumerated()), id: \.element.date) { index, dailyScore in
                            let score = dailyScore.sleepScore
                            let height = max(4, (score / 100.0) * geometry.size.height)
                            let color: Color = score >= 80 ? ColorScale.greenAccent : score >= 60 ? ColorScale.yellowAccent : ColorScale.amberAccent
                            
                            VStack(spacing: 2) {
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
                    Text("Optimal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer().frame(width: 8)
                    
                    Circle()
                        .fill(ColorScale.yellowAccent)
                        .frame(width: 6, height: 6)
                    Text("Good")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer().frame(width: 8)
                    
                    Circle()
                        .fill(ColorScale.amberAccent)
                        .frame(width: 6, height: 6)
                    Text("Fair")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        )
    }
    
    @ViewBuilder
    private func sleepConsistencyTrendChart() -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return AnyView(EmptyView())
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let results = try? context.fetch(fetchRequest), !results.isEmpty else {
            return AnyView(EmptyView())
        }
        
        // Use sleep scores as a proxy for consistency
        let scores = results.compactMap { $0.sleepScore }
        guard !scores.isEmpty else {
            return AnyView(EmptyView())
        }
        
        let avgScore = scores.reduce(0, +) / Double(scores.count)
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("7-Day Sleep Score Pattern")
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
                        ForEach(Array(results.enumerated()), id: \.element.date) { index, dailyScore in
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
                
                Text("Dots show deviation from average score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        )
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func sleepDataAvailabilityMessage(requiredDays: Int, metricName: String, description: String) -> some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -requiredDays, to: endDate) else {
            return AnyView(EmptyView())
        }
        
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND sleepScore > 0", startDate as NSDate, endDate as NSDate)
        
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
                                .fill(ColorScale.purpleAccent)
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
