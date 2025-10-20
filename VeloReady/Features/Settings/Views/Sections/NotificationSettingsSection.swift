import SwiftUI

/// Notification settings section
struct NotificationSettingsSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: Icons.System.bell)
                        .foregroundColor(Color.semantic.warning)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Notifications.title)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(SettingsContent.Notifications.subtitle)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
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
