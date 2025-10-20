import SwiftUI

/// Reusable Pro upgrade button that opens paywall
struct ProUpgradeButton: View {
    let title: String
    let description: String
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: Icons.System.sparkles)
                        .foregroundColor(ColorScale.purpleAccent)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(PaywallContent.upgradeNow)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorScale.purpleAccent)
                    .cornerRadius(10)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    ProUpgradeButton(
        title: "Upgrade to Pro for Adaptive Zones",
        description: "A comprehensive, research-backed athlete profiling system that uses cutting-edge sports science to compute and adapt training zones from actual performance data."
    )
    .padding()
}
