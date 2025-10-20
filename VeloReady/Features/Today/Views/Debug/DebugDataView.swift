import SwiftUI
import HealthKit

/// Debug view for testing HealthKit data integration
struct DebugDataView: View {
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Authorization Status
                    authorizationSection
                    
                    // Authorization Details
                    authorizationDetailsSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle(DebugContent.Navigation.healthDataDebug)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CommonContent.Debug.healthKitIntegration)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(CommonContent.Debug.testingHealthKit)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CommonContent.Debug.authorizationStatus)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(healthKitManager.isAuthorized ? Color.semantic.success : Color.semantic.error)
                
                VStack(alignment: .leading) {
                    Text(healthKitManager.isAuthorized ? "Authorized" : "Not Authorized")
                        .fontWeight(.medium)
                    Text(healthKitManager.authorizationState.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var authorizationDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CommonContent.Debug.authorizationDetails)
                .font(.headline)
                .fontWeight(.semibold)
            
            let details = healthKitManager.getAuthorizationDetails()
            
            ForEach(details.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(details[key] ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(DebugContent.HealthDataDebug.requestHealthKitAuthorization) {
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(healthKitManager.isAuthorized)
            
            Button(DebugContent.HealthDataDebug.refreshAuthorizationStatus) {
                Task {
                    await healthKitManager.refreshAuthorizationStatus()
                }
            }
            .buttonStyle(.bordered)
            
            Button(DebugContent.HealthDataDebug.openSettings) {
                healthKitManager.openSettings()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CommonContent.Debug.error)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.error)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(Color.text.error)
        }
        .padding()
        .background(Color.semantic.error.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func statusString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Supporting Views

struct HealthDataCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct DebugDataView_Previews: PreviewProvider {
    static var previews: some View {
        DebugDataView()
    }
}