import Foundation

/// Zone calculation utilities for power and heart rate
public struct ZoneCalculations {
    
    // MARK: - Power Zones (Coggan Model)
    
    /// Calculate Coggan power zones from FTP
    /// Returns zone boundaries: [Z1/Z2, Z2/Z3, Z3/Z4, Z4/Z5, Z5/Z6]
    /// 
    /// Zones:
    /// - Z1 (Active Recovery): < 55% FTP
    /// - Z2 (Endurance): 56-75% FTP
    /// - Z3 (Tempo): 76-90% FTP
    /// - Z4 (Lactate Threshold): 91-105% FTP
    /// - Z5 (VO2max): 106-120% FTP
    /// - Z6 (Anaerobic Capacity): 121-150% FTP
    /// - Z7 (Neuromuscular Power): > 150% FTP
    public static func calculatePowerZones(ftp: Double) -> [Double] {
        guard isValidFTP(ftp) else { return [] }
        
        return [
            ftp * 0.55,  // Z1 upper bound (Active Recovery)
            ftp * 0.75,  // Z2 upper bound (Endurance)
            ftp * 0.90,  // Z3 upper bound (Tempo)
            ftp * 1.05,  // Z4 upper bound (Threshold)
            ftp * 1.20,  // Z5 upper bound (VO2max)
            ftp * 1.50   // Z6 upper bound (Anaerobic)
            // Z7 (Neuromuscular) is > 1.50 * FTP
        ]
    }
    
    /// Determine power zone for a given wattage
    /// Returns zone number (1-7) or 0 if invalid
    public static func determinePowerZone(watts: Double, ftp: Double) -> Int {
        guard isValidFTP(ftp) && watts >= 0 else { return 0 }
        
        let percentage = watts / ftp
        
        if percentage < 0.55 { return 1 }
        if percentage < 0.75 { return 2 }
        if percentage < 0.90 { return 3 }
        if percentage < 1.05 { return 4 }
        if percentage < 1.20 { return 5 }
        if percentage < 1.50 { return 6 }
        return 7
    }
    
    // MARK: - Heart Rate Zones
    
    /// Calculate heart rate zones from max HR
    /// Returns zone boundaries: [Z1/Z2, Z2/Z3, Z3/Z4, Z4/Z5, Z5/Z6]
    ///
    /// Zones (5-zone model):
    /// - Z1 (Recovery): < 60% max HR
    /// - Z2 (Aerobic): 60-70% max HR
    /// - Z3 (Tempo): 70-80% max HR
    /// - Z4 (Threshold): 80-90% max HR
    /// - Z5 (Maximum): 90-100% max HR
    public static func calculateHRZones(maxHR: Double) -> [Double] {
        guard isValidMaxHR(maxHR) else { return [] }
        
        return [
            maxHR * 0.60,  // Z1 upper bound
            maxHR * 0.70,  // Z2 upper bound
            maxHR * 0.80,  // Z3 upper bound
            maxHR * 0.90   // Z4 upper bound
            // Z5 upper bound is maxHR
        ]
    }
    
    /// Determine heart rate zone for a given HR
    /// Returns zone number (1-5) or 0 if invalid
    public static func determineHRZone(hr: Double, maxHR: Double) -> Int {
        guard isValidMaxHR(maxHR) && hr >= 0 else { return 0 }
        
        let percentage = hr / maxHR
        
        if percentage < 0.60 { return 1 }
        if percentage < 0.70 { return 2 }
        if percentage < 0.80 { return 3 }
        if percentage < 0.90 { return 4 }
        return 5
    }
    
    // MARK: - LTHR-Based Heart Rate Zones
    
    /// Calculate heart rate zones from Lactate Threshold Heart Rate (LTHR)
    /// Returns zone boundaries: [Z1/Z2, Z2/Z3, Z3/Z4, Z4/Z5]
    ///
    /// This is an alternative to max HR zones, often more accurate
    /// - Z1 (Recovery): < 85% LTHR
    /// - Z2 (Aerobic): 85-89% LTHR
    /// - Z3 (Tempo): 90-94% LTHR
    /// - Z4 (Threshold): 95-99% LTHR
    /// - Z5 (Maximum): > 100% LTHR
    public static func calculateHRZonesFromLTHR(lthr: Double) -> [Double] {
        guard isValidLTHR(lthr) else { return [] }
        
        return [
            lthr * 0.85,  // Z1 upper bound
            lthr * 0.89,  // Z2 upper bound
            lthr * 0.94,  // Z3 upper bound
            lthr * 0.99   // Z4 upper bound
            // Z5 is > LTHR
        ]
    }
    
    // MARK: - Validation
    
    /// Validate FTP is within reasonable range
    /// Typical range: 50-500W (covering beginner to world-class)
    public static func isValidFTP(_ ftp: Double) -> Bool {
        return ftp > 0 && ftp < 500
    }
    
    /// Validate max HR is within reasonable range
    /// Typical range: 120-220 bpm
    public static func isValidMaxHR(_ maxHR: Double) -> Bool {
        return maxHR >= 120 && maxHR <= 220
    }
    
    /// Validate LTHR is within reasonable range
    /// Typical range: 100-200 bpm
    public static func isValidLTHR(_ lthr: Double) -> Bool {
        return lthr >= 100 && lthr <= 200
    }
    
    // MARK: - FTP Estimation
    
    /// Estimate FTP from a 20-minute power test
    /// Standard protocol: FTP ≈ 95% of 20-min average power
    public static func estimateFTPFrom20MinTest(averagePower: Double) -> Double {
        return averagePower * 0.95
    }
    
    /// Estimate FTP from a 60-minute power test (most accurate)
    public static func estimateFTPFrom60MinTest(averagePower: Double) -> Double {
        return averagePower
    }
    
    /// Estimate max HR from age (220 - age formula)
    /// Note: This is a rough estimate, actual testing is more accurate
    public static func estimateMaxHRFromAge(age: Int) -> Double {
        return 220.0 - Double(age)
    }
}

