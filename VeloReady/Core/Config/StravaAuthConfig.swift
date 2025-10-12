import Foundation

/// Configuration constants for Strava OAuth
enum StravaAuthConfig {
    // Backend configuration
    static let backendBase = "https://rideready.icu"
    static let startURL = "\(backendBase)/oauth/strava/start"
    static let statusURL = "\(backendBase)/api/me/strava/status"
    
    // Deep link configuration
    // Toggle this to switch between Universal Links and custom URL scheme
    static let useUniversalLinks = false
    
    static let universalLinkRedirect = "https://rideready.icu/oauth/strava/done"
    static let customSchemeRedirect = "rideready://oauth/strava/done"
    
    /// The active redirect URL based on configuration
    static var redirectURL: String {
        useUniversalLinks ? universalLinkRedirect : customSchemeRedirect
    }
    
    // Polling configuration
    static let maxPollingAttempts = 5
    static let initialPollingDelay: TimeInterval = 1.0 // 1 second
    static let pollingBackoffMultiplier: Double = 1.5
    static let pollingTimeout: TimeInterval = 10.0 // 10 seconds max
    
    // Network configuration
    static let requestTimeout: TimeInterval = 10.0
    
    // Storage keys
    static let isConnectedKey = "strava_is_connected"
    static let athleteIdKey = "strava_athlete_id"
}
