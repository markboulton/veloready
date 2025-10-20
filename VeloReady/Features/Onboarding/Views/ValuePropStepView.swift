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
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Text(OnboardingContent.ValueProp.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingContent.ValueProp.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 48)
            
            // Benefits List - Not scrollable
            VStack(spacing: 20) {
                ForEach(benefits) { benefit in
                    ValuePropBenefitRow(benefit: benefit)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onboardingManager.nextStep()
            }) {
                Text(OnboardingContent.ValueProp.continueButton)
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
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.blue)
                .clipShape(Circle())
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(benefit.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
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
