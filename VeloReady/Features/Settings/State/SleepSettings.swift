import Foundation

/// Sleep preferences and reminders (Phase 1 Refactor)
/// Part of Settings DTO decomposition from UserSettings god object
struct SleepSettings: Codable, Equatable, Sendable {
    let targetHours: Double
    let targetMinutes: Int
    let reminders: Bool
    let reminderTime: Date

    // MARK: - Defaults

    static let `default` = SleepSettings(
        targetHours: 8.0,
        targetMinutes: 0,
        reminders: true,
        reminderTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    )

    // MARK: - Validation

    enum ValidationError: Error, CustomStringConvertible {
        case invalidTargetHours(String)
        case invalidTargetMinutes(String)

        var description: String {
            switch self {
            case .invalidTargetHours(let msg): return msg
            case .invalidTargetMinutes(let msg): return msg
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Target hours must be between 4 and 12
        if targetHours < 4.0 || targetHours > 12.0 {
            errors.append(.invalidTargetHours("Sleep target hours must be between 4 and 12 hours"))
        }

        // Target minutes must be between 0 and 59
        if targetMinutes < 0 || targetMinutes > 59 {
            errors.append(.invalidTargetMinutes("Sleep target minutes must be between 0 and 59"))
        }

        return errors
    }

    // MARK: - Computed Properties

    /// Total target sleep duration in hours
    var totalTargetHours: Double {
        targetHours + (Double(targetMinutes) / 60.0)
    }

    /// Total target sleep duration in minutes
    var totalTargetMinutes: Int {
        Int(targetHours * 60) + targetMinutes
    }
}
