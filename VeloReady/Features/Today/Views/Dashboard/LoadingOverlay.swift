import SwiftUI

/// Full-screen loading overlay with pulse-scale animation
/// Centered horizontally and vertically during initial app load (Phase 1)
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
        Color.background.primary
            .ignoresSafeArea()
            
                // Pulse-scale loader animation - centered in viewport
                PulseScaleLoader()
        }
            .onAppear {
            Logger.info("🔵 [LOADING-OVERLAY] onAppear - LoadingOverlay is NOW VISIBLE")
            }
            .onDisappear {
            Logger.info("🟢 [LOADING-OVERLAY] onDisappear - LoadingOverlay is NOW HIDDEN")
            }
    }
}
