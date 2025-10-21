import SwiftUI

/// Profile view showing user info with edit capability
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    
    var body: some View {
        List {
            // Avatar and Name Section
            Section {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Avatar
                        if let image = viewModel.avatarImage {
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
                        if !viewModel.name.isEmpty {
                            Text(viewModel.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        // Email
                        if !viewModel.email.isEmpty {
                            Text(viewModel.email)
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
            if viewModel.hasAthleticInfo {
                Section {
                    if viewModel.age > 0 {
                        HStack {
                            Text(SettingsContent.Profile.title)
                            Spacer()
                            Text("\(viewModel.age) years")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.weight > 0 {
                        HStack {
                            Text(SettingsContent.Profile.weight)
                            Spacer()
                            Text("\(String(format: "%.1f", viewModel.weight)) kg")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.height > 0 {
                        HStack {
                            Text(SettingsContent.Profile.height)
                            Spacer()
                            Text("\(viewModel.height) cm")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.bmr > 0 {
                        HStack {
                            Text(SettingsContent.Profile.bmr)
                            Spacer()
                            Text("\(Int(viewModel.bmr)) \(CommonContent.Units.calories)/day")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(SettingsContent.Profile.athleticProfile)
                }
            }
            
            // Connected Services
            Section {
                if let intervalsID = viewModel.intervalsID {
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
                
                if let stravaID = viewModel.stravaID {
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
                
                if viewModel.intervalsID == nil && viewModel.stravaID == nil {
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
            viewModel.loadProfile()
        }) {
            ProfileEditView()
        }
        .onAppear {
            viewModel.loadProfile()
        }
        .refreshable {
            viewModel.loadProfile()
        }
    }
}

// MARK: - View Model

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var age: Int = 0
    @Published var weight: Double = 0
    @Published var height: Int = 0
    @Published var avatarImage: UIImage?
    @Published var isLoading = false
    
    var intervalsID: String?
    var stravaID: String?
    
    private let profileKey = "userProfile"
    private let avatarKey = "userAvatar"
    
    var hasAthleticInfo: Bool {
        age > 0 || weight > 0 || height > 0
    }
    
    var bmr: Double {
        guard weight > 0, height > 0, age > 0 else { return 0 }
        // Mifflin-St Jeor Equation (assuming male, can be made configurable)
        return (10 * weight) + (6.25 * Double(height)) - (5 * Double(age)) + 5
    }
    
    func loadProfile() {
        isLoading = true
        defer { isLoading = false }
        
        // Load profile data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            // Only use UserDefaults name if AthleteProfile doesn't have one
            if AthleteProfileManager.shared.profile.fullName == nil {
                name = profile.name
            }
            email = profile.email
            age = profile.age
            weight = profile.weight
            height = profile.height
        }
        
        // Load name from AthleteProfileManager (synced from Strava)
        let athleteProfile = AthleteProfileManager.shared.profile
        if let fullName = athleteProfile.fullName {
            name = fullName
        }
        
        // Load avatar from Strava profile photo URL
        if let photoURLString = athleteProfile.profilePhotoURL,
           let photoURL = URL(string: photoURLString) {
            Task {
                await loadProfilePhoto(from: photoURL)
            }
        } else {
            // Fallback to local avatar
            if let imageData = UserDefaults.standard.data(forKey: avatarKey),
               let image = UIImage(data: imageData) {
                avatarImage = image
            }
        }
        
        // Load connected services
        loadConnectedServices()
    }
    
    private func loadProfilePhoto(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                }
            }
        } catch {
            Logger.error("Failed to load profile photo from Strava: \(error)")
        }
    }
    
    private func loadConnectedServices() {
        // Check Intervals.icu
        if IntervalsOAuthManager.shared.isAuthenticated {
            intervalsID = IntervalsOAuthManager.shared.user?.id ?? "Connected"
        } else {
            intervalsID = nil
        }
        
        // Check Strava
        if StravaAuthService.shared.connectionState.isConnected {
            stravaID = "Connected"
        } else {
            stravaID = nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
    }
}
