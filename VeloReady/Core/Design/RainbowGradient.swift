import SwiftUI

/// Rainbow gradient modifier for AI-powered features
/// Uses design tokens from ColorPalette.aiGradientColors and ColorPalette.aiGradientAngle
struct RainbowGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: ColorPalette.aiGradientColors),
                    startPoint: ColorPalette.aiGradientAngle.start,
                    endPoint: ColorPalette.aiGradientAngle.end
                )
            )
            .mask(content)
    }
}

extension View {
    /// Applies AI gradient to text and icons for AI-powered features
    /// Uses design tokens: ColorPalette.aiGradientColors and ColorPalette.aiGradientAngle
    func rainbowGradient() -> some View {
        modifier(RainbowGradient())
    }
}
