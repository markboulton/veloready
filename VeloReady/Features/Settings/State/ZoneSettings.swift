import Foundation

/// Athletic training zones for heart rate and power (Phase 1 Refactor)
/// Part of Settings DTO decomposition from UserSettings god object
struct ZoneSettings: Codable, Equatable, Sendable {
    let source: String  // "intervals", "coggan", "custom"

    // Heart Rate Zones (5 zones)
    let hrZone1Max: Int
    let hrZone2Max: Int
    let hrZone3Max: Int
    let hrZone4Max: Int
    let hrZone5Max: Int

    // Power Zones (5 zones)
    let powerZone1Max: Int
    let powerZone2Max: Int
    let powerZone3Max: Int
    let powerZone4Max: Int
    let powerZone5Max: Int

    // Free User Coggan Parameters
    let freeUserFTP: Int
    let freeUserMaxHR: Int

    // MARK: - Defaults

    static let `default` = ZoneSettings(
        source: "intervals",
        hrZone1Max: 120,
        hrZone2Max: 140,
        hrZone3Max: 160,
        hrZone4Max: 180,
        hrZone5Max: 200,
        powerZone1Max: 150,
        powerZone2Max: 200,
        powerZone3Max: 250,
        powerZone4Max: 300,
        powerZone5Max: 350,
        freeUserFTP: 200,
        freeUserMaxHR: 180
    )

    // MARK: - Validation

    enum ValidationError: Error, CustomStringConvertible {
        case invalidZoneOrder(String)
        case invalidZoneValue(String)
        case invalidSource(String)
        case invalidFTP(String)
        case invalidMaxHR(String)

