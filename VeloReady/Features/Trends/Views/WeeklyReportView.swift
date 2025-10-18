import SwiftUI

/// Weekly Performance Report View - Comprehensive weekly analysis
/// Redesigned to match Today tab patterns with proper data viz
struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyReportViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var selectedSleepDay = 0 // For segmented control
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. AI Summary (matches AIBriefView design)
                aiSummarySection
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                
                SectionDivider()
                
                // 2. CTL/ATL/TSB Chart (moved to top after AI)
                if let metrics = viewModel.weeklyMetrics {
                    fitnessTrajectoryChart
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 3. Wellness Foundation (single color - purple)
                if let wellness = viewModel.wellnessFoundation {
                    wellnessFoundationSection(wellness: wellness)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 4. Recovery Capacity
                if let metrics = viewModel.weeklyMetrics {
                    recoveryCapacitySection(metrics: metrics)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 5. Training Load Summary
                if let zones = viewModel.trainingZoneDistribution {
                    trainingLoadSection(zones: zones)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 6. Sleep Hypnograms with segmented control
                if !viewModel.sleepHypnograms.isEmpty {
                    sleepHypnogramSection
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 7. Circadian Rhythm
                if let circadian = viewModel.circadianRhythm {
                    circadianRhythmSection(circadian: circadian)
                        .padding(.horizontal, Spacing.lg)
                    
                    SectionDivider()
                }
                
                // 8. Week-over-Week
                if let metrics = viewModel.weeklyMetrics {
                    weekOverWeekSection(metrics: metrics)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
            }
        }
        .background(Color.background.primary)
        .task {
            await viewModel.loadWeeklyReport()
        }
        .refreshable {
            await viewModel.loadWeeklyReport()
        }
    }
    
    // MARK: - 1. AI Summary (Matches AIBriefView)
    
    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header matches AIBriefView exactly
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.heading)
                    .foregroundColor(ColorPalette.aiIconColor)
                
                Text("Weekly Performance Report")
                    .font(.heading)
                    .rainbowGradient()
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Date range
            Text(formatWeekRange())
                .font(.caption)
                .foregroundColor(.text.secondary)
                .padding(.bottom, 8)
            
            // AI Summary Content
            if viewModel.isLoadingAI {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing your week...")
                        .bodyStyle()
                        .foregroundColor(.text.secondary)
                }
                .padding(.vertical, Spacing.md)
            } else if let summary = viewModel.aiSummary {
                Text(summary)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)
            } else if let error = viewModel.aiError {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unable to generate analysis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                .padding(.bottom, 12)
            }
            
            // Next report countdown
            if viewModel.daysUntilNextReport > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text("Next report: \(viewModel.daysUntilNextReport) \(viewModel.daysUntilNextReport == 1 ? "day" : "days")")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Generated today")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            }
        }
    }
    
    // MARK: - 2. CTL/ATL/TSB Chart
    
    private var fitnessTrajectoryChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Fitness Trajectory (7 Days)")
                .font(.heading)
            
            if let metrics = viewModel.weeklyMetrics, let ctlData = viewModel.ctlHistoricalData {
                // Chart showing CTL, ATL, TSB over 7 days
                FitnessTrajectoryChart(data: ctlData)
                    .frame(height: 200)
                
                // Current values
                HStack(spacing: Spacing.lg) {
                    metricPill(
                        label: "CTL",
                        value: "\(Int(metrics.ctlEnd))",
                        change: metrics.ctlEnd - metrics.ctlStart,
                        color: .workout.power
                    )
                    metricPill(
                        label: "ATL",
                        value: "\(Int(metrics.atl))",
                        change: nil,
                        color: .workout.tss
                    )
                    metricPill(
                        label: "Form",
                        value: "\(Int(metrics.tsb))",
                        change: nil,
                        color: tsbColor(metrics.tsb)
                    )
                }
                
                Text(tsbInterpretation(metrics.tsb))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            } else {
                Text("No training load data available")
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
    
    private func tsbColor(_ tsb: Double) -> Color {
        switch tsb {
        case ..<(-10): return .red
        case -10..<5: return .yellow
        case 5..<25: return .green
        default: return .blue
        }
    }
    
    private func tsbInterpretation(_ tsb: Double) -> String {
        switch tsb {
        case ..<(-10): return "Fatigued - prioritize recovery"
        case -10..<5: return "Optimal training zone"
        case 5..<25: return "Fresh - ready for hard efforts"
        default: return "Very fresh - consider increasing load"
        }
    }
    
    // MARK: - 3. Wellness Foundation
    
    private func wellnessFoundationSection(wellness: WeeklyReportViewModel.WellnessFoundation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wellness Foundation")
                .font(.heading)
            
            // Use single color - health purple with minimal fill
            RadarChart(
                dataPoints: [
                    .init(label: "Sleep", value: wellness.sleepQuality, icon: "moon.fill"),
                    .init(label: "Recovery", value: wellness.recoveryCapacity, icon: "heart.fill"),
                    .init(label: "HRV", value: wellness.hrvStatus, icon: "waveform.path.ecg"),
                    .init(label: "Low Stress", value: 100 - wellness.stressLevel, icon: "brain.head.profile"),
                    .init(label: "Consistent", value: wellness.consistency, icon: "calendar"),
                    .init(label: "Fueling", value: wellness.nutrition, icon: "fork.knife")
                ],
                maxValue: 100,
                fillColor: Color.health.hrv.opacity(0.08),
                strokeColor: Color.health.hrv
            )
            .frame(height: 280)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Score: \(Int(wellness.overallScore))/100")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(wellnessInterpretation(wellness: wellness))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func wellnessInterpretation(wellness: WeeklyReportViewModel.WellnessFoundation) -> String {
        var insights: [String] = []
        
        if wellness.sleepQuality < 70 {
            insights.append("Sleep quality needs attention")
        }
        if wellness.stressLevel > 70 {
            insights.append("Stress levels elevated (lower is better)")
        }
        if wellness.consistency < 70 {
            insights.append("Consistency could improve")
        }
        
        if insights.isEmpty {
            return "Strong wellness foundation supporting your training"
        } else {
            return insights.joined(separator: ". ") + "."
        }
    }
    
    // MARK: - 4. Recovery Capacity
    
    private func recoveryCapacitySection(metrics: WeeklyReportViewModel.WeeklyMetrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recovery Capacity")
                .font(.heading)
            
            HStack(alignment: .top, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Recovery")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    HStack(spacing: 4) {
                        Text("\(Int(metrics.avgRecovery))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.health.heartRate)
                        if metrics.recoveryChange != 0 {
                            Image(systemName: metrics.recoveryChange > 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(metrics.recoveryChange > 0 ? .green : .red)
                            Text("\(Int(abs(metrics.recoveryChange)))%")
                                .font(.caption)
                                .foregroundColor(metrics.recoveryChange > 0 ? .green : .red)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRV Trend")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(metrics.hrvTrend)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(String(format: "%.1fh", metrics.avgSleep))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Text(recoveryCapacityMessage(metrics: metrics))
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func recoveryCapacityMessage(metrics: WeeklyReportViewModel.WeeklyMetrics) -> String {
        if metrics.avgRecovery >= 75 {
            return "Excellent capacity - ready for challenging training"
        } else if metrics.avgRecovery >= 65 {
            return "Good capacity - can handle moderate training load"
        } else if metrics.avgRecovery >= 55 {
            return "Adequate - maintain current training level"
        } else {
            return "Low capacity - prioritize recovery before increasing load"
        }
    }
    
    // MARK: - 5. Training Load Summary
    
    private func trainingLoadSection(zones: WeeklyReportViewModel.TrainingZoneDistribution) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Training Load Summary")
                .font(.heading)
            
            if let metrics = viewModel.weeklyMetrics {
                // Weekly totals
                HStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total TSS")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                        Text("\(Int(metrics.weeklyTSS))")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Training Time")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                        Text(formatDuration(metrics.weeklyDuration))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workouts")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                        Text("\(metrics.workoutCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Training days breakdown (smaller, cleaner)
            VStack(alignment: .leading, spacing: 8) {
                Text("Training Pattern")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    dayTypePill("Optimal", count: zones.optimalDays, color: .green)
                    dayTypePill("Hard", count: zones.overreachingDays, color: .orange)
                    dayTypePill("Easy/Rest", count: zones.restoringDays, color: .blue)
                }
                
                Text(trainingPatternMessage(zones: zones))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
            .padding(.bottom, 8)
            
            // Intensity distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("Intensity Distribution")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                intensityBar(
                    label: "Easy (Z1-2)",
                    percent: zones.zoneEasyPercent,
                    color: .green
                )
                intensityBar(
                    label: "Tempo (Z3-4)",
                    percent: zones.zoneTempoPercent,
                    color: .orange
                )
                intensityBar(
                    label: "Hard (Z5+)",
                    percent: zones.zoneHardPercent,
                    color: .red
                )
                
                HStack(spacing: 4) {
                    Text("Polarization:")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text("\(Int(zones.polarizationScore))/100")
                        .font(.caption)
                        .fontWeight(.medium)
                    if zones.polarizationScore >= 80 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Text(zones.polarizationScore >= 80 ? "Well polarized" : "Could be more polarized")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            }
        }
    }
    
    private func dayTypePill(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func trainingPatternMessage(zones: WeeklyReportViewModel.TrainingZoneDistribution) -> String {
        if zones.optimalDays >= 4 {
            return "Good balance of training stress and recovery"
        } else if zones.overreachingDays > zones.optimalDays {
            return "High training stress - monitor recovery closely"
        } else {
            return "Light training week - good for recovery or taper"
        }
    }
    
    private func intensityBar(label: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.text.secondary)
                .frame(width: 90, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(width: geometry.size.width * (percent / 100))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
            
            Text("\(Int(percent))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    // MARK: - 6. Sleep Hypnograms with Segmented Control
    
    private var sleepHypnogramSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Weekly Sleep")
                .font(.heading)
            
            // Segmented control for days
            if viewModel.sleepHypnograms.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.sleepHypnograms.count, id: \.self) { index in
                            Button(action: {
                                selectedSleepDay = index
                            }) {
                                Text(dayLabel(for: viewModel.sleepHypnograms[index].date))
                                    .font(.caption)
                                    .fontWeight(selectedSleepDay == index ? .semibold : .regular)
                                    .foregroundColor(selectedSleepDay == index ? .white : .text.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedSleepDay == index ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Selected hypnogram
            if selectedSleepDay < viewModel.sleepHypnograms.count {
                let hypnogram = viewModel.sleepHypnograms[selectedSleepDay]
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatHypnogramDate(hypnogram.date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatNightDuration(hypnogram))
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                    
                    SleepHypnogramChart(
                        sleepSamples: hypnogram.samples,
                        nightStart: hypnogram.bedtime,
                        nightEnd: hypnogram.wakeTime
                    )
                }
            }
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHypnogramDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatNightDuration(_ hypnogram: WeeklyReportViewModel.SleepNightData) -> String {
        let duration = hypnogram.wakeTime.timeIntervalSince(hypnogram.bedtime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - 7. Circadian Rhythm
    
    private func circadianRhythmSection(circadian: WeeklyReportViewModel.CircadianRhythmData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sleep Schedule")
                .font(.heading)
            
            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Bedtime")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(formatHour(circadian.avgBedtime))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Wake")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(formatHour(circadian.avgWakeTime))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consistency")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text("±\(Int(circadian.bedtimeVariance)) min")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            
            Text(circadianMessage(circadian: circadian))
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func formatHour(_ hour: Double) -> String {
        let h = Int(hour.truncatingRemainder(dividingBy: 24))
        let m = Int((hour - Double(Int(hour))) * 60)
        let period = h >= 12 ? "PM" : "AM"
        let displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h)
        return String(format: "%d:%02d %@", displayHour, m, period)
    }
    
    private func circadianMessage(circadian: WeeklyReportViewModel.CircadianRhythmData) -> String {
        if circadian.bedtimeVariance < 30 {
            return "Excellent schedule consistency - supports recovery and adaptation"
        } else if circadian.bedtimeVariance < 60 {
            return "Good consistency - small variations are normal"
        } else {
            return "Variable schedule - more consistency could improve recovery"
        }
    }
    
    // MARK: - 8. Week-over-Week
    
    private func weekOverWeekSection(metrics: WeeklyReportViewModel.WeeklyMetrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Week-over-Week Changes")
                .font(.heading)
            
            VStack(spacing: 8) {
                changeRow(
                    label: "Recovery",
                    value: "\(Int(metrics.avgRecovery))%",
                    change: metrics.recoveryChange
                )
                changeRow(
                    label: "TSS",
                    value: "\(Int(metrics.weeklyTSS))",
                    change: nil
                )
                changeRow(
                    label: "Training Time",
                    value: formatDuration(metrics.weeklyDuration),
                    change: nil
                )
                changeRow(
                    label: "CTL",
                    value: "\(Int(metrics.ctlEnd))",
                    change: metrics.ctlEnd - metrics.ctlStart
                )
            }
        }
    }
    
    private func changeRow(label: String, value: String, change: Double?) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.text.secondary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text("\(Int(abs(change)))")
                        .font(.caption)
                }
                .foregroundColor(change >= 0 ? .green : .red)
                .frame(width: 50, alignment: .trailing)
            } else {
                Text("")
                    .frame(width: 50)
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
