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
                                    Image(systemName: "person.fill")
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
                            Label("Edit Profile", systemImage: "pencil")
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
                            Text("\(Int(viewModel.bmr)) cal/day")
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
                        Image(systemName: "chart.line.uptrend.xyaxis")
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
                        Image(systemName: "figure.outdoor.cycle")
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
                        Image(systemName: "link.circle")
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
        
        // Load profile data
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            name = profile.name
            email = profile.email
            age = profile.age
            weight = profile.weight
            height = profile.height
        }
        
        // Load avatar
        if let imageData = UserDefaults.standard.data(forKey: avatarKey),
           let image = UIImage(data: imageData) {
            avatarImage = image
        }
        
        // Load connected services
        loadConnectedServices()
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
