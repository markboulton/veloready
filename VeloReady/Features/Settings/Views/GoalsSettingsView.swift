import SwiftUI

/// Goals settings view - Configure daily step and calorie targets
struct GoalsSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Step Goals
                Section {
                    VStack(alignment: .leading, spacing: 8) {
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
                    
                    if !userSettings.useBMRAsGoal {
                        VStack(alignment: .leading, spacing: 8) {
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
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Calorie Goals")
                } footer: {
                    Text("Set your daily calorie goal. Use BMR (Basal Metabolic Rate) or set a custom target.")
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct GoalsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsSettingsView()
    }
}
