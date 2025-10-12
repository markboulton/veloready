import SwiftUI

/// Step 4: Connect Strava or Intervals.icu
struct DataSourcesStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var intervalsManager = IntervalsOAuthManager.shared
    @State private var showingIntervalsAuth = false
    @State private var showingStravaAuth = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Connect Your Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Connect to Intervals.icu or Strava to import your rides and track your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Connection options
            VStack(spacing: 16) {
                // Intervals.icu
                ConnectWithIntervalsButton(
                    action: {
                        showingIntervalsAuth = true
                    },
                    isConnected: intervalsManager.isAuthenticated
                )
                
                // Strava
                ConnectWithStravaButton(
                    action: {
                        showingStravaAuth = true
                    },
                    isConnected: false // TODO: Update when Strava implemented
                )
            }
            .padding(.horizontal, 24)
            
            if intervalsManager.isAuthenticated {
                Text("✓ You're all set!")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Text("You can connect either one or both")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    if intervalsManager.isAuthenticated {
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
                        .cornerRadius(16)
                }
                
                if !intervalsManager.isAuthenticated {
                    Button(action: {
                        onboardingManager.nextStep()
                    }) {
                        Text("I'll Connect Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingIntervalsAuth) {
            IntervalsLoginView {
                showingIntervalsAuth = false
                if intervalsManager.isAuthenticated {
                    onboardingManager.hasConnectedIntervalsOrStrava = true
                }
            }
        }
        .sheet(isPresented: $showingStravaAuth) {
            // TODO: Strava auth view
            VStack(spacing: 20) {
                Text("Strava")
                    .font(.largeTitle)
                Text("Coming Soon")
                    .foregroundColor(.secondary)
                Button("Close") {
                    showingStravaAuth = false
                }
            }
            .padding()
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
