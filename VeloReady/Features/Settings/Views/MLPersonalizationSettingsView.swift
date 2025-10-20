import SwiftUI

/// Settings for ML personalization features
struct MLPersonalizationSettingsView: View {
    @StateObject private var mlRegistry = MLModelRegistry.shared
    @StateObject private var mlService = MLTrainingDataService.shared
    
    var body: some View {
        List {
            Section {
                Toggle(SettingsContent.MLPersonalizationSettings.personalizedRecovery, isOn: Binding(
                    get: { mlRegistry.isMLEnabled },
                    set: { mlRegistry.setMLEnabled($0) }
                ))
                
                Text(SettingsContent.MLPersonalizationSettings.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label(SettingsContent.MLPersonalizationSettings.mlPersonalizationHeader, systemImage: "sparkles")
            }
            
            Section(SettingsContent.MLPersonalizationSettings.statusSection) {
                HStack {
                    Text(SettingsContent.MLPersonalizationSettings.trainingData)
                    Spacer()
                    Text("\(mlService.trainingDataCount) \(TrendsContent.Units.days)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(SettingsContent.MLPersonalizationSettings.modelStatus)
                    Spacer()
                    if mlRegistry.currentModelVersion != nil {
                        Label(SettingsContent.MLPersonalizationSettings.ready, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label(SettingsContent.MLPersonalizationSettings.notReady, systemImage: "xmark.circle")
                            .foregroundColor(.orange)
                    }
                }
                
                if mlService.trainingDataCount < 30 {
                    HStack {
                        Text(SettingsContent.MLPersonalizationSettings.daysUntilReady)
                        Spacer()
                        Text("\(30 - mlService.trainingDataCount) \(TrendsContent.Units.days)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Text(SettingsContent.MLPersonalizationSettings.howItWorksDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(SettingsContent.MLPersonalizationSettings.requires30Days)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(SettingsContent.MLPersonalizationSettings.learnsPatterns)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(SettingsContent.MLPersonalizationSettings.updatesWeekly)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(SettingsContent.MLPersonalizationSettings.fallbackStandard)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text(SettingsContent.MLPersonalizationSettings.howItWorks)
            }
        }
        .navigationTitle(SettingsContent.MLPersonalizationSettings.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MLPersonalizationSettingsView()
    }
}
