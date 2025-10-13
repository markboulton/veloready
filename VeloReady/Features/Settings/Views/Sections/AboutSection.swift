import SwiftUI

/// About section showing app info
struct AboutSection: View {
    var body: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("About VeloReady")
                        .font(.body)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Help & Support")
                        .font(.body)
                    
                    Text("Get help and report issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - Preview

struct AboutSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AboutSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
