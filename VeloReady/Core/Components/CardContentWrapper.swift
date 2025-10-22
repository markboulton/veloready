import SwiftUI

/// Extension to ensure all card content uses standardized padding and styling
/// This wrapper enforces the 5% opacity card design system across the entire app
extension View {
    /// Wraps content in a standardized card with 5% opacity background
    /// - Parameters:
    ///   - padding: Content padding (default: Spacing.md)
    ///   - horizontalSpacing: Horizontal margin (default: Spacing.md)
    ///   - verticalSpacing: Vertical spacing (default: Spacing.md / 2)
    /// - Returns: View wrapped in standardized card styling
    func standardCard(
        padding: CGFloat = Spacing.md,
        horizontalSpacing: CGFloat = Spacing.md,
        verticalSpacing: CGFloat = Spacing.md / 2
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, horizontalSpacing)
            .padding(.vertical, verticalSpacing)
    }
}
