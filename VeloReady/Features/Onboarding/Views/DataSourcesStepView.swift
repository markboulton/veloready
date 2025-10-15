import SwiftUI

/// Step 5: Connect Data Sources (conditional based on sport)
struct DataSourcesStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var intervalsManager = IntervalsOAuthManager.shared
    @StateObject private var stravaAuthService = StravaAuthService.shared
    
    // Check if user selected cycling as primary sport
    private var showCyclingIntegrations: Bool {
        onboardingManager.primarySport == .cycling
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: showCyclingIntegrations ? "link.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(showCyclingIntegrations ? "Connect Your Cycling Data" : "Connect Your Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(headerDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Connection options (conditional)
            if showCyclingIntegrations {
                VStack(spacing: 12) {
                    // Strava (top)
                    ConnectWithStravaButton(
                        action: {
                            stravaAuthService.startAuth()
                        },
                        isConnected: stravaAuthService.connectionState.isConnected,
                        connectionState: stravaAuthService.connectionState
                    )
                    
                    // Intervals.icu (middle)
                    ConnectWithIntervalsButton(
                        action: {
                            // Open the Intervals login view
                            // Note: This should open IntervalsLoginView but we're simplifying
                        },
                        isConnected: intervalsManager.isAuthenticated
                    )
                    
                    // Wahoo (bottom) - Coming soon
                    Button(action: {}) {
                        Text("Wahoo (Coming Soon)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 32)
                
                Text("Optional: Connect your training platform")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                // Non-cycling message
                VStack(spacing: 16) {
                    Text("You're all set!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("We'll track your activities through Apple Health")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                if intervalsManager.isAuthenticated || stravaAuthService.connectionState.isConnected {
                    onboardingManager.hasConnectedIntervalsOrStrava = true
                }
                onboardingManager.nextStep()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Computed Properties
    
    private var headerDescription: String {
        if showCyclingIntegrations {
            return "Connect to Strava, Intervals.icu, or Wahoo to sync your rides and track your progress. This step is optional."
        } else {
            return "We'll use Apple Health to track your activities and health metrics"
        }
    }
}

/// Data source connection card
struct DataSourceConnectionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isConnected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isConnected)
    }
}

// MARK: - Preview

struct DataSourcesStepView_Previews: PreviewProvider {
    static var previews: some View {
        DataSourcesStepView()
    }
}
