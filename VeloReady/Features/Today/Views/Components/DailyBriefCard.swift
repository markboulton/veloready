import SwiftUI

/// Daily Brief card for free users - static, computed version (not AI-generated)
/// Shows TSB, Target TSS, and recovery status based on current metrics
struct DailyBriefCard: View {
    @StateObject private var recoveryScoreService = RecoveryScoreService.shared
    @StateObject private var strainScoreService = StrainScoreService.shared
    @StateObject private var profileManager = AthleteProfileManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: Icons.System.docText)
                    .foregroundStyle(Color.text.secondary)
                    .font(.system(size: 16))
                
                Text(DailyBriefContent.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.text.primary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
            
            // Divider
            Divider()
                .padding(.horizontal, Spacing.md)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Recovery Status
                if let recoveryScore = recoveryScoreService.currentRecoveryScore {
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(recoveryColor(recoveryScore.score))
                            .frame(width: 8, height: 8)
                        
                        Text(recoveryMessage(recoveryScore.score))
                            .font(.subheadline)
                            .foregroundStyle(Color.text.primary)
                    }
                }
                
                // Training Stress Balance
                if let recoveryScore = recoveryScoreService.currentRecoveryScore,
                   let ctl = recoveryScore.inputs.ctl,
                   let atl = recoveryScore.inputs.atl {
                    let tsb = ctl - atl
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DailyBriefContent.trainingStressBalance)
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", tsb))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(tsbColor(tsb))
                            
                            Text(tsbLabel(tsb))
                                .font(.caption)
                                .foregroundStyle(Color.text.secondary)
                        }
                    }
                }
                
                // Target TSS
                if let recoveryScore = recoveryScoreService.currentRecoveryScore {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DailyBriefContent.recommendedTraining)
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                        
                        Text(trainingRecommendation(recoveryScore.score))
                            .font(.subheadline)
                            .foregroundStyle(Color.text.primary)
                    }
                }
                
                // Upgrade prompt
                HStack(spacing: Spacing.xs) {
                    Image(systemName: Icons.System.sparkles)
                        .font(.caption)
                        .foregroundStyle(ColorScale.blueAccent)
                    
                    Text(DailyBriefContent.upgradePrompt)
                        .font(.caption)
                        .foregroundStyle(Color.text.secondary)
                }
                .padding(.top, Spacing.xs)
            }
            .padding(Spacing.md)
        }
        .background(Color.background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func recoveryColor(_ score: Int) -> Color {
        if score >= 80 {
            return ColorScale.greenAccent
        } else if score >= 60 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.redAccent
        }
    }
    
    private func recoveryMessage(_ score: Int) -> String {
        if score >= 80 {
            return DailyBriefContent.Recovery.optimal
        } else if score >= 60 {
            return DailyBriefContent.Recovery.moderate
        } else {
            return DailyBriefContent.Recovery.low
        }
    }
    
    private func tsbColor(_ tsb: Double) -> Color {
        if tsb < -10 {
            return ColorScale.redAccent // Fatigued
        } else if tsb < 5 {
            return ColorScale.greenAccent // Optimal
        } else if tsb < 15 {
            return ColorScale.amberAccent // Fresh
        } else {
            return ColorScale.blueAccent // Very fresh / detraining
        }
    }
    
    private func tsbLabel(_ tsb: Double) -> String {
        if tsb < -10 {
            return DailyBriefContent.TSB.fatigued
        } else if tsb < 5 {
            return DailyBriefContent.TSB.optimal
        } else if tsb < 15 {
            return DailyBriefContent.TSB.fresh
        } else {
            return DailyBriefContent.TSB.veryFresh
        }
    }
    
    private func trainingRecommendation(_ recoveryScore: Int) -> String {
        if recoveryScore >= 80 {
            return DailyBriefContent.TrainingRecommendation.highIntensity
        } else if recoveryScore >= 60 {
            return DailyBriefContent.TrainingRecommendation.moderate
        } else {
            return DailyBriefContent.TrainingRecommendation.easy
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        DailyBriefCard()
    }
    .padding()
    .background(Color.background.secondary)
}
