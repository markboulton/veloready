import Foundation

/// Lightweight Supabase client for authentication
/// Uses native URLSession - no external dependencies required
@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()
    
    @Published var session: SupabaseSession?
    @Published var isAuthenticated: Bool = false
    
    private init() {
        // Load saved session from UserDefaults
        loadSession()
    }
    
    // MARK: - Session Management
    
    /// Get current access token for API requests
    var accessToken: String? {
        return session?.accessToken
    }
    
    /// Load session from UserDefaults
    private func loadSession() {
        guard let data = UserDefaults.standard.data(forKey: "supabase_session"),
              let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
            return
        }
        
        // Check if token is expired
        if session.expiresAt > Date() {
            self.session = session
            self.isAuthenticated = true
            Logger.debug("✅ [Supabase] Loaded saved session (expires: \(session.expiresAt))")
        } else {
            Logger.debug("⚠️ [Supabase] Saved session expired - clearing")
            clearSession()
        }
    }
    
    /// Save session to UserDefaults
    private func saveSession(_ session: SupabaseSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "supabase_session")
            self.session = session
            self.isAuthenticated = true
            Logger.debug("✅ [Supabase] Session saved (expires: \(session.expiresAt))")
        }
    }
    
    /// Clear session
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: "supabase_session")
        self.session = nil
        self.isAuthenticated = false
        Logger.debug("🗑️ [Supabase] Session cleared")
    }
    
    // MARK: - Authentication
    
    /// Sign in with OAuth provider (Strava)
    /// This creates a Supabase session after Strava OAuth completes
    func signInWithOAuth(accessToken: String, refreshToken: String, expiresIn: Int) async throws {
        // Create session from OAuth tokens
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: SupabaseUser(id: "", email: nil)
        )
        
        saveSession(session)
        Logger.debug("✅ [Supabase] OAuth session created")
    }
    
    /// Create session from OAuth tokens received from backend
    /// The backend already created the Supabase user and returned valid tokens
    func createSession(accessToken: String, refreshToken: String, expiresIn: Int, userId: String) {
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: SupabaseUser(id: userId, email: nil)
        )
        
        saveSession(session)
        Logger.debug("✅ [Supabase] Session created (user: \(userId), expires: \(expiresAt))")
    }
    
    /// Refresh access token if expired
    func refreshTokenIfNeeded() async throws {
        guard let session = session else {
            throw SupabaseError.notAuthenticated
        }
        
        // If token expires in less than 5 minutes, refresh it
        if session.expiresAt.timeIntervalSinceNow < 300 {
            try await refreshToken()
        }
    }
    
    /// Refresh the access token
    /// Note: In production, this should call your backend to refresh the token
    /// For now, we'll just log and throw an error - user will need to re-authenticate
    private func refreshToken() async throws {
        guard let session = session else {
            throw SupabaseError.notAuthenticated
        }
        
        Logger.warning("⚠️ [Supabase] Token refresh not implemented - user needs to re-authenticate")
        Logger.debug("   Current token expires at: \(session.expiresAt)")
        
        // TODO: Implement token refresh via backend endpoint
        // For now, clear the session so user will re-authenticate
        clearSession()
        throw SupabaseError.refreshFailed
    }
}

// MARK: - Models

struct SupabaseSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case refreshFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Supabase"
        case .refreshFailed:
            return "Failed to refresh access token"
        case .invalidResponse:
            return "Invalid response from Supabase"
        }
    }
}
