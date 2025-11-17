import Foundation
import SwiftUI

/// User settings and preferences for the app
@MainActor
class UserSettings: ObservableObject {
    nonisolated(unsafe) static let shared = UserSettings()
    
    /// Flag to prevent saving during initialization
    private var isLoading = false
    
    // MARK: - Sleep Settings
    @Published var sleepTargetHours: Double = 8.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var sleepTargetMinutes: Int = 0 {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Sport Preferences
    @Published var sportPreferences: SportPreferences = .default {
        didSet {
            saveSettings()
        }
    }
    
    /// Convenience accessor for primary sport
    var primarySport: SportPreferences.Sport {
        sportPreferences.primarySport
    }
    
    /// Convenience accessor for ordered sports list
    var orderedSports: [SportPreferences.Sport] {
        sportPreferences.orderedSports
    }
    
    // MARK: - Heart Rate Zones (from Intervals.icu)
    @Published var hrZone1Max: Int = 120 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hrZone2Max: Int = 140 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hrZone3Max: Int = 160 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hrZone4Max: Int = 180 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hrZone5Max: Int = 200 {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Power Zones (from Intervals.icu)
    @Published var powerZone1Max: Int = 150 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var powerZone2Max: Int = 200 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var powerZone3Max: Int = 250 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var powerZone4Max: Int = 300 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var powerZone5Max: Int = 350 {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Zone Source Selection (FREE users)
    @Published var zoneSource: String = "intervals" {
        didSet {
            saveSettings()
            applyZoneSource()
        }
    }
    
    @Published var freeUserFTP: Int = 200 {
        didSet {
            saveSettings()
            if zoneSource == "coggan" {
                applyCogganPowerZones()
            }
        }
    }
    
    @Published var freeUserMaxHR: Int = 180 {
        didSet {
            saveSettings()
            if zoneSource == "coggan" {
                applyCogganHRZones()
            }
        }
    }
    
    // MARK: - Display Settings
    @Published var showSleepScore: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showRecoveryScore: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showHealthData: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Units
    @Published var useMetricUnits: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var use24HourTime: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Calorie Settings
    @Published var calorieGoal: Double = 0.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useBMRAsGoal: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Step Settings
    @Published var stepGoal: Int = 10000 {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Notifications
    @Published var sleepReminders: Bool = true {
        didSet {
            saveSettings()
            Task { @MainActor in
                await NotificationManager.shared.updateScheduledNotifications()
            }
        }
    }
    
    @Published var sleepReminderTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            saveSettings()
            Task { @MainActor in
                await NotificationManager.shared.updateScheduledNotifications()
            }
        }
    }
    
    @Published var recoveryAlerts: Bool = true {
        didSet {
            saveSettings()
            // Recovery alerts are sent on-demand, not scheduled
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total sleep target in seconds
    var sleepTargetSeconds: Double {
        return (sleepTargetHours * 3600) + (Double(sleepTargetMinutes) * 60)
    }
    
    /// Formatted sleep target for display
    var formattedSleepTarget: String {
        if sleepTargetMinutes == 0 {
            return "\(Int(sleepTargetHours))h"
        } else {
            return "\(Int(sleepTargetHours))h \(sleepTargetMinutes)m"
        }
    }
    
    /// Formatted sleep reminder time
    var formattedSleepReminderTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = use24HourTime ? .short : .short
        return formatter.string(from: sleepReminderTime)
    }
    
    /// Effective calorie goal (either user-set or BMR)
    var effectiveCalorieGoal: Double {
        return useBMRAsGoal ? 0.0 : calorieGoal
    }
    
    // MARK: - Zone Source Helpers
    
    private func applyZoneSource() {
        switch zoneSource {
        case "coggan":
            applyCogganPowerZones()
            applyCogganHRZones()
        case "manual":
            // Keep current manual values
            break
        case "intervals":
            // Will be synced from Intervals.icu
            break
        default:
            break
        }
    }
    
    private func applyCogganPowerZones() {
        let ftp = Double(freeUserFTP)
        powerZone1Max = Int(ftp * 0.55)  // 55%
        powerZone2Max = Int(ftp * 0.75)  // 75%
        powerZone3Max = Int(ftp * 0.90)  // 90%
        powerZone4Max = Int(ftp * 1.05)  // 105%
        powerZone5Max = Int(ftp * 1.20)  // 120%
    }
    
    private func applyCogganHRZones() {
        let maxHR = Double(freeUserMaxHR)
        hrZone1Max = Int(maxHR * 0.68)  // 68%
        hrZone2Max = Int(maxHR * 0.83)  // 83%
        hrZone3Max = Int(maxHR * 0.90)  // 90%
        hrZone4Max = Int(maxHR * 0.95)  // 95%
        hrZone5Max = Int(maxHR * 1.00)  // 100%
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        setupCloudRestoreNotification()
    }
    
    // MARK: - iCloud Restore
    
    private func setupCloudRestoreNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudRestore),
            name: .userSettingsDidRestore,
            object: nil
        )
    }
    
