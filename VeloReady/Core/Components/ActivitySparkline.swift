import SwiftUI
import Charts

/// Sparkline bar chart showing activities by day with stacked bars for multiple activities per day
struct ActivitySparkline: View {
    let dailyActivities: [DailyActivityData]
    let alignment: HorizontalAlignment
    let height: CGFloat
    
    @State private var animatedBars: Set<Int> = []
    
    init(dailyActivities: [DailyActivityData], alignment: HorizontalAlignment = .trailing, height: CGFloat = 24) {
        self.dailyActivities = dailyActivities
        self.alignment = alignment
        self.height = height
    }
    
    var body: some View {
        Chart {
            ForEach(dailyActivities) { dayData in
                ForEach(dayData.activities) { activity in
                    BarMark(
                        x: .value("Day", dayData.dayOffset),
                        y: .value("Duration", animatedBars.contains(dayData.dayOffset) ? activity.duration : 0),
                        stacking: .standard
                    )
                    .foregroundStyle(colorForActivityType(activity.type))
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: (dailyActivities.first?.dayOffset ?? 0)...(dailyActivities.last?.dayOffset ?? 0))
        .frame(height: height)
        .onScrollAppear {
            Logger.debug("📊 [ACTIVITY SPARKLINE] Scroll trigger fired - starting animation")
            animateBars()
        }
    }
    
    private func animateBars() {
        // Animate bars one by one from left to right
        let sortedDays = dailyActivities.map { $0.dayOffset }.sorted()
        let delayPerBar = 0.65 / Double(max(sortedDays.count, 1)) // Faster animation (0.65s total)
        
        Logger.debug("📊 [ACTIVITY SPARKLINE] Animating \(sortedDays.count) bars, delay per bar: \(String(format: "%.3f", delayPerBar))s")
        
        for (index, dayOffset) in sortedDays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * delayPerBar) {
                withAnimation(.easeOut(duration: 0.15)) {
                    _ = animatedBars.insert(dayOffset)
                }
                if index == 0 {
                    Logger.debug("📊 [ACTIVITY SPARKLINE] First bar animated")
                } else if index == sortedDays.count - 1 {
                    Logger.debug("📊 [ACTIVITY SPARKLINE] Last bar animated - sequence complete")
                }
            }
        }
    }
    
    private func colorForActivityType(_ type: SparklineActivityType) -> Color {
        switch type {
        case .cycling:
            return Color.activityType.cycling
        case .running:
            return Color.activityType.running
        case .walking:
            return Color.activityType.walking
        case .swimming:
            return Color.activityType.swimming
        case .strength:
            return Color.activityType.strength
        case .other:
            return Color.activityType.other
        }
    }
}

struct DailyActivityData: Identifiable {
    let id = UUID()
    let dayOffset: Int // 0 = today, -1 = yesterday, etc.
    let activities: [ActivityBarData]
}

struct ActivityBarData: Identifiable {
    let id = UUID()
    let type: SparklineActivityType
    let duration: Double // in minutes for visualization
}

