import SwiftUI

/// Goals settings section - Daily targets for steps and calories
struct GoalsSettingsSection: View {
    @ObservedObject private var viewState = SettingsViewState.shared

    private var formattedSleepTarget: String {
        let hours = Int(viewState.sleepSettings.targetHours)
        let minutes = viewState.sleepSettings.targetMinutes
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        Section {
            NavigationLink(destination: GoalsSettingsView()) {
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text("Daily Goals")
                        .font(TypeScale.font(size: TypeScale.md))

                    Text("Steps: \(viewState.goalsSettings.stepGoal) • Calories: \(Int(viewState.goalsSettings.calorieGoal)) • Sleep: \(formattedSleepTarget)")
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
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
