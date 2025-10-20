import Foundation

/// Content strings for Athlete Zones settings
enum AthleteZonesContent {
    // MARK: - Navigation
    static let title = "Adaptive Zones"  /// Navigation title
    
    // MARK: - Summary Section
    enum Summary {
        static let adaptiveFTP = "Adaptive FTP"  /// Adaptive FTP label
        static let maxHR = "Max HR"  /// Max HR label
        static let vo2Max = "VO2 Max"  /// VO2 Max label
        static let wPrime = "W'"  /// W' label
        static let proBadge = "PRO"  /// PRO badge text
    }
    
    // MARK: - Power Zones
    enum PowerZones {
        static let title = "Power Zones"  /// Power zones section title
        static let ftp = "FTP"  /// FTP label
        static let zone1 = "Active Recovery"  /// Zone 1 name
        static let zone2 = "Endurance"  /// Zone 2 name
        static let zone3 = "Tempo"  /// Zone 3 name
        static let zone4 = "Threshold"  /// Zone 4 name
        static let zone5 = "VO2 Max"  /// Zone 5 name
        static let zone6 = "Anaerobic"  /// Zone 6 name
        static let zone7 = "Neuromuscular"  /// Zone 7 name
    }
    
    // MARK: - Heart Rate Zones
    enum HRZones {
        static let title = "Heart Rate Zones"  /// HR zones section title
        static let maxHR = "Max HR"  /// Max HR label
        static let zone1 = "Recovery"  /// Zone 1 name
        static let zone2 = "Endurance"  /// Zone 2 name
        static let zone3 = "Tempo"  /// Zone 3 name
        static let zone4 = "Threshold"  /// Zone 4 name
        static let zone5 = "VO2 Max"  /// Zone 5 name
        static let zone6 = "Anaerobic"  /// Zone 6 name
        static let zone7 = "Max"  /// Zone 7 name
    }
    
    // MARK: - Source Labels
    enum Source {
        static let computed = "Computed"  /// Computed source
        static let manual = "Manual"  /// Manual source
        static let intervalsICU = "Intervals.icu"  /// Intervals.icu source
    }
    
    // MARK: - Actions
    static let edit = "Edit"  /// Edit button
    static let save = "Save"  /// Save button
    static let cancel = "Cancel"  /// Cancel button
    static let recompute = "Recompute Zones"  /// Recompute button
    static let recomputeMessage = "This will reset any manual overrides and recompute zones from your last 120 days of activities."  /// Recompute confirmation message
    
    // MARK: - Additional Metrics
    enum AdditionalMetrics {
        static let title = "Additional Metrics"  /// Section title
        static let vo2Max = "VO2 Max"  /// VO2 Max label
        static let wPrime = "W' (Anaerobic Capacity)"  /// W' label
        static let lactateThreshold = "Lactate Threshold"  /// LT label
    }
    
    // MARK: - Empty States
    static let noData = "No zone data available"  /// No data message
    static let computingZones = "Computing zones from your activities..."  /// Computing message
    
    // MARK: - TextField Placeholders
    static let ftpPlaceholder = "FTP"  /// FTP placeholder
    static let maxHRPlaceholder = "Max HR"  /// Max HR placeholder
}

