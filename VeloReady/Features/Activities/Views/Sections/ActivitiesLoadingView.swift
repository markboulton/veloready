import SwiftUI

/// Loading view with skeleton placeholders for activities list
struct ActivitiesLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Skeleton activity cards
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonActivityCard()
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xxl)
        }
    }
}

// MARK: - Preview

struct ActivitiesLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesLoadingView()
    }
}
