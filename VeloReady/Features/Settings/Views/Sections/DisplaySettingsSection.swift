import SwiftUI

/// Display settings section
struct DisplaySettingsSection: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Section {
            // Theme settings
            NavigationLink(destination: ThemeSettingsView()) {
                HStack {
                    Image(systemName: themeManager.currentTheme.icon)
                        .foregroundColor(ColorPalette.aiIconColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Appearance.theme)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(themeManager.currentTheme.rawValue + " mode")
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Display preferences
            NavigationLink(destination: DisplaySettingsView()) {
                HStack {
                    Image(systemName: Icons.System.eye)
                        .foregroundColor(ColorPalette.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Appearance.displayPreferences)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(SettingsContent.Appearance.unitsTimeFormat)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text(SettingsContent.appearanceSection)
        } footer: {
            Text(SettingsContent.Appearance.footer)
        }
    }
}

// MARK: - Preview

struct DisplaySettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DisplaySettingsSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
