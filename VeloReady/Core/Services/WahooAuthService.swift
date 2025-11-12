import Foundation
import AuthenticationServices
import SwiftUI

/// Service handling Wahoo OAuth flow with ASWebAuthenticationSession
@MainActor
class WahooAuthService: NSObject, ObservableObject {
    static let shared = WahooAuthService()
    
    // MARK: - Published State
    
    @Published private(set) var connectionState: WahooConnectionState = .disconnected
    
    /// Current user ID (from Wahoo)
    var userId: String? {
        if case .connected(let userId) = connectionState {
            return userId
        }
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: WahooAuthConfig.userIdKey)
    }
    
    // MARK: - Private Properties
    
    private var authSession: ASWebAuthenticationSession?
    private var currentState: String?
    
    private override init() {
        super.init()
        Logger.debug("🔵 [WAHOO] WahooAuthService initializing...")
        loadStoredConnection()
        Logger.debug("🔵 [WAHOO] WahooAuthService initialized - connectionState: \(connectionState)")
    }
    
    // MARK: - Public API
    
    /// Start OAuth flow
    func startAuth() {
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.debug("🚀 [WAHOO OAUTH] Starting OAuth Flow")
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate secure state
        let state = generateState()
        currentState = state
        
        Logger.debug("🔐 [WAHOO OAUTH] Generated state: \(state.prefix(16))...")
        
        // Update connection state
        connectionState = .connecting(state: state)
        
        // Construct auth URL
        guard let authURL = constructAuthURL(state: state) else {
            Logger.error("[WAHOO OAUTH] Failed to construct auth URL")
            connectionState = .error(message: "Failed to construct auth URL")
            currentState = nil
            return
        }
        
        Logger.debug("🔗 [WAHOO OAUTH] Auth URL constructed:")
        Logger.debug("   URL: \(authURL.absoluteString)")
        Logger.debug("   Using: Custom Scheme (veloready://)")
        Logger.debug("   Wahoo redirect: https://api.veloready.app/oauth/wahoo/callback")
        Logger.debug("   App callback: veloready://auth/wahoo/done")
        
        // Create and start ASWebAuthenticationSession
        Logger.debug("📱 [WAHOO OAUTH] Creating ASWebAuthenticationSession...")
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: WahooAuthConfig.useUniversalLinks ? "https" : "veloready"
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
        Logger.debug("▶️ [WAHOO OAUTH] Starting session...")
        if !session.start() {
            Logger.error("[WAHOO OAUTH] Session failed to start!")
            connectionState = .error(message: "Failed to start authentication session")
            currentState = nil
        } else {
            Logger.debug("✅ [WAHOO OAUTH] Session started successfully - waiting for user...")
            Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }
    
    /// Re-authenticate with Wahoo (forces fresh OAuth flow)
    func reAuthenticate() async {
        Logger.debug("🔄 [WAHOO] Re-authenticating...")
        await disconnect()
        startAuth()
    }
    
    /// Disconnect from Wahoo
    func disconnect() async {
        Logger.debug("🔌 [WAHOO] Disconnecting...")
        
        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: WahooAuthConfig.userIdKey)
        UserDefaults.standard.removeObject(forKey: WahooAuthConfig.accessTokenKey)
        UserDefaults.standard.removeObject(forKey: WahooAuthConfig.refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: WahooAuthConfig.expiresAtKey)
        UserDefaults.standard.removeObject(forKey: WahooAuthConfig.connectionStateKey)
        
        // Update state
        connectionState = .disconnected
        authSession?.cancel()
        authSession = nil
        currentState = nil
        
        Logger.debug("✅ [WAHOO] Disconnected successfully")
    }
    
    // MARK: - Private Helpers
    
    private func generateState() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func constructAuthURL(state: String) -> URL? {
        var components = URLComponents(string: WahooAuthConfig.oauthStartURL)
        components?.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "redirect", value: WahooAuthConfig.oauthCallbackURL)
        ]
        return components?.url
    }
    
    private func handleSessionCompletion(callbackURL: URL?, error: Error?) async {
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.debug("📥 [WAHOO OAUTH] Session completed")
        
        // Handle cancellation
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession"
                && nsError.code == 1 {
                Logger.debug("❌ [WAHOO OAUTH] User cancelled authentication")
                connectionState = .disconnected
                currentState = nil
                return
            }
            
            Logger.error("[WAHOO OAUTH] Session error: \(error.localizedDescription)")
            connectionState = .error(message: error.localizedDescription)
            currentState = nil
            return
        }
        
        // Parse callback URL
        guard let url = callbackURL else {
            Logger.error("[WAHOO OAUTH] No callback URL received")
            connectionState = .error(message: "No callback URL received")
            currentState = nil
            return
        }
        
        Logger.debug("🔗 [WAHOO OAUTH] Callback URL: \(url.absoluteString)")
        
        // Extract tokens from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Logger.error("[WAHOO OAUTH] Failed to parse callback URL")
            connectionState = .error(message: "Failed to parse callback URL")
            currentState = nil
            return
        }
        
        // Check for errors
        if let errorParam = queryItems.first(where: { $0.name == "error" })?.value {
            Logger.error("[WAHOO OAUTH] OAuth error: \(errorParam)")
            connectionState = .error(message: errorParam)
            currentState = nil
            return
        }
        
        // Extract tokens and user ID
        guard let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
              let userId = queryItems.first(where: { $0.name == "user_id" })?.value else {
            Logger.error("[WAHOO OAUTH] Missing required parameters in callback")
            connectionState = .error(message: "Missing authentication data")
            currentState = nil
            return
        }
        
        let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value
        let expiresInStr = queryItems.first(where: { $0.name == "expires_in" })?.value
        
        Logger.debug("✅ [WAHOO OAUTH] Successfully received tokens")
        Logger.debug("   User ID: \(userId)")
        Logger.debug("   Access Token: \(accessToken.prefix(16))...")
        Logger.debug("   Refresh Token: \(refreshToken?.prefix(16) ?? "nil")...")
        Logger.debug("   Expires In: \(expiresInStr ?? "nil")s")
        
        // Store credentials
        UserDefaults.standard.set(userId, forKey: WahooAuthConfig.userIdKey)
        UserDefaults.standard.set(accessToken, forKey: WahooAuthConfig.accessTokenKey)
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: WahooAuthConfig.refreshTokenKey)
        }
        if let expiresIn = expiresInStr.flatMap(TimeInterval.init) {
            let expiresAt = Date().addingTimeInterval(expiresIn)
            UserDefaults.standard.set(expiresAt.timeIntervalSince1970, forKey: WahooAuthConfig.expiresAtKey)
        }
        
        // Update connection state
        connectionState = .connected(userId: userId)
        
        // Store connection state
        if let encoded = try? JSONEncoder().encode(connectionState) {
            UserDefaults.standard.set(encoded, forKey: WahooAuthConfig.connectionStateKey)
        }
        
        currentState = nil
        
        Logger.debug("✅ [WAHOO OAUTH] Authentication complete!")
        Logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func loadStoredConnection() {
        // Try to load stored connection state
        if let data = UserDefaults.standard.data(forKey: WahooAuthConfig.connectionStateKey),
           let state = try? JSONDecoder().decode(WahooConnectionState.self, from: data) {
            connectionState = state
            Logger.debug("📂 [WAHOO] Loaded stored connection state: \(state)")
        } else {
            Logger.debug("📂 [WAHOO] No stored connection state found")
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension WahooAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the first window (works for iOS app)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for presentation")
        }
        return window
    }
}

