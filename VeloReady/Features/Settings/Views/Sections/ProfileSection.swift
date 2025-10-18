import SwiftUI

/// Profile section showing user info with edit capability
struct ProfileSection: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        Section {
            NavigationLink(destination: ProfileView()) {
                HStack {
                    // Profile avatar
                    if let image = viewModel.avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(ColorScale.purpleAccent)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.name.isEmpty ? "VeloReady User" : viewModel.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !viewModel.email.isEmpty {
                            Text(viewModel.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to edit profile")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Profile")
        }
        .onAppear {
            viewModel.loadProfile()
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
