import SwiftUI

/// Recovery metrics section showing Recovery, Sleep, and Load scores
struct RecoveryMetricsSection: View {
    @ObservedObject var recoveryScoreService: RecoveryScoreService
    @ObservedObject var sleepScoreService: SleepScoreService
    @ObservedObject var strainScoreService: StrainScoreService
    let isHealthKitAuthorized: Bool
    @Binding var missingSleepBannerDismissed: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show empty state rings when HealthKit is not authorized
            if !isHealthKitAuthorized {
                HStack(spacing: 12) {
                    // Recovery (left)
                    EmptyStateRingView(
                        title: "Recovery",
                        icon: "heart.fill",
                        animationDelay: 0.0
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Sleep (center)
                    EmptyStateRingView(
                        title: "Sleep",
                        icon: "moon.fill",
                        animationDelay: 0.1
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Load (right)
                    EmptyStateRingView(
                        title: "Load",
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recovery Score
    
    private var recoveryScoreView: some View {
        Group {
            if let recoveryScore = recoveryScoreService.currentRecoveryScore {
                NavigationLink(destination: RecoveryDetailView(recoveryScore: recoveryScore)) {
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.recoveryScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Show "Limited Data" label if sleep data is missing
                        let title = recoveryScore.inputs.sleepDuration == nil
                            ? "Limited Data"
                            : recoveryScore.bandDescription
                        
                        CompactRingView(
                            score: recoveryScore.score,
                            title: title,
                            band: recoveryScore.band,
                            animationDelay: 0.0
                        ) {
                            // Empty action - navigation handled by parent NavigationLink
                        }
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
                                title: missingSleepBannerDismissed ? "No Data ⓘ" : "No Data",
                                band: SleepScore.SleepBand.poor,
                                animationDelay: 0.1
                            ) {
                                // Action handled by button wrapper
                            }
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
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            CompactRingView(
                                score: sleepScore.score,
                                title: sleepScore.bandDescription,
                                band: sleepScore.band,
                                animationDelay: 0.1
                            ) {
                                // Empty action - navigation handled by parent NavigationLink
                            }
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
                            Image(systemName: "chevron.right")
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
                            title: missingSleepBannerDismissed ? "No Data ⓘ" : "No Data",
                            band: SleepScore.SleepBand.poor,
                            animationDelay: 0.1
                        ) {
                            // Action handled by button wrapper
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Load Score
    
    private var loadScoreView: some View {
        Group {
            if let strainScore = strainScoreService.currentStrainScore {
                NavigationLink(destination: StrainDetailView(strainScore: strainScore)) {
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(TodayContent.Scores.strainScore)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Convert 0-18 score to 0-100 for ring display
                        let ringScore = Int((strainScore.score / 18.0) * 100.0)
                        CompactRingView(
                            score: ringScore,
                            title: strainScore.formattedScore,
                            band: strainScore.band,
                            animationDelay: 0.2
                        ) {
                            // Empty action - navigation handled by parent NavigationLink
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 12) {
                    Text(TodayContent.Scores.strainScore)
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
}

// MARK: - Preview

struct RecoveryMetricsSection_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryMetricsSection(
            recoveryScoreService: RecoveryScoreService.shared,
            sleepScoreService: SleepScoreService.shared,
            strainScoreService: StrainScoreService.shared,
            isHealthKitAuthorized: true,
            missingSleepBannerDismissed: .constant(false)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
