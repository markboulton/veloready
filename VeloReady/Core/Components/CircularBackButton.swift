import SwiftUI

/// Circular glass back button matching Apple Fitness style
/// Used in detail views to replace default back button
struct CircularBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
                    .frame(width: 32, height: 32)
                
                // Border (same as FloatingTabBar)
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    .frame(width: 32, height: 32)
                
                // Chevron icon
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}
