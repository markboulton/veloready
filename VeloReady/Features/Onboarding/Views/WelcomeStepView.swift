import SwiftUI

/// Step 1: Welcome screen with overview
struct WelcomeStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo
            RideReadyLogo(size: .large)
            
            // Welcome message
            VStack(spacing: 16) {
                Text("Welcome to RideReady")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your intelligent cycling companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Feature bullets
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeatureBullet(
                    icon: "figure.outdoor.cycle",
                    title: "Track Your Rides",
                    description: "Comprehensive activity tracking with power, heart rate, and GPS"
                )
                
                OnboardingFeatureBullet(
                    icon: "heart.text.square",
                    title: "Monitor Recovery",
                    description: "Science-based recovery scores using HRV, sleep, and training load"
                )
                
                OnboardingFeatureBullet(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Improve Performance",
                    description: "Adaptive training zones and personalized insights"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // CTA Button
            Button(action: {
                onboardingManager.nextStep()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

/// Feature bullet point component for onboarding
struct OnboardingFeatureBullet: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeStepView()
    }
}
