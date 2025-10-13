import SwiftUI

/// Debug section (DEBUG builds only)
struct DebugSection: View {
    var body: some View {
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
                }
            }
        } header: {
            Text("Developer")
        } footer: {
            Text("Debug tools, cache management, and testing features.")
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
