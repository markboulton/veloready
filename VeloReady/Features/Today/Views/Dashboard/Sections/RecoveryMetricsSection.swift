import SwiftUI

/// Recovery metrics section showing Recovery, Sleep, and Load scores with MVVM
/// ViewModel handles all score state management and calculations
struct RecoveryMetricsSection: View {
    @StateObject private var viewModel = RecoveryMetricsSectionViewModel()
    let isHealthKitAuthorized: Bool
    let animationTrigger: UUID // Triggers animations on change
    var hideBottomDivider: Bool = false
    
    // Binding for parent view coordination
    var missingSleepBannerDismissed: Binding<Bool> {
        Binding(
            get: { viewModel.missingSleepBannerDismissed },
            set: { viewModel.missingSleepBannerDismissed = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Transparent background to match StandardCard structure but without the grey
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
            
            VStack(alignment: .leading, spacing: 0) {
                // Show empty state rings when HealthKit is not authorized
                if !isHealthKitAuthorized {
                    HStack(spacing: Spacing.lg) {
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
                    HStack(spacing: Spacing.lg) {
                        recoveryScoreView
                        sleepScoreView
                        loadScoreView
                    }
                }
            }
            .padding(Spacing.md)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxl / 2)
    }
    
    // MARK: - Recovery Score
    
    @ViewBuilder
    private var recoveryScoreView: some View {
            if let recoveryScore = viewModel.recoveryScore {
                HapticNavigationLink(destination: RecoveryDetailView(recoveryScore: recoveryScore)) {
                    VStack(spacing: 12) {
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
                            animationTrigger: animationTrigger
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    Text(TodayContent.Scores.recoveryScore)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(CommonContent.loading)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, height: 80)
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
                    VStack(spacing: 12) {
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
                        VStack(spacing: 12) {
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
                // No sleep data available - make entire ring tappable to reinstate banner
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
            }
        }
    }
    
    // MARK: - Load Score
    
    @ViewBuilder
    private var loadScoreView: some View {
            if viewModel.hasStrainScore {
                HapticNavigationLink(destination: StrainDetailView(strainScore: viewModel.strainScore!)) {
                    VStack(spacing: 12) {
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
                VStack(spacing: 12) {
                    Text(TodayContent.Scores.loadScore)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(CommonContent.loading)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, height: 80)
                }
                .frame(maxWidth: .infinity)
            }
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
