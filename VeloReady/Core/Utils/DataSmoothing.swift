import Foundation

/// Utility for smoothing and downsampling workout data
struct DataSmoothing {
    
    /// Douglas-Peucker algorithm for line simplification
    /// Reduces number of points while preserving shape
    static func douglasPeucker<T>(
        points: [T],
        epsilon: Double,
        getValue: (T) -> (x: Double, y: Double)
    ) -> [T] {
        guard points.count > 2 else { return points }
        
        // Find the point with maximum distance from line segment
        var maxDistance = 0.0
        var maxIndex = 0
        let start = getValue(points.first!)
        let end = getValue(points.last!)
        
        for i in 1..<(points.count - 1) {
            let point = getValue(points[i])
            let distance = perpendicularDistance(
                point: point,
                lineStart: start,
                lineEnd: end
            )
            
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // If max distance is greater than epsilon, recursively simplify
        if maxDistance > epsilon {
            // Recursive call on both segments
            let left = douglasPeucker(
                points: Array(points[0...maxIndex]),
                epsilon: epsilon,
                getValue: getValue
            )
            let right = douglasPeucker(
                points: Array(points[maxIndex..<points.count]),
                epsilon: epsilon,
                getValue: getValue
            )
            
            // Combine results (remove duplicate middle point)
            return left.dropLast() + right
        } else {
            // All points between start and end can be removed
            return [points.first!, points.last!]
        }
    }
    
    /// Calculate perpendicular distance from point to line segment
    private static func perpendicularDistance(
        point: (x: Double, y: Double),
        lineStart: (x: Double, y: Double),
        lineEnd: (x: Double, y: Double)
    ) -> Double {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        // Handle vertical/horizontal lines
        let magnitude = sqrt(dx * dx + dy * dy)
        if magnitude < 0.0001 {
            let pdx = point.x - lineStart.x
            let pdy = point.y - lineStart.y
            return sqrt(pdx * pdx + pdy * pdy)
        }
        
        // Calculate perpendicular distance
        let numerator = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        return numerator / magnitude
    }
    
    /// Downsample workout samples using Douglas-Peucker
    /// - Parameters:
    ///   - samples: Original workout samples
    ///   - metric: Which metric to optimize for (power, hr, speed, etc)
    ///   - targetPoints: Approximate target number of points (default 500)
    /// - Returns: Downsampled array
    static func downsampleWorkoutSamples(
        _ samples: [WorkoutSample],
        optimizeFor metric: WorkoutMetric = .heartRate,
        targetPoints: Int = 500
    ) -> [WorkoutSample] {
        guard samples.count > targetPoints else { return samples }
        
        // Calculate epsilon based on data range and target reduction
        let values = samples.map { metric.getValue($0) }.filter { $0 > 0 }
        guard !values.isEmpty else { return samples }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let range = maxValue - minValue
        
        // Start with 0.75% epsilon for balanced simplification
        let epsilon = range * 0.0075
        var result = samples
        
        // Iteratively increase epsilon until we hit target (smaller steps)
        for multiplier in [1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0] {
            result = douglasPeucker(
                points: samples,
                epsilon: epsilon * multiplier,
                getValue: { sample in
                    (x: sample.time, y: metric.getValue(sample))
                }
            )
            
            if result.count <= targetPoints {
                break
            }
        }
        
        print("📉 Downsampled \(samples.count) → \(result.count) points (target: \(targetPoints))")
        return result
    }
    
    /// Downsample heart rate samples for walking/strength workouts
    static func downsampleHeartRateSamples(
        _ samples: [(time: TimeInterval, heartRate: Double)],
        targetPoints: Int = 500
    ) -> [(time: TimeInterval, heartRate: Double)] {
        guard samples.count > targetPoints else { return samples }
        
        let values = samples.map { $0.heartRate }
        let minValue = values.min() ?? 60
        let maxValue = values.max() ?? 180
        let range = maxValue - minValue
        
        // 0.75% epsilon for balanced simplification
        let epsilon = range * 0.0075
        var result = samples
        
        for multiplier in [1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0] {
            result = douglasPeucker(
                points: samples,
                epsilon: epsilon * multiplier,
                getValue: { sample in
                    (x: sample.time, y: sample.heartRate)
                }
            )
            
            if result.count <= targetPoints {
                break
            }
        }
        
        print("📉 Downsampled HR: \(samples.count) → \(result.count) points")
        return result
    }
}

// MARK: - Workout Metric Enum

enum WorkoutMetric {
    case power
    case heartRate
    case speed
    case cadence
    case elevation
    
    func getValue(_ sample: WorkoutSample) -> Double {
        switch self {
        case .power: return sample.power
        case .heartRate: return sample.heartRate
        case .speed: return sample.speed
        case .cadence: return sample.cadence
        case .elevation: return sample.elevation
        }
    }
}
