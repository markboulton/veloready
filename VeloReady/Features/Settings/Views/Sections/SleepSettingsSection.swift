import SwiftUI

/// Sleep settings section
struct SleepSettingsSection: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        Section {
            HapticNavigationLink(destination: SleepSettingsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Sleep.targetTitle)
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text(userSettings.formattedSleepTarget)
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
