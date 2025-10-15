import Foundation

/// Centralized formatting utilities for activity-related data
/// Eliminates duplicate formatting code across the app
enum ActivityFormatters {
    
    // MARK: - Duration Formatting
    
    /// Format duration in seconds to "Xh Ym" or "Ym" format
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string like "2h 15m" or "45m"
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Format duration with seconds for detailed display
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string like "2:15:30" or "45:30"
    static func formatDurationDetailed(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Distance Formatting
    
    /// Format distance from meters to km or miles
    /// - Parameters:
    ///   - meters: Distance in meters
    ///   - useMetric: If true, returns km; if false, returns miles
    /// - Returns: Formatted string like "15.5 km" or "9.6 mi"
    static func formatDistance(_ meters: Double, useMetric: Bool = true) -> String {
        let km = meters / 1000.0
        
        if useMetric {
            return String(format: "%.1f km", km)
        } else {
            let miles = km * 0.621371
            return String(format: "%.1f mi", miles)
        }
    }
    
    /// Format distance with UserSettings preference
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string based on user's unit preference
    @MainActor
    static func formatDistance(_ meters: Double) -> String {
        let useMetric = UserSettings.shared.useMetricUnits
        return formatDistance(meters, useMetric: useMetric)
    }
    
    // MARK: - Speed Formatting
    
    /// Format speed from m/s to km/h or mph
    /// - Parameters:
    ///   - metersPerSecond: Speed in meters per second
    ///   - useMetric: If true, returns km/h; if false, returns mph
    /// - Returns: Formatted string like "25.5 km/h" or "15.8 mph"
    static func formatSpeed(_ metersPerSecond: Double, useMetric: Bool = true) -> String {
        if useMetric {
            let kmh = metersPerSecond * 3.6
            return String(format: "%.1f km/h", kmh)
        } else {
            let mph = metersPerSecond * 2.237
            return String(format: "%.1f mph", mph)
        }
    }
    
    /// Format speed with UserSettings preference
    /// - Parameter metersPerSecond: Speed in meters per second
    /// - Returns: Formatted string based on user's unit preference
    @MainActor
    static func formatSpeed(_ metersPerSecond: Double) -> String {
        let useMetric = UserSettings.shared.useMetricUnits
        return formatSpeed(metersPerSecond, useMetric: useMetric)
    }
    
    // MARK: - Power Formatting
    
    /// Format power in watts
    /// - Parameter watts: Power in watts
    /// - Returns: Formatted string like "250 W"
    static func formatPower(_ watts: Double) -> String {
        return String(format: "%.0f W", watts)
    }
    
    // MARK: - Heart Rate Formatting
    
    /// Format heart rate in beats per minute
    /// - Parameter bpm: Heart rate in beats per minute
    /// - Returns: Formatted string like "150 bpm"
    static func formatHeartRate(_ bpm: Double) -> String {
        return String(format: "%.0f bpm", bpm)
    }
    
    // MARK: - Intensity Formatting
    
    /// Format intensity factor
    /// - Parameter intensityFactor: Intensity factor (typically 0.0-1.5)
    /// - Returns: Formatted string like "0.85"
    static func formatIntensityFactor(_ intensityFactor: Double) -> String {
        return String(format: "%.2f", intensityFactor)
    }
    
    /// Format TSS (Training Stress Score)
    /// - Parameter tss: TSS value
    /// - Returns: Formatted string like "125"
    static func formatTSS(_ tss: Double) -> String {
        return String(format: "%.0f", tss)
    }
    
    // MARK: - Calories Formatting
    
    /// Format calories
    /// - Parameter calories: Calories burned
    /// - Returns: Formatted string like "450 cal"
    static func formatCalories(_ calories: Int) -> String {
        return "\(calories) cal"
    }
}
