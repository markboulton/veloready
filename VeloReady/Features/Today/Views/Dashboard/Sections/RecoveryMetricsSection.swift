import SwiftUI

/// Recovery metrics section showing Recovery, Sleep, and Load scores with MVVM
/// ViewModel handles all score state management and calculations
struct RecoveryMetricsSection: View {
    @StateObject private var viewModel = RecoveryMetricsSectionViewModel()
    let isHealthKitAuthorized: Bool
    let animationTrigger: UUID // Triggers animations on change
    var hideBottomDivider: Bool = false
    
    init(isHealthKitAuthorized: Bool, animationTrigger: UUID, hideBottomDivider: Bool = false) {
        self.isHealthKitAuthorized = isHealthKitAuthorized
        self.animationTrigger = animationTrigger
        self.hideBottomDivider = hideBottomDivider
        Logger.debug("📺 [VIEW] RecoveryMetricsSection INIT called")
    }
    
    // Binding for parent view coordination
    var missingSleepBannerDismissed: Binding<Bool> {
        Binding(
            get: { viewModel.missingSleepBannerDismissed },
            set: { viewModel.missingSleepBannerDismissed = $0 }
        )
    }
    
    var body: some View {
        let _ = Logger.debug("📺 [VIEW] RecoveryMetricsSection body evaluated - recovery: \(viewModel.recoveryScore?.score ?? -1), sleep: \(viewModel.sleepScore?.score ?? -1), strain: \(viewModel.strainScore?.score ?? -1)")
        
        ZStack {
            // Transparent background to match StandardCard structure but without the grey
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
            
            VStack(alignment: .leading, spacing: 0) {
                // Show empty state rings when HealthKit is not authorized
                if !isHealthKitAuthorized {
                    HStack(spacing: Spacing.xxl) {
                        // Recovery (left)
                        EmptyStateRingView(
                            title: TodayContent.recoverySection,
                            icon: "heart.fill",
                            animationDelay: 0.0
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Sleep (center)
                        EmptyStateRingView(
                            title: TodayContent.sleepSection,
                            icon: "moon.fill",
                            animationDelay: 0.1
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Load (right)
                        EmptyStateRingView(
                            title: TodayContent.loadSection,
                            icon: "figure.walk",
                            animationDelay: 0.2
                        )
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Show actual data when HealthKit is authorized
                    // Check if sleep data is available or simulated as unavailable
                    let config = ProFeatureConfig.shared
                    let showSleepRing = viewModel.hasSleepData && !config.simulateNoSleepData
                    
                    // Show loading state until all scores are ready
                    if !viewModel.allScoresReady {
                        // Loading state - show grey rings with shimmer for all three
                        HStack(spacing: Spacing.xxl) {
                            loadingRingView(title: TodayContent.Scores.recoveryScore, delay: 0.0)
                            loadingRingView(title: TodayContent.Scores.sleepScore, delay: 0.1)
                            loadingRingView(title: TodayContent.Scores.loadScore, delay: 0.2)
                        }
                    } else if showSleepRing {
                        // Standard 3-ring layout
                        HStack(spacing: Spacing.xxl) {
                            recoveryScoreView
                            sleepScoreView
                            loadScoreView
                        }
                    } else {
                        // 2-ring layout when sleep unavailable - centered as a group
                        HStack(spacing: Spacing.xxl) {
                            recoveryScoreView
                            loadScoreView
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Spacing.md)
        }
    }
    
    // MARK: - Recovery Score
    
    @ViewBuilder
    private var recoveryScoreView: some View {
            if let recoveryScore = viewModel.recoveryScore {
                HapticNavigationLink(destination: RecoveryDetailView(recoveryScore: recoveryScore)) {
                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.recoveryScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                        
                        CompactRingView(
                            score: viewModel.recoveryScoreValue,
                            title: viewModel.recoveryTitle,
                            band: viewModel.recoveryBand ?? .optimal,
                            animationDelay: 0.0,
                            action: {
                                // Empty action - navigation handled by parent NavigationLink
                            },
                            centerText: nil,
                            animationTrigger: animationTrigger,
                            isLoading: false
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    Text(TodayContent.Scores.recoveryScore)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Show grey ring with shimmer while loading (no spinner)
                    CompactRingView(
                        score: nil,
                        title: "",
                        band: RecoveryScore.RecoveryBand.optimal,
                        animationDelay: 0.0,
                        action: {},
                        centerText: nil,
                        animationTrigger: animationTrigger,
                        isLoading: true
                    )
                }
                .frame(maxWidth: .infinity)
            }
    }
    
    // MARK: - Sleep Score
    
    private var sleepScoreView: some View {
        Group {
            if let sleepScore = viewModel.sleepScore {
                // Show ? if no sleep data
                if !viewModel.hasSleepData {
                    // No NavigationLink when no data - make entire ring tappable to reinstate banner
                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.sleepScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            // No chevron when sleep data is missing
                        }
                        
                        Button(action: {
                            if viewModel.missingSleepBannerDismissed {
                                viewModel.reinstateSleepBanner()
                            }
                        }) {
                            CompactRingView(
                                score: nil,
                                title: viewModel.sleepTitle,
                                band: viewModel.sleepBand,
                                animationDelay: 0.1,
                                action: {
                                    // Action handled by button wrapper
                                },
                                centerText: nil,
                                animationTrigger: animationTrigger
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Normal HapticNavigationLink when we have sleep data
                    HapticNavigationLink(destination: SleepDetailView(sleepScore: sleepScore)) {
                        VStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Text(TodayContent.Scores.sleepScore)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Image(systemName: Icons.System.chevronRight)
                                    .font(.caption)
                                    .foregroundColor(Color.text.secondary)
                            }
                            
                            CompactRingView(
                                score: viewModel.sleepScoreValue,
                                title: viewModel.sleepTitle,
                                band: viewModel.sleepBand,
                                animationDelay: 0.1,
                                action: {
                                    // Empty action - navigation handled by parent NavigationLink
                                },
                                centerText: nil,
                                animationTrigger: animationTrigger
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // No sleep score calculated yet - show loading spinner or '?' if done loading
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(TodayContent.Scores.sleepScore)
                            .font(.headline)
                            .fontWeight(.semibold)
                        if viewModel.shouldShowSleepChevron {
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Show background ring with loading spinner or '?' when no data
                    ZStack(alignment: .center) {
                        Button(action: {
                            if viewModel.missingSleepBannerDismissed {
                                viewModel.reinstateSleepBanner()
                            }
                        }) {
                            CompactRingView(
                                score: nil,
                                title: "",
                                band: viewModel.sleepBand,
                                animationDelay: 0.1,
                                action: {
                                    // Action handled by button wrapper
                                },
                                centerText: nil,
                                animationTrigger: animationTrigger
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Show spinner when loading, '?' when done loading with no data
                        if viewModel.isSleepLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .offset(y: -8) // Offset to account for title below ring
                        } else {
                            // Show '?' when loading is done but no data available
                            Text("?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color.text.secondary)
                                .offset(y: -16)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Load Score
    
    @ViewBuilder
    private var loadScoreView: some View {
            if viewModel.hasStrainScore {
                HapticNavigationLink(destination: StrainDetailView(strainScore: viewModel.strainScore!)) {
                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.loadScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                        
                        CompactRingView(
                            score: viewModel.strainRingScore,
                            title: viewModel.strainTitle,
                            band: viewModel.strainBand ?? .moderate,
                            animationDelay: 0.2,
                            action: {
                                // Empty action - navigation handled by parent NavigationLink
                            },
                            centerText: viewModel.strainFormattedScore,
                            animationTrigger: animationTrigger
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    Text(TodayContent.Scores.loadScore)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Show grey ring with shimmer while loading (no spinner)
                    CompactRingView(
                        score: nil,
                        title: "",
                        band: StrainScore.StrainBand.moderate,
                        animationDelay: 0.2,
                        action: {},
                        centerText: nil,
                        animationTrigger: animationTrigger,
                        isLoading: true
                    )
                }
                .frame(maxWidth: .infinity)
            }
    }
    
    // MARK: - Loading Ring View
    
    @ViewBuilder
    private func loadingRingView(title: String, delay: Double) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            CompactRingView(
                score: nil,
                title: "",
                band: RecoveryScore.RecoveryBand.optimal,
                animationDelay: delay,
                action: {},
                centerText: nil,
                animationTrigger: animationTrigger,
                isLoading: true
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct RecoveryMetricsSection_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryMetricsSection(
            isHealthKitAuthorized: true,
            animationTrigger: UUID()
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
