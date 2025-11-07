import SwiftUI

/// Debug view to test SportPreferences functionality
struct SportPreferencesDebugView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var testOutput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Settings
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(DebugContent.SportPreferences.currentPrefs)
                        .font(.headline)
                    
                    Text(DebugContent.SportPreferencesDebugExtended.primarySportPrefix + userSettings.primarySport.displayName)
                        .foregroundColor(.blue)
                    
                    ForEach(userSettings.orderedSports, id: \.self) { sport in
                        if let rank = userSettings.sportPreferences.ranking(for: sport) {
                            HStack {
                                Text(DebugContent.SportPreferencesDebugExtended.rankPrefix + "\(rank)")
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
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(DebugContent.SportPreferences.testActions)
                        .font(.headline)
                    
                    Button(DebugContent.SportPreferences.setCycling) {
                        let newPrefs = SportPreferences(primarySport: .cycling)
                        userSettings.sportPreferences = newPrefs
                        testOutput = DebugContent.SportPreferencesDebugExtended.setCyclingSuccess
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setStrength) {
                        let newPrefs = SportPreferences(primarySport: .strength)
                        userSettings.sportPreferences = newPrefs
                        testOutput = DebugContent.SportPreferencesDebugExtended.setStrengthSuccess
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setGeneral) {
                        let newPrefs = SportPreferences(primarySport: .general)
                        userSettings.sportPreferences = newPrefs
                        testOutput = DebugContent.SportPreferencesDebugExtended.setGeneralSuccess
                    }
                    .buttonStyle(.bordered)
                    
                    Button(DebugContent.SportPreferences.setFullRanking) {
                        let newPrefs = SportPreferences(orderedSports: [.cycling, .strength, .general])
                        userSettings.sportPreferences = newPrefs
                        testOutput = DebugContent.SportPreferencesDebugExtended.setFullRankingSuccess
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(DebugContent.SportPreferences.runTests) {
                        SportPreferencesTests.runAllTests()
                        testOutput = DebugContent.SportPreferencesDebugExtended.runTestsSuccess
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button(DebugContent.SportPreferences.resetDefaults) {
                        userSettings.sportPreferences = .default
                        testOutput = DebugContent.SportPreferencesDebugExtended.resetDefaultsSuccess
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Output
                if !testOutput.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(DebugContent.SportPreferencesDebugExtended.testOutput)
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
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(DebugContent.SportPreferencesDebugExtended.technicalDetails)
                        .font(.headline)
                    
                    Text(DebugContent.SportPreferencesDebugExtended.codableCheck)
                    Text(DebugContent.SportPreferencesDebugExtended.equatableCheck)
                    Text(DebugContent.SportPreferencesDebugExtended.savedTo)
                    Text(DebugContent.SportPreferencesDebugExtended.syncedTo)
                    Text(DebugContent.SportPreferencesDebugExtended.settingsKey)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(DebugContent.Navigation.sportPreferencesDebug)
    }
}

#Preview {
    NavigationStack {
        SportPreferencesDebugView()
    }
}
