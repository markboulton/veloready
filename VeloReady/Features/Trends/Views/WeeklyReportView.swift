import SwiftUI

/// Weekly Performance Report View
/// Comprehensive weekly analysis with holistic health metrics and innovative visualizations
struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyReportViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // AI Summary with rainbow gradient header
                aiSummarySection
                
                // Wellness Foundation (Radar Chart)
                if let wellness = viewModel.wellnessFoundation {
                    wellnessFoundationSection(wellness: wellness)
                }
                
                // Training Zone Assessment
                if let zones = viewModel.trainingZoneDistribution {
                    trainingZoneSection(zones: zones)
                }
                
                // Fitness & Form Trajectory
                if let metrics = viewModel.weeklyMetrics {
                    fitnessFormSection(metrics: metrics)
                }
                
                // Recovery Capacity
                if let metrics = viewModel.weeklyMetrics {
                    recoveryCapacitySection(metrics: metrics)
                }
                
                // Sleep Architecture (Stacked Area Chart)
                if !viewModel.sleepArchitecture.isEmpty {
                    sleepArchitectureSection
                }
                
                // Weekly Rhythm Heatmap
                if let heatmap = viewModel.weeklyHeatmap {
                    weeklyRhythmSection(heatmap: heatmap)
                }
                
                // Circadian Rhythm (Clock Chart)
                if let circadian = viewModel.circadianRhythm {
                    circadianRhythmSection(circadian: circadian)
                }
                
                // Week-over-Week Comparison
                if let metrics = viewModel.weeklyMetrics {
                    weekOverWeekSection(metrics: metrics)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.background.primary)
        .task {
            await viewModel.loadWeeklyReport()
        }
        .refreshable {
            await viewModel.loadWeeklyReport()
        }
    }
    
    // MARK: - AI Summary Section
    
    private var aiSummarySection: some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Rainbow gradient header with sparkle
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: TypeScale.lg, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan, .green, .yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Weekly Performance Report")
                        .font(.system(size: TypeScale.lg, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan, .green, .yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                }
                
                // Date range
                Text(formatWeekRange())
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                SectionDivider()
                
                // AI Summary
                if viewModel.isLoadingAI {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing your week...")
                            .font(.body)
                            .foregroundColor(.text.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
                } else if let summary = viewModel.aiSummary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let error = viewModel.aiError {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Unable to generate analysis")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.text.primary)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                }
                
                // Next report countdown
                if viewModel.daysUntilNextReport > 0 {
                    SectionDivider()
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: TypeScale.xs))
                            .foregroundColor(.text.secondary)
                        Text("Next weekly report: \(viewModel.daysUntilNextReport) \(viewModel.daysUntilNextReport == 1 ? "day" : "days")")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                } else {
                    SectionDivider()
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: TypeScale.xs))
                            .foregroundColor(.green)
                        Text("Generated today")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Wellness Foundation Section
    
    private func wellnessFoundationSection(wellness: WeeklyReportViewModel.WellnessFoundation) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.health.hrv)
                    Text("Wellness Foundation")
                        .font(.heading)
                    Spacer()
                }
                
                RadarChart(
                    dataPoints: [
                        .init(label: "Sleep", value: wellness.sleepQuality, icon: "moon.fill"),
                        .init(label: "Recovery", value: wellness.recoveryCapacity, icon: "heart.fill"),
                        .init(label: "HRV", value: wellness.hrvStatus, icon: "waveform.path.ecg"),
                        .init(label: "Stress", value: 100 - wellness.stressLevel, icon: "brain.head.profile"),
                        .init(label: "Consistency", value: wellness.consistency, icon: "calendar"),
                        .init(label: "Nutrition", value: wellness.nutrition, icon: "fork.knife")
                    ],
                    fillColor: Color.health.hrv.opacity(0.25),
                    strokeColor: Color.health.hrv
                )
                .frame(height: 300)
                
                Text("Foundation Score: \(Int(wellness.overallScore))/100")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                let foundationStatus = wellness.overallScore >= 75 ? "Strong base for performance goals" :
                                      wellness.overallScore >= 60 ? "Adequate foundation, some room for improvement" :
                                      "Foundation needs attention before increasing training load"
                
                Text(foundationStatus)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    // MARK: - Training Zone Section
    
    private func trainingZoneSection(zones: WeeklyReportViewModel.TrainingZoneDistribution) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.workout.power)
                    Text("Training Zone Assessment")
                        .font(.heading)
                    Spacer()
                }
                
                // Zone bar
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        if zones.restoringDays > 0 {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * CGFloat(zones.restoringDays) / 7.0)
                        }
                        if zones.optimalDays > 0 {
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: geometry.size.width * CGFloat(zones.optimalDays) / 7.0)
                        }
                        if zones.overreachingDays > 0 {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geometry.size.width * CGFloat(zones.overreachingDays) / 7.0)
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                let dominantZone = zones.optimalDays >= zones.restoringDays && zones.optimalDays >= zones.overreachingDays ? "OPTIMAL" :
                                  zones.restoringDays > zones.overreachingDays ? "RESTORING" : "OVERREACHING"
                
                Text(dominantZone)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You trained in the \(dominantZone) zone \(max(zones.optimalDays, zones.restoringDays, zones.overreachingDays)) out of 7 days this week.")
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    zoneRow(label: "Restoring", days: zones.restoringDays, color: .green)
                    zoneRow(label: "Optimal", days: zones.optimalDays, color: .yellow)
                    zoneRow(label: "Overreaching", days: zones.overreachingDays, color: .red)
                }
                
                // Intensity Distribution
                SectionDivider()
                
                Text("Intensity Distribution")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 4) {
                    intensityBar(label: "Zone 1-2 (Endurance)", percent: zones.zoneEasyPercent, color: .green)
                    intensityBar(label: "Zone 3-4 (Tempo/SS)", percent: zones.zoneTempoPercent, color: .orange)
                    intensityBar(label: "Zone 5-7 (Threshold+)", percent: zones.zoneHardPercent, color: .red)
                }
                
                HStack {
                    Text("Polarization Score: \(Int(zones.polarizationScore))/100")
                        .font(.caption)
                        .fontWeight(.medium)
                    if zones.polarizationScore >= 80 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                let polarizationMessage = zones.polarizationScore >= 80 ? "Well-distributed for sustainable improvement" :
                                         "Consider more polarization (80% easy, 20% hard)"
                Text(polarizationMessage)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func zoneRow(label: String, days: Int, color: Color) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.text.secondary)
            ForEach(0..<days, id: \.self) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            Text("\(days) \(days == 1 ? "day" : "days")")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func intensityBar(label: String, percent: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
                .frame(width: 140, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (percent / 100))
                }
            }
            .frame(height: 16)
            
            Text("\(Int(percent))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    // MARK: - Other Sections (simplified for length)
    
    private func fitnessFormSection(metrics: WeeklyReportViewModel.WeeklyMetrics) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.workout.tss)
                    Text("Fitness & Form Trajectory")
                        .font(.heading)
                    Spacer()
                }
                
                HStack(spacing: Spacing.xl) {
                    metricPill(label: "CTL (Fitness)", value: "\(Int(metrics.ctlEnd))", change: metrics.ctlEnd - metrics.ctlStart, color: .workout.power)
                    metricPill(label: "ATL (Fatigue)", value: "\(Int(metrics.atl))", change: nil, color: .workout.tss)
                    metricPill(label: "TSB (Form)", value: "\(Int(metrics.tsb))", change: nil, color: .health.hrv)
                }
                
                let trajectory = metrics.ctlEnd > metrics.ctlStart ? "Building fitness" :
                                metrics.ctlEnd < metrics.ctlStart ? "Maintaining/Tapering" : "Stable"
                Text("Trajectory: \(trajectory)")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func metricPill(label: String, value: String, change: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                if let change = change, change != 0 {
                    Text(change > 0 ? "+\(Int(change))" : "\(Int(change))")
                        .font(.caption)
                        .foregroundColor(change > 0 ? .green : .red)
                }
            }
        }
    }
    
    private func recoveryCapacitySection(metrics: WeeklyReportViewModel.WeeklyMetrics) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.health.heartRate)
                    Text("Recovery Capacity")
                        .font(.heading)
                    Spacer()
                }
                
                HStack {
                    Text("Weekly Avg: \(Int(metrics.avgRecovery))%")
                        .font(.title3)
                        .fontWeight(.bold)
                    if metrics.recoveryChange != 0 {
                        Text(metrics.recoveryChange > 0 ? "↑ +\(Int(metrics.recoveryChange))%" : "↓ \(Int(metrics.recoveryChange))%")
                            .font(.caption)
                            .foregroundColor(metrics.recoveryChange > 0 ? .green : .red)
                    }
                }
                
                Text("HRV Trend: \(metrics.hrvTrend)")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text("Sleep Consistency: \(Int(metrics.sleepConsistency))/100")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                let capacity = metrics.avgRecovery >= 70 ? "Good - can absorb moderate training load" :
                              metrics.avgRecovery >= 50 ? "Adequate - maintain current load" :
                              "Low - prioritize recovery this week"
                Text("Capacity: \(capacity)")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private var sleepArchitectureSection: some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.blue)
                    Text("Sleep Architecture (7 days)")
                        .font(.heading)
                    Spacer()
                }
                
                StackedAreaChart(
                    data: viewModel.sleepArchitecture.map { sleep in
                        StackedAreaChart.DayData(
                            date: sleep.date,
                            values: [
                                "awake": sleep.awake,
                                "core": sleep.core,
                                "rem": sleep.rem,
                                "deep": sleep.deep
                            ]
                        )
                    },
                    categories: [
                        .init(name: "awake", color: Color.red.opacity(0.6), label: "Awake"),
                        .init(name: "core", color: Color.blue.opacity(0.5), label: "Core"),
                        .init(name: "rem", color: Color.purple.opacity(0.6), label: "REM"),
                        .init(name: "deep", color: Color.indigo.opacity(0.7), label: "Deep")
                    ],
                    yAxisMax: 9.0
                )
            }
        }
    }
    
    private func weeklyRhythmSection(heatmap: WeeklyReportViewModel.WeeklyHeatmapData) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.purple)
                    Text("Weekly Rhythm Pattern")
                        .font(.heading)
                    Spacer()
                }
                
                WeeklyHeatmap(
                    trainingData: heatmap.trainingData,
                    sleepData: heatmap.sleepData
                )
            }
        }
    }
    
    private func circadianRhythmSection(circadian: WeeklyReportViewModel.CircadianRhythmData) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(.orange)
                    Text("Daily Rhythm Patterns")
                        .font(.heading)
                    Spacer()
                }
                
                CircadianClockChart(
                    sleepWindow: .init(
                        startHour: circadian.avgBedtime,
                        endHour: circadian.avgWakeTime,
                        label: "Sleep",
                        color: .blue,
                        icon: "moon.fill"
                    ),
                    trainingWindows: circadian.avgTrainingTime != nil ? [
                        .init(
                            startHour: circadian.avgTrainingTime!,
                            endHour: circadian.avgTrainingTime! + 1.5,
                            label: "Training",
                            color: .workout.power,
                            icon: "figure.outdoor.cycle"
                        )
                    ] : [],
                    consistency: circadian.consistency
                )
                .frame(height: 280)
                
                Text("Bedtime variance: ±\(Int(circadian.bedtimeVariance)) min")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text("Stable rhythm supports recovery and training adaptations.")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func weekOverWeekSection(metrics: WeeklyReportViewModel.WeeklyMetrics) -> some View {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Week-over-Week Changes")
                    .font(.heading)
                
                VStack(spacing: 8) {
                    changeRow(label: "Avg Recovery", thisWeek: "\(Int(metrics.avgRecovery))%", change: metrics.recoveryChange)
                    changeRow(label: "Weekly TSS", thisWeek: "\(Int(metrics.weeklyTSS))", change: nil)
                    changeRow(label: "Training Time", thisWeek: formatDuration(metrics.weeklyDuration), change: nil)
                    changeRow(label: "Sleep Quality", thisWeek: "\(Int(metrics.sleepConsistency))/100", change: nil)
                }
            }
        }
    }
    
    private func changeRow(label: String, thisWeek: String, change: Double?) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.text.secondary)
                .frame(width: 120, alignment: .leading)
            Spacer()
            Text(thisWeek)
                .font(.body)
                .fontWeight(.medium)
            if let change = change {
                Text(change >= 0 ? "+\(Int(change))" : "\(Int(change))")
                    .font(.caption)
                    .foregroundColor(change >= 0 ? .green : .red)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatWeekRange() -> String {
        let calendar = Calendar.current
        let monday = viewModel.weekStartDate
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: monday)) - \(formatter.string(from: sunday))"
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeeklyReportView()
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
    }
}
