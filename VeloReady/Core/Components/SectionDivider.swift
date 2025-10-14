import SwiftUI

/// 2px mid-grey dividing line between sections
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray3))
            .frame(height: 2)
    }
}
