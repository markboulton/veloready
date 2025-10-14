import SwiftUI

/// Reusable Pro upgrade card component
struct ProUpgradeCard: View {
    let content: ProUpgradeContent
    let showBenefits: Bool
    @State private var showPaywall = false
    
    init(content: ProUpgradeContent, showBenefits: Bool = false) {
        self.content = content
        self.showBenefits = showBenefits
    }
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with PRO badge
                HStack(spacing: 12) {
                    // PRO badge
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.button.primary)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Title
                Text(content.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.text.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Description
                Text(content.description)
                    .font(.subheadline)
                    .foregroundColor(Color.text.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Benefits (optional)
                if showBenefits, let benefits = content.benefits {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.button.primary)
                                
                                Text(benefit)
                                    .font(.caption)
                                    .foregroundColor(Color.text.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Upgrade button
                HStack {
                    Spacer()
                    
                    Text("Upgrade to Pro")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.button.primary)
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(ColorScale.gray100)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Compact inline Pro badge button
struct ProBadgeButton: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            Text("PRO")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.button.primary)
                .cornerRadius(3)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Preview

#Preview("Pro Upgrade Card") {
    VStack(spacing: 20) {
        ProUpgradeCard(content: .trainingLoad)
        
        ProUpgradeCard(content: .intensityAnalysis, showBenefits: true)
    }
    .padding()
}

#Preview("Pro Badge Button") {
    ProBadgeButton()
}
