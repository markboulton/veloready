import SwiftUI
import HealthKit

/// In-app HealthKit permissions sheet
/// Provides a better UX than redirecting to Settings
struct HealthKitPermissionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequesting = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // Header
                    VStack(spacing: Spacing.xl) {
                        Image(systemName: Icons.Health.heartFill)
                            .font(.system(size: 80))
                            .foregroundColor(Color.health.heartRate)
                        
                        Text(TodayContent.HealthKit.enableTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(TodayContent.HealthKit.description)
                            .font(.body)
                            .foregroundColor(ColorPalette.labelSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    
                    // What we track
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(TodayContent.HealthKit.weAccess)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HealthKitDataRow(icon: "moon.fill", title: TodayContent.HealthKit.sleepAnalysis, color: Color.health.sleep)
                        HealthKitDataRow(icon: "heart.fill", title: TodayContent.HealthKit.hrv, color: Color.health.hrv)
                        HealthKitDataRow(icon: "heart.circle.fill", title: TodayContent.HealthKit.restingHR, color: Color.health.heartRate)
                        HealthKitDataRow(icon: "lungs.fill", title: TodayContent.HealthKit.respiratoryRate, color: Color.health.respiratory)
                        HealthKitDataRow(icon: "figure.walk", title: TodayContent.HealthKit.stepsActivity, color: Color.health.activity)
                    }
                    .padding(Spacing.lg)
                    .background(Color.background.secondary)
                    .cornerRadius(Spacing.md)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(TodayContent.HealthKit.whatYouGet)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        BenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: TodayContent.HealthKit.recoveryScoreTitle,
                            description: TodayContent.HealthKit.recoveryScoreDesc
                        )
                        
                        BenefitRow(
                            icon: "moon.stars.fill",
                            title: TodayContent.HealthKit.sleepAnalysisTitle,
                            description: TodayContent.HealthKit.sleepAnalysisDesc
                        )
                        
                        BenefitRow(
                            icon: "figure.strengthtraining.traditional",
                            title: TodayContent.HealthKit.trainingLoadTitle,
                            description: TodayContent.HealthKit.trainingLoadDesc
                        )
                    }
                    .padding(Spacing.lg)
                    .background(Color.background.secondary)
                    .cornerRadius(Spacing.md)
                    
                    Spacer(minLength: 20)
                    
                    // Action buttons
                    VStack(spacing: Spacing.md) {
                        // Enable button
                        Button(action: requestPermissions) {
                            HStack(spacing: Spacing.sm) {
                                if isRequesting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: Icons.Health.heartFill)
                                }
                                
                                Text(isRequesting ? TodayContent.HealthKit.enabling : TodayContent.HealthKit.enableButton)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.lg)
                            .background(Color.button.danger)
                            .foregroundColor(ColorPalette.labelPrimary)
                            .cornerRadius(Spacing.md)
                        }
                        .disabled(isRequesting)
                        
                        // Skip button
                        Button(TodayContent.HealthKit.skipButton) {
                            dismiss()
                        }
                        .foregroundColor(ColorPalette.labelSecondary)
                        
                        Text(TodayContent.HealthKit.privacyNote)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle(TodayContent.HealthKit.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(TodayContent.HealthKit.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .alert(TodayContent.HealthKit.authorizationTitle, isPresented: $showingSuccessAlert) {
            if healthKitManager.isAuthorized {
                Button(TodayContent.HealthKit.ok) {
                    dismiss()
                }
            } else {
                Button(TodayContent.HealthKit.openSettings) {
                    healthKitManager.openSettings()
                    dismiss()
                }
                Button(CommonContent.cancel, role: .cancel) {
                    dismiss()
                }
            }
        } message: {
            if healthKitManager.isAuthorized {
                Text(TodayContent.HealthKit.successMessage)
            } else {
                Text(TodayContent.HealthKit.instructionsMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() {
        isRequesting = true
        
        Task {
            // Always try the native authorization first
            await healthKitManager.requestAuthorization()
            
            // Small delay to let iOS process
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isRequesting = false
                showingSuccessAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct HealthKitDataRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.button.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(TypeScale.font(size: TypeScale.xs))
                    .foregroundColor(ColorPalette.labelSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct HealthKitPermissionsSheet_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsSheet()
    }
}
