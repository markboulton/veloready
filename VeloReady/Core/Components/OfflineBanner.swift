import SwiftUI

/// Offline banner that shows when device is not connected to the internet
/// Displays amber warning banner at top of views
struct OfflineBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                // Offline state
                bannerView(
                    icon: "wifi.slash",
                    text: "No internet connection",
                    badge: "Offline",
                    backgroundColor: ColorScale.amberAccent
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }

    // MARK: - Banner View

    private func bannerView(icon: String, text: String, badge: String, backgroundColor: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))

            Text(text)
                .font(.system(size: 14, weight: .medium))

            Spacer()

            Text(badge)
                .font(.system(size: 12, weight: .regular))
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("Offline State") {
    VStack(spacing: 0) {
        OfflineBanner()
        Spacer()
        Text("Banner appears when offline")
            .foregroundColor(Color.text.secondary)
    }
}
