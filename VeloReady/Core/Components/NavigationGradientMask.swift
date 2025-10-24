import SwiftUI

/// Gradient mask that appears below navigation bar
/// Matches Apple Fitness behavior - ensures content remains legible when scrolling
struct NavigationGradientMask: View {
    var body: some View {
        VStack(spacing: 0) {
            // Solid background area for navigation bar (adaptive to theme)
            Color.background.app
                .frame(height: Spacing.navigationBarHeight)
            
            // Gradient fade to transparent (adaptive to theme)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.background.app.opacity(Opacity.gradientFull), location: 0.0),
                    .init(color: Color.background.app.opacity(Opacity.gradientHigh), location: 0.3),
                    .init(color: Color.background.app.opacity(Opacity.gradientMedium), location: 0.6),
                    .init(color: Color.background.app.opacity(Opacity.gradientLow), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Spacing.navigationGradientHeight)
            
            Spacer()
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - View Extension

extension View {
    /// Add navigation gradient mask below navigation bar
    /// Matches iOS Mail behavior for content legibility
    func navigationGradientMask() -> some View {
        ZStack(alignment: .top) {
            self
            NavigationGradientMask()
        }
    }
}
