import Foundation

/// App-wide constants and configuration
struct AppConstants {
    
    // MARK: - App Info
    static let appName = "VeloReady"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.rideready.com"
        static let timeout: TimeInterval = 30.0
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12.0
        static let shadowRadius: CGFloat = 4.0
        static let animationDuration: Double = 0.3
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isAuthenticated = "isAuthenticated"
        static let userPreferences = "userPreferences"
    }
}