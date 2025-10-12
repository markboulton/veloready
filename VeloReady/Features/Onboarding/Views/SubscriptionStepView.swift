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
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                Text("Unlock Pro Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get the most out of RideReady")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
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
            .padding(.horizontal, 24)
            
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
                                    .foregroundColor(selectedPlan == plan ? .white : .primary)
                                
                                Text(plan.period)
                                    .font(.caption)
                                    .foregroundColor(selectedPlan == plan ? .white.opacity(0.8) : .secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(plan.price)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedPlan == plan ? .white : .primary)
                                
                                if let savings = plan.savings {
                                    Text(savings)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedPlan == plan ? .white : .secondary)
                        }
                        .padding()
                        .background(
                            selectedPlan == plan
                                ? LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color(.systemGray6), Color(.systemGray6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPlan == plan ? Color.clear : Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement actual subscription flow
                    print("🔥 Starting \(selectedPlan.rawValue) subscription")
                    onboardingManager.completeOnboarding()
                }) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                
                Button(action: {
                    onboardingManager.completeOnboarding()
                }) {
                    Text("Continue with Free")
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview

struct SubscriptionStepView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionStepView()
    }
}
