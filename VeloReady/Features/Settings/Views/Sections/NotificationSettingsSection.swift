import SwiftUI

/// Notification settings section
struct NotificationSettingsSection: View {
    var body: some View {
        Section {
            HapticNavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Notifications.title)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(SettingsContent.Notifications.subtitle)
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
            Text(SettingsContent.notificationsSection)
        } footer: {
            Text(SettingsContent.Notifications.description)
        }
    }
}

// MARK: - Preview

struct NotificationSettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            NotificationSettingsSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
