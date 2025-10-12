import SwiftUI

/// Gate component that shows content if Pro, otherwise shows upgrade prompt
struct ProFeatureGate<Content: View>: View {
    @ObservedObject var config = ProFeatureConfig.shared
    @State private var showPaywall = false
    
    let featureName: String
    let featureDescription: String
    let isEnabled: Bool
    let content: () -> Content
    
    init(
        featureName: String,
        featureDescription: String,
        isEnabled: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.featureName = featureName
        self.featureDescription = featureDescription
        self.isEnabled = isEnabled
        self.content = content
    }
    
    var body: some View {
        if isEnabled {
            content()
        } else {
            upgradePrompt
        }
    }
    
    private var upgradePrompt: some View {
        Button(action: { showPaywall = true }) {
            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.gradient.proIcon)
                
                Text(featureName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(featureDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Upgrade to VeloReady Pro")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gradient.pro)
                    .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.background.secondary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Inline Pro badge for features
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gradient.pro)
            .cornerRadius(4)
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
        featureName: "Weekly Trends",
        featureDescription: "View your performance trends over the past 7 days",
        isEnabled: false
    ) {
        Text("Trend content here")
    }
    .padding()
}

#Preview("Pro Badge") {
    ProBadge()
}
