import SwiftUI

/// Extension to ensure all card content uses standardized padding and styling
/// This wrapper enforces the elevated background color (matching Settings section items) across the entire app
extension View {
    /// Wraps content in a standardized card with elevated background (matching Settings)
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
                    .fill(Color.background.card)
            )
            .padding(.horizontal, horizontalSpacing)
            .padding(.vertical, verticalSpacing)
    }
}
