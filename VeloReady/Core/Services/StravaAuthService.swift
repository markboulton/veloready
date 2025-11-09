import Foundation
import AuthenticationServices
import SwiftUI

/// Service handling Strava OAuth flow with ASWebAuthenticationSession
@MainActor
class StravaAuthService: NSObject, ObservableObject {
    static let shared = StravaAuthService()
    
    // MARK: - Published State
    
    @Published private(set) var connectionState: StravaConnectionState = .disconnected
    
    /// Current athlete ID (from Strava)
    var athleteId: Int? {
        if case .connected(let athleteId) = connectionState, let id = athleteId {
            return Int(id)
        }
        // Fallback to UserDefaults
        if let idString = UserDefaults.standard.string(forKey: StravaAuthConfig.athleteIdKey) {
            return Int(idString)
        }
        return nil
    }
    
    // MARK: - Private Properties
    
    private var authSession: ASWebAuthenticationSession?
    private var currentState: String?
    
    private override init() {
        super.init()
        Logger.debug("🔵 [STRAVA] StravaAuthService initializing...")
        loadStoredConnection()
        Logger.debug("🔵 [STRAVA] StravaAuthService initialized - connectionState: \(connectionState)")
    }
    
    // MARK: - Public API
    
    /// Start OAuth flow
    func startAuth() {
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.debug("🚀 [STRAVA OAUTH] Starting OAuth Flow")
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate secure state
        let state = generateState()
        currentState = state
        
        Logger.debug("🔐 [STRAVA OAUTH] Generated state: \(state.prefix(16))...")
        
        // Update connection state
        connectionState = .connecting(state: state)
        
        // Construct auth URL
        guard let authURL = constructAuthURL(state: state) else {
            Logger.error("[STRAVA OAUTH] Failed to construct auth URL")
            connectionState = .error(message: "Failed to construct auth URL")
            currentState = nil
            return
        }
        
        Logger.debug("🔗 [STRAVA OAUTH] Auth URL constructed:")
        Logger.debug("   URL: \(authURL.absoluteString)")
        Logger.debug("   Using: Custom Scheme (veloready://)")
        Logger.debug("   Strava redirect: https://veloready.app/auth/strava/callback")
        Logger.debug("   App callback: veloready://auth/strava/done")
        
        // Create and start ASWebAuthenticationSession
        Logger.debug("📱 [STRAVA OAUTH] Creating ASWebAuthenticationSession...")
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: StravaAuthConfig.useUniversalLinks ? "https" : "veloready"
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                await self?.handleSessionCompletion(callbackURL: callbackURL, error: error)
            }
        }
        
        // Set presentation context provider
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false // Allow cookies for better UX
        
        authSession = session
        
        // Start the session
        Logger.debug("▶️ [STRAVA OAUTH] Starting session...")
        if !session.start() {
            Logger.error("[STRAVA OAUTH] Session failed to start!")
            connectionState = .error(message: "Failed to start authentication session")
            currentState = nil
        } else {
            Logger.debug("✅ [STRAVA OAUTH] Session started successfully - waiting for user...")
            Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }
    
    /// Re-authenticate with Strava (forces fresh OAuth flow to create new Supabase session)
    /// Use this when backend authentication is failing
    func reAuthenticate() async {
        print("🔄 [STRAVA] Re-authenticating to create fresh Supabase session...")
        Logger.debug("🔄 [STRAVA] Re-authentication requested - clearing old session and starting fresh OAuth")
        
        // Clear current Supabase session
        SupabaseClient.shared.clearSession()
        
        // Clear Strava connection state but keep athlete ID
        // This forces a fresh OAuth flow while maintaining the connection
        currentState = nil
        authSession?.cancel()
        authSession = nil
        
        // Start fresh OAuth flow
        startAuth()
    }
    
    /// Handle incoming deep link callback
    func handleCallback(url: URL) async {
        #if DEBUG
        Logger.debug("🔗 Strava callback: \(url.absoluteString)")
        #endif
        
        // Validate the callback URL scheme/host
        guard validateCallbackURL(url) else {
            #if DEBUG
            Logger.error("Strava callback: Invalid URL scheme/host")
            #endif
            connectionState = .error(message: "Invalid callback URL")
            return
        }
        
        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            #if DEBUG
            Logger.error("Strava callback: Failed to parse query parameters")
            #endif
            connectionState = .error(message: "Invalid callback format")
            return
        }
        
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        
        // Validate state
        guard let receivedState = queryDict["state"],
              receivedState == currentState else {
            #if DEBUG
            Logger.error("Strava callback: State validation failed (security issue)")
            #endif
            connectionState = .error(message: "State validation failed - possible security issue")
            return
        }
        
        // Clear the state after validation
        currentState = nil
        
        // Check for errors from backend
        if let errorMessage = queryDict["err"] {
            #if DEBUG
            Logger.error("Strava callback: Backend error - \(errorMessage)")
            #endif
            connectionState = .error(message: errorMessage)
            return
        }
        
        // Check for success
        guard queryDict["ok"] == "1" else {
            #if DEBUG
            Logger.error("Strava callback: Authentication failed")
            #endif
            connectionState = .error(message: "Authentication failed")
            return
        }
        
        // Extract athlete ID and Supabase tokens
        let athleteId = queryDict["athlete_id"]
        let accessToken = queryDict["access_token"]
        let refreshToken = queryDict["refresh_token"]
        let expiresInStr = queryDict["expires_in"]
        let userId = queryDict["user_id"]
        
        #if DEBUG
        Logger.debug("✅ Strava OAuth successful")
        Logger.debug("   Athlete ID: \(athleteId ?? "none")")
        Logger.debug("   User ID: \(userId ?? "none")")
        Logger.debug("   Access Token: \(accessToken != nil ? "present" : "missing")")
        Logger.debug("   Refresh Token: \(refreshToken != nil ? "present" : "missing")")
        #endif
        
        // Save connection state
        saveConnection(athleteId: athleteId)
        
        // Create Supabase session with real tokens from backend
        if let accessToken = accessToken,
           let refreshToken = refreshToken,
           let expiresInStr = expiresInStr,
           let expiresIn = Int(expiresInStr),
           let userId = userId {
            // Create session with real Supabase JWT tokens
            SupabaseClient.shared.createSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn,
                userId: userId
            )
        } else {
            Logger.warning("⚠️ [Supabase] No tokens received from backend - API requests may fail")
        }
        
        // Sync athlete info (name, photo) from Strava
        await AthleteProfileManager.shared.syncFromStrava()
        
        // Start polling for status
        connectionState = .pending(status: "Syncing your rides...")
        await pollStatus()
    }
    
    /// Disconnect from Strava
    func disconnect() {
        // Cancel any active session
        authSession?.cancel()
        authSession = nil
        currentState = nil
        
        // Clear stored state
        clearStoredConnection()
        
        // Clear Supabase session
        SupabaseClient.shared.clearSession()
        
        // Update state
        connectionState = .disconnected
        
        #if DEBUG
        Logger.debug("🔌 Disconnected from Strava")
        #endif
    }
    
    // MARK: - Private Helpers
    
    private func generateState() -> String {
        // Generate 32 bytes of random data
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard result == errSecSuccess else {
            // Fallback to UUID if SecRandomCopyBytes fails
            return UUID().uuidString
        }
        
        // Convert to hex string
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    private func constructAuthURL(state: String) -> URL? {
        var components = URLComponents(string: StravaAuthConfig.startURL)
        components?.queryItems = [
            URLQueryItem(name: "state", value: state),
            // Always send HTTPS URL to Strava (they don't accept custom schemes)
            // The HTML page will redirect to the custom scheme after token exchange
            URLQueryItem(name: "redirect", value: "https://veloready.app/auth/strava/callback")
        ]
        return components?.url
    }
    
    private func validateCallbackURL(_ url: URL) -> Bool {
        if StravaAuthConfig.useUniversalLinks {
            // Validate Universal Link
            return url.scheme == "https" && url.host == "veloready.app"
        } else {
            // Validate custom scheme
            return url.scheme == "veloready"
        }
    }
    
    private func handleSessionCompletion(callbackURL: URL?, error: Error?) async {
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.debug("📞 [STRAVA OAUTH] Session Completion Handler Called")
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.debug("📍 Callback URL: \(callbackURL?.absoluteString ?? "❌ NIL")")
        Logger.debug("📍 Error: \(error?.localizedDescription ?? "✅ No error")")
        
        if let error = error {
            Logger.debug("📍 Error Code: \((error as NSError).code)")
            Logger.debug("📍 Error Domain: \((error as NSError).domain)")
        }
        
        if let error = error {
            // Check if user cancelled
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                Logger.debug("👋 [STRAVA OAUTH] User cancelled - closing session")
                Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                connectionState = .disconnected
                currentState = nil
            } else {
                Logger.error("[STRAVA OAUTH] Session error: \(error.localizedDescription)")
                Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                connectionState = .error(message: error.localizedDescription)
                currentState = nil
            }
            return
        }
        
        guard let callbackURL = callbackURL else {
            Logger.error("[STRAVA OAUTH] No callback URL received!")
            Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            connectionState = .error(message: "No callback URL received")
            currentState = nil
            return
        }
        
        Logger.debug("✅ [STRAVA OAUTH] Callback URL received!")
        Logger.debug("   Processing callback...")
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Handle the callback
        await handleCallback(url: callbackURL)
    }
    
    private func pollStatus() async {
        var attempt = 0
        var delay = StravaAuthConfig.initialPollingDelay
        let startTime = Date()
        
        #if DEBUG
        Logger.debug("🔄 Strava status polling started (max \(StravaAuthConfig.maxPollingAttempts) attempts)")
        #endif
        
        while attempt < StravaAuthConfig.maxPollingAttempts {
            // Check if we've exceeded the timeout
            if Date().timeIntervalSince(startTime) > StravaAuthConfig.pollingTimeout {
                #if DEBUG
                Logger.debug("⏰ Strava polling timeout - marking as connected")
                #endif
                // Still mark as connected but with "syncing" status
                let athleteId = loadAthleteId()
                saveConnection(athleteId: athleteId)
                connectionState = .connected(athleteId: athleteId)
                return
            }
            
            // Wait before polling
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            // Poll the status endpoint
            if let status = await fetchStatus() {
                #if DEBUG
                Logger.debug("🔄 Strava status [\(attempt + 1)/\(StravaAuthConfig.maxPollingAttempts)]: \(status)")
                #endif
                
                if status == "ready" {
                    // Syncing complete
                    #if DEBUG
                    Logger.debug("✅ Strava sync complete")
                    #endif
                    let athleteId = loadAthleteId()
                    saveConnection(athleteId: athleteId)
                    connectionState = .connected(athleteId: athleteId)
                    #if DEBUG
                    Logger.debug("🔍 [STRAVA] Connection state set to: \(connectionState)")
                    #endif
                    return
                } else {
                    // Still syncing
                    connectionState = .pending(status: "Syncing: \(status)")
                }
            }
            
            // Exponential backoff
            attempt += 1
            delay *= StravaAuthConfig.pollingBackoffMultiplier
        }
        
        // Max attempts reached, mark as connected anyway
        #if DEBUG
        Logger.warning("️ Strava polling max attempts reached - marking as connected")
        #endif
        if let athleteId = loadAthleteId() {
            connectionState = .connected(athleteId: athleteId)
        } else {
            connectionState = .connected(athleteId: nil)
        }
    }
    
    private func fetchStatus() async -> String? {
        guard let url = URL(string: StravaAuthConfig.statusURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = StravaAuthConfig.requestTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let json = try JSONDecoder().decode(StravaStatusResponse.self, from: data)
            return json.status
        } catch {
            return nil
        }
    }
    
    // MARK: - Persistence
    
    private func saveConnection(athleteId: String?) {
        UserDefaults.standard.set(true, forKey: StravaAuthConfig.isConnectedKey)
        if let athleteId = athleteId {
            UserDefaults.standard.set(athleteId, forKey: StravaAuthConfig.athleteIdKey)
        }
        UserDefaults.standard.synchronize() // Force immediate write
        
        #if DEBUG
        Logger.debug("💾 [STRAVA] Saved connection to UserDefaults:")
        Logger.debug("   Key: \(StravaAuthConfig.isConnectedKey)")
        Logger.debug("   Value: true")
        Logger.debug("   AthleteId: \(athleteId ?? "nil")")
        Logger.debug("💾 [STRAVA] Immediate verification:")
        Logger.debug("   Read isConnected: \(UserDefaults.standard.bool(forKey: StravaAuthConfig.isConnectedKey))")
        Logger.debug("   Read athleteId: \(UserDefaults.standard.string(forKey: StravaAuthConfig.athleteIdKey) ?? "nil")")
        #endif
    }
    
    private func clearStoredConnection() {
        #if DEBUG
        Logger.debug("🗑️ [STRAVA] Clearing stored connection from UserDefaults")
        #endif
        UserDefaults.standard.removeObject(forKey: StravaAuthConfig.isConnectedKey)
        UserDefaults.standard.removeObject(forKey: StravaAuthConfig.athleteIdKey)
        UserDefaults.standard.synchronize()
        #if DEBUG
        Logger.debug("   Verification - isConnected after clear: \(UserDefaults.standard.bool(forKey: StravaAuthConfig.isConnectedKey))")
        #endif
    }
    
    private func loadStoredConnection() {
        let isConnected = UserDefaults.standard.bool(forKey: StravaAuthConfig.isConnectedKey)
        let athleteId = UserDefaults.standard.string(forKey: StravaAuthConfig.athleteIdKey)
        
        #if DEBUG
        Logger.debug("🔍 [STRAVA] Loading stored connection:")
        Logger.debug("   Key being checked: \(StravaAuthConfig.isConnectedKey)")
        Logger.debug("   Value read: \(isConnected)")
        Logger.debug("   AthleteId read: \(athleteId ?? "nil")")
        
        // Debug: List ALL UserDefaults keys containing "strava"
        let allKeys = Array(UserDefaults.standard.dictionaryRepresentation().keys).filter({ $0.lowercased().contains("strava") })
        if !allKeys.isEmpty {
            Logger.debug("   All Strava-related keys in UserDefaults:")
            for key in allKeys {
                let value = UserDefaults.standard.object(forKey: key)
                Logger.debug("     - \(key): \(value ?? "nil")")
            }
        } else {
            Logger.debug("   ⚠️ NO Strava-related keys found in UserDefaults!")
        }
        #endif
        
        if isConnected {
            #if DEBUG
            Logger.debug("🔍 [STRAVA] Restoring connection state: athleteId=\(athleteId ?? "nil")")
            #endif
            connectionState = .connected(athleteId: athleteId)
            
            // Sync athlete profile from Strava on app launch
            Task {
                await AthleteProfileManager.shared.syncFromStrava()
            }
        } else {
            connectionState = .disconnected
        }
    }
    
    private func loadAthleteId() -> String? {
        return UserDefaults.standard.string(forKey: StravaAuthConfig.athleteIdKey)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension StravaAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the first connected scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for ASWebAuthenticationSession")
        }
        return window
    }
}

// MARK: - Supporting Types

private struct StravaStatusResponse: Codable {
    let connected: Bool
    let status: String
}
