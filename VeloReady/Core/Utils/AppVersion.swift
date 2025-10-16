import Foundation
import UIKit

/// Provides version and build information for logging and debugging
enum AppVersion {
    
    /// App version string (e.g., "1.0")
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number (e.g., "1")
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Git commit hash (short form, 7 characters)
    /// This will be set at build time via a build script
    static var gitCommit: String {
        // This will be replaced by a build script
        // For now, return a placeholder
        #if DEBUG
        return "dev"
        #else
        return Bundle.main.infoDictionary?["GitCommitHash"] as? String ?? "unknown"
        #endif
    }
    
    /// Full version string for logging (e.g., "v1.0 (1) [abc1234]")
    static var fullVersion: String {
        "v\(version) (\(build)) [\(gitCommit)]"
    }
    
    /// Log version information at app startup
    static func logVersionInfo() {
        Logger.info("🚀 VeloReady \(fullVersion)")
        Logger.info("📱 iOS \(UIDevice.current.systemVersion)")
        Logger.info("📱 Device: \(UIDevice.current.model)")
        
        #if DEBUG
        Logger.info("🔧 Build: DEBUG")
        #else
        Logger.info("🔧 Build: RELEASE")
        #endif
    }
}
