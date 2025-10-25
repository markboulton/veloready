import Foundation

/// Lightweight Supabase client for authentication
/// Uses native URLSession - no external dependencies required
@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()
    
    @Published var session: SupabaseSession?
    @Published var isAuthenticated: Bool = false
    
    private let baseURL: String
    private let anonKey: String
    
    private init() {
        self.baseURL = SupabaseConfig.url
        self.anonKey = SupabaseConfig.anonKey
        
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
    
    /// Exchange Strava tokens for Supabase session
    /// This is called after Strava OAuth callback
    func exchangeStravaTokens(stravaAccessToken: String, stravaRefreshToken: String, athleteId: Int) async throws {
        // For now, we'll create a simple session
        // In production, this should call your backend to create a proper Supabase user
        
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a session with the Strava tokens
        // This is a simplified version - in production you'd want proper user creation
        let expiresAt = Date().addingTimeInterval(3600) // 1 hour
        let session = SupabaseSession(
            accessToken: stravaAccessToken,
            refreshToken: stravaRefreshToken,
            expiresAt: expiresAt,
            user: SupabaseUser(id: String(athleteId), email: nil)
        )
        
        saveSession(session)
        Logger.debug("✅ [Supabase] Session created for athlete \(athleteId)")
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
    private func refreshToken() async throws {
        guard let session = session else {
            throw SupabaseError.notAuthenticated
        }
        
        Logger.debug("🔄 [Supabase] Refreshing access token...")
        
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": session.refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.refreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        let newSession = SupabaseSession(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
            user: session.user
        )
        
        saveSession(newSession)
        Logger.debug("✅ [Supabase] Token refreshed successfully")
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

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
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
