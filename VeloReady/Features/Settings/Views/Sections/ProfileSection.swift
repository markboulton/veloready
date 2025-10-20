import SwiftUI

/// Profile section showing user info with edit capability
struct ProfileSection: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var refreshTrigger = false
    
    var body: some View {
        Section {
            NavigationLink(destination: ProfileView()
                .onDisappear {
                    // Reload profile when returning from ProfileView
                    viewModel.loadProfile()
                }
            ) {
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
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(viewModel.name.isEmpty ? SettingsContent.Profile.user : viewModel.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !viewModel.email.isEmpty {
                            Text(viewModel.email)
                                .font(.subheadline)
                                .foregroundColor(ColorPalette.labelSecondary)
                        } else {
                            Text(SettingsContent.Profile.tapToEdit)
                                .font(.subheadline)
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, Spacing.sm)
            }
        } header: {
            Text(SettingsContent.profileSection)
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
