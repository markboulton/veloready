import SwiftUI

/// ML Personalization section for settings
struct MLPersonalizationSection: View {
    @StateObject private var mlRegistry = MLModelRegistry.shared
    
    var body: some View {
        Section {
            NavigationLink(destination: MLPersonalizationSettingsView()) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ML Personalization")
                            .font(.body)
                        
                        if mlRegistry.isMLEnabled {
                            Text("Enabled")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Personalization")
        } footer: {
            Text("Machine learning personalization for more accurate recovery predictions")
        }
    }
}

// MARK: - Preview

struct MLPersonalizationSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MLPersonalizationSection()
        }
    }
}
