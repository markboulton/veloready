import SwiftUI

/// 2px mid-grey dividing line between sections
/// Full width with 24px padding top and bottom
struct SectionDivider: View {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    init(topPadding: CGFloat = 24, bottomPadding: CGFloat = 24) {
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray3))
            .frame(height: 2)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -16) // Negative padding to escape container
    }
}
