import SwiftUI

/// 2px mid-grey dividing line between sections
/// Full width with 24px padding top and bottom
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray3))
            .frame(height: 2)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -16) // Negative padding to escape container
    }
}
