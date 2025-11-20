import Foundation
import UIKit

/// Loads and saves profile data from multiple sources
/// Part of Phase 5 Profile Refactor - extracts data loading from ProfileViewModel
class ProfileDataLoader {

    // MARK: - Dependencies

    private let athleteProfileManager: AthleteProfileManager
    private let intervalsManager: IntervalsOAuthManager
    private let stravaService: StravaAuthService

    // MARK: - Constants

    private let legacyProfileKey = "userProfile"
    private let legacyAvatarKey = "userAvatar"
    private let profileSettingsKey = "ProfileSettings"

    // MARK: - Initialization

    /// Convenience init using shared instances
    @MainActor
    init() {
        self.athleteProfileManager = .shared
        self.intervalsManager = .shared
        self.stravaService = .shared
    }

    /// Dependency injection init for testing
    init(
        athleteProfileManager: AthleteProfileManager,
        intervalsManager: IntervalsOAuthManager,
        stravaService: StravaAuthService
    ) {
        self.athleteProfileManager = athleteProfileManager
        self.intervalsManager = intervalsManager
        self.stravaService = stravaService
    }

    // MARK: - Load Profile

    /// Load profile from all available sources (UserDefaults, AthleteProfile, Strava)
    @MainActor
    func loadProfile() async -> ProfileData {
        // Start with defaults
        var profileSettings = ProfileSettings.default
        var avatarImage: UIImage?
        var intervalsID: String?
        var stravaID: String?

        // 1. Load from new ProfileSettings if available
        if let data = UserDefaults.standard.data(forKey: profileSettingsKey),
           let settings = try? JSONDecoder().decode(ProfileSettings.self, from: data) {
            profileSettings = settings

            // Load avatar from settings
            if let imageData = settings.avatarData {
                avatarImage = UIImage(data: imageData)
            }
        } else {
            // 2. Fallback: Migrate from legacy UserProfile
            profileSettings = migrateLegacyProfile()

            // Load legacy avatar
            if let imageData = UserDefaults.standard.data(forKey: legacyAvatarKey) {
                avatarImage = UIImage(data: imageData)
            }
        }

        // 3. Override with AthleteProfile data (Intervals.icu synced)
        let athleteProfile = athleteProfileManager.profile
        if let fullName = athleteProfile.fullName {
            profileSettings = ProfileSettings(
                name: fullName,
                email: profileSettings.email,
                age: profileSettings.age,
                weight: profileSettings.weight,
                height: profileSettings.height,
                sex: profileSettings.sex,
                avatarData: profileSettings.avatarData
            )
        }

        // 4. Load Strava profile photo (overrides local avatar)
        if let photoURLString = athleteProfile.profilePhotoURL,
           let photoURL = URL(string: photoURLString) {
            avatarImage = await loadProfilePhoto(from: photoURL)
        }

        // 5. Load connected services
        if intervalsManager.isAuthenticated {
            intervalsID = intervalsManager.user?.id ?? "Connected"
        }

        if stravaService.connectionState.isConnected {
            stravaID = "Connected"
        }

        return ProfileData(
            profile: profileSettings,
            avatarImage: avatarImage,
            intervalsID: intervalsID,
            stravaID: stravaID
        )
    }

    // MARK: - Save Profile

    /// Save profile to UserDefaults
    func saveProfile(_ settings: ProfileSettings) async throws {
        // Validate before saving
        let errors = settings.validate()
        guard errors.isEmpty else {
            throw ProfileDataLoaderError.validationFailed(errors)
        }

        // Encode and save
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: profileSettingsKey)

        Logger.debug("💾 Profile saved: \(settings.name)")
    }

    /// Save profile with UIImage avatar
    func saveProfile(
        name: String,
        email: String,
        age: Int,
        weight: Double,
        height: Int,
        sex: String,
        avatarImage: UIImage?
    ) async throws {
        let settings = ProfileSettings.with(
            name: name,
            email: email,
            age: age,
            weight: weight,
            height: height,
            sex: sex,
            avatarImage: avatarImage
        )

        try await saveProfile(settings)
    }

    // MARK: - Private Helpers

    /// Load profile photo from URL
    private func loadProfilePhoto(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            Logger.error("Failed to load profile photo: \(error)")
            return nil
        }
    }

    /// Migrate legacy UserProfile to ProfileSettings
    private func migrateLegacyProfile() -> ProfileSettings {
        guard let data = UserDefaults.standard.data(forKey: legacyProfileKey),
              let legacy = try? JSONDecoder().decode(LegacyUserProfile.self, from: data) else {
            return ProfileSettings.default
        }

        Logger.debug("🔄 Migrating legacy profile to ProfileSettings")

        return ProfileSettings(
            name: legacy.name,
            email: legacy.email,
            age: legacy.age,
            weight: legacy.weight,
            height: legacy.height,
            sex: "M", // Default, user can update
            avatarData: nil
        )
    }
}

// MARK: - Profile Data

/// Complete profile data loaded from all sources
struct ProfileData {
    let profile: ProfileSettings
    let avatarImage: UIImage?
    let intervalsID: String?
    let stravaID: String?
}

// MARK: - Legacy Profile

/// Legacy profile structure for migration
private struct LegacyUserProfile: Codable {
    let name: String
    let email: String
    let age: Int
    let weight: Double
    let height: Int
}

// MARK: - Errors

enum ProfileDataLoaderError: Error, CustomStringConvertible {
    case validationFailed([ProfileSettings.ValidationError])

    var description: String {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map(\.description).joined(separator: ", "))"
        }
    }
}
