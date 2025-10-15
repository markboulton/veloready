import Foundation

/// Configuration for AI Brief feature
/// 
/// To enable AI Brief:
/// 1. Set your HMAC secret below (for development)
/// 2. For production, use Keychain or secure configuration management
struct AIBriefConfig {
    
    // MARK: - Configuration
    
    /// Production HMAC secret for AI Brief API
    private static let hmacSecret = "F3zY7wQeJp9tVgM1Lx8aC2bRuN5kZsH0dTrW"
    
    /// Configure the AI Brief client with the HMAC secret
    /// Call this during app initialization
    @MainActor
    static func configure() {
        AIBriefClient.shared.setHMACSecret(hmacSecret)
        Logger.debug("🔐 AI Brief configured successfully")
    }
    
    /// Check if AI Brief is configured
    @MainActor
    static var isConfigured: Bool {
        return AIBriefClient.shared.getHMACSecret() != nil
    }
    
    /// Get configuration status message
    @MainActor
    static var statusMessage: String {
        if isConfigured {
            return "✅ AI Brief is configured and ready"
        } else {
            return """
            ⚠️ AI Brief is not configured
            
            To enable:
            1. Set developmentSecret in AIBriefConfig.swift (for testing)
            2. Or use Debug Dashboard to set the secret
            3. Or implement production secret loading
            
            See AI_BRIEF_SETUP.md for details
            """
        }
    }
}

// MARK: - App Initialization Helper

extension AIBriefConfig {
    /// Call this from your app's init() method
    /// Example:
    /// ```
    /// @main
    /// struct RidereadyApp: App {
    ///     init() {
    ///         Task { @MainActor in
    ///             AIBriefConfig.configure()
    ///         }
    ///     }
    /// }
    /// ```
    @MainActor
    static func initializeOnAppLaunch() {
        configure()
        print(statusMessage)
    }
}
