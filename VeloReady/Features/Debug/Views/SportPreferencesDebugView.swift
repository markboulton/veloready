import SwiftUI

/// Debug view to test SportPreferences functionality
struct SportPreferencesDebugView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var testOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text(DebugContent.SportPreferences.currentPrefs)
                        .font(.headline)
                    
                    Text("Primary Sport: \(userSettings.primarySport.displayName)")
                        .foregroundColor(.blue)
                    
                    ForEach(userSettings.orderedSports, id: \.self) { sport in
                        if let rank = userSettings.sportPreferences.ranking(for: sport) {
                            HStack {
                                Text("#\(rank)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Image(systemName: sport.icon)
                                
                                Text(sport.displayName)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Divider()
                
                // Test Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text(DebugContent.SportPreferences.testActions)
                        .font(.headline)
                    
                    Button(DebugContent.SportPreferences.setCycling) {
                        let newPrefs = SportPreferences(primarySport: .cycling)
                        userSettings.sportPreferences = newPrefs
                        testOutput = "✅ Set cycling as primary"
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setStrength) {
                        let newPrefs = SportPreferences(primarySport: .strength)
                        userSettings.sportPreferences = newPrefs
                        testOutput = "✅ Set strength as primary"
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setGeneral) {
                        let newPrefs = SportPreferences(primarySport: .general)
                        userSettings.sportPreferences = newPrefs
                        testOutput = "✅ Set general as primary"
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setFullRanking) {
                        let newPrefs = SportPreferences(orderedSports: [.cycling, .strength, .general])
                        userSettings.sportPreferences = newPrefs
                        testOutput = "✅ Set full ranking"
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(DebugContent.SportPreferences.runTests) {
                        SportPreferencesTests.runAllTests()
                        testOutput = "✅ Check console for test results"
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button(DebugContent.SportPreferences.resetDefaults) {
                        userSettings.sportPreferences = .default
                        testOutput = "✅ Reset to defaults"
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Output
                if !testOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Output")
                            .font(.headline)
                        
                        Text(testOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Technical Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technical Details")
                        .font(.headline)
                    
                    Text("Codable: ✅")
                    Text("Equatable: ✅")
                    Text("Saved to: UserDefaults")
                    Text("Synced to: iCloud")
                    Text("Key: UserSettings.sportPreferences")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Sport Preferences Debug")
    }
}

#Preview {
    NavigationStack {
        SportPreferencesDebugView()
    }
}
