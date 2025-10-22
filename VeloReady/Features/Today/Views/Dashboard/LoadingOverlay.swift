import SwiftUI

/// Full-screen loading overlay with bike icon and spinner
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Bike icon
                Image(systemName: Icons.Activity.cycling)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(ColorPalette.blue)
                
                // Spinner
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.blue))
                
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
