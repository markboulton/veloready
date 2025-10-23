import SwiftUI

/// Debug view showcasing all V2 card components with dummy data
/// Use this to preview all available cards and understand when to use each
struct CardGalleryDebugView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // MARK: - Metric Cards (Simple Data Display)
                    
                    sectionHeader("Metric Cards", subtitle: "Simple stats with scores/metrics")
                    
                    StepsCardV2()
                        .annotated("StepsCardV2", "Daily step count with goal tracking")
                    
                    CaloriesCardV2()
                        .annotated("CaloriesCardV2", "Active calories with goal tracking")
                    
                    DebtMetricCardV2(
                        debtType: .recovery(
                            RecoveryDebt(
                                consecutiveDays: 3,
                                band: .accumulating,
                                averageRecoveryScore: 62,
                                calculatedAt: Date()
                            )
                        ),
                        onTap: {}
                    )
                    .annotated("DebtMetricCardV2 (Recovery)", "Recovery debt tracking")
                    
                    DebtMetricCardV2(
                        debtType: .sleep(
                            SleepDebt(
                                totalDebtHours: 4.5,
                                band: .moderate,
                                averageSleepDuration: 6.2,
                                sleepNeed: 8.0,
                                calculatedAt: Date()
                            )
                        ),
                        onTap: {}
                    )
                    .annotated("DebtMetricCardV2 (Sleep)", "Sleep debt tracking")
                    
                    // MARK: - Alert/Warning Cards
                    
                    sectionHeader("Alert Cards", subtitle: "Health warnings and notifications")
                    
                    HealthWarningsCardV2()
                        .annotated("HealthWarningsCardV2", "Illness/wellness detection alerts")
                    
                    // MARK: - Activity Cards
                    
                    sectionHeader("Activity Cards", subtitle: "Workout/activity summaries")
                    
                    LatestActivityCardV2(
                        activity: UnifiedActivity(from: sampleIntervalsActivity)
                    )
                    .annotated("LatestActivityCardV2", "Latest ride/workout with map")
                    
                    // MARK: - Trend Line Charts
                    
                    sectionHeader("Trend Line Charts", subtitle: "Time-series data with trends")
                    
                    HRVTrendCardV2(
                        data: sampleHRVData,
                        timeRange: .days30
                    )
                    .annotated("HRVTrendCardV2", "HRV trend over time")
                    
                    RecoveryTrendCardV2(
                        data: sampleTrendData(baseline: 72, range: -10...10),
                        timeRange: .days30
                    )
                    .annotated("RecoveryTrendCardV2", "Recovery score trend")
                    
                    RestingHRCardV2(
                        data: sampleTrendData(baseline: 52, range: -4...8),
                        timeRange: .days30
                    )
                    .annotated("RestingHRCardV2", "Resting heart rate trend")
                    
                    StressLevelCardV2(
                        data: sampleTrendData(baseline: 35, range: -15...25),
                        timeRange: .days30
                    )
                    .annotated("StressLevelCardV2", "Daily stress level trend")
                    
                    FTPTrendCardV2(
                        data: sampleFTPData,
                        timeRange: .days90
                    )
                    .annotated("FTPTrendCardV2", "FTP progression over time")
                    
                    TrainingLoadTrendCardV2(
                        data: sampleTrendData(baseline: 50, range: -20...30),
                        timeRange: .days30
                    )
                    .annotated("TrainingLoadTrendCardV2", "Daily training load (normalized)")
                    
                    // MARK: - Complex Overlay Charts
                    
                    sectionHeader("Overlay Charts", subtitle: "Multiple metrics on one chart")
                    
                    PerformanceOverviewCardV2(
                        recoveryData: sampleTrendData(baseline: 70, range: -10...15),
                        loadData: sampleTrendData(baseline: 50, range: -20...30),
                        sleepData: sampleTrendData(baseline: 75, range: -15...10),
                        timeRange: .days30
                    )
                    .annotated("PerformanceOverviewCardV2", "3-metric overlay: Recovery + Load + Sleep")
                    
                    // MARK: - Scatter/Correlation Charts
                    
                    sectionHeader("Correlation Charts", subtitle: "Relationship analysis")
                    
                    RecoveryVsPowerCardV2(
                        data: sampleCorrelationData,
                        correlation: sampleCorrelation,
                        timeRange: .days90
                    )
                    .annotated("RecoveryVsPowerCardV2", "Scatter plot: Recovery % vs Power (W)")
                    
                    // MARK: - Bar Charts
                    
                    sectionHeader("Bar Charts", subtitle: "Weekly/categorical data")
                    
                    WeeklyTSSTrendCardV2(
                        data: sampleWeeklyTSSData,
                        timeRange: .days90
                    )
                    .annotated("WeeklyTSSTrendCardV2", "Weekly TSS totals (bar chart)")
                    
                    // MARK: - Assessment Cards
                    
                    sectionHeader("Assessment Cards", subtitle: "Phase detection & risk analysis")
                    
                    TrainingPhaseCardV2(
                        phase: samplePhaseDetection
                    )
                    .annotated("TrainingPhaseCardV2", "Auto-detected training phase")
                    
                    OvertrainingRiskCardV2(
                        risk: sampleRiskAssessment
                    )
                    .annotated("OvertrainingRiskCardV2", "Overtraining risk with factors")
                    
                    // MARK: - Sleep Detail Cards
                    
                    sectionHeader("Sleep Detail Cards", subtitle: "Sleep metrics and breakdown")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.md) {
                        SleepMetricCard(
                            title: "Duration",
                            value: "7h 24m",
                            icon: Icons.Health.sleepFill,
                            color: ColorScale.sleepCore
                        )
                        .annotated("SleepMetricCard", "Sleep metric with icon and color")
                        
                        SleepMetricCard(
                            title: "Efficiency",
                            value: "92%",
                            icon: Icons.System.percent,
                            color: ColorScale.sleepREM
                        )
                        .annotated("SleepMetricCard", "Sleep metric variant")
                    }
                    
                    // MARK: - Load Detail Cards
                    
                    sectionHeader("Load Detail Cards", subtitle: "Training load breakdown")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.md) {
                        LoadMetricCard(
                            title: "Cardio Time",
                            value: "1h 15m",
                            icon: "bicycle",
                            color: .blue
                        )
                        .annotated("LoadMetricCard", "Training load metric card")
                        
                        LoadMetricCard(
                            title: "Avg Intensity",
                            value: "0.87 IF",
                            icon: "speedometer",
                            color: .orange
                        )
                        .annotated("LoadMetricCard", "Intensity factor display")
                    }
                    
                    // MARK: - Empty States
                    
                    sectionHeader("Empty States", subtitle: "Cards with no data")
                    
                    HRVTrendCardV2(data: [], timeRange: .days30)
                        .annotated("Empty State Example", "Shows requirements and guidance")
                }
                .padding()
            }
            .background(Color.background.primary)
            .navigationTitle("Card Gallery Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
                .padding(.vertical, Spacing.md)
            
            VRText(title, style: .title2, color: Color.text.primary)
            VRText(subtitle, style: .caption, color: Color.text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Sample Data Generators
    
    private func sampleTrendData(baseline: Double, range: ClosedRange<Double>) -> [TrendsViewModel.TrendDataPoint] {
        (0..<30).map { day in
            TrendsViewModel.TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: baseline + Double.random(in: range)
            )
        }.reversed()
    }
    
    private var sampleHRVData: [TrendsViewModel.HRVTrendDataPoint] {
        (0..<30).map { day in
            TrendsViewModel.HRVTrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: 65 + Double.random(in: -12...12),
                baseline: 65
            )
        }.reversed()
    }
    
    private var sampleFTPData: [TrendsViewModel.TrendDataPoint] {
        [
            TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*60), value: 285),
            TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*45), value: 288),
            TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*30), value: 292),
            TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*15), value: 295),
            TrendsViewModel.TrendDataPoint(date: Date(), value: 298)
        ]
    }
    
    private var sampleCorrelationData: [TrendsViewModel.CorrelationDataPoint] {
        (0..<30).map { i in
            let recovery = Double.random(in: 50...95)
            let power = 150 + (recovery - 70) * 2 + Double.random(in: -20...20)
            return TrendsViewModel.CorrelationDataPoint(
                date: Date().addingTimeInterval(Double(-i) * 24 * 60 * 60),
                x: recovery,
                y: power
            )
        }
    }
    
    private var sampleCorrelation: CorrelationCalculator.CorrelationResult {
        CorrelationCalculator.CorrelationResult(
            coefficient: 0.72,
            rSquared: 0.52,
            sampleSize: 30,
            significance: .strong,
            trend: .positive
        )
    }
    
    private var sampleWeeklyTSSData: [TrendsViewModel.WeeklyTSSDataPoint] {
        (0..<12).map { week in
            TrendsViewModel.WeeklyTSSDataPoint(
                weekStart: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                tss: Double.random(in: 200...650)
            )
        }.reversed()
    }
    
    private var samplePhaseDetection: TrainingPhaseDetector.PhaseDetectionResult {
        TrainingPhaseDetector.PhaseDetectionResult(
            phase: .build,
            confidence: 0.85,
            weeklyTSS: 450,
            lowIntensityPercent: 65,
            highIntensityPercent: 20,
            recommendation: "Build phase: Good mix of volume and intensity. Maintain consistency."
        )
    }
    
    private var sampleRiskAssessment: OvertrainingRiskCalculator.RiskResult {
        OvertrainingRiskCalculator.RiskResult(
            riskScore: 42,
            riskLevel: .moderate,
            factors: [
                OvertrainingRiskCalculator.RiskFactor(
                    name: "Training Load",
                    severity: 0.5,
                    description: "Elevated: TSS significantly above baseline"
                ),
                OvertrainingRiskCalculator.RiskFactor(
                    name: "Sleep Quality",
                    severity: 0.3,
                    description: "Below optimal: Sleep score averaging 72%"
                )
            ],
            recommendation: "Moderate risk. Monitor recovery closely and consider an extra rest day this week."
        )
    }
    
    private var sampleIntervalsActivity: IntervalsActivity {
        IntervalsActivity(
            id: "debug-1",
            name: "Morning Ride",
            description: "Easy spin",
            startDateLocal: "2025-10-23T07:30:00",
            type: "Ride",
            duration: 3600,
            distance: 25000,
            elevationGain: 200,
            averagePower: 180,
            normalizedPower: 190,
            averageHeartRate: 140,
            maxHeartRate: 165,
            averageCadence: 85,
            averageSpeed: 25,
            maxSpeed: 45,
            calories: 500,
            fileType: "fit",
            tss: 70,
            intensityFactor: 0.85,
            atl: 30,
            ctl: 35,
            icuZoneTimes: [600, 900, 1200, 600, 300, 0, 0],
            icuHrZoneTimes: [800, 1600, 1000, 200, 0, 0, 0]
        )
    }
}

// MARK: - Annotation View Modifier

extension View {
    func annotated(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            self
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(Color.chart.primary)
                    
                    VRText(title, style: .caption, color: Color.chart.primary)
                        .fontWeight(.semibold)
                }
                
                VRText(description, style: .caption, color: Color.text.tertiary)
                    .italic()
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.chart.primary.opacity(0.1))
            .cornerRadius(Spacing.xs)
        }
    }
}

// MARK: - Preview

#Preview {
    CardGalleryDebugView()
}
