import SwiftUI

/// Section displaying recent activities (excluding the latest cycling one)
struct RecentActivitiesSection: View {
    let allActivities: [UnifiedActivity]
    let dailyActivityData: [DailyActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with sparkline
            HStack(spacing: 4) {
                Text(TodayContent.activitiesSection)
                    .font(.heading)
                Spacer()
                ActivitySparkline(
                    dailyActivities: dailyActivityData,
                    alignment: .trailing,
                    height: 24
                )
                .frame(width: 200)
            }
            .padding(.bottom, Spacing.md)
            
            // Show all activities including the latest ride (no offset)
            if allActivities.isEmpty {
                EmptyStateCard(
                    icon: "figure.walk",
                    title: TodayContent.noRecentActivities,
                    message: TodayContent.noActivities
                )
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(allActivities) { activity in
                        UnifiedActivityCard(activity: activity)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .padding(.bottom, 100) // Extra space for tab bar
        .onAppear {
            Logger.debug("📊 RecentActivitiesSection - padding(Spacing.md=\(Spacing.md)) + padding(.bottom, 100)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background.card)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Preview

struct RecentActivitiesSection_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivitiesSection(
            allActivities: [],
            dailyActivityData: []
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Empty State")
    }
}
