import SwiftUI
import HealthKit

struct HealthPermissionsView: View {
    let onAuthorized: () -> Void
    
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequesting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: Icons.Health.heart)
                        .font(.system(size: 80))
                        .foregroundColor(Color.health.heartRate)
                    
                    Text(OnboardingContent.HealthPermissions.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(OnboardingContent.HealthPermissions.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // What we track
                VStack(alignment: .leading, spacing: 16) {
                    Text(OnboardingContent.HealthPermissions.required)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HealthDataRow(icon: Icons.Health.sleep, title: "Sleep Analysis", color: Color.health.sleep)
                    HealthDataRow(icon: Icons.Health.hrv, title: "Heart Rate Variability", color: Color.health.hrv)
                    HealthDataRow(icon: Icons.Health.heartRate, title: "Resting Heart Rate", color: Color.health.heartRate)
                    HealthDataRow(icon: Icons.Health.respiratory, title: "Respiratory Rate", color: Color.health.respiratory)
                    HealthDataRow(icon: "figure.walk", title: "Steps & Activity", color: Color.health.activity)
                }
                .padding()
                .background(Color.background.secondary)
                .cornerRadius(12)
                
                Spacer()
                
                // Status message
                if healthKitManager.authorizationState != .notDetermined {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if healthKitManager.isAuthorized {
                        Button(OnboardingContent.HealthPermissions.continueButton) {
                            onAuthorized()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Button(action: requestPermissions) {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(OnboardingContent.HealthPermissions.grantAccess)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isRequesting)
                        
                        Button(OnboardingContent.HealthPermissions.skipForNow) {
                            onAuthorized()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                
                Text(OnboardingContent.WhatVeloReady.privacyNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusMessage: String {
        switch healthKitManager.authorizationState {
        case .authorized:
            return "✓ Health data access granted"
        case .denied:
            return "Health access was denied. You can enable it in Settings → Privacy → Health → VeloReady"
        case .partial:
            return "Some permissions were granted. You can update them in Settings."
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notDetermined:
            return ""
        }
    }
    
    private var statusColor: Color {
        switch healthKitManager.authorizationState {
        case .authorized:
            return Color.semantic.success
        case .denied, .notAvailable:
            return Color.semantic.error
        case .partial:
            return Color.semantic.warning
        case .notDetermined:
            return .secondary
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() {
        isRequesting = true
        
        Task {
            await healthKitManager.requestAuthorization()
            
            // Small delay to let iOS process
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isRequesting = false
                
                // Auto-continue if authorized
                if healthKitManager.isAuthorized {
                    onAuthorized()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct HealthDataRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: Icons.Status.successFill)
                .foregroundColor(Color.semantic.success)
                .font(.caption)
        }
    }
}

// MARK: - Previews

struct HealthPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthPermissionsView(onAuthorized: {})
    }
}
