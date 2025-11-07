import SwiftUI

/// Debug section - Shows alpha tester settings in DEBUG builds, full debug menu for developers
struct DebugSection: View {
    var body: some View {
        #if DEBUG
        // Alpha testers get simplified settings
        Section {
            NavigationLink(destination: AlphaTesterSettingsView()) {
                HStack {
                    Image(systemName: Icons.System.sparkles)
                        .foregroundColor(ColorScale.blueAccent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text("Alpha Testing")
                            .font(TypeScale.font(size: TypeScale.md))
                        
                        Text("Test features and report bugs")
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                    
                    // Show ALPHA badge
                    Text("ALPHA")
                        .font(TypeScale.font(size: TypeScale.xxs))
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.xs + 2)
                        .padding(.vertical, Spacing.xs / 2)
                        .background(ColorScale.blueAccent.opacity(0.2))
                        .foregroundColor(ColorScale.blueAccent)
                        .cornerRadius(Spacing.xs)
                }
            }
            
            // Full debug menu for developers only
            if DebugFlags.showDebugMenu {
                NavigationLink(destination: DebugHub()) {
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
                
                // Icon Test Sheet
                NavigationLink(destination: IconTestView()) {
                    HStack {
                        Image(systemName: Icons.System.grid2x2)
                            .foregroundColor(ColorPalette.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                            Text("Icon Test Sheet")
                                .font(TypeScale.font(size: TypeScale.md))
                            
                            Text("View all SF Symbols and custom icons")
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        } header: {
            Text(DebugFlags.showDebugMenu ? SettingsContent.developerSection : "Testing")
        } footer: {
            if DebugFlags.showDebugMenu {
                Text("\(SettingsContent.Debug.developerFooter)\n\n\(SettingsContent.Debug.deviceIdPrefix)\(DebugFlags.getDeviceIdentifier())")
            } else {
                Text("Thank you for helping test VeloReady! Enable debug logging to help us track down bugs.")
            }
        }
        #endif
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
