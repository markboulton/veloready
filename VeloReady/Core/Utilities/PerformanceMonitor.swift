import Foundation

/// Actor-based performance monitoring for tracking operation durations
/// Provides statistics for debugging and optimization
actor PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [String: [TimeInterval]] = [:]
    private let maxMeasurementsPerLabel = 100
    
    /// Measure the execution time of an async operation
    /// - Parameters:
    ///   - label: Descriptive label for the operation
    ///   - operation: The async operation to measure
    /// - Returns: The result of the operation
    func measure<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            Task { await recordMeasurement(label, duration: duration) }
            
            // Log if slow
            if duration > 1.0 {
                Logger.warning("🐌 SLOW: [\(label)] \(Int(duration * 1000))ms")
            } else {
                Logger.debug("⚡ [\(label)] \(Int(duration * 1000))ms")
            }
        }
        return try await operation()
    }
    
    /// Measure the execution time of a synchronous operation
    func measureSync<T>(_ label: String, operation: () throws -> T) rethrows -> T {
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            Task { await recordMeasurement(label, duration: duration) }
            
            if duration > 0.5 {
                Logger.warning("🐌 SLOW SYNC: [\(label)] \(Int(duration * 1000))ms")
            }
        }
        return try operation()
    }
    
    private func recordMeasurement(_ label: String, duration: TimeInterval) {
        if measurements[label] == nil {
            measurements[label] = []
        }
        measurements[label]?.append(duration)
        
        // Keep last N measurements to prevent memory growth
        if let count = measurements[label]?.count, count > maxMeasurementsPerLabel {
            measurements[label]?.removeFirst(count - maxMeasurementsPerLabel)
        }
    }
    
    /// Get performance statistics for a specific operation
    func getStatistics(for label: String) -> PerformanceStats? {
        guard let times = measurements[label], !times.isEmpty else { return nil }
        
        let sorted = times.sorted()
        let avg = times.reduce(0, +) / Double(times.count)
        let minValue = sorted.first!
        let maxValue = sorted.last!
        let p50 = sorted[sorted.count / 2]
        let p95Index = Swift.min(Int(Double(sorted.count) * 0.95), sorted.count - 1)
        let p99Index = Swift.min(Int(Double(sorted.count) * 0.99), sorted.count - 1)
        let p95 = sorted[p95Index]
        let p99 = sorted[p99Index]
        
        return PerformanceStats(
            label: label,
            count: times.count,
            average: avg,
            min: minValue,
            max: maxValue,
            median: p50,
            p95: p95,
            p99: p99
        )
    }
    
    /// Get all tracked operation labels
    func getAllLabels() -> [String] {
        Array(measurements.keys).sorted()
    }
    
    /// Print all performance statistics to console
    func printAllStatistics() {
        Logger.debug("📊 ========== PERFORMANCE STATISTICS ==========")
        for label in getAllLabels() {
            if let stats = getStatistics(for: label) {
                Logger.debug("📊 [\(label)]")
                Logger.debug("     Count: \(stats.count)")
                Logger.debug("     Avg: \(Int(stats.average * 1000))ms")
                Logger.debug("     Min: \(Int(stats.min * 1000))ms")
                Logger.debug("     Max: \(Int(stats.max * 1000))ms")
                Logger.debug("     P50: \(Int(stats.median * 1000))ms")
                Logger.debug("     P95: \(Int(stats.p95 * 1000))ms")
            }
        }
        Logger.debug("📊 =============================================")
    }
    
    /// Clear all recorded measurements
    func reset() {
        measurements.removeAll()
        Logger.debug("📊 Performance measurements reset")
    }
}

/// Performance statistics for an operation
struct PerformanceStats: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let average: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let median: TimeInterval
    let p95: TimeInterval
    let p99: TimeInterval
    
    var averageMs: Int { Int(average * 1000) }
    var minMs: Int { Int(min * 1000) }
    var maxMs: Int { Int(max * 1000) }
    var medianMs: Int { Int(median * 1000) }
    var p95Ms: Int { Int(p95 * 1000) }
    var p99Ms: Int { Int(p99 * 1000) }
}
