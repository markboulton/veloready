import SwiftUI

/// Empty state view when no activities are available
struct ActivitiesEmptyStateView: View {
    let onRefresh: () async -> Void
    
    var body: some View {
        EmptyStateCard(
            icon: "figure.outdoor.cycle",
            title: ActivitiesContent.noActivities,
            message: ActivitiesContent.noActivitiesMessage,
            actionTitle: ActivitiesContent.refreshButton,
            action: {
                Task {
                    await onRefresh()
                }
            }
        )
    }
}

// MARK: - Preview

struct ActivitiesEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesEmptyStateView(onRefresh: {})
    }
}
