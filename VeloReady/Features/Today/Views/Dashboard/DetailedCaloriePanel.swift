import SwiftUI

/// Detailed calorie panel showing Goal, Active Energy, and Total
struct DetailedCaloriePanel: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @StateObject private var userSettings = UserSettings.shared
    @State private var dataOpacity: Double = 0.0
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.cardContentSpacing) {
            // Header
            Text(TodayContent.Calories.calories)
                .font(.heading)
            
            // Goal (BMR or user-set)
            StatRow(
                label: TodayContent.Calories.goal,
                value: "\(Int(effectiveGoal))",
                valueColor: ColorPalette.peach
            )
            
            // Active Energy - always show to preserve layout
            StatRow(
                label: TodayContent.Calories.activeEnergy,
                value: "\(Int(liveActivityService.activeCalories))",
                valueColor: Color.semantic.success
            )
            .opacity(dataOpacity)
            
            // Divider
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Total
            HStack {
                Text(TodayContent.Calories.total)
                    .font(.heading)
                
                Spacer()
                
                Text("\(Int(totalCalories))")
                    .font(.heading)
                    .foregroundColor(Color.text.primary)
                    .opacity(dataOpacity)
            }
            
            // Last updated
            if let lastUpdated = liveActivityService.lastUpdated {
                Text("\(TodayContent.Calories.updated) \(formatLastUpdated(lastUpdated))")
                    .captionStyle()
            }
        }
        .cardStyle()
        .onChange(of: liveActivityService.isLoading) { _, isLoading in
            if !isLoading {
                withAnimation(.easeIn(duration: 0.3)) {
                    dataOpacity = 1.0
                }
            }
        }
        .onAppear {
            if !liveActivityService.isLoading {
                dataOpacity = 1.0
            }
        }
    }
    
    private var effectiveGoal: Double {
        if userSettings.useBMRAsGoal {
            return liveActivityService.bmrCalories
        } else {
            return userSettings.calorieGoal
        }
    }
    
    private var totalCalories: Double {
        return effectiveGoal + liveActivityService.activeCalories
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    DetailedCaloriePanel(liveActivityService: LiveActivityService.shared)
        .padding()
        .onAppear {
            let service = LiveActivityService.shared
            service.bmrCalories = 1200
            service.activeCalories = 350
            service.dailyCalories = 1550
            service.lastUpdated = Date()
        }
}
