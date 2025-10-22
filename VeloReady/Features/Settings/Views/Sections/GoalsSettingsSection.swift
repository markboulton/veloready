import SwiftUI

/// Goals settings section - Daily targets for steps and calories
struct GoalsSettingsSection: View {
    @ObservedObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Section {
            HapticNavigationLink(destination: GoalsSettingsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text("Daily Goals")
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text("Steps: \(userSettings.stepGoal) • Calories: \(Int(userSettings.calorieGoal)) • Sleep: \(userSettings.formattedSleepTarget)")
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Goals")
        } footer: {
            Text("Set your daily step, calorie, and sleep targets to track your progress.")
        }
    }
}

// MARK: - Preview

struct GoalsSettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            GoalsSettingsSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