        var description: String {
            switch self {
            case .invalidZoneOrder(let msg): return msg
            case .invalidZoneValue(let msg): return msg
            case .invalidSource(let msg): return msg
            case .invalidFTP(let msg): return msg
            case .invalidMaxHR(let msg): return msg
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Validate zone source
        let validSources = ["intervals", "coggan", "custom"]
        if !validSources.contains(source) {
            errors.append(.invalidSource("Zone source must be one of: \(validSources.joined(separator: ", "))"))
        }

        // Validate HR zone ordering (each zone must be greater than the previous)
        if hrZone1Max >= hrZone2Max {
            errors.append(.invalidZoneOrder("HR Zone 1 max (\(hrZone1Max)) must be less than Zone 2 max (\(hrZone2Max))"))
        }
        if hrZone2Max >= hrZone3Max {
            errors.append(.invalidZoneOrder("HR Zone 2 max (\(hrZone2Max)) must be less than Zone 3 max (\(hrZone3Max))"))
        }
        if hrZone3Max >= hrZone4Max {
            errors.append(.invalidZoneOrder("HR Zone 3 max (\(hrZone3Max)) must be less than Zone 4 max (\(hrZone4Max))"))
        }
        if hrZone4Max >= hrZone5Max {
            errors.append(.invalidZoneOrder("HR Zone 4 max (\(hrZone4Max)) must be less than Zone 5 max (\(hrZone5Max))"))
        }

        // Validate HR zone values (must be positive and reasonable)
        let hrZones = [hrZone1Max, hrZone2Max, hrZone3Max, hrZone4Max, hrZone5Max]
        for (index, zone) in hrZones.enumerated() {
            if zone < 50 || zone > 250 {
                errors.append(.invalidZoneValue("HR Zone \(index + 1) max (\(zone)) must be between 50 and 250 bpm"))
            }
        }

        // Validate power zone ordering
        if powerZone1Max >= powerZone2Max {
            errors.append(.invalidZoneOrder("Power Zone 1 max (\(powerZone1Max)) must be less than Zone 2 max (\(powerZone2Max))"))
        }
        if powerZone2Max >= powerZone3Max {
            errors.append(.invalidZoneOrder("Power Zone 2 max (\(powerZone2Max)) must be less than Zone 3 max (\(powerZone3Max))"))
        }
        if powerZone3Max >= powerZone4Max {
            errors.append(.invalidZoneOrder("Power Zone 3 max (\(powerZone3Max)) must be less than Zone 4 max (\(powerZone4Max))"))
        }
        if powerZone4Max >= powerZone5Max {
            errors.append(.invalidZoneOrder("Power Zone 4 max (\(powerZone4Max)) must be less than Zone 5 max (\(powerZone5Max))"))
        }

        // Validate power zone values (must be positive and reasonable)
        let powerZones = [powerZone1Max, powerZone2Max, powerZone3Max, powerZone4Max, powerZone5Max]
        for (index, zone) in powerZones.enumerated() {
            if zone < 50 || zone > 1000 {
                errors.append(.invalidZoneValue("Power Zone \(index + 1) max (\(zone)) must be between 50 and 1000 watts"))
            }
        }

        // Validate Coggan parameters
        if freeUserFTP < 50 || freeUserFTP > 600 {
            errors.append(.invalidFTP("FTP (\(freeUserFTP)) must be between 50 and 600 watts"))
        }

        if freeUserMaxHR < 100 || freeUserMaxHR > 250 {
            errors.append(.invalidMaxHR("Max HR (\(freeUserMaxHR)) must be between 100 and 250 bpm"))
        }

        return errors
    }

    // MARK: - Computed Properties

    /// All HR zones as an array
    var hrZones: [Int] {
        [hrZone1Max, hrZone2Max, hrZone3Max, hrZone4Max, hrZone5Max]
    }

    /// All power zones as an array
    var powerZones: [Int] {
        [powerZone1Max, powerZone2Max, powerZone3Max, powerZone4Max, powerZone5Max]
    }

    // MARK: - Factory Methods

    /// Create zones from Intervals.icu athlete data
    static func fromIntervals(hrZones: [Int], powerZones: [Int]) -> ZoneSettings {
        guard hrZones.count == 5, powerZones.count == 5 else {
            return .default
        }

        return ZoneSettings(
            source: "intervals",
            hrZone1Max: hrZones[0],
            hrZone2Max: hrZones[1],
            hrZone3Max: hrZones[2],
            hrZone4Max: hrZones[3],
            hrZone5Max: hrZones[4],
            powerZone1Max: powerZones[0],
            powerZone2Max: powerZones[1],
            powerZone3Max: powerZones[2],
            powerZone4Max: powerZones[3],
            powerZone5Max: powerZones[4],
            freeUserFTP: 200,
            freeUserMaxHR: 180
        )
    }

    /// Create zones using Coggan method
    static func fromCoggan(ftp: Int, maxHR: Int) -> ZoneSettings {
        // Coggan Power Zones (based on FTP)
        let powerZones = [
            Int(Double(ftp) * 0.55),  // Zone 1: Active Recovery (< 55% FTP)
            Int(Double(ftp) * 0.75),  // Zone 2: Endurance (56-75% FTP)
            Int(Double(ftp) * 0.90),  // Zone 3: Tempo (76-90% FTP)
            Int(Double(ftp) * 1.05),  // Zone 4: Threshold (91-105% FTP)
            Int(Double(ftp) * 1.50)   // Zone 5: VO2Max (106-150% FTP)
        ]

        // Coggan HR Zones (based on Max HR)
        let hrZones = [
            Int(Double(maxHR) * 0.68),  // Zone 1: Active Recovery (< 68% MaxHR)
            Int(Double(maxHR) * 0.83),  // Zone 2: Endurance (69-83% MaxHR)
            Int(Double(maxHR) * 0.94),  // Zone 3: Tempo (84-94% MaxHR)
            Int(Double(maxHR) * 1.05),  // Zone 4: Threshold (95-105% MaxHR)
            maxHR                        // Zone 5: VO2Max (>105% MaxHR)
        ]

        return ZoneSettings(
            source: "coggan",
            hrZone1Max: hrZones[0],
            hrZone2Max: hrZones[1],
            hrZone3Max: hrZones[2],
            hrZone4Max: hrZones[3],
            hrZone5Max: hrZones[4],
            powerZone1Max: powerZones[0],
            powerZone2Max: powerZones[1],
            powerZone3Max: powerZones[2],
            powerZone4Max: powerZones[3],
            powerZone5Max: powerZones[4],
            freeUserFTP: ftp,
            freeUserMaxHR: maxHR
        )
    }
}
