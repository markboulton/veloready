import SwiftUI

/// Reusable Pro upgrade card component with inverted color scheme
struct ProUpgradeCard: View {
    let content: ProUpgradeContent
    let showBenefits: Bool
    let learnMoreContent: LearnMoreContent?
    @State private var showPaywall = false
    @Environment(\.colorScheme) var colorScheme
    
    init(content: ProUpgradeContent, showBenefits: Bool = false, learnMore: LearnMoreContent? = nil) {
        self.content = content
        self.showBenefits = showBenefits
        self.learnMoreContent = learnMore
    }
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header with title and PRO badge (aligned top right)
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Title
                    Text(content.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(invertedTextColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // PRO badge (top right)
                    Text(CommonContent.pro)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.button.primary)
                        .cornerRadius(4)
                }
                
                // Description with optional Learn More link
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(content.description)
                        .font(.subheadline)
                        .foregroundColor(invertedTextColor.opacity(1.0))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let learnMoreContent = learnMoreContent {
                        LearnMoreLink(content: learnMoreContent)
                    }
                }
                
                // Benefits (optional)
                if showBenefits, let benefits = content.benefits {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: benefit.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(invertedTextColor.opacity(1.0))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(benefit.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(invertedTextColor)
                                    
                                    Text(benefit.description)
                                        .font(.caption)
                                        .foregroundColor(invertedTextColor.opacity(1.0))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Upgrade button (full width)
                Text(CommonContent.upgradeToPro)
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
        colorScheme == .dark ? Color.white.opacity(1.0) : Color.black.opacity(1.0)
    }

    private var invertedTextColor: Color {
        colorScheme == .dark ? .black : .white  // Keep text solid
    }
}

/// Compact inline Pro badge button
struct ProBadgeButton: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            Text(CommonContent.pro)
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
