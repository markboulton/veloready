import SwiftUI

/// Recovery metrics section showing Recovery, Sleep, and Load scores
struct RecoveryMetricsSection: View {
    @ObservedObject var recoveryScoreService: RecoveryScoreService
    @ObservedObject var sleepScoreService: SleepScoreService
    @ObservedObject var strainScoreService: StrainScoreService
    let isHealthKitAuthorized: Bool
    @Binding var missingSleepBannerDismissed: Bool
    let animationTrigger: UUID // Triggers animations on change
    var hideBottomDivider: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show empty state rings when HealthKit is not authorized
            if !isHealthKitAuthorized {
                HStack(spacing: 12) {
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
                HStack(spacing: 12) {
                    recoveryScoreView
                    sleepScoreView
                    loadScoreView
                }
            }
            
            if !hideBottomDivider {
                SectionDivider()
            }
        }
    }
    
    // MARK: - Recovery Score
    
    @ViewBuilder
    private var recoveryScoreView: some View {
            if let recoveryScore = recoveryScoreService.currentRecoveryScore {
                NavigationLink(destination: RecoveryDetailView(recoveryScore: recoveryScore)) {
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.recoveryScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                        
                        // Show "Limited Data" label if sleep data is missing
                        let title = recoveryScore.inputs.sleepDuration == nil
                            ? TodayContent.limitedData
                            : recoveryScore.bandDescription
                        
                        CompactRingView(
                            score: recoveryScore.score,
                            title: title,
                            band: recoveryScore.band,
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
                .buttonStyle(PlainButtonStyle())
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
            if let sleepScore = sleepScoreService.currentSleepScore {
                // Show ? if no sleep data
                if sleepScore.inputs.sleepDuration == nil || sleepScore.inputs.sleepDuration == 0 {
                    // No NavigationLink when no data - make entire ring tappable to reinstate banner
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.sleepScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            // No chevron when sleep data is missing
                        }
                        
                        Button(action: {
                            if missingSleepBannerDismissed {
                                missingSleepBannerDismissed = false
                                UserDefaults.standard.set(false, forKey: "missingSleepBannerDismissed")
                            }
                        }) {
                            CompactRingView(
                                score: nil,
                                title: missingSleepBannerDismissed ? TodayContent.noDataInfo : TodayContent.noData,
                                band: SleepScore.SleepBand.payAttention,
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
                    // Normal NavigationLink when we have sleep data
                    NavigationLink(destination: SleepDetailView(sleepScore: sleepScore)) {
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
                                score: sleepScore.score,
                                title: sleepScore.bandDescription,
                                band: sleepScore.band,
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
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // No sleep data available - make entire ring tappable to reinstate banner
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(TodayContent.Scores.sleepScore)
                            .font(.headline)
                            .fontWeight(.semibold)
                        if !missingSleepBannerDismissed {
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        if missingSleepBannerDismissed {
                            missingSleepBannerDismissed = false
                            UserDefaults.standard.set(false, forKey: "missingSleepBannerDismissed")
                        }
                    }) {
                        CompactRingView(
                            score: nil,
                            title: missingSleepBannerDismissed ? TodayContent.noDataInfo : TodayContent.noData,
                            band: SleepScore.SleepBand.payAttention,
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
            if let strainScore = strainScoreService.currentStrainScore {
                NavigationLink(destination: StrainDetailView(strainScore: strainScore)) {
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.loadScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: Icons.System.chevronRight)
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                        
                        // Convert 0-18 score to 0-100 for ring display
                        let ringScore = Int((strainScore.score / 18.0) * 100.0)
                        CompactRingView(
                            score: ringScore,
                            title: strainScore.bandDescription,
                            band: strainScore.band,
                            animationDelay: 0.2,
                            action: {
                                // Empty action - navigation handled by parent NavigationLink
                            },
                            centerText: strainScore.formattedScore,
                            animationTrigger: animationTrigger
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
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
            recoveryScoreService: RecoveryScoreService.shared,
            sleepScoreService: SleepScoreService.shared,
            strainScoreService: StrainScoreService.shared,
            isHealthKitAuthorized: true,
            missingSleepBannerDismissed: .constant(false),
            animationTrigger: UUID()
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
