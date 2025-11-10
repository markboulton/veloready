import Foundation

/// Lightweight Supabase client for authentication
/// Uses native URLSession - no external dependencies required
@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()
    
    @Published var isAuthenticated = false
    @Published var isRefreshing = false // Track if refresh is in progress
    private var session: SupabaseSession?
    private var refreshContinuation: CheckedContinuation<Void, Never>? // For awaiting refresh
    private var refreshTimer: Timer? // Solution 3: Proactive refresh timer
    
    private init() {
        // Load saved session from UserDefaults
        loadSession()
        
        // Solution 3: Start proactive token refresh
        startProactiveRefresh()
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
    /// Solution 5: Better error messages
    private func loadSession() {
        guard let data = UserDefaults.standard.data(forKey: "supabase_session"),
              let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
            // Solution 5: Friendlier message - not an error, just a state
            Logger.info("ℹ️ [Supabase] No session found - app is in onboarding mode")
            Logger.info("💡 [Supabase] Connect Strava in Settings to enable cloud sync and analytics")
            return
        }
        
        // Check if token is expired
        if session.expiresAt > Date() {
            self.session = session
            self.isAuthenticated = true
            Logger.info("✅ [Supabase] Session loaded (expires: \(session.expiresAt))")
            Logger.info("   User ID: \(session.user.id)")
        } else {
            // Solution 2: Keep expired session, don't clear it
            let expiredMinutes = Int(Date().timeIntervalSince(session.expiresAt) / 60)
            Logger.info("⏳ [Supabase] Session expired \(expiredMinutes) minutes ago - attempting refresh...")
            
            // Solution 2: Temporarily set expired session for refresh
            self.session = session
            isRefreshing = true
            
            // Try to refresh the token using the refresh token
            Task {
                do {
                    try await refreshToken()
                    Logger.info("✅ [Supabase] Session refreshed on startup")
                } catch {
                    // Solution 2: DON'T clear session on failure - keep it for retry
                    Logger.error("❌ [Supabase] Token refresh failed on launch: \(error)")
                    Logger.warning("⚠️ [Supabase] Keeping expired session for retry - will attempt refresh on next API call")
                    // Note: Session is still set, just expired. API calls will trigger retry.
                }
                
                // Mark refresh complete and resume any waiting callers
                isRefreshing = false
                refreshContinuation?.resume()
                refreshContinuation = nil
            }
        }
    }
    
    /// Save session to UserDefaults
    /// Solution 1: Robust save with verification
    private func saveSession(_ session: SupabaseSession, retryCount: Int = 0) {
        guard let data = try? JSONEncoder().encode(session) else {
            Logger.error("❌ [Supabase] Failed to encode session!")
            if retryCount < 2 {
                Logger.warning("⚠️ [Supabase] Retrying save (attempt \(retryCount + 2)/3)...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.saveSession(session, retryCount: retryCount + 1)
                }
            }
            return
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(data, forKey: "supabase_session")
        UserDefaults.standard.synchronize() // Solution 1: Force immediate write
        
        // Solution 1: Verify save succeeded
        if let savedData = UserDefaults.standard.data(forKey: "supabase_session"),
           let _ = try? JSONDecoder().decode(SupabaseSession.self, from: savedData) {
            self.session = session
            self.isAuthenticated = true
            Logger.info("✅ [Supabase] Session saved and verified (expires: \(session.expiresAt))")
            Logger.info("   User ID: \(session.user.id)")
            Logger.info("   Retry count: \(retryCount)")
        } else {
            Logger.error("❌ [Supabase] Session save verification FAILED!")
            if retryCount < 2 {
                Logger.warning("⚠️ [Supabase] Retrying save (attempt \(retryCount + 2)/3)...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.saveSession(session, retryCount: retryCount + 1)
                }
            } else {
                Logger.error("❌ [Supabase] Session save failed after 3 attempts - user may need to re-authenticate")
            }
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
    /// Solution 1 & 4: Robust session creation with validation
    func createSession(accessToken: String, refreshToken: String, expiresIn: Int, userId: String) {
        Logger.info("💾 [Supabase] Creating session...")
        Logger.info("   User ID: \(userId)")
        Logger.info("   Expires in: \(expiresIn)s")
        Logger.info("   Access token: \(accessToken.prefix(20))...")
        Logger.info("   Refresh token: \(refreshToken.prefix(20))...")
        
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: SupabaseUser(id: userId, email: nil)
        )
        
        // Solution 1: Robust save with retry and verification
        saveSession(session)
        
        // Solution 4: Validate session asynchronously (don't block OAuth flow)
        Task {
            await validateSession(accessToken: accessToken)
        }
    }
    
    /// Refresh access token if needed (proactive - before expiry)
    func refreshTokenIfNeeded() async throws {
        guard let session = session else {
            Logger.warning("⚠️ [Supabase] No session available")
            throw SupabaseError.notAuthenticated
        }
        
        let now = Date()
        let timeUntilExpiry = session.expiresAt.timeIntervalSince(now)
        
        // Refresh 5 minutes BEFORE expiry (300 seconds) - PROACTIVE, not reactive
        if timeUntilExpiry < 300 {
            Logger.info("🔄 [Supabase] Token expires in \(Int(timeUntilExpiry))s, refreshing proactively...")
            try await refreshToken()
        } else {
            Logger.debug("✅ [Supabase] Token valid for \(Int(timeUntilExpiry))s, no refresh needed")
        }
    }
    
    /// Refresh token on app launch to ensure it's valid for startup
    func refreshOnAppLaunch() async {
        do {
            try await refreshTokenIfNeeded()
            Logger.info("✅ [Supabase] Token checked on app launch")
        } catch {
            Logger.error("❌ [Supabase] Token refresh failed on launch: \(error)")
        }
    }
    
    /// Wait for token refresh to complete (if in progress)
    func waitForRefreshIfNeeded() async {
        guard isRefreshing else { return }
        
        Logger.debug("⏳ [Supabase] Waiting for token refresh to complete...")
        await withCheckedContinuation { continuation in
            self.refreshContinuation = continuation
        }
        Logger.debug("✅ [Supabase] Token refresh wait complete")
    }
    
    /// Refresh the access token via backend
    /// Solution 2: Don't clear session on failure - preserve for retry
    private func refreshToken() async throws {
        guard let session = session else {
            throw SupabaseError.notAuthenticated
        }
        
        Logger.info("🔄 [Supabase] Refreshing access token...")
        Logger.info("   Refresh token: \(session.refreshToken.prefix(16))...")
        Logger.info("   Expired at: \(session.expiresAt)")
        
        // Call backend to refresh the token
        guard let url = URL(string: "https://api.veloready.app/.netlify/functions/auth-refresh-token") else {
            throw SupabaseError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // Solution 2: Explicit timeout
        
        let body = ["refresh_token": session.refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            Logger.info("🔄 [Supabase] Refresh response: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                // Solution 2: Log error but DON'T clear session
                Logger.error("❌ [Supabase] Token refresh failed with status \(httpResponse.statusCode)")
                Logger.warning("⚠️ [Supabase] Keeping expired session for retry - user won't be logged out")
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
            Logger.info("✅ [Supabase] Token refreshed successfully (expires: \(newSession.expiresAt))")
            
        } catch {
            // Solution 2: Log error but DON'T clear session
            Logger.error("❌ [Supabase] Token refresh network error: \(error)")
            Logger.warning("⚠️ [Supabase] Keeping expired session - will retry on next API call")
            throw error
        }
    }
    
    // MARK: - Solution 3: Proactive Token Refresh
    
    /// Start timer to proactively refresh tokens before expiry
    private func startProactiveRefresh() {
        Logger.info("⏰ [Supabase] Starting proactive token refresh timer (every 5 minutes)")
        
        // Check every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.proactiveRefresh()
            }
        }
    }
    
    /// Proactively refresh token if it expires soon
    private func proactiveRefresh() async {
        guard let session = session else { return }
        
        let now = Date()
        let timeUntilExpiry = session.expiresAt.timeIntervalSince(now)
        
        // If expires within 10 minutes, refresh proactively
        if timeUntilExpiry < 600 && timeUntilExpiry > 0 {
            Logger.info("🔄 [Supabase] Token expires in \(Int(timeUntilExpiry))s - refreshing proactively...")
            do {
                try await refreshToken()
            } catch {
                Logger.error("❌ [Supabase] Proactive refresh failed: \(error)")
                // Don't clear session - just log error and try again next cycle
            }
        } else if timeUntilExpiry < 0 {
            // Already expired
            Logger.warning("⚠️ [Supabase] Token already expired - will refresh on next API call")
        }
    }
    
    // MARK: - Solution 4: Session Validation
    
    /// Validate session with backend to ensure token is actually valid
    private func validateSession(accessToken: String) async {
        Logger.info("🔍 [Supabase] Validating session with backend...")
        
        // Try to make a simple authenticated API call to verify token works
        guard let url = URL(string: "https://api.veloready.app/.netlify/functions/api-health") else {
            Logger.error("❌ [Supabase] Invalid validation URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                Logger.error("❌ [Supabase] Session validation FAILED - token may be invalid")
                Logger.warning("⚠️ [Supabase] Session saved but not validated - API calls may fail")
                return
            }
            
            Logger.info("✅ [Supabase] Session validated successfully - ready for API calls")
            
        } catch {
            Logger.warning("⚠️ [Supabase] Session validation error (may be network issue): \(error)")
            Logger.info("💡 [Supabase] Session saved anyway - will validate on first API call")
        }
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
