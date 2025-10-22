import SwiftUI

/// Gradient mask that appears below navigation bar
/// Matches iOS Mail's behavior - ensures content remains legible when scrolling
struct NavigationGradientMask: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(1.0), location: 0.0),
                .init(color: Color.black.opacity(0.8), location: 0.25),
                .init(color: Color.black.opacity(0.5), location: 0.5),
                .init(color: Color.black.opacity(0.2), location: 0.75),
                .init(color: Color.black.opacity(0.0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 140)
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
