import SwiftUI
import Charts

// MARK: - Data Models

struct WorkoutSample: Identifiable, Equatable, Codable {
    let id = UUID()
    let time: TimeInterval // seconds since ride start
    let power: Double
    let heartRate: Double
    let speed: Double // km/h
    let cadence: Double
    let elevation: Double // meters
    let latitude: Double?
    let longitude: Double?
    
    static func == (lhs: WorkoutSample, rhs: WorkoutSample) -> Bool {
        lhs.id == rhs.id
    }
    
    init(time: TimeInterval, power: Double, heartRate: Double, speed: Double, cadence: Double, elevation: Double, latitude: Double? = nil, longitude: Double? = nil) {
        self.time = time
        self.power = power
        self.heartRate = heartRate
        self.speed = speed
        self.cadence = cadence
        self.elevation = elevation
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ZoneDefinition {
    let lowerBound: Double
    let upperBound: Double
    let color: Color
    let name: String
}

struct MetricSummary {
    let average: Double
    let max: Double
    let unit: String
}

// MARK: - Zone Definitions

struct WorkoutZones {
    static let powerZones: [ZoneDefinition] = [
        ZoneDefinition(lowerBound: 0, upperBound: 0.55, color: ColorScale.greenAccent, name: "Z1"),
        ZoneDefinition(lowerBound: 0.55, upperBound: 0.75, color: ColorScale.blueAccent, name: "Z2"),
        ZoneDefinition(lowerBound: 0.75, upperBound: 0.90, color: ColorScale.yellowAccent, name: "Z3"),
        ZoneDefinition(lowerBound: 0.90, upperBound: 1.05, color: ColorScale.amberAccent, name: "Z4"),
        ZoneDefinition(lowerBound: 1.05, upperBound: 1.50, color: ColorScale.redAccent, name: "Z5")
    ]
    
    static let heartRateZones: [ZoneDefinition] = [
        ZoneDefinition(lowerBound: 0, upperBound: 0.60, color: ColorScale.greenAccent, name: "Z1"),
        ZoneDefinition(lowerBound: 0.60, upperBound: 0.72, color: ColorScale.blueAccent, name: "Z2"),
        ZoneDefinition(lowerBound: 0.72, upperBound: 0.82, color: ColorScale.yellowAccent, name: "Z3"),
        ZoneDefinition(lowerBound: 0.82, upperBound: 0.92, color: ColorScale.amberAccent, name: "Z4"),
        ZoneDefinition(lowerBound: 0.92, upperBound: 1.10, color: ColorScale.redAccent, name: "Z5")
    ]
}

// MARK: - Chart Styling

struct ChartStyle {
    static let chartHeight: CGFloat = 160
    static let chartCornerRadius: CGFloat = 0
    static let chartStrokeWidth: CGFloat = 1
    static let chartPadding: CGFloat = 32  // Reduced from 64 for tighter spacing
    
    static let backgroundColor = Color.background.primary
    static let foregroundColor = Color.text.primary
    static let gridColor = ColorPalette.neutral200
    static let axisColor = ColorPalette.neutral400
    
    static let powerColor = Color.workout.power
    static let heartRateColor = Color.workout.heartRate
    static let speedColor = Color.workout.speed
    static let cadenceColor = Color.workout.cadence
    static let elevationColor = Color.workout.elevation
}

// MARK: - Main View

@MainActor
struct WorkoutDetailCharts: View {
    let samples: [WorkoutSample]
    let ftp: Double? // Functional Threshold Power
    let maxHR: Double? // Maximum Heart Rate
    
    // Helper to check if metric has meaningful data (at least 5% of samples must be non-zero)
    private func hasData(_ getValue: (WorkoutSample) -> Double, metricName: String = "Unknown") -> Bool {
        guard !samples.isEmpty else {
            return false
        }
        
        let values = samples.map(getValue).filter { $0 > 0 }
        let percentage = Double(values.count) / Double(samples.count)
        let hasEnoughData = percentage >= 0.05
        
        // Require at least 5% of samples to have data to avoid showing charts with all zeros
        return hasEnoughData
    }
    
    var body: some View {
        let _ = print("📊 ========== WORKOUT DETAIL CHARTS: RENDERING ==========")
        let _ = print("📊 Total samples: \(samples.count)")
        let _ = print("📊 FTP: \(ftp ?? 0)W")
        let _ = print("📊 Max HR: \(maxHR ?? 0)bpm")
        
        return VStack(spacing: Spacing.xs) {
            // Power Chart - only show if we have meaningful data
            if !samples.isEmpty && hasData({ $0.power }, metricName: "Power") {
                let validPower = samples.map(\.power).filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
                let avgPower = validPower.isEmpty ? 0 : validPower.reduce(0, +) / Double(validPower.count)
                let maxPower = validPower.max() ?? 0
                
                let _ = print("📊 [Power] Rendering chart - Avg: \(Int(avgPower))W, Max: \(Int(maxPower))W")
                
                MetricChartView(
                    title: "Power",
                    samples: samples,
                    getValue: { $0.power },
                    color: ChartStyle.powerColor,
                    zones: WorkoutZones.powerZones,
                    maxReference: ftp,
                    summary: MetricSummary(
                        average: avgPower.isNaN || avgPower.isInfinite ? 0 : avgPower,
                        max: maxPower.isNaN || maxPower.isInfinite ? 0 : maxPower,
                        unit: "W"
                    ),
                    useDynamicYAxis: true
                )
            }
            
            // Heart Rate Chart - only show if we have meaningful data
            if !samples.isEmpty && hasData({ $0.heartRate }, metricName: "Heart Rate") {
                let validHR = samples.map(\.heartRate).filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
                let avgHR = validHR.isEmpty ? 0 : validHR.reduce(0, +) / Double(validHR.count)
                let maxHRValue = validHR.max() ?? 0
                
                let _ = print("📊 [Heart Rate] Rendering chart - Avg: \(Int(avgHR))bpm, Max: \(Int(maxHRValue))bpm")
                
                MetricChartView(
                    title: "Heart Rate",
                    samples: samples,
                    getValue: { $0.heartRate },
                    color: ChartStyle.heartRateColor,
                    zones: WorkoutZones.heartRateZones,
                    maxReference: maxHR,
                    summary: MetricSummary(
                        average: avgHR.isNaN || avgHR.isInfinite ? 0 : avgHR,
                        max: maxHRValue.isNaN || maxHRValue.isInfinite ? 0 : maxHRValue,
                        unit: "bpm"
                    ),
                    useDynamicYAxis: true
                )
            }
            
            // Speed Chart - only show if we have meaningful data
            if !samples.isEmpty && hasData({ $0.speed }, metricName: "Speed") {
                let validSpeed = samples.map(\.speed).filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
                let avgSpeed = validSpeed.isEmpty ? 0 : validSpeed.reduce(0, +) / Double(validSpeed.count)
                let maxSpeed = validSpeed.max() ?? 0
                
                // Convert to user's preferred units
                let userSettings = UserSettings.shared
                let (displayAvg, displayMax, speedUnit) = userSettings.useMetricUnits
                    ? (avgSpeed, maxSpeed, "km/h")
                    : (avgSpeed * 0.621371, maxSpeed * 0.621371, "mph") // km/h to mph
                
                let _ = print("📊 [Speed] Rendering chart - Avg: \(String(format: "%.1f", displayAvg))\(speedUnit), Max: \(String(format: "%.1f", displayMax))\(speedUnit)")
                
                MetricChartView(
                    title: "Speed",
                    samples: samples,
                    getValue: { userSettings.useMetricUnits ? $0.speed : $0.speed * 0.621371 },
                    color: ChartStyle.speedColor,
                    summary: MetricSummary(
                        average: displayAvg.isNaN || displayAvg.isInfinite ? 0 : displayAvg,
                        max: displayMax.isNaN || displayMax.isInfinite ? 0 : displayMax,
                        unit: speedUnit
                    ),
                    useDynamicYAxis: true
                )
            }
            
            // Cadence Chart - only show if we have meaningful data
            if !samples.isEmpty && hasData({ $0.cadence }, metricName: "Cadence") {
                let validCadence = samples.map(\.cadence).filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
                let avgCadence = validCadence.isEmpty ? 0 : validCadence.reduce(0, +) / Double(validCadence.count)
                let maxCadence = validCadence.max() ?? 0
                
                let _ = print("📊 [Cadence] Rendering chart - Avg: \(Int(avgCadence))rpm, Max: \(Int(maxCadence))rpm")
                
                MetricChartView(
                    title: "Cadence",
                    samples: samples,
                    getValue: { $0.cadence },
                    color: ChartStyle.cadenceColor,
                    summary: MetricSummary(
                        average: avgCadence.isNaN || avgCadence.isInfinite ? 0 : avgCadence,
                        max: maxCadence.isNaN || maxCadence.isInfinite ? 0 : maxCadence,
                        unit: "rpm"
                    ),
                    useDynamicYAxis: true
                )
            }
            
            // Elevation Chart - only show if we have meaningful data (hide for indoor/virtual rides)
            if !samples.isEmpty && hasData({ $0.elevation }, metricName: "Elevation") {
                let validElevation = samples.map(\.elevation).filter { !$0.isNaN && !$0.isInfinite }
                let avgElevation = validElevation.isEmpty ? 0 : validElevation.reduce(0, +) / Double(validElevation.count)
                let maxElevation = validElevation.max() ?? 0
                
                // Convert to user's preferred units
                let userSettings = UserSettings.shared
                let (displayAvg, displayMax, elevUnit) = userSettings.useMetricUnits
                    ? (avgElevation, maxElevation, "m")
                    : (avgElevation * 3.28084, maxElevation * 3.28084, "ft") // meters to feet
                
                let _ = print("📊 [Elevation] Rendering chart - Avg: \(Int(displayAvg))\(elevUnit), Max: \(Int(displayMax))\(elevUnit)")
                
                ElevationChartView(
                    title: "Elevation",
                    samples: samples,
                    color: ChartStyle.elevationColor,
                    summary: MetricSummary(
                        average: displayAvg.isNaN || displayAvg.isInfinite ? 0 : displayAvg,
                        max: displayMax.isNaN || displayMax.isInfinite ? 0 : displayMax,
                        unit: elevUnit
                    ),
                    useMetricUnits: userSettings.useMetricUnits
                )
            }
            
            let _ = print("📊 ================================================================")
        }
    }
}

// MARK: - Chart Components

@MainActor
struct MetricChartView: View {
    let title: String
    let samples: [WorkoutSample]
    let getValue: (WorkoutSample) -> Double
    let color: Color
    var zones: [ZoneDefinition]? = nil
    var maxReference: Double? = nil
    let summary: MetricSummary
    var useDynamicYAxis: Bool = false
    var useBlendedStyle: Bool = true  // Use .blended style (app background) instead of .standard (white)
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Downsample data for performance if needed - cached to avoid recomputation
    private var displaySamples: [WorkoutSample] {
        guard samples.count > 500 else { return samples }
        
        // Downsample to ~500 points for performance
        let step = samples.count / 500
        return Swift.stride(from: 0, to: samples.count, by: max(step, 1)).map { samples[$0] }
    }
    
    var body: some View {
        ChartCard(
            title: title,
            cardStyle: useBlendedStyle ? .blended : .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Summary
                summaryText
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chart
                chartContent
                    .frame(height: 200)
            }
        }
    }
    
    // Computed properties for dynamic y-axis
    private var yAxisRange: ClosedRange<Double> {
        if useDynamicYAxis && !samples.isEmpty {
            let values = samples.map(getValue).filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
            guard !values.isEmpty else { return 0...100 }
            
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 100
            
            // Add 10% padding above and below
            let range = maxValue - minValue
            let padding = max(range * 0.15, 5.0) // 15% padding, at least 5 units
            
            let lowerBound = max(0, minValue - padding)
            let upperBound = maxValue + padding
            
            return lowerBound...upperBound
        }
        return 0...1000 // Safe default range for auto-scaling
    }
    
    @ViewBuilder
    private var chartContent: some View {
        Chart {
            // Main metric line - no animation for performance
            ForEach(displaySamples) { sample in
                let value = getValue(sample)
                
                // Only render if value is valid
                if !value.isNaN && !value.isInfinite && value >= 0 {
                    LineMark(
                        x: .value("Time", sample.time),
                        y: .value(title, value)
                    )
                }
            }
            .foregroundStyle(color.opacity(0.7))
            .lineStyle(StrokeStyle(lineWidth: ChartStyle.chartStrokeWidth))
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: timeStride())) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(ColorPalette.neutral300)
                AxisTick()
                    .foregroundStyle(ColorPalette.neutral300)
                AxisValueLabel {
                    if let timeValue = value.as(Double.self) {
                        Text(formatTime(timeValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .foregroundStyle(ColorPalette.neutral300)
                AxisTick()
                    .foregroundStyle(ColorPalette.neutral300)
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                    } else if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXScale(domain: (samples.first?.time ?? 0)...(samples.last?.time ?? 0))
        .chartYScale(domain: yAxisRange)
        .chartBackground { _ in
            Color.clear
        }
        .clipped()
    }
    
    private var summaryText: some View {
        HStack(spacing: Spacing.xs) {
            Text("\(ChartContent.Summary.avg) \(safeInt(summary.average))\(summary.unit)")
            Text("\(ChartContent.Summary.max) \(safeInt(summary.max))\(summary.unit)")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private func safeInt(_ value: Double) -> String {
        if value.isNaN || value.isInfinite {
            return "0"
        }
        let rounded = value.rounded()
        // Clamp to Int range to prevent crash
        let clamped = max(Double(Int.min), min(Double(Int.max), rounded))
        return "\(Int(clamped))"
    }
    
    // Calculate appropriate time stride for x-axis
    private func timeStride() -> Double {
        guard let duration = samples.last?.time else { return 300 }
        
        // Choose stride based on total duration
        if duration <= 600 { return 120 }      // ≤10 min: every 2 min
        if duration <= 1800 { return 300 }     // ≤30 min: every 5 min
        if duration <= 3600 { return 600 }     // ≤1 hour: every 10 min
        if duration <= 7200 { return 1200 }    // ≤2 hours: every 20 min
        return 1800                             // >2 hours: every 30 min
    }
    
    // Helper function to format time from seconds to MM:SS
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        
        // For rides under 60 minutes, show M:SS format
        if minutes < 60 {
            return String(format: "%d:%02d", minutes, secs)
        }
        // For longer rides, show H:MM format
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}

@MainActor
struct ElevationChartView: View {
    let title: String
    let samples: [WorkoutSample]
    let color: Color
    let summary: MetricSummary
    var useMetricUnits: Bool = true
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Downsample data for performance if needed
    private var displaySamples: [WorkoutSample] {
        guard samples.count > 500 else { return samples }
        
        // Downsample to ~500 points for performance
        let step = samples.count / 500
        return Swift.stride(from: 0, to: samples.count, by: max(step, 1)).map { samples[$0] }
    }
    
    // Computed properties for dynamic y-axis
    private var yAxisRange: ClosedRange<Double> {
        guard !samples.isEmpty else { return 0...100 }
        
        let values = samples.map(\.elevation).filter { !$0.isNaN && !$0.isInfinite }
        guard !values.isEmpty else { return 0...100 }
        
        var minValue = values.min() ?? 0
        var maxValue = values.max() ?? 100
        
        // Convert to imperial if needed
        if !useMetricUnits {
            minValue *= 3.28084
            maxValue *= 3.28084
        }
        
        // Add 15% padding above and below to prevent clipping
        let range = maxValue - minValue
        let padding = max(range * 0.15, useMetricUnits ? 10.0 : 32.8) // At least 10m or 32.8ft padding
        
        // Ensure lower bound doesn't go below 0, but add padding
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding
        
        return lowerBound...upperBound
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header with icon
            HStack {
                Image(systemName: Icons.Training.elevation)
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                summaryText
            }
            
            // Chart
            chartContent
                .frame(height: 200)
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        Chart {
            // Filled area - no animation for performance
            ForEach(displaySamples) { sample in
                let elevValue = useMetricUnits ? sample.elevation : sample.elevation * 3.28084
                if !elevValue.isNaN && !elevValue.isInfinite {
                    AreaMark(
                        x: .value("Time", sample.time),
                        yStart: .value("Base", yAxisRange.lowerBound),
                        yEnd: .value("Elevation", elevValue)
                    )
                }
            }
            .foregroundStyle(color)
            
            // Line on top
            ForEach(displaySamples) { sample in
                let elevValue = useMetricUnits ? sample.elevation : sample.elevation * 3.28084
                if !elevValue.isNaN && !elevValue.isInfinite {
                    LineMark(
                        x: .value("Time", sample.time),
                        y: .value("Elevation", elevValue)
                    )
                }
            }
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: ChartStyle.chartStrokeWidth))
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: timeStride())) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(ColorPalette.neutral300)
                AxisTick()
                AxisValueLabel {
                    if let timeValue = value.as(Double.self) {
                        Text(formatTime(timeValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .foregroundStyle(ColorPalette.neutral300)
                AxisTick()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                    } else if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXScale(domain: (samples.first?.time ?? 0)...(samples.last?.time ?? 0))
        .chartYScale(domain: yAxisRange)
        .chartBackground { _ in
            Color.clear
        }
    }
    
    private var summaryText: some View {
        HStack(spacing: Spacing.xs) {
            Text("\(ChartContent.Summary.avg) \(safeInt(summary.average))\(summary.unit)")
            Text("\(ChartContent.Summary.max) \(safeInt(summary.max))\(summary.unit)")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private func safeInt(_ value: Double) -> String {
        if value.isNaN || value.isInfinite {
            return "0"
        }
        let rounded = value.rounded()
        // Clamp to Int range to prevent crash
        let clamped = max(Double(Int.min), min(Double(Int.max), rounded))
        return "\(Int(clamped))"
    }
    
    // Calculate appropriate time stride for x-axis
    private func timeStride() -> Double {
        guard let duration = samples.last?.time else { return 300 }
        
        // Choose stride based on total duration
        if duration <= 600 { return 120 }      // ≤10 min: every 2 min
        if duration <= 1800 { return 300 }     // ≤30 min: every 5 min
        if duration <= 3600 { return 600 }     // ≤1 hour: every 10 min
        if duration <= 7200 { return 1200 }    // ≤2 hours: every 20 min
        return 1800                             // >2 hours: every 30 min
    }
    
    // Helper function to format time from seconds to MM:SS
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        
        // For rides under 60 minutes, show M:SS format
        if minutes < 60 {
            return String(format: "%d:%02d", minutes, secs)
        }
        // For longer rides, show H:MM format
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}

// MARK: - Preview

#Preview {
    let activity = Activity(
        id: "1",
        name: "2 x 10 min Threshold Intervals",
        description: "Threshold intervals with recovery",
        startDateLocal: "2025-10-03T18:30:00",
        type: "cycling",
        duration: 2400, // 40 minutes
        distance: 15.2,
        elevationGain: 180,
        averagePower: 280,
        normalizedPower: 290,
        averageHeartRate: 165,
        maxHeartRate: 175,
        averageCadence: 95,
        averageSpeed: 25.5,
        maxSpeed: 35.2,
        calories: 450,
        fileType: "fit",
        tss: 85.0,
        intensityFactor: 0.85,
        atl: 75.0,
        ctl: 85.0,
        icuZoneTimes: [180, 1200, 720, 360, 120, 0, 0], // Power zones in seconds
        icuHrZoneTimes: [300, 1080, 720, 360, 60, 0, 0] // HR zones in seconds
    )
    
    return WorkoutDetailCharts(
        samples: ActivityDataTransformer.generateSamples(from: activity),
        ftp: 280,
        maxHR: activity.maxHeartRate
    )
    .preferredColorScheme(.dark)
}

// MARK: - Conditional Y-Axis Modifier

struct ConditionalYAxisModifier: ViewModifier {
    let useDynamicYAxis: Bool
    let yAxisRange: ClosedRange<Double>
    
    func body(content: Content) -> some View {
        if useDynamicYAxis {
            content.chartYScale(domain: yAxisRange)
        } else {
            content
        }
    }
}
