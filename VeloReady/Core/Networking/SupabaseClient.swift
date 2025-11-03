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
    
    /// Get current user ID for subscription sync
    var currentUserId: String? {
        return session?.user.id
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
            Logger.debug("⚠️ [Supabase] Saved session expired - attempting refresh...")
            
            // Try to refresh the token using the refresh token
            Task {
                do {
                    // Temporarily set the session so refreshToken() can access it
                    self.session = session
                    try await refreshToken()
                    Logger.debug("✅ [Supabase] Session refreshed on startup")
                } catch {
                    Logger.error("❌ [Supabase] Failed to refresh expired session: \(error)")
                    clearSession()
                }
            }
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
    
    /// Refresh the access token via backend
    private func refreshToken() async throws {
        guard let session = session else {
            throw SupabaseError.notAuthenticated
        }
        
        Logger.debug("🔄 [Supabase] Refreshing access token...")
        
        // Call backend to refresh the token
        guard let url = URL(string: "https://api.veloready.app/.netlify/functions/auth-refresh-token") else {
            throw SupabaseError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": session.refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            Logger.error("[Supabase] Token refresh failed - clearing session")
            clearSession()
            throw SupabaseError.refreshFailed
        }
        
        // Parse response
        struct RefreshResponse: Codable {
            let access_token: String
            let refresh_token: String
            let expires_in: Int
        }
        
        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        
        // Create new session with refreshed tokens
        let newSession = SupabaseSession(
            accessToken: refreshResponse.access_token,
            refreshToken: refreshResponse.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(refreshResponse.expires_in)),
            user: session.user
        )
        
        saveSession(newSession)
        Logger.debug("✅ [Supabase] Token refreshed successfully (expires: \(newSession.expiresAt))")
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
