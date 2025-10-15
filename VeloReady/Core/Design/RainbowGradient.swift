import SwiftUI

/// Rainbow gradient modifier for AI-powered features
/// Applies a 30-degree gradient with pink, purple, blue, and cyan colors
struct RainbowGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorPalette.pink,
                        ColorPalette.purple,
                        ColorPalette.blue,
                        ColorPalette.cyan
                    ]),
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 1, y: 0.577) // 30 degree angle (tan(30°) ≈ 0.577)
                )
            )
            .mask(content)
    }
}

extension View {
    /// Applies rainbow gradient to text and icons for AI features
    func rainbowGradient() -> some View {
        modifier(RainbowGradient())
    }
}
