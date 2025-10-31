import SwiftUI

/// Full-screen loading overlay with pulse-scale animation
/// Positioned to align with compact rings section
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.background.primary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add spacing from top to align with compact rings position
                // Compact rings appear at ~140pt from top (after nav title)
                Spacer()
                    .frame(height: 140)
                
                // Pulse-scale loader animation
                PulseScaleLoader()
                
                Spacer()
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
