import SwiftUI

/// Banner displayed when device is offline
/// Shows at the top of views to inform users they are not connected to the internet
struct OfflineBannerView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .medium))

                Text("No internet connection")
                    .font(.system(size: 14, weight: .medium))

                Spacer()

                Text("Offline")
                    .font(.system(size: 12, weight: .regular))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Preview offline state
        OfflineBannerView(networkMonitor: {
            let monitor = NetworkMonitor.shared
            return monitor
        }())

        Spacer()
    }
}
