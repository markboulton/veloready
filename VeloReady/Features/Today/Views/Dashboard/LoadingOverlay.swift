import SwiftUI

/// Full-screen loading overlay with pulse-scale animation
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.background.primary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Pulse-scale loader animation
                PulseScaleLoader(color: ColorPalette.blue)
                
                // Loading text
                Text(CommonContent.loading)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            Logger.debug("🔵 [SPINNER] LoadingOverlay SHOWING")
        }
        .onDisappear {
            Logger.debug("🟢 [SPINNER] LoadingOverlay HIDDEN")
        }
    }
}
