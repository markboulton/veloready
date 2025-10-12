import SwiftUI

struct IntervalsLoginView: View {
    let onAuthenticated: () -> Void
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticating = false
    @State private var showingWebView = false
    @State private var authURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 80))
                        .foregroundColor(Color.button.primary)
                    
                    Text("Welcome to VeloReady")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect your intervals.icu account to access your training data and get personalized recommendations.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    Text("What you'll get:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        LoginBenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Training Analysis",
                            description: "Detailed insights from your rides"
                        )
                        
                        LoginBenefitRow(
                            icon: "heart.fill",
                            title: "Health Metrics",
                            description: "Track your fitness and recovery"
                        )
                        
                        LoginBenefitRow(
                            icon: "calendar",
                            title: "Training Calendar",
                            description: "Plan and track your workouts"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action Button
                VStack(spacing: 16) {
                    Button("Connect to intervals.icu") {
                        authenticateWithIntervals()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isAuthenticating)
                    
                    if isAuthenticating {
                        ProgressView("Connecting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Your data stays private and secure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                checkAuthenticationStatus()
            }
            .sheet(isPresented: $showingWebView) {
                if let authURL = authURL {
                    IntervalsOAuthWebViewContainer(
                        url: authURL,
                        onCallback: { url in
                            Task {
                                await oauthManager.handleCallback(url: url)
                                showingWebView = false
                                if oauthManager.isAuthenticated {
                                    onAuthenticated()
                                } else {
                                    alertMessage = oauthManager.lastError ?? "Authentication failed"
                                    showingAlert = true
                                }
                            }
                        },
                        onDismiss: {
                            showingWebView = false
                            isAuthenticating = false
                        }
                    )
                }
            }
        }
    }
    
    private func authenticateWithIntervals() {
        isAuthenticating = true
        
        guard let url = oauthManager.startAuthentication() else {
            alertMessage = "Failed to start authentication"
            showingAlert = true
            isAuthenticating = false
            return
        }
        
        // Use WebView instead of Safari for better OAuth handling
        authURL = url
        showingWebView = true
    }
    
    private func checkAuthenticationStatus() {
        if oauthManager.isAuthenticated {
            onAuthenticated()
        }
    }
}

struct LoginBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.button.primary)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct IntervalsLoginView_Previews: PreviewProvider {
    static var previews: some View {
        IntervalsLoginView(onAuthenticated: {})
    }
}

