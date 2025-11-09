import SwiftUI

/// Step 3: Apple Health permissions
struct HealthKitStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequesting = false
    @State private var isCheckingPermissions = true
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: Icons.Health.heartFill)
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
                
                Text(OnboardingContent.AppleHealth.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(OnboardingContent.AppleHealth.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // What we need
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(OnboardingContent.AppleHealth.wellAccess)
                    .font(.headline)
                    .padding(.horizontal, 32)
                
                HealthKitPermissionRow(icon: "waveform.path.ecg", text: "Heart Rate Variability (HRV)")
                HealthKitPermissionRow(icon: "heart.circle", text: "Resting Heart Rate")
                HealthKitPermissionRow(icon: "moon.stars", text: "Sleep Analysis")
                HealthKitPermissionRow(icon: "figure.walk", text: "Workouts")
            }
            .padding(.vertical)
            
            Spacer()
            
            // Buttons
            VStack(spacing: Spacing.lg) {
                if healthKitManager.isAuthorized {
                    // Already authorized
                    HStack {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(.green)
                        Text(OnboardingContent.AppleHealth.connected)
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    
                    Button(action: {
                        onboardingManager.hasConnectedHealthKit = true
                        onboardingManager.nextStep()
                    }) {
                        Text(OnboardingContent.AppleHealth.continueButton)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorScale.blueAccent)
                            .cornerRadius(16)
                    }
                } else {
                    // Request permission
                    Button(action: {
                        print("🔵 [ONBOARDING] Grant Access button tapped")
                        print("🔵 [ONBOARDING] healthKitManager instance: \(ObjectIdentifier(healthKitManager))")
                        print("🔵 [ONBOARDING] Starting authorization request...")
                        Task {
                            isRequesting = true
                            print("🔵 [ONBOARDING] About to call healthKitManager.requestAuthorization()")
                            await healthKitManager.requestAuthorization()
                            print("🔵 [ONBOARDING] Returned from requestAuthorization()")
                            print("🔵 [ONBOARDING] healthKitManager.isAuthorized: \(healthKitManager.isAuthorized)")
                            isRequesting = false
                            
                            if healthKitManager.isAuthorized {
                                print("🔵 [ONBOARDING] Setting hasConnectedHealthKit = true")
                                onboardingManager.hasConnectedHealthKit = true
                            } else {
                                print("🔵 [ONBOARDING] Authorization failed or denied")
                            }
                        }
                    }) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isRequesting ? "Requesting..." : "Grant Access")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorScale.blueAccent)
                        .cornerRadius(16)
                    }
                    .disabled(isRequesting)
                    
                    // Skip button
                    Button(action: {
                        onboardingManager.skipStep()
                    }) {
                        Text(OnboardingContent.AppleHealth.doLater)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            print("🔵 [ONBOARDING] HealthKitStepView appeared - checking permissions...")
            Task {
                // Check current authorization status using the iOS 26 workaround
                await healthKitManager.checkAuthorizationAfterSettingsReturn()
                isCheckingPermissions = false
                print("🔵 [ONBOARDING] Permission check complete - isAuthorized: \(healthKitManager.isAuthorized)")
            }
        }
    }
}

/// Permission row component
struct HealthKitPermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

struct HealthKitStepView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitStepView()
    }
}
