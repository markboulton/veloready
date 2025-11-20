import Foundation
import UIKit

/// User profile information (Phase 1 Refactor)
/// Part of Settings DTO decomposition from UserSettings god object
struct ProfileSettings: Codable, Equatable, Sendable {
    let name: String
    let email: String
    let age: Int
    let weight: Double  // kilograms
    let height: Int     // centimeters
    let sex: String     // "M", "F", or "Other"
    let avatarData: Data?  // UIImage encoded as PNG data

    // MARK: - Defaults

    static let `default` = ProfileSettings(
        name: "",
        email: "",
        age: 0,
        weight: 0.0,
        height: 0,
        sex: "M",
        avatarData: nil
    )

    // MARK: - Validation

    enum ValidationError: Error, CustomStringConvertible {
        case invalidAge(String)
        case invalidWeight(String)
        case invalidHeight(String)
        case invalidSex(String)
        case invalidEmail(String)

        var description: String {
            switch self {
            case .invalidAge(let msg): return msg
            case .invalidWeight(let msg): return msg
            case .invalidHeight(let msg): return msg
            case .invalidSex(let msg): return msg
            case .invalidEmail(let msg): return msg
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Age must be between 13 and 120
        if age > 0 && (age < 13 || age > 120) {
            errors.append(.invalidAge("Age must be between 13 and 120 years"))
        }

        // Weight must be between 30 and 300 kg
        if weight > 0 && (weight < 30 || weight > 300) {
            errors.append(.invalidWeight("Weight must be between 30 and 300 kg"))
        }

        // Height must be between 100 and 250 cm
        if height > 0 && (height < 100 || height > 250) {
            errors.append(.invalidHeight("Height must be between 100 and 250 cm"))
        }

        // Sex must be M, F, or Other
        let validSexes = ["M", "F", "Other"]
        if !validSexes.contains(sex) {
            errors.append(.invalidSex("Sex must be one of: \(validSexes.joined(separator: ", "))"))
        }

        // Basic email validation (if provided)
        if !email.isEmpty && !email.contains("@") {
            errors.append(.invalidEmail("Email must contain @"))
        }

        return errors
    }

    // MARK: - Computed Properties

    /// BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
    var bmr: Double? {
        guard age > 0, weight > 0, height > 0 else { return nil }

        // Mifflin-St Jeor equation
        // Men: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
        // Women: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161
        let base = (10 * weight) + (6.25 * Double(height)) - (5 * Double(age))

        switch sex {
        case "M":
            return base + 5
        case "F":
            return base - 161
        default:
            // For "Other", use average of male and female
            return base - 78  // Average of +5 and -161
        }
    }

    /// BMI (Body Mass Index)
    var bmi: Double? {
        guard weight > 0, height > 0 else { return nil }
        let heightInMeters = Double(height) / 100.0
        return weight / (heightInMeters * heightInMeters)
    }

    /// BMI category description
    var bmiCategory: String? {
        guard let bmi = bmi else { return nil }

        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25.0:
            return "Normal"
        case 25.0..<30.0:
            return "Overweight"
        default:
            return "Obese"
        }
    }

    /// Weight in pounds (for display)
    var weightInPounds: Double {
        weight * 2.20462
    }

    /// Height in feet and inches (for display)
    var heightInFeetAndInches: (feet: Int, inches: Int) {
        let totalInches = Int(Double(height) / 2.54)
        let feet = totalInches / 12
        let inches = totalInches % 12
        return (feet, inches)
    }

    /// Avatar as UIImage (if available)
    var avatarImage: UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Factory Methods

    /// Create ProfileSettings with UIImage avatar
    static func with(
        name: String,
        email: String,
        age: Int,
        weight: Double,
        height: Int,
        sex: String,
        avatarImage: UIImage?
    ) -> ProfileSettings {
        let avatarData = avatarImage?.pngData()

        return ProfileSettings(
            name: name,
            email: email,
            age: age,
            weight: weight,
            height: height,
            sex: sex,
            avatarData: avatarData
        )
    }
}
