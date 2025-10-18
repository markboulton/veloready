import SwiftUI
import Charts

/// Chart styling modifiers for refined, sophisticated data visualization
/// Based on analysis of Whoop and other premium health apps
///
/// Key Principles:
/// - Subtle grid lines (6% opacity)
/// - Smooth curves (.catmullRom interpolation)
/// - Minimal axes - only essential labels
/// - Single metric color per chart
/// - Thin strokes (1.5-2.5px)
/// - No shadows or elevation

// MARK: - Chart Style Modifiers

extension View {
    /// Apply refined chart styling with very subtle grids
    func refinedChartStyle() -> some View {
        self
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.chartGridLine)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(ColorPalette.chartGridLine)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorPalette.chartAxisLabel)
                }
            }
    }
    
    /// Apply minimal chart styling (no grid, no axes)
    func minimalChartStyle() -> some View {
        self
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
    }
}

// MARK: - Chart Mark Helpers (Use in Chart blocks)

/// Helper functions for creating refined chart marks
/// Use these inside Chart { } blocks
enum RefinedChartMarks {
    /// Create area mark with subtle gradient fill
    static func areaGradient(metricColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                metricColor.opacity(0.25),
                metricColor.opacity(0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Create line style with smooth curves
    static func lineStyle(width: CGFloat = 2.0) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

// MARK: - Recovery Gradient Bar

struct RecoveryGradientBar: View {
    let value: Double // 0-100
    let height: CGFloat = 6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(ColorPalette.backgroundTertiary)
                
                // Gradient fill
                LinearGradient(
                    colors: [
                        ColorPalette.recoveryPoor,
                        ColorPalette.recoveryLow,
                        ColorPalette.recoveryMedium,
                        ColorPalette.recoveryGood,
                        ColorPalette.recoveryExcellent
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Rectangle()
                        .frame(width: geometry.size.width * (value / 100))
                )
                
                // Current value indicator
                Circle()
                    .fill(ColorPalette.recoveryColor(for: value))
                    .frame(width: height * 1.5, height: height * 1.5)
                    .offset(x: geometry.size.width * (value / 100) - (height * 0.75))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Contextual Zone Background

struct ChartZoneBackground: View {
    let zones: [Zone]
    let yRange: ClosedRange<Double>
    
    struct Zone {
        let range: ClosedRange<Double>
        let color: Color
        let label: String?
        
        init(range: ClosedRange<Double>, color: Color, label: String? = nil) {
            self.range = range
            self.color = color
            self.label = label
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(zones.indices, id: \.self) { index in
                    let zone = zones[index]
                    let height = heightForZone(zone, in: geometry.size.height)
                    let yOffset = yOffsetForZone(zone, in: geometry.size.height)
                    
                    Rectangle()
                        .fill(zone.color.opacity(0.06))
                        .frame(height: height)
                        .offset(y: yOffset)
                    
                    if let label = zone.label {
                        Text(label.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(zone.color.opacity(0.3))
                            .offset(y: yOffset)
                    }
                }
            }
        }
    }
    
    private func heightForZone(_ zone: Zone, in totalHeight: CGFloat) -> CGFloat {
        let rangeSize = yRange.upperBound - yRange.lowerBound
        let zoneSize = zone.range.upperBound - zone.range.lowerBound
        return totalHeight * (zoneSize / rangeSize)
    }
    
    private func yOffsetForZone(_ zone: Zone, in totalHeight: CGFloat) -> CGFloat {
        let rangeSize = yRange.upperBound - yRange.lowerBound
        let zoneStart = zone.range.lowerBound - yRange.lowerBound
        return totalHeight * (zoneStart / rangeSize) - (totalHeight / 2)
    }
}

// MARK: - Usage Examples

/*
 
 REFINED AREA CHART:
 -------------------
 
 Chart {
     ForEach(data) { point in
         AreaMark(
             x: .value("Date", point.date),
             y: .value("HRV", point.hrv)
         )
         .foregroundStyle(RefinedChartMarks.areaGradient(metricColor: ColorPalette.hrvMetric))
         .interpolationMethod(.catmullRom)
         
         LineMark(
             x: .value("Date", point.date),
             y: .value("HRV", point.hrv)
         )
         .foregroundStyle(ColorPalette.hrvMetric)
         .lineStyle(RefinedChartMarks.lineStyle())
         .interpolationMethod(.catmullRom)
     }
 }
 .refinedChartStyle()
 .frame(height: 200)
 
 
 RECOVERY GRADIENT BAR:
 ----------------------
 
 VStack(alignment: .leading, spacing: 8) {
     Text("RECOVERY")
         .font(.system(size: 11, weight: .medium))
         .foregroundColor(ColorPalette.labelSecondary)
         .textCase(.uppercase)
     
     RecoveryGradientBar(value: recoveryScore)
         .frame(height: 6)
 }
 
 
 CHART WITH ZONE BACKGROUND:
 ---------------------------
 
 Chart {
     // Your marks
 }
 .chartBackground { proxy in
     ChartZoneBackground(
         zones: [
             .init(range: 0...30, color: ColorPalette.recoveryPoor, label: "Poor"),
             .init(range: 30...70, color: ColorPalette.recoveryMedium, label: "Medium"),
             .init(range: 70...100, color: ColorPalette.recoveryExcellent, label: "Excellent")
         ],
         yRange: 0...100
     )
 }
 .refinedChartStyle()
 
 */
