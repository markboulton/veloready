import SwiftUI

/// Simple background - black in dark mode, white in light mode
struct GradientBackground: View {
    var body: some View {
        Color.background.primary
            .ignoresSafeArea()
    }
}