    @objc private func handleCloudRestore() {
        // loadSettings() already has isLoading protection
        loadSettings()
        Logger.debug("☁️ User settings restored from iCloud")
    }
    
    // MARK: - Settings Management
    
    private func saveSettings() {
        // Skip saves during initialization to avoid excessive disk I/O
        guard !isLoading else { return }
        
        let settings = UserSettingsData(
            sleepTargetHours: sleepTargetHours,
            sleepTargetMinutes: sleepTargetMinutes,
            sportPreferences: sportPreferences,
            hrZone1Max: hrZone1Max,
            hrZone2Max: hrZone2Max,
            hrZone3Max: hrZone3Max,
            hrZone4Max: hrZone4Max,
            hrZone5Max: hrZone5Max,
            powerZone1Max: powerZone1Max,
            powerZone2Max: powerZone2Max,
            powerZone3Max: powerZone3Max,
            powerZone4Max: powerZone4Max,
            powerZone5Max: powerZone5Max,
            zoneSource: zoneSource,
            freeUserFTP: freeUserFTP,
            freeUserMaxHR: freeUserMaxHR,
            showSleepScore: showSleepScore,
            showRecoveryScore: showRecoveryScore,
            showHealthData: showHealthData,
            useMetricUnits: useMetricUnits,
            use24HourTime: use24HourTime,
            calorieGoal: calorieGoal,
            useBMRAsGoal: useBMRAsGoal,
            stepGoal: stepGoal,
            sleepReminders: sleepReminders,
            sleepReminderTime: sleepReminderTime,
            recoveryAlerts: recoveryAlerts
        )
        
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "UserSettings")
            Logger.debug("💾 User settings saved")
        }
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "UserSettings"),
              let settings = try? JSONDecoder().decode(UserSettingsData.self, from: data) else {
            Logger.debug("📱 No saved settings found, using defaults")
            return
        }
        
        // Prevent saves during bulk property updates
        isLoading = true
        defer { isLoading = false }
        
        sleepTargetHours = settings.sleepTargetHours
        sleepTargetMinutes = settings.sleepTargetMinutes
        sportPreferences = settings.sportPreferences
        hrZone1Max = settings.hrZone1Max
        hrZone2Max = settings.hrZone2Max
        hrZone3Max = settings.hrZone3Max
        hrZone4Max = settings.hrZone4Max
        hrZone5Max = settings.hrZone5Max
        powerZone1Max = settings.powerZone1Max
        powerZone2Max = settings.powerZone2Max
        powerZone3Max = settings.powerZone3Max
        powerZone4Max = settings.powerZone4Max
        powerZone5Max = settings.powerZone5Max
        zoneSource = settings.zoneSource
        freeUserFTP = settings.freeUserFTP
        freeUserMaxHR = settings.freeUserMaxHR
        showSleepScore = settings.showSleepScore
        showRecoveryScore = settings.showRecoveryScore
        showHealthData = settings.showHealthData
        useMetricUnits = settings.useMetricUnits
        use24HourTime = settings.use24HourTime
        calorieGoal = settings.calorieGoal
        useBMRAsGoal = settings.useBMRAsGoal
        stepGoal = settings.stepGoal
        sleepReminders = settings.sleepReminders
        sleepReminderTime = settings.sleepReminderTime
        recoveryAlerts = settings.recoveryAlerts
        
        Logger.debug("📱 User settings loaded")
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        // Prevent saves during bulk property updates
        isLoading = true
        
        sleepTargetHours = 8.0
        sleepTargetMinutes = 0
        sportPreferences = .default
        hrZone1Max = 120
        hrZone2Max = 140
        hrZone3Max = 160
        hrZone4Max = 180
        hrZone5Max = 200
        powerZone1Max = 150
        powerZone2Max = 200
        powerZone3Max = 250
        powerZone4Max = 300
        powerZone5Max = 350
        zoneSource = "intervals"
        freeUserFTP = 200
        freeUserMaxHR = 180
        showSleepScore = true
        showRecoveryScore = true
        showHealthData = true
        useMetricUnits = true
        use24HourTime = true
        calorieGoal = 0.0
        useBMRAsGoal = true
        stepGoal = 10000
        sleepReminders = true
        sleepReminderTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        recoveryAlerts = true
        
        // Re-enable saves and perform final save
        isLoading = false
        saveSettings()
        Logger.debug("🔄 Settings reset to defaults")
    }
}

// MARK: - Settings Data Model

private struct UserSettingsData: Codable {
    let sleepTargetHours: Double
    let sleepTargetMinutes: Int
    let sportPreferences: SportPreferences
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
    let showSleepScore: Bool
    let showRecoveryScore: Bool
    let showHealthData: Bool
    let useMetricUnits: Bool
    let use24HourTime: Bool
    let calorieGoal: Double
    let useBMRAsGoal: Bool
    let stepGoal: Int
    let sleepReminders: Bool
    let sleepReminderTime: Date
    let recoveryAlerts: Bool
}
