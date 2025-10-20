import SwiftUI
import PhotosUI

/// Profile editing view with user info and avatar picker
struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Avatar Section
                Section {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Avatar Display
                            ZStack(alignment: .bottomTrailing) {
                                if let image = viewModel.avatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.secondary)
                                        )
                                }
                                
                                // Edit Button
                                Button(action: {
                                    viewModel.showingImagePicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: 8)
                            }
                            
                            if viewModel.avatarImage != nil {
                                Button("Remove Photo", role: .destructive) {
                                    viewModel.removeAvatar()
                                }
                                .font(.caption)
                            }
                        }
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // Personal Info
                Section {
                    TextField("Name", text: $viewModel.name)
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Personal Information")
                } footer: {
                    Text("This information is stored locally on your device.")
                }
                
                // Athletic Info
                Section {
                    HStack {
                        Text(SettingsContent.Profile.name)
                        Spacer()
                        TextField("", value: $viewModel.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(SettingsContent.Profile.email)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(SettingsContent.Profile.weight)
                        Spacer()
                        TextField("", value: $viewModel.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(SettingsContent.Profile.weight)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(SettingsContent.Profile.height)
                        Spacer()
                        TextField("", value: $viewModel.height, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(SettingsContent.Profile.name)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(SettingsContent.Profile.editProfile)
                } footer: {
                    Text("Used for calculating BMR and other metrics.")
                }
                
                // Connected Services
                Section {
                    if let intervalsID = viewModel.intervalsID {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
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
                            Text(SettingsContent.Profile.editProfile)
                            Spacer()
                            Text(stravaID)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if viewModel.intervalsID == nil && viewModel.stravaID == nil {
                        Text("No connected services")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Connected Services")
                } footer: {
                    Text("Connect services in Data Sources settings.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(
                isPresented: $viewModel.showingImagePicker,
                selection: $viewModel.selectedPhoto,
                matching: .images
            )
            .onChange(of: viewModel.selectedPhoto) { _, newValue in
                if let newValue {
                    viewModel.loadImage(from: newValue)
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class ProfileEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var age: Int = 0
    @Published var weight: Double = 0
    @Published var height: Int = 0
    @Published var avatarImage: UIImage?
    @Published var showingImagePicker = false
    @Published var selectedPhoto: PhotosPickerItem?
    
    var intervalsID: String?
    var stravaID: String?
    
    private let profileKey = "userProfile"
    private let avatarKey = "userAvatar"
    
    init() {
        loadProfile()
        loadConnectedServices()
    }
    
    func loadProfile() {
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
    }
    
    func saveProfile() {
        let profile = UserProfile(
            name: name,
            email: email,
            age: age,
            weight: weight,
            height: height
        )
        
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
            Logger.info("✅ Profile saved", category: .data)
        }
        
        // Save avatar
        if let image = avatarImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: avatarKey)
            Logger.info("✅ Avatar saved", category: .data)
        }
    }
    
    func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Resize image to save space
                let resized = resizeImage(image, targetSize: CGSize(width: 300, height: 300))
                await MainActor.run {
                    self.avatarImage = resized
                }
            }
        }
    }
    
    func removeAvatar() {
        avatarImage = nil
        UserDefaults.standard.removeObject(forKey: avatarKey)
        Logger.info("🗑️ Avatar removed", category: .data)
    }
    
    private func loadConnectedServices() {
        // Check Intervals.icu
        if IntervalsOAuthManager.shared.isAuthenticated {
            intervalsID = IntervalsOAuthManager.shared.user?.id ?? "Connected"
        }
        
        // Check Strava
        if StravaAuthService.shared.connectionState.isConnected {
            stravaID = "Connected" // Strava doesn't expose athlete ID easily
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable {
    let name: String
    let email: String
    let age: Int
    let weight: Double
    let height: Int
}

// MARK: - Preview

#Preview {
    ProfileEditView()
}
