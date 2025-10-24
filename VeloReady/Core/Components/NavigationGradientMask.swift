import SwiftUI

/// Gradient mask that appears below navigation bar
/// iOS 26+: Uses native Liquid Glass toolbar (no custom gradient needed)
/// iOS 25 and earlier: Custom gradient for content legibility
struct NavigationGradientMask: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ - No custom gradient needed
            // Toolbars automatically get Liquid Glass effect
            // System handles the blur and transparency
            EmptyView()
                .onAppear {
                    print("🎨 [NavigationGradientMask] iOS 26+ detected - using native toolbar (no custom gradient)")
                }
        } else {
            // iOS 25 and earlier - Custom gradient mask
            customGradientMask
                .onAppear {
                    print("🎨 [NavigationGradientMask] iOS < 26 - using custom gradient mask")
                }
        }
    }
    
    private var customGradientMask: some View {
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
