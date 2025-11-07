import SwiftUI

/// Step 6: Pro subscription offer
struct SubscriptionStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var selectedPlan: SubscriptionPlan = .annual
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"
        
        var price: String {
            switch self {
            case .monthly: return "$9.99"
            case .annual: return "$79.99"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "per month"
            case .annual: return "per year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save $40"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Text(OnboardingContent.Subscription.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingContent.Subscription.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            // Features
            VStack(alignment: .leading, spacing: 20) {
                ProFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Daily Brief",
                    description: "Personalized training insights"
                )
                
                ProFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "FTP trends, training load, and more"
                )
                
                ProFeatureRow(
                    icon: "calendar",
                    title: "Extended History",
                    description: "Access unlimited activity history"
                )
                
                ProFeatureRow(
                    icon: "bell.badge.fill",
                    title: "Smart Notifications",
                    description: "Recovery alerts and reminders"
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            
            // Pricing
            VStack(spacing: 12) {
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    Button(action: {
                        selectedPlan = plan
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(plan.period)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(plan.price)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                if let savings = plan.savings {
                                    Text(savings)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ColorScale.greenAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(ColorScale.greenAccent.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedPlan == plan ? .blue : .secondary)
                        }
                        .padding()
                        .background(Color.background.card)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPlan == plan ? Color.blue : ColorPalette.neutral300, lineWidth: selectedPlan == plan ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement actual subscription flow
                    Logger.debug("🔥 Starting \(selectedPlan.rawValue) subscription")
                    onboardingManager.completeOnboarding()
                }) {
                    Text(OnboardingContent.Subscription.continueButton)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorScale.blueAccent)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    onboardingManager.completeOnboarding()
                }) {
                    Text(OnboardingContent.Subscription.skipButton)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

/// Pro feature row component
struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // White icon on blue circle
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(ColorScale.blueAccent)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct SubscriptionStepView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionStepView()
    }
}
