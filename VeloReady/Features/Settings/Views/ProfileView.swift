import SwiftUI

/// Profile view showing user info with edit capability
struct ProfileView: View {
    @StateObject private var viewState = ProfileViewState()
    @State private var showingEditProfile = false
    
    var body: some View {
        List {
            // Avatar and Name Section
            Section {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Avatar
                        if let image = viewState.avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: Icons.System.person)
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                )
                        }

                        // Name
                        if !viewState.name.isEmpty {
                            Text(viewState.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        // Email
                        if !viewState.email.isEmpty {
                            Text(viewState.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Edit Button
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Label(SettingsContent.Profile.editProfileLabel, systemImage: "pencil")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            // Athletic Info
            if viewState.hasAthleticInfo {
                Section {
                    if viewState.age > 0 {
                        HStack {
                            Text(SettingsContent.Profile.title)
                            Spacer()
                            Text("\(viewState.age) years")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewState.weight > 0 {
                        HStack {
                            Text(SettingsContent.Profile.weight)
                            Spacer()
                            Text("\(String(format: "%.1f", viewState.weight)) kg")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewState.height > 0 {
                        HStack {
                            Text(SettingsContent.Profile.height)
                            Spacer()
                            Text("\(viewState.height) cm")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewState.bmr > 0 {
                        HStack {
                            Text(SettingsContent.Profile.bmr)
                            Spacer()
                            Text("\(Int(viewState.bmr)) \(CommonContent.Units.calories)/day")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(SettingsContent.Profile.athleticProfile)
                }
            }
            
            // Connected Services
            Section {
                if let intervalsID = viewState.intervalsID {
                    HStack {
                        Image(systemName: Icons.DataSource.intervalsICU)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text(SettingsContent.Profile.dateOfBirth)
                        Spacer()
                        Text(intervalsID)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if let stravaID = viewState.stravaID {
                    HStack {
                        Image(systemName: Icons.DataSource.strava)
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text(SettingsContent.Profile.strava)
                        Spacer()
                        Text(stravaID)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if viewState.intervalsID == nil && viewState.stravaID == nil {
                    HStack {
                        Image(systemName: Icons.System.linkCircle)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text(SettingsContent.Profile.noConnectedServices)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(SettingsContent.Profile.connectedServicesSection)
            } footer: {
                Text(SettingsContent.Profile.connectedServicesFooter)
            }
        }
        .navigationTitle(SettingsContent.Profile.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditProfile, onDismiss: {
            // Reload profile when edit sheet dismisses
            viewState.loadProfile()
        }) {
            ProfileEditView()
        }
        .onAppear {
            viewState.loadProfile()
        }
        .refreshable {
            viewState.loadProfile()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
    }
}
