import SwiftUI

/// Notification settings section
struct NotificationSettingsSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color.semantic.warning)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(.body)
                        
                        Text("Sleep reminders and recovery alerts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Manage sleep reminders and recovery notifications.")
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
