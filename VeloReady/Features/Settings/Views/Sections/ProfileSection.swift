import SwiftUI

/// Profile section showing user info with edit capability
struct ProfileSection: View {
    @StateObject private var viewState = ProfileViewState()
    @State private var refreshTrigger = false

    var body: some View {
        Section {
            NavigationLink(destination: ProfileView()
                .onDisappear {
                    // Reload profile when returning from ProfileView
                    viewState.loadProfile()
                }
            ) {
                HStack {
                    // Profile avatar
                    if let image = viewState.avatarImage {
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
                                Image(systemName: Icons.System.person)
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(viewState.name.isEmpty ? SettingsContent.Profile.user : viewState.name)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if !viewState.email.isEmpty {
                            Text(viewState.email)
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
            viewState.loadProfile()
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
