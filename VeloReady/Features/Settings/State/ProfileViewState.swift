import Foundation
import SwiftUI

/// View state for ProfileView
/// Part of Phase 5 Profile Refactor - separates state management from view
@MainActor
class ProfileViewState: ObservableObject {

    // MARK: - Published State

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var age: Int = 0
    @Published var weight: Double = 0
    @Published var height: Int = 0
    @Published var sex: String = "M"
    @Published var avatarImage: UIImage?
    @Published var isLoading = false
    @Published var intervalsID: String?
    @Published var stravaID: String?

    // MARK: - Dependencies

    private let dataLoader = ProfileDataLoader()

    // MARK: - Computed Properties

    var hasAthleticInfo: Bool {
        age > 0 || weight > 0 || height > 0
    }

    var bmr: Double {
        guard weight > 0, height > 0, age > 0 else { return 0 }

        // Mifflin-St Jeor Equation
        let base = (10 * weight) + (6.25 * Double(height)) - (5 * Double(age))

        switch sex {
        case "M":
            return base + 5
        case "F":
            return base - 161
        default:
            return base - 78  // Average
        }
    }

    // MARK: - Public Methods

    /// Load profile from all sources
    func loadProfile() {
        isLoading = true

        Task {
            let profileData = await dataLoader.loadProfile()

            // Update published properties
            name = profileData.profile.name
            email = profileData.profile.email
            age = profileData.profile.age
            weight = profileData.profile.weight
            height = profileData.profile.height
            sex = profileData.profile.sex
            avatarImage = profileData.avatarImage
            intervalsID = profileData.intervalsID
            stravaID = profileData.stravaID

            isLoading = false

            Logger.debug("✅ Profile loaded: \(name)")
        }
    }

    /// Save profile with current state
    func saveProfile(
        name: String,
        email: String,
        age: Int,
        weight: Double,
        height: Int,
        sex: String,
        avatarImage: UIImage?
    ) async throws {
        try await dataLoader.saveProfile(
            name: name,
            email: email,
            age: age,
            weight: weight,
            height: height,
            sex: sex,
            avatarImage: avatarImage
        )

        // Reload to sync with saved data
        loadProfile()
    }
}
