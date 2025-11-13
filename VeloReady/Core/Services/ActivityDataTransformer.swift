import Foundation

/// Transforms Intervals.icu activity data into time-series data for charts
@MainActor
struct ActivityDataTransformer {
    /// Generate time-series data from activity summary
    /// - Parameter activity: The activity summary from Intervals.icu
    /// - Returns: Array of WorkoutSample data points
    static func generateSamples(from activity: Activity) -> [WorkoutSample] {
        Logger.debug("🔄 ========== ACTIVITY DATA TRANSFORMER: GENERATE SAMPLES ==========")
        Logger.debug("🔄 Activity: \(activity.name ?? "Unknown")")
        Logger.debug("🔄 Activity ID: \(activity.id)")
        Logger.debug("🔄 Activity Type: \(activity.type ?? "Unknown")")
        
        // Use duration if available, otherwise estimate from other metrics
        var duration = activity.duration ?? 0
        Logger.debug("🔄 Initial duration: \(duration)s")
        
        // If duration is 0 or nil, estimate based on distance and average speed
        if duration <= 0 {
            Logger.debug("🔄 Duration is 0 or nil, attempting to estimate...")
            if let distance = activity.distance, let avgSpeed = activity.averageSpeed, 
               distance > 0 && avgSpeed > 0 {
                // Estimate duration: distance (m) / speed (km/h) / 1000 * 3600 (seconds/hour)
                duration = (distance / 1000 / avgSpeed) * 3600
                Logger.debug("🔄 Estimated duration: \(duration)s from distance \(distance)m and speed \(avgSpeed)km/h")
            } else {
                // Default to a reasonable workout duration if we can't estimate
                duration = 3600 // 1 hour default
                Logger.debug("🔄 Using default duration: \(duration)s (no distance/speed available)")
                Logger.debug("🔄   - Distance: \(activity.distance ?? 0)m")
                Logger.debug("🔄   - Avg Speed: \(activity.averageSpeed ?? 0)km/h")
            }
        }
        
        guard duration > 0 else { 
            Logger.warning("️ Cannot generate samples: duration is still 0")
            Logger.debug("🔄 ================================================================")
            return [] 
        }
        
        // Sample every second
        let sampleInterval: TimeInterval = 1
        var samples: [WorkoutSample] = []
        
        // Get the ranges for each metric
        let powerRange = getMetricRange(avg: activity.averagePower)
        let hrRange = getMetricRange(avg: activity.averageHeartRate, max: activity.maxHeartRate)
        let speedRange = getMetricRange(avg: activity.averageSpeed, max: activity.maxSpeed)
        let cadenceRange = getMetricRange(avg: activity.averageCadence)
        let elevationRange = getElevationRange(gain: activity.elevationGain)
        
        Logger.debug("🔄 Metric Ranges for Generation:")
        Logger.debug("🔄   - Power: \(powerRange.min)-\(powerRange.max)W (avg: \(activity.averagePower ?? 0)W)")
        Logger.debug("🔄   - HR: \(hrRange.min)-\(hrRange.max)bpm (avg: \(activity.averageHeartRate ?? 0)bpm, max: \(activity.maxHeartRate ?? 0)bpm)")
        Logger.debug("🔄   - Speed: \(speedRange.min)-\(speedRange.max)km/h (avg: \(activity.averageSpeed ?? 0)km/h, max: \(activity.maxSpeed ?? 0)km/h)")
        Logger.debug("🔄   - Cadence: \(cadenceRange.min)-\(cadenceRange.max)rpm (avg: \(activity.averageCadence ?? 0)rpm)")
        Logger.debug("🔄   - Elevation: \(elevationRange.min)-\(elevationRange.max)m (gain: \(activity.elevationGain ?? 0)m)")
        
        // Generate samples
        for time in stride(from: 0, to: duration, by: sampleInterval) {
            // Create variations using multiple sine waves of different frequencies
            let powerVariation = generateVariation(time: time, range: powerRange)
            let hrVariation = generateVariation(time: time + 30, range: hrRange) // Lag HR behind power
            let speedVariation = generateVariation(time: time, range: speedRange)
            let cadenceVariation = generateVariation(time: time, range: cadenceRange)
            let elevationVariation = generateElevation(time: time, range: elevationRange)
            
            samples.append(WorkoutSample(
                time: time,
                power: powerVariation,
                heartRate: hrVariation,
                speed: speedVariation,
                cadence: cadenceVariation,
                elevation: elevationVariation,
                latitude: nil, // No GPS coordinates in simulated data
                longitude: nil
            ))
        }
        
        Logger.debug("🔄 Generated \(samples.count) samples for activity '\(activity.name ?? "Unknown")'")
        
        // Verify generated data quality
        let avgPower = samples.map { $0.power }.filter { $0 > 0 }.reduce(0, +) / Double(samples.count)
        let avgHR = samples.map { $0.heartRate }.filter { $0 > 0 }.reduce(0, +) / Double(samples.count)
        let avgSpeed = samples.map { $0.speed }.filter { $0 > 0 }.reduce(0, +) / Double(samples.count)
        
        Logger.debug("🔄 Generated Data Verification:")
        Logger.debug("🔄   - Avg Power: \(Int(avgPower))W (target: \(activity.averagePower ?? 0)W)")
        Logger.debug("🔄   - Avg HR: \(Int(avgHR))bpm (target: \(activity.averageHeartRate ?? 0)bpm)")
        Logger.debug("🔄   - Avg Speed: \(String(format: "%.1f", avgSpeed))km/h (target: \(activity.averageSpeed ?? 0)km/h)")
        Logger.debug("🔄 ================================================================")
        
        return samples
    }
    
    // MARK: - Helper Functions
    
    private static func getMetricRange(avg: Double?, max: Double? = nil) -> (min: Double, max: Double) {
        guard let average = avg else { return (0, 0) }
        
        if let maxValue = max {
            // Use actual max if available
            return (min(average * 0.7, maxValue * 0.7), maxValue)
        } else {
            // Estimate range based on average
            return (average * 0.7, average * 1.3)
        }
    }
    
    private static func getElevationRange(gain: Double?) -> (min: Double, max: Double) {
        guard let elevationGain = gain else { return (0, 0) }
        // Create a reasonable elevation profile based on total gain
        return (0, elevationGain)
    }
    
    private static func generateVariation(time: TimeInterval, range: (min: Double, max: Double)) -> Double {
        let amplitude = (range.max - range.min) / 2
        let offset = range.min + amplitude
        
        // Combine multiple sine waves for natural-looking variations
        let slowVariation = sin(time / 300) // 5-minute cycle
        let mediumVariation = sin(time / 60) * 0.3 // 1-minute cycle
        let fastVariation = sin(time / 15) * 0.1 // 15-second cycle
        
        let combined = (slowVariation + mediumVariation + fastVariation) / 1.4 // Normalize
        return offset + (amplitude * combined)
    }
    
    private static func generateElevation(time: TimeInterval, range: (min: Double, max: Double)) -> Double {
        let amplitude = (range.max - range.min) / 2
        let offset = range.min + amplitude
        
        // Create a smoother elevation profile with longer cycles
        let slowVariation = sin(time / 1200) // 20-minute cycle
        let mediumVariation = sin(time / 300) * 0.3 // 5-minute cycle
        
        let combined = (slowVariation + mediumVariation) / 1.3 // Normalize
        return offset + (amplitude * combined)
    }
}
