import SwiftUI

/// Data sources section for connecting external services
struct DataSourcesSection: View {
    var body: some View {
        Section {
            HapticNavigationLink(destination: DataSourcesSettingsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.DataSources.title)
                            .font(TypeScale.font(size: TypeScale.md))
                        Text(SettingsContent.DataSources.subtitle)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.secondary.opacity(0.5))
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
