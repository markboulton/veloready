import Foundation

/// Display preferences and visibility toggles (Phase 1 Refactor)
/// Part of Settings DTO decomposition from UserSettings god object
struct DisplaySettings: Codable, Equatable, Sendable {
    let showSleepScore: Bool
    let showRecoveryScore: Bool
    let showHealthData: Bool
    let useMetricUnits: Bool
    let use24HourTime: Bool

    // MARK: - Defaults

    static let `default` = DisplaySettings(
        showSleepScore: true,
        showRecoveryScore: true,
        showHealthData: true,
        useMetricUnits: true,
        use24HourTime: true
    )

    // MARK: - Validation

    /// Display settings have no validation constraints (all boolean flags)
    func validate() -> [Error] {
        return []
    }

    // MARK: - Helpers

    /// Format distance based on unit preference
    func formatDistance(_ meters: Double) -> String {
        if useMetricUnits {
            let km = meters / 1000.0
            return String(format: "%.2f km", km)
        } else {
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        }
    }

    /// Format speed based on unit preference
    func formatSpeed(_ metersPerSecond: Double) -> String {
        if useMetricUnits {
            let kmPerHour = metersPerSecond * 3.6
            return String(format: "%.1f km/h", kmPerHour)
        } else {
            let milesPerHour = metersPerSecond * 2.23694
            return String(format: "%.1f mph", milesPerHour)
        }
    }

    /// Format temperature based on unit preference
    func formatTemperature(_ celsius: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f°C", celsius)
        } else {
            let fahrenheit = (celsius * 9/5) + 32
            return String(format: "%.1f°F", fahrenheit)
        }
    }

    /// Format time based on 12/24 hour preference
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
}