enum SparklineActivityType {
    case cycling
    case running
    case walking
    case swimming
    case strength
    case other
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        // Preview: Right-aligned (for Today Activities section)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(CommonContent.TabLabels.activities)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                ActivitySparkline(
                    dailyActivities: [
                        DailyActivityData(dayOffset: -13, activities: [ActivityBarData(type: .cycling, duration: 60)]),
                        DailyActivityData(dayOffset: -12, activities: [ActivityBarData(type: .walking, duration: 30)]),
                        DailyActivityData(dayOffset: -11, activities: []),
                        DailyActivityData(dayOffset: -10, activities: [ActivityBarData(type: .cycling, duration: 90)]),
                        DailyActivityData(dayOffset: -9, activities: []),
                        DailyActivityData(dayOffset: -8, activities: [ActivityBarData(type: .cycling, duration: 45)]),
                        DailyActivityData(dayOffset: -7, activities: [ActivityBarData(type: .running, duration: 40), ActivityBarData(type: .walking, duration: 20)]),
                        DailyActivityData(dayOffset: -6, activities: []),
                        DailyActivityData(dayOffset: -5, activities: [ActivityBarData(type: .cycling, duration: 120)]),
                        DailyActivityData(dayOffset: -4, activities: [ActivityBarData(type: .strength, duration: 45)]),
                        DailyActivityData(dayOffset: -3, activities: [ActivityBarData(type: .cycling, duration: 75)]),
                        DailyActivityData(dayOffset: -2, activities: []),
                        DailyActivityData(dayOffset: -1, activities: [ActivityBarData(type: .walking, duration: 35)]),
                        DailyActivityData(dayOffset: 0, activities: [ActivityBarData(type: .cycling, duration: 60)])
                    ],
                    alignment: .trailing
                )
                .frame(width: 80)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        // Preview: Full-width (for Activities list page)
        VStack(alignment: .leading, spacing: 8) {
            Text(CommonContent.TabLabels.activities)
                .font(.title2)
                .fontWeight(.bold)
            
            ActivitySparkline(
                dailyActivities: [
                    DailyActivityData(dayOffset: -29, activities: [ActivityBarData(type: .cycling, duration: 50)]),
                    DailyActivityData(dayOffset: -28, activities: []),
                    DailyActivityData(dayOffset: -27, activities: [ActivityBarData(type: .running, duration: 40)]),
                    DailyActivityData(dayOffset: -26, activities: []),
                    DailyActivityData(dayOffset: -25, activities: [ActivityBarData(type: .cycling, duration: 90)]),
                    DailyActivityData(dayOffset: -24, activities: [ActivityBarData(type: .walking, duration: 30)]),
                    DailyActivityData(dayOffset: -23, activities: []),
                    DailyActivityData(dayOffset: -22, activities: [ActivityBarData(type: .cycling, duration: 75)]),
                    DailyActivityData(dayOffset: -21, activities: [ActivityBarData(type: .strength, duration: 45), ActivityBarData(type: .walking, duration: 25)]),
                    DailyActivityData(dayOffset: -20, activities: []),
                    DailyActivityData(dayOffset: -19, activities: []),
                    DailyActivityData(dayOffset: -18, activities: [ActivityBarData(type: .cycling, duration: 120)]),
                    DailyActivityData(dayOffset: -17, activities: []),
                    DailyActivityData(dayOffset: -16, activities: [ActivityBarData(type: .running, duration: 50)]),
                    DailyActivityData(dayOffset: -15, activities: []),
                    DailyActivityData(dayOffset: -14, activities: [ActivityBarData(type: .cycling, duration: 85)]),
                    DailyActivityData(dayOffset: -13, activities: [ActivityBarData(type: .walking, duration: 30)]),
                    DailyActivityData(dayOffset: -12, activities: []),
                    DailyActivityData(dayOffset: -11, activities: [ActivityBarData(type: .cycling, duration: 95)]),
                    DailyActivityData(dayOffset: -10, activities: []),
                    DailyActivityData(dayOffset: -9, activities: [ActivityBarData(type: .cycling, duration: 60)]),
                    DailyActivityData(dayOffset: -8, activities: [ActivityBarData(type: .strength, duration: 50)]),
                    DailyActivityData(dayOffset: -7, activities: []),
                    DailyActivityData(dayOffset: -6, activities: [ActivityBarData(type: .cycling, duration: 110)]),
                    DailyActivityData(dayOffset: -5, activities: []),
                    DailyActivityData(dayOffset: -4, activities: [ActivityBarData(type: .running, duration: 45)]),
                    DailyActivityData(dayOffset: -3, activities: []),
                    DailyActivityData(dayOffset: -2, activities: [ActivityBarData(type: .cycling, duration: 70), ActivityBarData(type: .walking, duration: 20)]),
                    DailyActivityData(dayOffset: -1, activities: []),
                    DailyActivityData(dayOffset: 0, activities: [ActivityBarData(type: .cycling, duration: 65)])
                ],
                alignment: .leading
            )
        }
        .padding()
    }
}
