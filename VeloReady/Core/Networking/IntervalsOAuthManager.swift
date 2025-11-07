import Foundation
import SwiftUI

/// Manages OAuth authentication with intervals.icu
@MainActor
class IntervalsOAuthManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared: IntervalsOAuthManager = {
        let instance = IntervalsOAuthManager()
        return instance
    }()
    
    // MARK: - Properties
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var user: IntervalsUser?
    @Published var lastError: String?
    
    // OAuth Configuration - Based on official intervals.icu documentation
    private let clientID = "108"
    private let clientSecret = "lahzoh8pieCha5aiFai4eeveax0aithi"
    // Use veloready:// scheme
    private let redirectURI = "veloready://auth/intervals/callback"
    private let baseURL = "https://intervals.icu"
    private let authURL = "https://intervals.icu/oauth/authorize"
    private let tokenURL = "https://intervals.icu/api/oauth/token" // Correct endpoint per documentation
    
    // Scopes based on official documentation
    // SETTINGS:READ is required to access /athlete/{id} endpoint for FTP and zones
    private let scopes = ["ACTIVITY:READ", "WELLNESS:READ", "CALENDAR:READ", "SETTINGS:READ"]
    
    // MARK: - Initialization
    init() {
        loadStoredCredentials()
    }
    
    // MARK: - OAuth Flow
    
    /// Start the OAuth authentication flow
    func startAuthentication() -> URL? {
        return startAuthenticationWithScopes(scopes)
    }
    
    /// Start OAuth with specific scopes
    func startAuthenticationWithScopes(_ scopes: [String]) -> URL? {
        let state = UUID().uuidString
        UserDefaults.standard.set(state, forKey: "oauth_state")
        
        // Build OAuth URL according to official intervals.icu documentation
        var components = URLComponents(string: authURL)!
        
        // Try comma-separated scopes first (common OAuth format)
        let scopeString = scopes.joined(separator: ",")
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state)
        ]
        
        let url = components.url
        Logger.debug("🔗 OAuth URL: \(url?.absoluteString ?? "nil")")
        Logger.debug("🔗 Scopes: \(scopeString)")
        return url
    }
    
    /// Try OAuth with space-separated scopes (alternative format)
    func startAuthenticationWithSpaceScopes() -> URL? {
        let state = UUID().uuidString
        UserDefaults.standard.set(state, forKey: "oauth_state")
        
        var components = URLComponents(string: authURL)!
        
        // Try space-separated scopes
        let scopeString = scopes.joined(separator: " ")
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state)
        ]
        
        let url = components.url
        Logger.debug("🔗 OAuth URL (space-separated): \(url?.absoluteString ?? "nil")")
        Logger.debug("🔗 Scopes: \(scopeString)")
        return url
    }
    
    /// Handle OAuth callback
    func handleCallback(url: URL) async {
        Logger.debug("📱 OAuth Callback URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            lastError = "Invalid callback URL"
            Logger.error("Invalid callback URL")
            return
        }
        
        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            lastError = "OAuth error: \(error)"
            Logger.error("OAuth error: \(error)")
            return
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            lastError = "No authorization code received"
            Logger.error("No authorization code received")
            return
        }
        
        Logger.debug("✅ Authorization code received")
        
        // Verify state parameter
        let storedState = UserDefaults.standard.string(forKey: "oauth_state")
        guard let state = queryItems.first(where: { $0.name == "state" })?.value,
              state == storedState else {
            lastError = "Invalid state parameter"
            Logger.error("Invalid state parameter")
            return
        }
        
        Logger.debug("✅ State parameter verified")
        
        // Exchange code for tokens
        await exchangeCodeForTokens(code: code)
    }
    
    /// Exchange authorization code for access and refresh tokens
    /// Based on official intervals.icu documentation
    private func exchangeCodeForTokens(code: String) async {
        guard let url = URL(string: tokenURL) else {
            lastError = "Invalid token URL"
            Logger.error("Invalid token URL")
            return
        }
        
        Logger.debug("🔄 Exchanging code for tokens...")
        Logger.debug("📍 Token URL: \(tokenURL)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Build request body according to official documentation
        let body = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        Logger.debug("📤 Request body: \(bodyString)")
        Logger.debug("📤 Request URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.data("HTTP Status: \(httpResponse.statusCode)")
                Logger.data("Response Headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode != 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    Logger.error("HTTP Error Response: \(responseString)")
                    lastError = "HTTP \(httpResponse.statusCode): \(responseString)"
                    return
                }
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            Logger.debug("📥 Token response: \(responseString)")
            
            // Try to decode the response
            do {
                let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
                
                accessToken = tokenResponse.accessToken
                refreshToken = tokenResponse.refreshToken
                
                Logger.debug("✅ Tokens received successfully")
                Logger.debug("✅ Access Token: \(tokenResponse.accessToken.prefix(20))...")
                if let refreshToken = tokenResponse.refreshToken {
                    Logger.debug("✅ Refresh Token: \(refreshToken.prefix(20))...")
                }
                
                // Extract athlete info from token response
                if let athlete = tokenResponse.athlete {
                    self.user = IntervalsUser(
                        id: athlete.id,  // Use string ID directly (e.g., "i397833")
                        name: athlete.name,
                        email: "",
                        username: nil,
                        profileImageURL: nil,
                        createdAt: "",
                        updatedAt: ""
                    )
                    Logger.debug("✅ Athlete info from OAuth: \(athlete.name) (ID: \(athlete.id))")
                }
                
                // Store credentials securely
                storeCredentials()
                
                // Fetch additional user info if needed
                if self.user == nil {
                    await fetchUserInfo()
                }
                
                isAuthenticated = true
                lastError = nil
                
            } catch let decodeError {
                Logger.error("JSON Decode Error: \(decodeError)")
                Logger.error("Raw response: \(responseString)")
                lastError = "Failed to decode token response: \(decodeError.localizedDescription)"
            }
            
        } catch {
            let errorMessage = "Failed to exchange code for tokens: \(error.localizedDescription)"
            lastError = errorMessage
            Logger.error("Token exchange error: \(errorMessage)")
        }
    }
    
    /// Fetch user information from intervals.icu (fallback if not in OAuth response)
    private func fetchUserInfo() async {
        guard let accessToken = accessToken else { return }
        
        // Fallback: Verify authentication by testing wellness endpoint
        guard let url = URL(string: "\(baseURL)/api/v1/athlete/0/wellness?oldest=2025-01-01&newest=2025-01-01") else {
            lastError = "Invalid user info URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Successfully authenticated - create a basic user object
                    self.user = IntervalsUser(
                        id: "0",  // Default ID as string
                        name: "Athlete",
                        email: "",
                        username: nil,
                        profileImageURL: nil,
                        createdAt: "",
                        updatedAt: ""
                    )
                    Logger.debug("✅ User authenticated (fallback method)")
                } else {
                    Logger.error("Failed to verify user: HTTP \(httpResponse.statusCode)")
                    lastError = "Failed to verify user: HTTP \(httpResponse.statusCode)"
                }
            }
        } catch {
            Logger.error("Failed to verify user: \(error)")
            lastError = "Failed to verify user: \(error.localizedDescription)"
        }
    }
    
    /// Refresh access token using refresh token
    func refreshAccessToken() async {
        guard let refreshToken = refreshToken else {
            lastError = "No refresh token available"
            return
        }
        
        guard let url = URL(string: tokenURL) else {
            lastError = "Invalid token URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": refreshToken
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            
            accessToken = response.accessToken
            if let newRefreshToken = response.refreshToken {
                self.refreshToken = newRefreshToken
            }
            
            storeCredentials()
            lastError = nil
            
        } catch {
            lastError = "Failed to refresh token: \(error.localizedDescription)"
            // If refresh fails, user needs to re-authenticate
            await signOut()
        }
    }
    
    /// Sign out and clear stored credentials
    func signOut() async {
        accessToken = nil
        refreshToken = nil
        user = nil
        isAuthenticated = false
        lastError = nil
        
        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: "intervals_access_token")
        UserDefaults.standard.removeObject(forKey: "intervals_refresh_token")
        UserDefaults.standard.removeObject(forKey: "intervals_user")
        
        // Clear cached Intervals data so only HealthKit data is shown
        // IntervalsCache deleted - cache is now managed by CacheOrchestrator
        await CacheOrchestrator.shared.invalidate(matching: "intervals:.*")
        Logger.debug("🗑️ Cleared Intervals.icu cache on sign out - switching to HealthKit-only mode")
    }
    
    // MARK: - Credential Management
    
    private func storeCredentials() {
        if let accessToken = accessToken {
            UserDefaults.standard.set(accessToken, forKey: "intervals_access_token")
        }
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "intervals_refresh_token")
        }
        if let user = user {
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "intervals_user")
            }
        }
    }
    
    private func loadStoredCredentials() {
        accessToken = UserDefaults.standard.string(forKey: "intervals_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "intervals_refresh_token")
        
        if let userData = UserDefaults.standard.data(forKey: "intervals_user"),
           let user = try? JSONDecoder().decode(IntervalsUser.self, from: userData) {
            self.user = user
        }
        
        isAuthenticated = accessToken != nil
    }
}

// MARK: - Data Models

struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int?
    let scope: String?
    let athlete: OAuthAthlete?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
        case athlete
    }
}

struct OAuthAthlete: Codable {
    let id: String
    let name: String
}

struct IntervalsUser: Codable {
    let id: String  // Changed to String to support intervals.icu format (e.g., "i397833")
    let name: String
    let email: String
    let username: String?
    let profileImageURL: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, username
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

