import SwiftUI

/// Data sources section for connecting external services
struct DataSourcesSection: View {
    var body: some View {
        Section {
            HapticNavigationLink(destination: DataSourcesSettingsView()) {
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(SettingsContent.DataSources.title)
                        .font(TypeScale.font(size: TypeScale.md))
                    Text(SettingsContent.DataSources.subtitle)
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
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
