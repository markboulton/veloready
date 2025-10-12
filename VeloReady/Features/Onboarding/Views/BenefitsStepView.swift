import SwiftUI

/// Step 2: Benefits explanation
struct BenefitsStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("What RideReady Does")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Benefits
            VStack(spacing: 24) {
                BenefitCard(
                    icon: "brain.head.profile",
                    title: "Smart Recovery Tracking",
                    description: "AI-powered daily recovery scores combining HRV, sleep quality, resting heart rate, and training load"
                )
                
                BenefitCard(
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    title: "Adaptive Training Zones",
                    description: "Automatically updated power and heart rate zones based on your recent performance"
                )
                
                BenefitCard(
                    icon: "chart.xyaxis.line",
                    title: "Performance Analytics",
                    description: "Detailed ride analysis, FTP trends, and training load management"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue Button
            Button(action: {
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
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

/// Benefit card component
struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Preview

struct BenefitsStepView_Previews: PreviewProvider {
    static var previews: some View {
        BenefitsStepView()
    }
}
