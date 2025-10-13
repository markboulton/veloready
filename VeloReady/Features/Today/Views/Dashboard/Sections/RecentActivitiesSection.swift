import SwiftUI

/// Section displaying recent activities (excluding the latest cycling one)
struct RecentActivitiesSection: View {
    let allActivities: [UnifiedActivity]
    let dailyActivityData: [DailyActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(TodayContent.activitiesSection)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                ActivitySparkline(
                    dailyActivities: dailyActivityData,
                    alignment: .trailing,
                    height: 24
                )
                .frame(width: 120)
            }
            
            // Show all activities except the first cycling one (which is shown in latest ride panel)
            let firstCyclingIndex = allActivities.firstIndex(where: { $0.type == .cycling })
            let remainingActivities = firstCyclingIndex != nil ?
                Array(allActivities.enumerated().filter { $0.offset != firstCyclingIndex }.map { $0.element }) :
                allActivities
            
            if remainingActivities.isEmpty {
                Text(TodayContent.noActivities)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(remainingActivities) { activity in
                        UnifiedActivityCard(activity: activity)
                            .padding(.vertical, 8)
                        
                        if activity.id != remainingActivities.last?.id {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
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
