import Foundation
import UIKit

/// Controls debug features visibility - developer-only vs beta users
struct DebugFlags {
    
    // MARK: - Developer Detection
    
    /// Check if the current user is a developer
    /// Uses multiple signals to determine developer status
    static var isDeveloper: Bool {
        #if DEBUG
        // Always true in debug builds (Xcode)
        return true
        #else
        // In release builds, check for specific identifiers
        return isKnownDeveloperDevice || isTestFlightBuild
        #endif
    }
    
    /// Check if this is a TestFlight build
    static var isTestFlightBuild: Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }
    
    /// Check if this is a known developer device
    /// Add your device identifiers here
    private static var isKnownDeveloperDevice: Bool {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        // Add your device UUIDs here for production debug access
        let developerDevices: Set<String> = [
            // Example: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
            // Add your iPhone/iPad identifierForVendor here
        ]
        
        return developerDevices.contains(deviceId)
    }
    
    // MARK: - Feature Flags
    
    /// Show debug menu in Settings (developer only)
    static var showDebugMenu: Bool {
        return isDeveloper
    }
    
    /// Show detailed logging
    static var verboseLogging: Bool {
        return isDeveloper
    }
    
    /// Show development-only features
    static var showExperimentalFeatures: Bool {
        return isDeveloper
    }
    
    // MARK: - Build Info
    
    /// Get current build environment
    static var buildEnvironment: String {
        #if DEBUG
        return "Debug (Xcode)"
        #else
        if isTestFlightBuild {
            return "TestFlight Beta"
        } else {
            return "Production (App Store)"
        }
        #endif
    }
    
    /// Get device identifier (for adding to developer list)
    static func getDeviceIdentifier() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    /// Get build information for logging
    static func getBuildInfo() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let device = UIDevice.current.model
        let os = UIDevice.current.systemVersion
        
        return """
        VeloReady \(version) (\(build))
        Environment: \(buildEnvironment)
        Device: \(device) - iOS \(os)
        Device ID: \(getDeviceIdentifier())
        """
    }
}
