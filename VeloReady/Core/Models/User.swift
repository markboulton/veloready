import Foundation

/// User model representing the current user
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let createdAt: Date
    let updatedAt: Date
    
    // OAuth provider information
    let provider: String?
    let providerID: String?
    let accessToken: String?
    let refreshToken: String?
    
    init(id: String, email: String, name: String, profileImageURL: String? = nil, provider: String? = nil, providerID: String? = nil, accessToken: String? = nil, refreshToken: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
        self.provider = provider
        self.providerID = providerID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Create User from IntervalsUser
    static func fromIntervalsUser(_ intervalsUser: IntervalsUser, accessToken: String, refreshToken: String?) -> User {
        return User(
            id: intervalsUser.id,  // Already a String (e.g., "i397833")
            email: intervalsUser.email,
            name: intervalsUser.name,
            profileImageURL: intervalsUser.profileImageURL,
            provider: "intervals.icu",
            providerID: intervalsUser.id,  // Already a String
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}