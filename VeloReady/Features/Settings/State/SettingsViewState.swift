import Foundation
import SwiftUI

/// Unified state container for Settings view (Phase 1 Refactor)
/// Single source of truth for settings state management
/// Follows the pattern established in TodayViewState, ActivitiesViewState, and TrendsViewState
@MainActor
final class SettingsViewState: ObservableObject {
    static let shared = SettingsViewState()

    // MARK: - Loading Phase

    enum LoadingPhase: Equatable {
        case notStarted
        case loading
        case complete
        case error(Error)

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }

        var description: String {
            switch self {
            case .notStarted: return "notStarted"
            case .loading: return "loading"
            case .complete: return "complete"
            case .error(let error): return "error(\(error.localizedDescription))"
            }
        }

        // Equatable conformance
        static func == (lhs: LoadingPhase, rhs: LoadingPhase) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted),
                 (.loading, .loading),
                 (.complete, .complete):
                return true
            case (.error, .error):
                return true  // Consider all error states equal
            default:
                return false
            }
        }
    }

    // MARK: - Sheet Management

    enum Sheet: Identifiable {
        case sleep
        case zones
        case display
        case profile
        case goals
        case zoneSource
        case notifications

        var id: String {
            switch self {
            case .sleep: return "sleep"
            case .zones: return "zones"
            case .display: return "display"
            case .profile: return "profile"
            case .goals: return "goals"
            case .zoneSource: return "zoneSource"
            case .notifications: return "notifications"
            }
        }
    }

    // MARK: - Published State (6 properties instead of 28)

    @Published var phase: LoadingPhase = .notStarted
    @Published var activeSheet: Sheet?
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?  // For showing validation error alerts

    // Settings groups
    @Published var sleepSettings: SleepSettings = .default
    @Published var zoneSettings: ZoneSettings = .default
    @Published var displaySettings: DisplaySettings = .default
    @Published var profileSettings: ProfileSettings = .default
    @Published var goalsSettings: GoalsSettings = .default

    // MARK: - Dependencies

    private let loader: SettingsDataLoader

    private init() {
        self.loader = SettingsDataLoader()
        Logger.debug("⚙️ [SettingsViewState] Initialized")
    }

    // MARK: - Public API

    /// Load all settings
    func load() async {
        Logger.info("⚙️ [SettingsViewState] Loading settings...")
        phase = .loading

        let bundle = await loader.loadAllSettings()

        sleepSettings = bundle.sleep
        zoneSettings = bundle.zones
        displaySettings = bundle.display
        profileSettings = bundle.profile
        goalsSettings = bundle.goals

        phase = .complete
        lastUpdated = Date()

        Logger.info("⚙️ [SettingsViewState] Settings loaded successfully")
    }

    // MARK: - Save Operations

    /// Save sleep settings
    func saveSleepSettings(_ settings: SleepSettings) async {
        do {
            try await loader.saveSleepSettings(settings)
            sleepSettings = settings
            lastUpdated = Date()
            errorMessage = nil  // Clear any previous errors
            Logger.info("⚙️ [SettingsViewState] Sleep settings saved")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to save sleep settings: \(error)")
            errorMessage = error.localizedDescription
            phase = .error(error)
        }
    }

    /// Save zone settings
    func saveZoneSettings(_ settings: ZoneSettings) async {
        do {
            try await loader.saveZoneSettings(settings)
            zoneSettings = settings
            lastUpdated = Date()
            errorMessage = nil  // Clear any previous errors
            Logger.info("⚙️ [SettingsViewState] Zone settings saved")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to save zone settings: \(error)")
            errorMessage = error.localizedDescription
            phase = .error(error)
        }
    }

    /// Save display settings
    func saveDisplaySettings(_ settings: DisplaySettings) async {
        do {
            try await loader.saveDisplaySettings(settings)
            displaySettings = settings
            lastUpdated = Date()
            errorMessage = nil  // Clear any previous errors
            Logger.info("⚙️ [SettingsViewState] Display settings saved")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to save display settings: \(error)")
            errorMessage = error.localizedDescription
            phase = .error(error)
        }
    }

    /// Save profile settings
    func saveProfileSettings(_ settings: ProfileSettings) async {
        do {
            try await loader.saveProfileSettings(settings)
            profileSettings = settings
            lastUpdated = Date()
            errorMessage = nil  // Clear any previous errors
            Logger.info("⚙️ [SettingsViewState] Profile settings saved")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to save profile settings: \(error)")
            errorMessage = error.localizedDescription
            phase = .error(error)
        }
    }

    /// Save goals settings
    func saveGoalsSettings(_ settings: GoalsSettings) async {
        do {
            try await loader.saveGoalsSettings(settings)
            goalsSettings = settings
            lastUpdated = Date()
            errorMessage = nil  // Clear any previous errors
            Logger.info("⚙️ [SettingsViewState] Goals settings saved")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to save goals settings: \(error)")
            errorMessage = error.localizedDescription
            phase = .error(error)
        }
    }

    // MARK: - External Service Integration

    /// Sync zones from Intervals.icu
    func syncZonesFromIntervals() async {
        do {
            let settings = try await loader.syncZonesFromIntervals()
            zoneSettings = settings
            lastUpdated = Date()
            Logger.info("⚙️ [SettingsViewState] Synced zones from Intervals.icu")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to sync zones: \(error)")
            phase = .error(error)
        }
    }

    /// Apply Coggan zones
    func applyCogganZones(ftp: Int, maxHR: Int) async {
        do {
            let settings = try await loader.applyCogganZones(ftp: ftp, maxHR: maxHR)
            zoneSettings = settings
            lastUpdated = Date()
            Logger.info("⚙️ [SettingsViewState] Applied Coggan zones")
        } catch {
            Logger.error("❌ [SettingsViewState] Failed to apply Coggan zones: \(error)")
            phase = .error(error)
        }
    }

    // MARK: - Convenience Methods

    /// Show a specific settings sheet
    func show(sheet: Sheet) {
        activeSheet = sheet
    }

    /// Dismiss the active sheet
    func dismissSheet() {
        activeSheet = nil
    }

    /// Reset all settings to defaults (dangerous!)
    func resetToDefaults() async {
        Logger.warning("⚠️ [SettingsViewState] Resetting all settings to defaults")

        await saveSleepSettings(.default)
        await saveZoneSettings(.default)
        await saveDisplaySettings(.default)
        await saveProfileSettings(.default)
        await saveGoalsSettings(.default)

        Logger.info("⚙️ [SettingsViewState] All settings reset to defaults")
    }
}
