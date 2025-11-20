import Foundation

/// Data loader for Settings feature (Phase 1 Refactor)
/// Handles all persistence, validation, and syncing for settings
/// Follows the pattern established in TodayDataLoader and TrendsDataLoader
@MainActor
final class SettingsDataLoader {

    // MARK: - Data Transfer Objects

    /// Complete settings bundle
    struct SettingsBundle {
        let sleep: SleepSettings
        let zones: ZoneSettings
        let display: DisplaySettings
        let profile: ProfileSettings
        let goals: GoalsSettings
    }

    // MARK: - Dependencies (Dependency Injection)

    private let userDefaults: UserDefaults
    private let notificationManager: NotificationManager
    private let athleteZoneService: AthleteZoneService

    init(
        userDefaults: UserDefaults = .standard,
        notificationManager: NotificationManager = .shared,
        athleteZoneService: AthleteZoneService = .shared
    ) {
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager
        self.athleteZoneService = athleteZoneService
    }

    // MARK: - Public API

    /// Load all settings at once
    func loadAllSettings() async -> SettingsBundle {
        async let sleep = loadSleepSettings()
        async let zones = loadZoneSettings()
        async let display = loadDisplaySettings()
        async let profile = loadProfileSettings()
        async let goals = loadGoalsSettings()

        return await SettingsBundle(
            sleep: sleep,
            zones: zones,
            display: display,
            profile: profile,
            goals: goals
        )
    }

    // MARK: - Individual Load Operations

    /// Load sleep settings from UserDefaults
    func loadSleepSettings() async -> SleepSettings {
        // Try new format first
        if let data = userDefaults.data(forKey: SettingsKeys.sleep),
           let settings = try? JSONDecoder().decode(SleepSettings.self, from: data) {
            Logger.debug("📥 [SettingsDataLoader] Loaded sleep settings (new format)")
            return settings
        }

        // Fall back to migrating from UserSettings
        if let migrated = migrateFromUserSettings()?.sleep {
            Logger.debug("📥 [SettingsDataLoader] Migrated sleep settings from UserSettings")
            // Save in new format
            Task {
                try? await saveSleepSettings(migrated)
            }
            return migrated
        }

        Logger.debug("📥 [SettingsDataLoader] Using default sleep settings")
        return .default
    }

    /// Load zone settings from UserDefaults
    func loadZoneSettings() async -> ZoneSettings {
        // Try new format first
        if let data = userDefaults.data(forKey: SettingsKeys.zones),
           let settings = try? JSONDecoder().decode(ZoneSettings.self, from: data) {
            Logger.debug("📥 [SettingsDataLoader] Loaded zone settings (new format)")
            return settings
        }

        // Fall back to migrating from UserSettings
        if let migrated = migrateFromUserSettings()?.zones {
            Logger.debug("📥 [SettingsDataLoader] Migrated zone settings from UserSettings")
            // Save in new format
            Task {
                try? await saveZoneSettings(migrated)
            }
            return migrated
        }

        Logger.debug("📥 [SettingsDataLoader] Using default zone settings")
        return .default
    }

    /// Load display settings from UserDefaults
    func loadDisplaySettings() async -> DisplaySettings {
        // Try new format first
        if let data = userDefaults.data(forKey: SettingsKeys.display),
           let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
            Logger.debug("📥 [SettingsDataLoader] Loaded display settings (new format)")
            return settings
        }

        // Fall back to migrating from UserSettings
        if let migrated = migrateFromUserSettings()?.display {
            Logger.debug("📥 [SettingsDataLoader] Migrated display settings from UserSettings")
            // Save in new format
            Task {
                try? await saveDisplaySettings(migrated)
            }
            return migrated
        }

