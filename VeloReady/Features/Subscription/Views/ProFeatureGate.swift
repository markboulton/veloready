import SwiftUI

/// Gate component that shows content if Pro, otherwise shows upgrade prompt
struct ProFeatureGate<Content: View>: View {
    @ObservedObject var config = ProFeatureConfig.shared
    
    let upgradeContent: ProUpgradeContent
    let isEnabled: Bool
    let showBenefits: Bool
    let content: () -> Content
    
    init(
        upgradeContent: ProUpgradeContent,
        isEnabled: Bool,
        showBenefits: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.upgradeContent = upgradeContent
        self.isEnabled = isEnabled
        self.showBenefits = showBenefits
        self.content = content
    }
    
    var body: some View {
        if isEnabled {
            Logger.debug("🔓 [PRO GATE] Showing content for: \(upgradeContent.title)")
            return AnyView(content())
        } else {
            Logger.debug("🔒 [PRO GATE] Blocking content for: \(upgradeContent.title)")
            return AnyView(ProUpgradeCard(content: upgradeContent, showBenefits: showBenefits))
        }
    }
}

/// Inline Pro upsell button (deprecated - use ProBadgeButton instead)
struct ProBadge: View {
    var body: some View {
        ProBadgeButton()
    }
}

/// Navigation link that shows paywall if not Pro
struct ProNavigationLink<Destination: View, Label: View>: View {
    @ObservedObject var config = ProFeatureConfig.shared
    @State private var showPaywall = false
    
    let isEnabled: Bool
    let destination: () -> Destination
    let label: () -> Label
    
    init(
        isEnabled: Bool,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isEnabled = isEnabled
        self.destination = destination
        self.label = label
    }
    
    var body: some View {
        if isEnabled {
            NavigationLink(destination: destination) {
                label()
            }
        } else {
            Button(action: { showPaywall = true }) {
                HStack {
                    label()
                    Spacer()
                    ProBadge()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Preview

#Preview("Feature Gate") {
    ProFeatureGate(
        upgradeContent: .weeklyRecoveryTrend,
        isEnabled: false,
        showBenefits: true
    ) {
        Text("Trend content here")
    }
    .padding()
}

#Preview("Pro Badge") {
    ProBadgeButton()
}
