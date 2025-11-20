import SwiftUI

/// Goals settings view - Configure daily step and calorie targets
struct GoalsSettingsView: View {
    @ObservedObject private var viewState = SettingsViewState.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Step Goals
            Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Daily Step Target")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("Steps:")
                                .frame(width: 80, alignment: .leading)

                            Stepper(value: Binding(
                                get: { viewState.goalsSettings.stepGoal },
                                set: { newValue in
                                    Task {
                                        let updated = GoalsSettings(
                                            calorieGoal: viewState.goalsSettings.calorieGoal,
                                            useBMRAsGoal: viewState.goalsSettings.useBMRAsGoal,
                                            stepGoal: newValue
                                        )
                                        await viewState.saveGoalsSettings(updated)
                                        HapticFeedback.selection()
                                    }
                                }
                            ), in: 1000...30000, step: 500) {
                                Text("\(viewState.goalsSettings.stepGoal) steps")
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Step Goals")
                } footer: {
                    Text("Set your daily step target. The default is 10,000 steps per day.")
                }
                
                // Calorie Goals
                Section {
                    Toggle("Use BMR as Calorie Goal", isOn: Binding(
                        get: { viewState.goalsSettings.useBMRAsGoal },
                        set: { newValue in
                            Task {
                                let updated = GoalsSettings(
                                    calorieGoal: viewState.goalsSettings.calorieGoal,
                                    useBMRAsGoal: newValue,
                                    stepGoal: viewState.goalsSettings.stepGoal
                                )
                                await viewState.saveGoalsSettings(updated)
                                HapticFeedback.selection()
                            }
                        }
                    ))

                    if !viewState.goalsSettings.useBMRAsGoal {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Daily Calorie Target")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                Text("Calories:")
                                    .frame(width: 80, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.goalsSettings.calorieGoal },
                                    set: { newValue in
                                        Task {
                                            let updated = GoalsSettings(
                                                calorieGoal: newValue,
                                                useBMRAsGoal: viewState.goalsSettings.useBMRAsGoal,
                                                stepGoal: viewState.goalsSettings.stepGoal
                                            )
                                            await viewState.saveGoalsSettings(updated)
                                            HapticFeedback.selection()
                                        }
                                    }
                                ), in: 1000...5000, step: 50) {
                                    Text("\(Int(viewState.goalsSettings.calorieGoal)) \(CommonContent.Units.calories)")
                                        .frame(width: 100, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Calorie Goals")
                } footer: {
                    Text("Set your daily calorie goal. Use BMR (Basal Metabolic Rate) or set a custom target.")
                }
                
                // Sleep Target
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sleep Target")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text("Hours:")
                                .frame(width: 80, alignment: .leading)

                            Stepper(value: Binding(
                                get: { viewState.sleepSettings.targetHours },
                                set: { newValue in
                                    Task {
                                        let updated = SleepSettings(
                                            targetHours: newValue,
                                            targetMinutes: viewState.sleepSettings.targetMinutes,
                                            reminders: viewState.sleepSettings.reminders,
                                            reminderTime: viewState.sleepSettings.reminderTime,
                                            recoveryAlerts: viewState.sleepSettings.recoveryAlerts
                                        )
                                        await viewState.saveSleepSettings(updated)
                                        HapticFeedback.selection()
                                    }
                                }
                            ), in: 4...12, step: 0.5) {
                                Text("\(viewState.sleepSettings.targetHours, specifier: "%.1f")")
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }

                        HStack {
                            Text("Minutes:")
                                .frame(width: 80, alignment: .leading)

                            Stepper(value: Binding(
                                get: { viewState.sleepSettings.targetMinutes },
                                set: { newValue in
                                    Task {
                                        let updated = SleepSettings(
                                            targetHours: viewState.sleepSettings.targetHours,
                                            targetMinutes: newValue,
                                            reminders: viewState.sleepSettings.reminders,
                                            reminderTime: viewState.sleepSettings.reminderTime,
                                            recoveryAlerts: viewState.sleepSettings.recoveryAlerts
                                        )
                                        await viewState.saveSleepSettings(updated)
                                        HapticFeedback.selection()
                                    }
                                }
                            ), in: 0...59, step: 15) {
                                Text("\(viewState.sleepSettings.targetMinutes)")
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }

                        Text("Total: \(formattedSleepTarget)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Sleep Goals")
                } footer: {
                    Text("Set your nightly sleep target. This is used to calculate your sleep performance score.")
                }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formattedSleepTarget: String {
        let hours = Int(viewState.sleepSettings.targetHours)
        let minutes = viewState.sleepSettings.targetMinutes
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview

struct GoalsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsSettingsView()
    }
}
