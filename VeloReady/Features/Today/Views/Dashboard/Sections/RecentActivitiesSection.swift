import SwiftUI

/// Section displaying recent activities (excluding the latest cycling one)
struct RecentActivitiesSection: View {
    let allActivities: [UnifiedActivity]
    let dailyActivityData: [DailyActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
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
            
            // Show all activities except the first cycling one (which is shown in latest ride panel)
            let firstCyclingIndex = allActivities.firstIndex(where: { $0.type == .cycling })
            let remainingActivities = firstCyclingIndex != nil ?
                Array(allActivities.enumerated().filter { $0.offset != firstCyclingIndex }.map { $0.element }) :
                allActivities
            
            if remainingActivities.isEmpty {
                EmptyStateCard(
                    icon: "figure.walk",
                    title: "No Recent Activities",
                    message: TodayContent.noActivities
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(remainingActivities) { activity in
                        UnifiedActivityCard(activity: activity)
                            .padding(.vertical, 8)
                        
                        if activity.id != remainingActivities.last?.id {
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
