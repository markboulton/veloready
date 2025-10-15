import SwiftUI

/// Debug section (Developers only - controlled by DebugFlags)
struct DebugSection: View {
    var body: some View {
        // Only show if user is a developer
        if DebugFlags.showDebugMenu {
            Section {
                NavigationLink(destination: DebugSettingsView()) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(Color.semantic.warning)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DEBUG & TESTING")
                                .font(.body)
                            
                            Text("Developer tools and testing options")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Show environment badge
                        Text(DebugFlags.buildEnvironment)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.semantic.warning.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            } header: {
                Text("Developer")
            } footer: {
                Text("Debug tools, cache management, and testing features. Only visible to developers.\n\nDevice ID: \(DebugFlags.getDeviceIdentifier())")
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
