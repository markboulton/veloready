import SwiftUI

/// Settings view for app theme selection
struct ThemeSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button(action: {
                        withAnimation {
                            themeManager.currentTheme = theme
                        }
                    }) {
                        HStack {
                            Image(systemName: theme.icon)
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme == theme ? .button.primary : .text.secondary)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.rawValue)
                                    .font(.body)
                                    .foregroundColor(.text.primary)
                                
                                Text(themeDescription(for: theme))
                                    .font(.caption)
                                    .foregroundColor(.text.secondary)
                            }
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.button.primary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } header: {
                Text(SettingsContent.Theme.appearance)
            } footer: {
                Text(SettingsContent.Theme.footer)
            }
        }
        .navigationTitle(SettingsContent.Theme.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        case .auto:
            return "Match system settings"
        }
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}
