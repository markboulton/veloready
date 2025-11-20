import SwiftUI

/// Sleep settings section
struct SleepSettingsSection: View {
    @ObservedObject private var viewState = SettingsViewState.shared

    private var formattedSleepTarget: String {
        let hours = Int(viewState.sleepSettings.targetHours)
        let minutes = viewState.sleepSettings.targetMinutes
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        Section {
            NavigationLink(destination: SleepSettingsView()) {
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(SettingsContent.Sleep.targetTitle)
                        .font(TypeScale.font(size: TypeScale.md))

                    Text(formattedSleepTarget)
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
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
            SleepSettingsSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
