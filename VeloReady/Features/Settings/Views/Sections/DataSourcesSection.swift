import SwiftUI

/// Data sources section for connecting external services
struct DataSourcesSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: DataSourcesSettingsView()) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(ColorPalette.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.DataSources.title)
                            .font(TypeScale.font(size: TypeScale.md))
                        Text(SettingsContent.DataSources.subtitle)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text(SettingsContent.integrationsSection)
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
