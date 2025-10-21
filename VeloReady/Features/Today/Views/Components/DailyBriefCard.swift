import SwiftUI

/// Daily Brief card for free users - static, computed version (not AI-generated)
/// Shows TSB, Target TSS, and recovery status based on current metrics
/// MATCHES AIBriefView structure exactly
struct DailyBriefCard: View {
    @StateObject private var recoveryScoreService = RecoveryScoreService.shared
    @StateObject private var strainScoreService = StrainScoreService.shared
    @StateObject private var profileManager = AthleteProfileManager.shared
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (matches AIBriefView exactly)
            HStack(spacing: 8) {
                Image(systemName: Icons.System.docText)
                    .font(.heading)
                    .foregroundColor(Color.text.secondary)
                
                Text(DailyBriefContent.title)
                    .font(.heading)
                    .foregroundColor(Color.text.primary)
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Content (matches AIBriefView structure)
            VStack(alignment: .leading, spacing: 12) {
                // Main brief text (computed from recovery data)
                Text(generateBriefText())
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                
                // Training Metrics (matches AIBriefView)
                TrainingMetricsView()
                
                // Upgrade prompt button
                Button(action: {
                    showingUpgradeSheet = true
                }) {
                    Text(DailyBriefContent.upgradePrompt)
                        .font(.subheadline)
                        .foregroundColor(ColorScale.blueAccent)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Section divider (matches AIBriefView exactly)
            SectionDivider(bottomPadding: 0)
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            PaywallView()
        }
    }
    
    // MARK: - Brief Text Generation
    
    private func generateBriefText() -> String {
        guard let recoveryScore = recoveryScoreService.currentRecoveryScore else {
            return "Calculating your daily brief..."
        }
        
        var brief = recoveryMessage(recoveryScore.score)
        
        // Add TSB info if available
        if let ctl = recoveryScore.inputs.ctl,
           let atl = recoveryScore.inputs.atl {
            let tsb = ctl - atl
            brief += " Your training stress balance is \(tsbLabel(tsb).lowercased()) (\(String(format: "%.0f", tsb))). "
        }
        
        // Add training recommendation
        brief += trainingRecommendation(recoveryScore.score) + "."
        
        return brief
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