        Logger.debug("📥 [SettingsDataLoader] Using default display settings")
        return .default
    }

    /// Load profile settings from UserDefaults
    func loadProfileSettings() async -> ProfileSettings {
        // Try new format first
        if let data = userDefaults.data(forKey: SettingsKeys.profile),
           let settings = try? JSONDecoder().decode(ProfileSettings.self, from: data) {
            Logger.debug("📥 [SettingsDataLoader] Loaded profile settings (new format)")
            return settings
        }

        // Fall back to migrating from UserSettings
        if let migrated = migrateFromUserSettings()?.profile {
            Logger.debug("📥 [SettingsDataLoader] Migrated profile settings from UserSettings")
            // Save in new format
            Task {
                try? await saveProfileSettings(migrated)
            }
            return migrated
        }

        Logger.debug("📥 [SettingsDataLoader] Using default profile settings")
        return .default
    }

    /// Load goals settings from UserDefaults
    func loadGoalsSettings() async -> GoalsSettings {
        // Try new format first
        if let data = userDefaults.data(forKey: SettingsKeys.goals),
           let settings = try? JSONDecoder().decode(GoalsSettings.self, from: data) {
            Logger.debug("📥 [SettingsDataLoader] Loaded goals settings (new format)")
            return settings
        }

        // Fall back to migrating from UserSettings
        if let migrated = migrateFromUserSettings()?.goals {
            Logger.debug("📥 [SettingsDataLoader] Migrated goals settings from UserSettings")
            // Save in new format
            Task {
                try? await saveGoalsSettings(migrated)
            }
            return migrated
        }

        Logger.debug("📥 [SettingsDataLoader] Using default goals settings")
        return .default
    }

    // MARK: - Save Operations (Atomic)

    /// Save sleep settings with validation
    func saveSleepSettings(_ settings: SleepSettings) async throws {
        // Validate
        let errors = settings.validate()
        guard errors.isEmpty else {
            Logger.error("❌ [SettingsDataLoader] Sleep settings validation failed: \(errors)")
            throw SettingsError.validationFailed(errors.map { $0.description })
        }

        // Encode
        let encoded = try JSONEncoder().encode(settings)

        // Save to UserDefaults
        userDefaults.set(encoded, forKey: SettingsKeys.sleep)
        Logger.debug("💾 [SettingsDataLoader] Saved sleep settings")

        // Update notifications if reminder settings changed
        await notificationManager.updateScheduledNotifications()
    }

    /// Save zone settings with validation
    func saveZoneSettings(_ settings: ZoneSettings) async throws {
        // Validate
        let errors = settings.validate()
        guard errors.isEmpty else {
            Logger.error("❌ [SettingsDataLoader] Zone settings validation failed: \(errors)")
            throw SettingsError.validationFailed(errors.map { $0.description })
        }

        // Encode
        let encoded = try JSONEncoder().encode(settings)

        // Save to UserDefaults
        userDefaults.set(encoded, forKey: SettingsKeys.zones)
        Logger.debug("💾 [SettingsDataLoader] Saved zone settings")
    }

    /// Save display settings (no validation needed)
    func saveDisplaySettings(_ settings: DisplaySettings) async throws {
        // Encode
        let encoded = try JSONEncoder().encode(settings)

        // Save to UserDefaults
        userDefaults.set(encoded, forKey: SettingsKeys.display)
        Logger.debug("💾 [SettingsDataLoader] Saved display settings")
    }

    /// Save profile settings with validation
    func saveProfileSettings(_ settings: ProfileSettings) async throws {
        // Validate
        let errors = settings.validate()
        guard errors.isEmpty else {
            Logger.error("❌ [SettingsDataLoader] Profile settings validation failed: \(errors)")
            throw SettingsError.validationFailed(errors.map { $0.description })
        }

        // Encode
        let encoded = try JSONEncoder().encode(settings)

        // Save to UserDefaults
        userDefaults.set(encoded, forKey: SettingsKeys.profile)
        Logger.debug("💾 [SettingsDataLoader] Saved profile settings")
    }

    /// Save goals settings with validation
    func saveGoalsSettings(_ settings: GoalsSettings) async throws {
        // Validate
        let errors = settings.validate()
        guard errors.isEmpty else {
            Logger.error("❌ [SettingsDataLoader] Goals settings validation failed: \(errors)")
            throw SettingsError.validationFailed(errors.map { $0.description })
        }

        // Encode
        let encoded = try JSONEncoder().encode(settings)

        // Save to UserDefaults
        userDefaults.set(encoded, forKey: SettingsKeys.goals)
        Logger.debug("💾 [SettingsDataLoader] Saved goals settings")
    }

    // MARK: - External Service Integration

    /// Sync zones from Intervals.icu (no longer modifies UserSettings directly)
    func syncZonesFromIntervals() async throws -> ZoneSettings {
        Logger.info("🔄 [SettingsDataLoader] Syncing zones from Intervals.icu")

        // Fetch athlete data from Intervals
        await athleteZoneService.fetchAthleteData()

        // Extract zone data (this no longer has side effects)
        guard let zoneData = athleteZoneService.extractZoneData() else {
            throw SettingsError.syncFailed("No zone data available from Intervals.icu")
        }

        // Get current zone settings to preserve source and Coggan parameters
        let currentZones = await loadZoneSettings()

        // Create new zone settings with Intervals data
        let settings = ZoneSettings(
            source: "intervals",
            hrZone1Max: zoneData.hrZones.count > 0 ? zoneData.hrZones[0] : currentZones.hrZone1Max,
            hrZone2Max: zoneData.hrZones.count > 1 ? zoneData.hrZones[1] : currentZones.hrZone2Max,
            hrZone3Max: zoneData.hrZones.count > 2 ? zoneData.hrZones[2] : currentZones.hrZone3Max,
            hrZone4Max: zoneData.hrZones.count > 3 ? zoneData.hrZones[3] : currentZones.hrZone4Max,
            hrZone5Max: zoneData.hrZones.count > 4 ? zoneData.hrZones[4] : currentZones.hrZone5Max,
            powerZone1Max: zoneData.powerZones.count > 0 ? zoneData.powerZones[0] : currentZones.powerZone1Max,
            powerZone2Max: zoneData.powerZones.count > 1 ? zoneData.powerZones[1] : currentZones.powerZone2Max,
            powerZone3Max: zoneData.powerZones.count > 2 ? zoneData.powerZones[2] : currentZones.powerZone3Max,
            powerZone4Max: zoneData.powerZones.count > 3 ? zoneData.powerZones[3] : currentZones.powerZone4Max,
            powerZone5Max: zoneData.powerZones.count > 4 ? zoneData.powerZones[4] : currentZones.powerZone5Max,
            freeUserFTP: currentZones.freeUserFTP,
            freeUserMaxHR: currentZones.freeUserMaxHR
        )

        // Validate and save
        try await saveZoneSettings(settings)

        Logger.info("✅ [SettingsDataLoader] Synced zones from Intervals.icu")
        return settings
    }

    /// Apply Coggan zones based on FTP and Max HR
    func applyCogganZones(ftp: Int, maxHR: Int) async throws -> ZoneSettings {
        Logger.info("🔄 [SettingsDataLoader] Applying Coggan zones (FTP: \(ftp)W, MaxHR: \(maxHR)bpm)")

        // Generate Coggan zones
        let settings = ZoneSettings.fromCoggan(ftp: ftp, maxHR: maxHR)

        // Validate and save
        try await saveZoneSettings(settings)

        Logger.info("✅ [SettingsDataLoader] Applied Coggan zones")
        return settings
    }

    // MARK: - Migration from UserSettings

    /// Migrate from old UserSettings format to new DTOs
    private func migrateFromUserSettings() -> SettingsBundle? {
        // Check if old UserSettings exists
        guard let data = userDefaults.data(forKey: "UserSettings"),
              let legacy = try? JSONDecoder().decode(LegacyUserSettings.self, from: data) else {
            return nil
        }

        Logger.info("🔄 [SettingsDataLoader] Migrating from legacy UserSettings format")

        // Migrate to new DTOs
        let sleep = SleepSettings(
            targetHours: legacy.sleepTargetHours,
            targetMinutes: legacy.sleepTargetMinutes,
            reminders: legacy.sleepReminders,
            reminderTime: legacy.sleepReminderTime
        )

        let zones = ZoneSettings(
            source: legacy.zoneSource,
            hrZone1Max: legacy.hrZone1Max,
            hrZone2Max: legacy.hrZone2Max,
            hrZone3Max: legacy.hrZone3Max,
            hrZone4Max: legacy.hrZone4Max,
            hrZone5Max: legacy.hrZone5Max,
            powerZone1Max: legacy.powerZone1Max,
            powerZone2Max: legacy.powerZone2Max,
            powerZone3Max: legacy.powerZone3Max,
            powerZone4Max: legacy.powerZone4Max,
            powerZone5Max: legacy.powerZone5Max,
            freeUserFTP: legacy.freeUserFTP,
            freeUserMaxHR: legacy.freeUserMaxHR
        )

        let display = DisplaySettings(
            showSleepScore: legacy.showSleepScore,
            showRecoveryScore: legacy.showRecoveryScore,
            showHealthData: legacy.showHealthData,
            useMetricUnits: legacy.useMetricUnits,
            use24HourTime: legacy.use24HourTime
        )

        let profile = ProfileSettings.default  // Profile not in UserSettings

        let goals = GoalsSettings(
            calorieGoal: legacy.calorieGoal,
            useBMRAsGoal: legacy.useBMRAsGoal,
            stepGoal: legacy.stepGoal
        )

        return SettingsBundle(
            sleep: sleep,
            zones: zones,
            display: display,
            profile: profile,
            goals: goals
        )
    }

    // MARK: - Supporting Types

    /// UserDefaults keys for settings
    private enum SettingsKeys {
        static let sleep = "SleepSettings_v1"
        static let zones = "ZoneSettings_v1"
        static let display = "DisplaySettings_v1"
        static let profile = "ProfileSettings_v1"
        static let goals = "GoalsSettings_v1"
    }

    /// Legacy UserSettings structure for migration
    private struct LegacyUserSettings: Codable {
        // Sleep
        let sleepTargetHours: Double
        let sleepTargetMinutes: Int
        let sleepReminders: Bool
        let sleepReminderTime: Date

        // Zones
        let hrZone1Max: Int
        let hrZone2Max: Int
        let hrZone3Max: Int
        let hrZone4Max: Int
        let hrZone5Max: Int
        let powerZone1Max: Int
        let powerZone2Max: Int
        let powerZone3Max: Int
        let powerZone4Max: Int
        let powerZone5Max: Int
        let zoneSource: String
        let freeUserFTP: Int
        let freeUserMaxHR: Int

        // Display
        let showSleepScore: Bool
        let showRecoveryScore: Bool
        let showHealthData: Bool
        let useMetricUnits: Bool
        let use24HourTime: Bool

        // Goals
        let calorieGoal: Double
        let useBMRAsGoal: Bool
        let stepGoal: Int
    }
}

// MARK: - Errors

enum SettingsError: Error, CustomStringConvertible {
    case validationFailed([String])
    case saveFailed(String)
    case syncFailed(String)

    var description: String {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .saveFailed(let msg):
            return "Save failed: \(msg)"
        case .syncFailed(let msg):
            return "Sync failed: \(msg)"
        }
    }
}
