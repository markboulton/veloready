import SwiftUI

#if DEBUG
/// Debug view for HealthKit and score recalculation
struct DebugHealthView: View {
    @State private var isRefreshingRecovery = false
    @State private var isRefreshingStrain = false
    @State private var isRefreshingSleep = false
    @State private var refreshSuccess = false
    
    var body: some View {
        Form {
            scoreRecalculationSection
            onboardingSection
        }
        .navigationTitle("Health")
    }
    
    // MARK: - Score Recalculation Section
    
    private var scoreRecalculationSection: some View {
        Section {
            // Force Recalculate Recovery
            Button(action: {
                Task {
                    isRefreshingRecovery = true
                    await RecoveryScoreService.shared.forceRefreshRecoveryScoreIgnoringDailyLimit()
                    refreshSuccess = true
                    isRefreshingRecovery = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    if isRefreshingRecovery {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: Icons.Health.heart)
                    }
                    VRText("Force Recalculate Recovery", style: .body)
                    Spacer()
                    if refreshSuccess && !isRefreshingRecovery {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorScale.amberAccent)
            .disabled(isRefreshingRecovery)
            
            // Force Recalculate Strain
            Button(action: {
                Task {
                    isRefreshingStrain = true
                    await StrainScoreService.shared.calculateStrainScore()
                    refreshSuccess = true
                    isRefreshingStrain = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    if isRefreshingStrain {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: Icons.Health.calories)
                    }
                    VRText("Force Recalculate Strain/Load", style: .body)
                    Spacer()
                    if refreshSuccess && !isRefreshingStrain {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorScale.blueAccent)
            .disabled(isRefreshingStrain)
            
            // Force Recalculate Sleep
            Button(action: {
                Task {
                    isRefreshingSleep = true
                    await SleepScoreService.shared.calculateSleepScore()
                    refreshSuccess = true
                    isRefreshingSleep = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    if isRefreshingSleep {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: Icons.Health.sleepFill)
                    }
                    VRText("Force Recalculate Sleep", style: .body)
                    Spacer()
                    if refreshSuccess && !isRefreshingSleep {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorScale.purpleAccent)
            .disabled(isRefreshingSleep)
            
            // Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    "These buttons ignore the daily calculation limit and force immediate recalculation using the latest HealthKit data.",
                    style: .caption,
                    color: .secondary
                )
                
                VRText(
                    "Useful for testing HealthKit-only mode without Intervals.icu connection.",
                    style: .caption,
                    color: ColorScale.blueAccent
                )
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Label("Score Recalculation", systemImage: Icons.Arrow.triangleCirclePath)
        } footer: {
            VRText(
                "Force recalculation bypasses the once-per-day limit. Perfect for testing HealthKit-only mode and algorithm changes.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Onboarding Section
    
    private var onboardingSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Onboarding Status", style: .body)
                    
                    VRText(
                        OnboardingManager.shared.hasCompletedOnboarding ? "Completed" : "Not Completed",
                        style: .caption,
                        color: OnboardingManager.shared.hasCompletedOnboarding ? ColorScale.greenAccent : .secondary
                    )
                }
                
                Spacer()
                
                if OnboardingManager.shared.hasCompletedOnboarding {
                    VRBadge("Done", style: .success)
                }
            }
            
            Button(action: {
                OnboardingManager.shared.resetOnboarding()
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Arrow.counterclockwise)
                    VRText("Reset Onboarding", style: .body)
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorScale.blueAccent)
        } header: {
            Label("Onboarding", systemImage: Icons.Status.successFill)
        } footer: {
            VRText(
                "Reset onboarding flow to test the first-time user experience.",
                style: .caption,
                color: .secondary
            )
        }
    }
}

#Preview {
    NavigationStack {
        DebugHealthView()
    }
}
#endif
