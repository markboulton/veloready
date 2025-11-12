import Foundation

/// Configuration for Wahoo OAuth
struct WahooAuthConfig {
    // MARK: - OAuth Configuration
    
    /// Wahoo OAuth client ID (from Wahoo API Console)
    static let clientId = ProcessInfo.processInfo.environment["WAHOO_CLIENT_ID"] ?? ""
    
    /// OAuth scopes requested from Wahoo
    /// Available scopes: email, power_zones_read, workouts_read, plans_read, routes_read, offline_data, user_read
    static let scopes = [
        "email",
        "power_zones_read",
        "workouts_read",
        "plans_read",
        "routes_read",
        "offline_data",
        "user_read"
    ]
    
    /// OAuth scope string (space-separated)
    static var scopeString: String {
        scopes.joined(separator: " ")
    }
    
    // MARK: - API Endpoints
    
    /// Wahoo API base URL (sandbox environment)
    static let apiBaseURL = "https://api.wahooligan.com"
    
    /// OAuth authorization URL
    static let authorizationURL = "\(apiBaseURL)/oauth/authorize"
    
    /// OAuth token URL
    static let tokenURL = "\(apiBaseURL)/oauth/token"
    
    // MARK: - Redirect URLs
    
    /// Whether to use universal links (https) or custom scheme (veloready://)
    /// Universal links: https://veloready.app/auth/wahoo/done
    /// Custom scheme: veloready://auth/wahoo/done
    static let useUniversalLinks = false
    
    /// Backend OAuth start endpoint
    /// Redirects to Wahoo's authorization page
    static let oauthStartURL = "https://api.veloready.app/oauth/wahoo/start"
    
    /// Backend OAuth callback endpoint
    /// Wahoo redirects here after authorization
    static let oauthCallbackURL = "https://api.veloready.app/oauth/wahoo/callback"
    
    /// App deep link callback (after token exchange)
    /// Backend redirects here with tokens
    static var appCallbackURL: String {
        if useUniversalLinks {
            return "https://veloready.app/auth/wahoo/done"
        } else {
            return "veloready://auth/wahoo/done"
        }
    }
    
    // MARK: - UserDefaults Keys
    
    static let userIdKey = "wahoo_user_id"
    static let accessTokenKey = "wahoo_access_token"
    static let refreshTokenKey = "wahoo_refresh_token"
    static let expiresAtKey = "wahoo_expires_at"
    static let connectionStateKey = "wahoo_connection_state"
    
    // MARK: - Rate Limits
    
    /// Wahoo API rate limits (adjust based on official documentation)
    /// Currently conservative estimates
    static let maxRequestsPer15Min = 60
    static let maxRequestsPerHour = 200
    static let maxRequestsPerDay = 2000
}

/// Connection state for Wahoo
enum WahooConnectionState: Codable, Equatable {
    case disconnected
    case connecting(state: String)
    case connected(userId: String?)
    case error(message: String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case type, state, userId, message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "disconnected":
            self = .disconnected
        case "connecting":
            let state = try container.decode(String.self, forKey: .state)
            self = .connecting(state: state)
        case "connected":
            let userId = try? container.decode(String.self, forKey: .userId)
            self = .connected(userId: userId)
        case "error":
            let message = try container.decode(String.self, forKey: .message)
            self = .error(message: message)
        default:
            self = .disconnected
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .disconnected:
            try container.encode("disconnected", forKey: .type)
        case .connecting(let state):
            try container.encode("connecting", forKey: .type)
            try container.encode(state, forKey: .state)
        case .connected(let userId):
            try container.encode("connected", forKey: .type)
            if let userId = userId {
                try container.encode(userId, forKey: .userId)
            }
        case .error(let message):
            try container.encode("error", forKey: .type)
            try container.encode(message, forKey: .message)
        }
    }
}

