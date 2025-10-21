import SwiftUI

/// 2px mid-grey dividing line between sections
/// Standard pattern: Each section owns its bottom divider with 24px top padding, 0 bottom
/// Next section provides its own top padding for consistent 24px spacing
struct SectionDivider: View {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    init(topPadding: CGFloat = Spacing.lg, bottomPadding: CGFloat = Spacing.lg) {
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
    }
    
    var body: some View {
        Rectangle()
            .fill(ColorScale.divider)
            .frame(height: 2)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -16) // Negative padding to escape container
    }
}
