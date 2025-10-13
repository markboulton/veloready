import SwiftUI

/// Profile section showing user info
struct ProfileSection: View {
    var body: some View {
        Section {
            HStack {
                // Profile avatar placeholder
                Circle()
                    .fill(ColorScale.purpleAccent)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("VeloReady User")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Cycling Performance Tracker")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text("Profile")
        }
    }
}

// MARK: - Preview

struct ProfileSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProfileSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
