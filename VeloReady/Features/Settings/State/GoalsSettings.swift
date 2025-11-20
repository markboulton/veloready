import Foundation

/// Daily goals and targets (Phase 1 Refactor)
/// Part of Settings DTO decomposition from UserSettings god object
struct GoalsSettings: Codable, Equatable, Sendable {
    let calorieGoal: Double
    let useBMRAsGoal: Bool
    let stepGoal: Int

    // MARK: - Defaults

    static let `default` = GoalsSettings(
        calorieGoal: 0.0,  // 0 means use BMR
        useBMRAsGoal: true,
        stepGoal: 10000
    )

    // MARK: - Validation

    enum ValidationError: Error, CustomStringConvertible {
        case invalidCalorieGoal(String)
        case invalidStepGoal(String)

        var description: String {
            switch self {
            case .invalidCalorieGoal(let msg): return msg
            case .invalidStepGoal(let msg): return msg
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Calorie goal must be 0 (use BMR) or between 1000-5000
        if calorieGoal < 0 {
            errors.append(.invalidCalorieGoal("Calorie goal cannot be negative"))
        } else if calorieGoal > 0 && (calorieGoal < 1000 || calorieGoal > 5000) {
            errors.append(.invalidCalorieGoal("Calorie goal must be between 1000 and 5000 calories"))
        }

        // Step goal must be positive and reasonable
        if stepGoal < 0 {
            errors.append(.invalidStepGoal("Step goal cannot be negative"))
        } else if stepGoal > 100000 {
            errors.append(.invalidStepGoal("Step goal must be less than 100,000 steps"))
        }

        return errors
    }

    // MARK: - Computed Properties

    /// Get effective calorie goal (either custom or BMR)
    func effectiveCalorieGoal(bmr: Double?) -> Double {
        if useBMRAsGoal || calorieGoal == 0 {
            return bmr ?? 2000  // Default to 2000 if BMR not available
        }
        return calorieGoal
    }

    /// Check if calorie goal is custom (not BMR)
    var isCustomCalorieGoal: Bool {
        !useBMRAsGoal && calorieGoal > 0
    }
}
