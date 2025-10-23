import SwiftUI

/// Gradient mask that appears below navigation bar
/// Matches Apple Fitness behavior - ensures content remains legible when scrolling
struct NavigationGradientMask: View {
    var body: some View {
        VStack(spacing: 0) {
            // Solid background area for navigation bar (adaptive to theme)
            Color.background.secondary
                .frame(height: 96)
            
            // Gradient fade to transparent (adaptive to theme)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.background.secondary.opacity(0.95), location: 0.0),
                    .init(color: Color.background.secondary.opacity(0.7), location: 0.3),
                    .init(color: Color.background.secondary.opacity(0.4), location: 0.6),
                    .init(color: Color.background.secondary.opacity(0.0), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            
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
