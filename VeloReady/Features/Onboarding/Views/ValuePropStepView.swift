import SwiftUI

/// Screen 1: Value Proposition - Introduces app benefits
struct ValuePropStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    // Key benefits to highlight
    private let benefits = [
        Benefit(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "Monitor recovery, sleep, and training load in one place"
        ),
        Benefit(
            icon: "brain.head.profile",
            title: "AI-Powered Insights",
            description: "Get personalized coaching based on your data"
        ),
        Benefit(
            icon: "figure.strengthtraining.traditional",
            title: "Multi-Sport Support",
            description: "Cycling, strength training, and general fitness"
        ),
        Benefit(
            icon: "heart.text.square",
            title: "Smart Recovery",
            description: "Know when to push hard and when to rest"
        ),
        Benefit(
            icon: "bolt.fill",
            title: "Training Load Balance",
            description: "Avoid overtraining with intelligent TSB tracking"
        )
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Welcome to VeloReady")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your intelligent training companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Benefits List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(benefits) { benefit in
                        ValuePropBenefitRow(benefit: benefit)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onboardingManager.nextStep()
            }) {
                Text("Get Started")
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
        .background(Color(.systemBackground))
    }
}

// MARK: - Benefit Row

struct ValuePropBenefitRow: View {
    let benefit: Benefit
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: benefit.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(benefit.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

struct Benefit: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    ValuePropStepView()
}
