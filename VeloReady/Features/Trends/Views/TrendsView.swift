import SwiftUI

/// Main Trends view - PRO feature
/// Shows performance and health trends over time
struct TrendsView: View {
    @ObservedObject private var viewState = TrendsViewState.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive background (light grey in light mode, black in dark mode)
                Color.background.app
                    .ignoresSafeArea()

                Group {
                    if proConfig.hasProAccess {
                        trendsContent
                    } else {
                        proGate
                    }
                }

                // Navigation gradient mask (iOS Mail style)
                NavigationGradientMask()
            }
            .navigationTitle(TrendsContent.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                // Fix critical bug: Load data when view appears
                await viewState.load()
            }
        }
    }
    
    // MARK: - Trends Content
    
    private var trendsContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Time range picker
                timeRangePicker

                // Quick stats summary
                quickStats

                // All trend cards
                trendCards
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, 120)
        }
        .refreshable {
            await viewState.refresh()
        }
    }
    
    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $viewState.selectedTimeRange) {
            ForEach(TrendsViewState.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewState.selectedTimeRange) { _, newRange in
            Task {
                await viewState.changeTimeRange(newRange)
            }
        }
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
                    if oauthManager.isAuthenticated, let ftp = viewState.fitnessData?.ftp.last?.value {
                        StatPill(
                            label: "Current FTP",
                            value: "\(Int(ftp))W",
                            color: .workout.power
                        )
                    }

                    // Always show recovery (HealthKit-based)
                    if let recovery = viewState.scoresData?.recovery, !recovery.isEmpty {
                        let avg = recovery.map(\.value).reduce(0, +) / Double(recovery.count)
                        StatPill(
                            label: "Avg Recovery",
                            value: "\(Int(avg))%",
                            color: .health.hrv
                        )
                    }

                    // Show TSS only when Intervals connected (cycling-specific)
                    if oauthManager.isAuthenticated, let weeklyTSS = viewState.fitnessData?.weeklyTSS, !weeklyTSS.isEmpty {
                        let avg = weeklyTSS.map(\.tss).reduce(0, +) / Double(weeklyTSS.count)
                        StatPill(
                            label: "Avg Weekly TSS",
                            value: "\(Int(avg))",
                            color: .workout.tss
                        )
                    }

                    // Show HRV for HealthKit-only mode
                    if !oauthManager.isAuthenticated, let hrv = viewState.scoresData?.hrv, !hrv.isEmpty {
                        let avg = hrv.map(\.value).reduce(0, +) / Double(hrv.count)
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
        VStack(spacing: Spacing.xs) {
            // Illness Alert (if present)
            IllnessAlertBanner()

            // Recovery & Readiness Section (Always visible - HealthKit-based)
            sectionHeader(
                title: "Recovery & Readiness",
                icon: "heart.fill",
                color: .health.heartRate
            )

            RecoveryTrendCardV2(
                data: viewState.scoresData?.recovery ?? [],
                timeRange: viewState.selectedTimeRange
            )

            HRVTrendCardV2(
                data: viewState.scoresData?.hrv ?? [],
                timeRange: viewState.selectedTimeRange
            )

            RestingHRCardV2(
                data: viewState.scoresData?.restingHR ?? [],
                timeRange: viewState.selectedTimeRange
            )

            StressLevelCardV2(
                data: viewState.scoresData?.stress ?? [],
                timeRange: viewState.selectedTimeRange
            )
            
            // Cycling-specific sections (only when Intervals connected)
            if oauthManager.isAuthenticated {
                // Performance Overview with TSS
                sectionHeader(
                    title: "Performance Overview",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .chart.primary
                )

                PerformanceOverviewCardV2(
                    recoveryData: viewState.scoresData?.recovery ?? [],
                    loadData: viewState.fitnessData?.dailyLoad ?? [],
                    sleepData: viewState.scoresData?.sleep ?? [],
                    timeRange: viewState.selectedTimeRange
                )

                TrainingLoadTrendCardV2(
                    data: viewState.fitnessData?.dailyLoad ?? [],
                    timeRange: viewState.selectedTimeRange
                )

                // Form & Fitness Section
                sectionHeader(
                    title: "Form & Fitness",
                    icon: "bolt.fill",
                    color: .workout.power
                )

                FTPTrendCardV2(
                    data: viewState.fitnessData?.ftp ?? [],
                    timeRange: viewState.selectedTimeRange
                )

                // Training Load Section
                sectionHeader(
                    title: "Training Load",
                    icon: "chart.bar.fill",
                    color: .workout.tss
                )

                WeeklyTSSTrendCardV2(
                    data: viewState.fitnessData?.weeklyTSS ?? [],
                    timeRange: viewState.selectedTimeRange
                )
                
                // Performance Correlations Section
                sectionHeader(
                    title: "Performance Insights",
                    icon: "star.fill",
                    color: .yellow
                )

                RecoveryVsPowerCardV2(
                    data: viewState.analyticsData?.recoveryVsPower ?? [],
                    correlation: viewState.analyticsData?.recoveryVsPowerCorrelation,
                    timeRange: viewState.selectedTimeRange
                )

                // Advanced Analytics Section
                sectionHeader(
                    title: "Advanced Analytics",
                    icon: "brain.head.profile",
                    color: .purple
                )

                TrainingPhaseCardV2(
                    phase: viewState.analyticsData?.trainingPhase
                )

                OvertrainingRiskCardV2(
                    risk: viewState.analyticsData?.overtrainingRisk
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
