import SwiftUI

/// Sleep settings section
struct SleepSettingsSection: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        Section {
            NavigationLink(destination: SleepSettingsView()) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(Color.health.sleep)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sleep Target")
                            .font(.body)
                        
                        Text(userSettings.formattedSleepTarget)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Sleep")
        } footer: {
            Text("Configure your sleep preferences and targets for better recovery tracking.")
        }
    }
}

// MARK: - Preview

struct SleepSettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SleepSettingsSection(userSettings: UserSettings.shared)
        }
        .previewLayout(.sizeThatFits)
    }
}
