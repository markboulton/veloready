import Foundation

/// Feature flags for controlling experimental features and A/B testing
/// Flags default to false for safety - features must be explicitly enabled
@MainActor
final class FeatureFlags {
    static let shared = FeatureFlags()

    private init() {}

    // MARK: - Today View V2 Architecture (Phase 1)

    /// Enable the new unified TodayViewState architecture with cache-first loading
    /// - Default: false (use existing Phase 3 architecture)
    /// - When enabled: Uses TodayViewState.shared for data loading during branding animation
    var useTodayViewV2: Bool {
        // For development, can be controlled via UserDefaults
        UserDefaults.standard.bool(forKey: "FeatureFlag.UseTodayViewV2")
    }

    // MARK: - Helper Methods

    /// Enable a feature flag (persisted across app launches)
    func enable(_ flag: String) {
        UserDefaults.standard.set(true, forKey: "FeatureFlag.\(flag)")
        Logger.info("🚩 Feature flag enabled: \(flag)")
    }

    /// Disable a feature flag (persisted across app launches)
    func disable(_ flag: String) {
        UserDefaults.standard.set(false, forKey: "FeatureFlag.\(flag)")
        Logger.info("🚩 Feature flag disabled: \(flag)")
    }

    /// Check if a feature flag is enabled
    func isEnabled(_ flag: String) -> Bool {
        UserDefaults.standard.bool(forKey: "FeatureFlag.\(flag)")
    }
}

// MARK: - Development Helper

#if DEBUG
extension FeatureFlags {
    /// Reset all feature flags to default (disabled)
    func resetAll() {
        let keys = ["UseTodayViewV2"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: "FeatureFlag.\(key)")
        }
        Logger.info("🚩 All feature flags reset to defaults")
    }
}
#endif
