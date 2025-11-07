import SwiftUI

/// Goals settings view - Configure daily step and calorie targets
struct GoalsSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
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
                            
                            Stepper(value: $userSettings.stepGoal, in: 1000...30000, step: 500) {
                                Text("\(userSettings.stepGoal) steps")
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .onChange(of: userSettings.stepGoal) { _, _ in
                                HapticFeedback.selection()
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
                    Toggle("Use BMR as Calorie Goal", isOn: $userSettings.useBMRAsGoal)
                        .onChange(of: userSettings.useBMRAsGoal) { _, _ in
                            HapticFeedback.selection()
                        }
                    
                    if !userSettings.useBMRAsGoal {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Daily Calorie Target")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Calories:")
                                    .frame(width: 80, alignment: .leading)
                                
                                Stepper(value: $userSettings.calorieGoal, in: 1000...5000, step: 50) {
                                    Text("\(Int(userSettings.calorieGoal)) \(CommonContent.Units.calories)")
                                        .frame(width: 100, alignment: .trailing)
                                }
                                .onChange(of: userSettings.calorieGoal) { _, _ in
                                    HapticFeedback.selection()
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
                            
                            Stepper(value: $userSettings.sleepTargetHours, in: 4...12, step: 0.5) {
                                Text("\(userSettings.sleepTargetHours, specifier: "%.1f")")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .onChange(of: userSettings.sleepTargetHours) { _, _ in
                                HapticFeedback.selection()
                            }
                        }
                        
                        HStack {
                            Text("Minutes:")
                                .frame(width: 80, alignment: .leading)
                            
                            Stepper(value: $userSettings.sleepTargetMinutes, in: 0...59, step: 15) {
                                Text("\(userSettings.sleepTargetMinutes)")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .onChange(of: userSettings.sleepTargetMinutes) { _, _ in
                                HapticFeedback.selection()
                            }
                        }
                        
                        Text("Total: \(userSettings.formattedSleepTarget)")
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
}

// MARK: - Preview

struct GoalsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsSettingsView()
    }
}
