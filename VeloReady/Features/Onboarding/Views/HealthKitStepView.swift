import SwiftUI

/// Step 3: Apple Health permissions
struct HealthKitStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
                
                Text("Apple Health")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("RideReady needs access to Apple Health to track your recovery metrics")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // What we need
            VStack(alignment: .leading, spacing: 16) {
                Text("We'll access:")
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
            VStack(spacing: 16) {
                if healthKitManager.isAuthorized {
                    // Already authorized
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Apple Health Connected")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    
                    Button(action: {
                        onboardingManager.hasConnectedHealthKit = true
                        onboardingManager.nextStep()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                } else {
                    // Request permission
                    Button(action: {
                        Task {
                            isRequesting = true
                            await healthKitManager.requestAuthorization()
                            isRequesting = false
                            
                            if healthKitManager.isAuthorized {
                                onboardingManager.hasConnectedHealthKit = true
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
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .disabled(isRequesting)
                    
                    // Skip button
                    Button(action: {
                        onboardingManager.skipStep()
                    }) {
                        Text("I'll Do This Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

/// Permission row component
struct HealthKitPermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
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
