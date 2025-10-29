import Foundation

/// Platform-agnostic activity data model
/// Represents a training activity from any source (Intervals.icu, Strava, HealthKit)
public struct ActivityData: Equatable {
    public let id: String
    public let startDate: Date
    public let type: String
    public let duration: TimeInterval // seconds
    public let distance: Double? // meters
    public let tss: Double? // Training Stress Score
    public let averagePower: Double? // watts
    public let normalizedPower: Double? // watts (NP or weighted average)
    public let averageHeartRate: Double? // bpm
    public let maxHeartRate: Double? // bpm
    public let intensityFactor: Double? // IF (NP/FTP)
    public let calories: Int?
    
    public init(
        id: String,
        startDate: Date,
        type: String,
        duration: TimeInterval,
        distance: Double? = nil,
        tss: Double? = nil,
        averagePower: Double? = nil,
        normalizedPower: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        intensityFactor: Double? = nil,
        calories: Int? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.type = type
        self.duration = duration
        self.distance = distance
        self.tss = tss
        self.averagePower = averagePower
        self.normalizedPower = normalizedPower
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.intensityFactor = intensityFactor
        self.calories = calories
    }
    
    /// Validate that the activity data is within reasonable bounds
    public var isValid: Bool {
        // Duration should be positive and less than 24 hours
        guard duration > 0 && duration < 86400 else { return false }
        
        // Power values should be reasonable (0-2000W)
        if let power = averagePower, power < 0 || power > 2000 { return false }
        if let power = normalizedPower, power < 0 || power > 2000 { return false }
        
        // Heart rate should be reasonable (30-250 bpm)
        if let hr = averageHeartRate, hr < 30 || hr > 250 { return false }
        if let hr = maxHeartRate, hr < 30 || hr > 250 { return false }
        
        // TSS should be reasonable (0-1000)
        if let tss = tss, tss < 0 || tss > 1000 { return false }
        
        // Intensity Factor should be 0-2.0
        if let if_ = intensityFactor, if_ < 0 || if_ > 2.0 { return false }
        
        return true
    }
    
    /// Calculate TSS from power and duration if not provided
    /// Formula: TSS = (duration_hours * NP * IF) / (FTP * 3600) * 100
    public func calculateTSS(ftp: Double) -> Double? {
        guard let np = normalizedPower else { return nil }
        guard ftp > 0 else { return nil }
        
        let if_ = np / ftp
        let durationHours = duration / 3600.0
        return (durationHours * np * if_) / (ftp * 3600.0) * 100.0
    }
}

/// Activity parsing and validation utilities
public struct ActivityParser {
    
    public enum ParsingError: Error, Equatable {
        case invalidJSON
        case missingRequiredField(String)
        case invalidDateFormat
        case invalidData(String)
    }
    
    /// Parse Intervals.icu activity JSON
    public static func parseIntervalsActivity(_ json: String) throws -> ActivityData {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(IntervalsResponse.self, from: data)
            
            // Validate required fields
            guard !response.id.isEmpty else {
                throw ParsingError.missingRequiredField("id")
            }
            
            guard !response.type.isEmpty else {
                throw ParsingError.missingRequiredField("type")
            }
            
            guard response.moving_time > 0 else {
                throw ParsingError.invalidData("Duration must be positive")
            }
            
            return ActivityData(
                id: response.id,
                startDate: response.start_date_local,
                type: response.type,
                duration: TimeInterval(response.moving_time),
                distance: response.distance,
                tss: response.icu_training_load,
                averagePower: response.average_watts,
                normalizedPower: response.weighted_average_watts,
                averageHeartRate: response.average_heartrate,
                maxHeartRate: response.max_heartrate,
                intensityFactor: response.intensity,
                calories: response.calories
            )
        } catch DecodingError.keyNotFound(let key, _) {
            throw ParsingError.missingRequiredField(key.stringValue)
        } catch DecodingError.dataCorrupted {
            throw ParsingError.invalidDateFormat
        } catch {
            throw ParsingError.invalidJSON
        }
    }
    
    private struct IntervalsResponse: Codable {
        let id: String
        let start_date_local: Date
        let type: String
        let moving_time: Int
        let distance: Double?
        let icu_training_load: Double?
        let average_watts: Double?
        let weighted_average_watts: Double?
        let average_heartrate: Double?
        let max_heartrate: Double?
        let intensity: Double?
        let calories: Int?
    }
}

/// Data validation utilities
public struct DataValidator {
    
    /// Validate that a value is within expected range
    public static func isInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return value >= min && value <= max
    }
    
    /// Check if a collection of values has outliers
    /// Uses IQR (Interquartile Range) method
    public static func hasOutlier<T: BinaryFloatingPoint>(_ values: [T]) -> Bool {
        guard values.count >= 4 else { return false }
        
        let sorted = values.sorted()
        let q1Index = sorted.count / 4
        let q3Index = (sorted.count * 3) / 4
        
        let q1 = sorted[q1Index]
        let q3 = sorted[q3Index]
        let iqr = q3 - q1
        
        let lowerBound = q1 - (iqr * 1.5)
        let upperBound = q3 + (iqr * 1.5)
        
        return sorted.first! < lowerBound || sorted.last! > upperBound
    }
    
    /// Validate HRV value (typical range: 20-100ms)
    public static func isValidHRV(_ value: Double) -> Bool {
        return isInRange(value, min: 20, max: 100)
    }
    
    /// Validate RHR value (typical range: 30-120 bpm)
    public static func isValidRHR(_ value: Double) -> Bool {
        return isInRange(value, min: 30, max: 120)
    }
    
    /// Validate sleep duration (typical range: 0-16 hours)
    public static func isValidSleepDuration(_ seconds: Double) -> Bool {
        let hours = seconds / 3600.0
        return isInRange(hours, min: 0, max: 16)
    }
    
    /// Validate respiratory rate (typical range: 8-25 breaths/min)
    public static func isValidRespiratoryRate(_ value: Double) -> Bool {
        return isInRange(value, min: 8, max: 25)
    }
}

