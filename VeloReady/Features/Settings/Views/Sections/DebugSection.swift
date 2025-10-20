import SwiftUI

/// Debug section (Developers only - controlled by DebugFlags)
struct DebugSection: View {
    var body: some View {
        // Only show if user is a developer
        if DebugFlags.showDebugMenu {
            Section {
                NavigationLink(destination: DebugSettingsView()) {
                    HStack {
                        Image(systemName: Icons.System.hammerFill)
                            .foregroundColor(Color.semantic.warning)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                            Text(SettingsContent.Debug.title)
                                .font(TypeScale.font(size: TypeScale.md))
                            
                            Text(SettingsContent.Debug.subtitle)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                        
                        Spacer()
                        
                        // Show environment badge
                        Text(DebugFlags.buildEnvironment)
                            .font(TypeScale.font(size: TypeScale.xxs))
                            .padding(.horizontal, Spacing.xs + 2)
                            .padding(.vertical, Spacing.xs / 2)
                            .background(ColorPalette.warning.opacity(0.2))
                            .cornerRadius(Spacing.xs)
                    }
                }
            } header: {
                Text(SettingsContent.developerSection)
            } footer: {
                Text("\(SettingsContent.Debug.developerFooter)\n\n\(SettingsContent.Debug.deviceIdPrefix)\(DebugFlags.getDeviceIdentifier())")
            }
        }
    }
}

// MARK: - Preview

struct DebugSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DebugSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
