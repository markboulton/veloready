import SwiftUI

/// ML Personalization section for settings
struct MLPersonalizationSection: View {
    @StateObject private var mlRegistry = MLModelRegistry.shared
    
    var body: some View {
        Section {
            NavigationLink(destination: MLPersonalizationSettingsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.MLPersonalization.title)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        if mlRegistry.isMLEnabled {
                            Text(SettingsContent.MLPersonalization.enabled)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.success)
                        } else {
                            Text(SettingsContent.MLPersonalization.disabled)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                    }
                }
            }
        } header: {
            Text(SettingsContent.personalizationSection)
        } footer: {
            Text(SettingsContent.MLPersonalization.footer)
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
