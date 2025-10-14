import SwiftUI

/// Reusable Pro upgrade card component with inverted color scheme
struct ProUpgradeCard: View {
    let content: ProUpgradeContent
    let showBenefits: Bool
    @State private var showPaywall = false
    @Environment(\.colorScheme) var colorScheme
    
    init(content: ProUpgradeContent, showBenefits: Bool = false) {
        self.content = content
        self.showBenefits = showBenefits
    }
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with title and PRO badge (aligned top right)
                HStack(alignment: .top, spacing: 12) {
                    // Title
                    Text(content.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(invertedTextColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // PRO badge (top right)
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.button.primary)
                        .cornerRadius(4)
                }
                
                // Description
                Text(content.description)
                    .font(.subheadline)
                    .foregroundColor(invertedTextColor.opacity(0.8))
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
                                    .foregroundColor(invertedTextColor.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Upgrade button (full width)
                Text("Upgrade to Pro")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.button.primary)
                    .cornerRadius(8)
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(invertedBackgroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Colors
    
    private var invertedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var invertedTextColor: Color {
        colorScheme == .dark ? .black : .white
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
