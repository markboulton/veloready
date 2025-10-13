import SwiftUI

/// Display settings section
struct DisplaySettingsSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: DisplaySettingsView()) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(ColorPalette.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Display Preferences")
                            .font(.body)
                        
                        Text("Units, time format, and visibility")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Display")
        } footer: {
            Text("Customize how information is displayed in the app.")
        }
    }
}

// MARK: - Preview

struct DisplaySettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DisplaySettingsSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
