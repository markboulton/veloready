import SwiftUI

/// Reusable dual gradient background (purple from top-left, cyan from top-right)
struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Purple gradient from top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.22),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.7
            )
            
            // Cyan gradient from top-right
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.18),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.7
            )
        }
        .ignoresSafeArea()
    }
}
