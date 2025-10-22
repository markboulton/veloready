import SwiftUI

/// Gradient mask that appears below navigation bar
/// Matches iOS Mail's behavior - ensures content remains legible when scrolling
struct NavigationGradientMask: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: backgroundColor.opacity(0.95), location: 0.0),
                .init(color: backgroundColor.opacity(0.7), location: 0.3),
                .init(color: backgroundColor.opacity(0.4), location: 0.6),
                .init(color: backgroundColor.opacity(0.0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
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
