import SwiftUI

/// Settings for ML personalization features
struct MLPersonalizationSettingsView: View {
    @StateObject private var mlRegistry = MLModelRegistry.shared
    @StateObject private var mlService = MLTrainingDataService.shared
    
    var body: some View {
        List {
            Section {
                Toggle("Personalized Recovery", isOn: Binding(
                    get: { mlRegistry.isMLEnabled },
                    set: { mlRegistry.setMLEnabled($0) }
                ))
                
                Text("Uses machine learning to personalize your recovery score based on your unique patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("ML Personalization", systemImage: "sparkles")
            }
            
            Section("Status") {
                HStack {
                    Text("Training Data")
                    Spacer()
                    Text("\(mlService.trainingDataCount) days")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Model Status")
                    Spacer()
                    if mlRegistry.currentModelVersion != nil {
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Training", systemImage: "clock")
                            .foregroundColor(.orange)
                    }
                }
                
                if mlService.trainingDataCount < 30 {
                    HStack {
                        Text("Days Until Ready")
                        Spacer()
                        Text("\(30 - mlService.trainingDataCount) days")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Text("Personalized recovery uses machine learning trained on YOUR data to provide more accurate recovery predictions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Requires 30 days of data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Learns your unique patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Updates weekly")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Falls back to standard if unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("How It Works")
            }
        }
        .navigationTitle("ML Personalization")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MLPersonalizationSettingsView()
    }
}
