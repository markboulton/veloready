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
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.health.heartRate)
                        
                        Text("Enable Health Data")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Connect your Apple Health data to see personalized recovery scores, sleep analysis, and training insights.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // What we track
                    VStack(alignment: .leading, spacing: 16) {
                        Text("We'll access:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HealthKitDataRow(icon: "moon.fill", title: "Sleep Analysis", color: Color.health.sleep)
                        HealthKitDataRow(icon: "heart.fill", title: "Heart Rate Variability", color: Color.health.hrv)
                        HealthKitDataRow(icon: "heart.circle.fill", title: "Resting Heart Rate", color: Color.health.heartRate)
                        HealthKitDataRow(icon: "lungs.fill", title: "Respiratory Rate", color: Color.health.respiratory)
                        HealthKitDataRow(icon: "figure.walk", title: "Steps & Activity", color: Color.health.activity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What you'll get:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        BenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Recovery Score",
                            description: "Track your readiness based on HRV, sleep, and training"
                        )
                        
                        BenefitRow(
                            icon: "moon.stars.fill",
                            title: "Sleep Analysis",
                            description: "Detailed sleep staging from Apple Watch"
                        )
                        
                        BenefitRow(
                            icon: "figure.strengthtraining.traditional",
                            title: "Training Load",
                            description: "Monitor daily strain and training stress"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 20)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Enable button
                        Button(action: requestPermissions) {
                            HStack(spacing: 12) {
                                if isRequesting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "heart.fill")
                                }
                                
                                Text(isRequesting ? "Enabling..." : "Enable Health Data")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.button.danger)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isRequesting)
                        
                        // Skip button
                        Button("Skip for now") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        
                        Text("Your health data stays private and secure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Health Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("HealthKit Authorization", isPresented: $showingSuccessAlert) {
            if healthKitManager.isAuthorized {
                Button("OK") {
                    dismiss()
                }
            } else {
                Button("Open Settings") {
                    healthKitManager.openSettings()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        } message: {
            if healthKitManager.isAuthorized {
                Text("HealthKit permissions are now enabled! Your data will be analyzed to provide personalized insights.")
            } else {
                Text("To enable HealthKit permissions:\n\n1. Tap 'Open Settings' below\n2. Scroll down and tap 'Privacy & Security'\n3. Tap 'Health'\n4. Find 'RideReady' and enable the permissions\n\nThen return to the app to see your data.")
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
        HStack(spacing: 12) {
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.button.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
