import SwiftUI

/// Individual Calories card for Today view
struct CaloriesCard: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @StateObject private var userSettings = UserSettings.shared
    
    init() {
        self.liveActivityService = LiveActivityService(oauthManager: IntervalsOAuthManager.shared)
    }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with grey outlined icon
                HStack {
                    Image(systemName: Icons.Health.caloriesFill)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.text.secondary)
                    
                    Text("Calories")
                        .font(.heading)
                        .foregroundColor(Color.text.primary)
                }
                
                // Goal
                StatRow(
                    label: "Goal",
                    value: "\(Int(effectiveGoal))",
                    valueColor: ColorPalette.peach
                )
                
                // Active Energy
                StatRow(
                    label: "Active Energy",
                    value: "\(Int(liveActivityService.activeCalories))",
                    valueColor: Color.semantic.success
                )
                
                // Divider
                Divider()
                    .background(Color.secondary.opacity(0.3))
                
                // Total
                HStack {
                    Text("Total")
                        .font(.heading)
                    
                    Spacer()
                    
                    Text("\(Int(totalCalories))")
                        .font(.heading)
                        .foregroundColor(totalCalories > effectiveGoal ? .white : .primary)
                }
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
