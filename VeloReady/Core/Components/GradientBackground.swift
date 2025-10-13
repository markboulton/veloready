import SwiftUI

/// Reusable dual gradient background (two shades of blue)
struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Lighter blue gradient from top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.7
            )
            
            // Deeper blue gradient from top-right
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.25),
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
