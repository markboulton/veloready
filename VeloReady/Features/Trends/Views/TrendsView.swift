import SwiftUI

/// Main Trends view - PRO feature
/// Shows performance and health trends over time
struct TrendsView: View {
    @StateObject private var viewModel = TrendsViewModel()
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientBackground()
                
                Group {
                    if proConfig.hasProAccess {
                        trendsContent
                    } else {
                        proGate
                    }
                }
            }
            .navigationTitle(TrendsContent.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.automatic, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Trends Content
    
    private var trendsContent: some View {
        WeeklyReportView()
    }
    
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        StandardCard(
            icon: "chart.bar.fill",
            title: oauthManager.isAuthenticated ? "Performance Summary" : "Health Summary"
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.lg) {
                    // Show FTP only when Intervals connected (cycling-specific)
                    if oauthManager.isAuthenticated, let ftp = viewModel.ftpTrendData.last?.value {
                        StatPill(
                            label: "Current FTP",
                            value: "\(Int(ftp))W",
                            color: .workout.power
                        )
                    }
                    
                    // Always show recovery (HealthKit-based)
                    if !viewModel.recoveryTrendData.isEmpty {
                        let avg = viewModel.recoveryTrendData.map(\.value).reduce(0, +) / Double(viewModel.recoveryTrendData.count)
                        StatPill(
                            label: "Avg Recovery",
                            value: "\(Int(avg))%",
                            color: .health.hrv
                        )
                    }
                    
                    // Show TSS only when Intervals connected (cycling-specific)
                    if oauthManager.isAuthenticated, !viewModel.weeklyTSSData.isEmpty {
                        let avg = viewModel.weeklyTSSData.map(\.tss).reduce(0, +) / Double(viewModel.weeklyTSSData.count)
                        StatPill(
                            label: "Avg Weekly TSS",
                            value: "\(Int(avg))",
                            color: .workout.tss
                        )
                    }
                    
                    // Show HRV for HealthKit-only mode
                    if !oauthManager.isAuthenticated, !viewModel.hrvTrendData.isEmpty {
                        let avg = viewModel.hrvTrendData.map(\.value).reduce(0, +) / Double(viewModel.hrvTrendData.count)
                        StatPill(
                            label: "Avg HRV",
                            value: "\(Int(avg))ms",
                            color: .health.hrv
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Trend Cards
    
    private var trendCards: some View {
        VStack(spacing: Spacing.cardSpacing) {
            // Illness Alert (if present)
            IllnessAlertBanner()
            
            // Recovery & Readiness Section (Always visible - HealthKit-based)
            sectionHeader(
                title: "Recovery & Readiness",
                icon: "heart.fill",
                color: .health.heartRate
            )
            
            RecoveryTrendCard(
                data: viewModel.recoveryTrendData,
                timeRange: viewModel.selectedTimeRange
            )
            
            HRVTrendCard(
                data: viewModel.hrvTrendData,
                timeRange: viewModel.selectedTimeRange
            )
            
            RestingHRCard(
                data: viewModel.restingHRData,
                timeRange: viewModel.selectedTimeRange
            )
            
            StressLevelCard(
                data: viewModel.stressData,
                timeRange: viewModel.selectedTimeRange
            )
            
            // Cycling-specific sections (only when Intervals connected)
            if oauthManager.isAuthenticated {
                // Performance Overview with TSS
                sectionHeader(
                    title: "Performance Overview",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .chart.primary
                )
                
                PerformanceOverviewCard(
                    recoveryData: viewModel.recoveryTrendData,
                    loadData: viewModel.dailyLoadData,
                    sleepData: viewModel.sleepData,
                    timeRange: viewModel.selectedTimeRange
                )
                
                TrainingLoadTrendCard(
                    activities: viewModel.activitiesForLoad,
                    timeRange: viewModel.selectedTimeRange
                )
                
                // Form & Fitness Section
                sectionHeader(
                    title: "Form & Fitness",
                    icon: "bolt.fill",
                    color: .workout.power
                )
                
                FTPTrendCard(
                    data: viewModel.ftpTrendData,
                    timeRange: viewModel.selectedTimeRange
                )
                
                // Training Load Section
                sectionHeader(
                    title: "Training Load",
                    icon: "chart.bar.fill",
                    color: .workout.tss
                )
                
                WeeklyTSSTrendCard(
                    data: viewModel.weeklyTSSData,
                    timeRange: viewModel.selectedTimeRange
                )
                
                // Performance Correlations Section
                sectionHeader(
                    title: "Performance Insights",
                    icon: "star.fill",
                    color: .yellow
                )
                
                RecoveryVsPowerCard(
                    data: viewModel.recoveryVsPowerData,
                    correlation: viewModel.recoveryVsPowerCorrelation,
                    timeRange: viewModel.selectedTimeRange
                )
                
                // Advanced Analytics Section
                sectionHeader(
                    title: "Advanced Analytics",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                TrainingPhaseCard(
                    phase: viewModel.currentTrainingPhase
                )
                
                OvertrainingRiskCard(
                    risk: viewModel.overtrainingRisk
                )
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .font(.title)
                .foregroundColor(.text.primary)
            
            Spacer()
        }
    }
    
    // MARK: - Pro Gate
    
    private var proGate: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.gradient.proIcon.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: Icons.DataSource.intervalsICU)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.gradient.proIcon)
            }
            
            // Title
            Text(TrendsContent.unlockTrends)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.text.primary)
                .multilineTextAlignment(.center)
            
            // Description
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureBullet(
                    text: "Track FTP evolution over time"
                )
                
                FeatureBullet(
                    text: "Monitor recovery and HRV trends"
                )
                
                FeatureBullet(
                    text: "Analyze weekly training load patterns"
                )
                
                FeatureBullet(
                    text: "Discover how recovery affects your power output"
                )
                
                FeatureBullet(
                    text: "See correlations no other app can show"
                )
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            // Upgrade Button
            Button(action: { showPaywall = true }) {
                HStack {
                    Image(systemName: Icons.System.star)
                    Text(TrendsContent.upgradeToPro)
                }
                .font(.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(Color.gradient.pro)
                .cornerRadius(Spacing.buttonCornerRadius)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .padding(Spacing.lg)
        .background(Color.background.primary)
    }
}

// MARK: - Supporting Views

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .metricLabel()
            
            Text(value)
                .font(.heading)
                .foregroundColor(color)
        }
    }
}

private struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(TrendsContent.bulletPoint)
                .font(.body)
                .foregroundColor(.text.primary)
                .frame(width: 12)
            
            Text(text)
                .font(.body)
                .foregroundColor(.text.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Trends - PRO") {
    TrendsView()
        .onAppear {
            ProFeatureConfig.shared.isProUser = true
        }
}

#Preview("Trends - Free") {
    TrendsView()
        .onAppear {
            ProFeatureConfig.shared.isProUser = false
            ProFeatureConfig.shared.isInTrialPeriod = false
        }
}
