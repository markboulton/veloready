import SwiftUI

/// Section displaying recent activities (excluding the latest cycling one)
struct RecentActivitiesSection: View {
    let allActivities: [UnifiedActivity]
    let dailyActivityData: [DailyActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                SectionHeader(TodayContent.activitiesSection)
                ActivitySparkline(
                    dailyActivities: dailyActivityData,
                    alignment: .leading,
                    height: 24
                )
                .frame(width: 120)
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Show all activities including the latest ride (no offset)
            if allActivities.isEmpty {
                EmptyStateCard(
                    icon: "figure.walk",
                    title: TodayContent.noRecentActivities,
                    message: TodayContent.noActivities
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(allActivities) { activity in
                        UnifiedActivityCard(activity: activity)
                            .padding(.vertical, 8)
                        
                        if activity.id != allActivities.last?.id {
                            Divider()
                        }
                    }
                }
            }
            
            SectionDivider()
        }
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
