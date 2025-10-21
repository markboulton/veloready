import SwiftUI

/// Display settings section
struct DisplaySettingsSection: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Section {
            // Theme settings
            NavigationLink(destination: ThemeSettingsView()) {
                HStack {
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
            
            // Today page layout
            NavigationLink(destination: TodaySectionOrderView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text("Today Page Layout")
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text("Customize section order")
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
