import SwiftUI

/// Full-screen loading overlay with pulse-scale animation
/// Centered horizontally and vertically during initial app load (Phase 1)
struct LoadingOverlay: View {
    var body: some View {
        Color.background.primary
            .ignoresSafeArea()
            .overlay(
                // Pulse-scale loader animation - centered in viewport
                PulseScaleLoader()
            )
            .onAppear {
                Logger.debug("🔵 [SPINNER] LoadingOverlay SHOWING")
            }
            .onDisappear {
                Logger.debug("🟢 [SPINNER] LoadingOverlay HIDDEN")
            }
    }
}
