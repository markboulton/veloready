import SwiftUI

/// Data sources section for connecting external services
struct DataSourcesSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: DataSourcesSettingsView()) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Sources")
                            .font(.body)
                        Text("Manage connected apps and services")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Integrations")
        }
    }
}

// MARK: - Preview

struct DataSourcesSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DataSourcesSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
