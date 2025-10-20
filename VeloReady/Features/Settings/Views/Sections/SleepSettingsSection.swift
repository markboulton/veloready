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
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Sleep.targetTitle)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(userSettings.formattedSleepTarget)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text(SettingsContent.sleepSection)
        } footer: {
            Text(SettingsContent.Sleep.footer)
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
