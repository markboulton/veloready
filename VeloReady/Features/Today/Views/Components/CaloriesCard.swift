import SwiftUI

/// Individual Calories card for Today view
struct CaloriesCard: View {
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        StandardCard(
            icon: Icons.Health.caloriesFill,
            title: "Calories"
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Goal
                StatRow(
                    label: "Goal",
                    value: "\(Int(effectiveGoal))",
                    valueColor: .secondary
                )
                
                // Active Energy
                StatRow(
                    label: "Active Energy",
                    value: "\(Int(liveActivityService.activeCalories))",
                    valueColor: .secondary
                )
                
                // Total
                HStack {
                    Text("Total")
                        .font(.heading)
                    
                    Spacer()
                    
                    Text("\(Int(totalCalories))")
                        .font(.heading)
                        .foregroundColor(totalCalories > effectiveGoal ? .white : .primary)
                }
                .padding(.top, Spacing.xs)
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
        return liveActivityService.bmrCalories + Double(liveActivityService.activeCalories)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        CaloriesCard()
    }
    .background(Color.background.primary)
}
