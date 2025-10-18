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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .font(.body)
                        
                        Text(themeManager.currentTheme.rawValue + " mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Display preferences
            NavigationLink(destination: DisplaySettingsView()) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(ColorPalette.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Display Preferences")
                            .font(.body)
                        
                        Text("Units, time format, and visibility")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Customize theme and how information is displayed in the app.")
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
