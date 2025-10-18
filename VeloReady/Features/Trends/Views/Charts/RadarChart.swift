import SwiftUI

/// Radar/Spider chart for multi-dimensional data visualization
/// Perfect for showing wellness foundation across multiple pillars
struct RadarChart: View {
    let dataPoints: [RadarDataPoint]
    let maxValue: Double
    let fillColor: Color
    let strokeColor: Color
    
    struct RadarDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let icon: String?
    }
    
    init(
        dataPoints: [RadarDataPoint],
        maxValue: Double = 100,
        fillColor: Color = .health.hrv.opacity(0.3),
        strokeColor: Color = .health.hrv
    ) {
        self.dataPoints = dataPoints
        self.maxValue = maxValue
        self.fillColor = fillColor
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.7
            
            ZStack {
                // Background grid circles
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    Circle()
                        .stroke(Color.text.tertiary.opacity(0.2), lineWidth: 1)
                        .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                }
                
                // Axis lines
                ForEach(0..<dataPoints.count, id: \.self) { index in
                    let angle = angleForIndex(index)
                    let endPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.text.tertiary.opacity(0.3), lineWidth: 1)
                }
                
                // Data polygon fill
                Path { path in
                    let points = dataPoints.enumerated().map { index, point in
                        let angle = angleForIndex(index)
                        let normalizedValue = point.value / maxValue
                        let pointRadius = radius * normalizedValue
                        return pointOnCircle(center: center, radius: pointRadius, angle: angle)
                    }
                    
                    if let first = points.first {
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.closeSubpath()
                    }
                }
                .fill(fillColor)
                
                // Data polygon stroke
                Path { path in
                    let points = dataPoints.enumerated().map { index, point in
                        let angle = angleForIndex(index)
                        let normalizedValue = point.value / maxValue
                        let pointRadius = radius * normalizedValue
                        return pointOnCircle(center: center, radius: pointRadius, angle: angle)
                    }
                    
                    if let first = points.first {
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.closeSubpath()
                    }
                }
                .stroke(strokeColor, lineWidth: 2)
                
                // Data point dots
                ForEach(0..<dataPoints.count, id: \.self) { index in
                    let point = dataPoints[index]
                    let angle = angleForIndex(index)
                    let normalizedValue = point.value / maxValue
                    let pointRadius = radius * normalizedValue
                    let position = pointOnCircle(center: center, radius: pointRadius, angle: angle)
                    
                    Circle()
                        .fill(strokeColor)
                        .frame(width: 6, height: 6)
                        .position(position)
                }
                
                // Labels
                ForEach(0..<dataPoints.count, id: \.self) { index in
                    let point = dataPoints[index]
                    let angle = angleForIndex(index)
                    let labelRadius = radius * 1.2
                    let labelPosition = pointOnCircle(center: center, radius: labelRadius, angle: angle)
                    
                    VStack(spacing: 2) {
                        if let icon = point.icon {
                            Image(systemName: icon)
                                .font(.system(size: TypeScale.xs))
                                .foregroundColor(strokeColor)
                        }
                        Text(point.label)
                            .font(.system(size: TypeScale.xxs, weight: .medium))
                            .foregroundColor(.text.secondary)
                        Text("\(Int(point.value))")
                            .font(.system(size: TypeScale.xs, weight: .semibold))
                            .foregroundColor(.text.primary)
                    }
                    .frame(width: 60)
                    .position(labelPosition)
                }
                
                // Center value (overall score)
                VStack(spacing: 2) {
                    let avgValue = dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)
                    Text("\(Int(avgValue))")
                        .font(.system(size: TypeScale.xxl, weight: .bold))
                        .foregroundColor(strokeColor)
                    Text("Overall")
                        .font(.system(size: TypeScale.xxs))
                        .foregroundColor(.text.secondary)
                }
                .position(center)
            }
        }
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        let count = Double(dataPoints.count)
        // Start from top (270 degrees) and go clockwise
        return (270 + (360 / count * Double(index))) * .pi / 180
    }
    
    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

// MARK: - Preview

#Preview {
    Card(style: .flat) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wellness Foundation")
                .font(.heading)
            
            RadarChart(
                dataPoints: [
                    RadarChart.RadarDataPoint(label: "Sleep", value: 85, icon: "moon.fill"),
                    RadarChart.RadarDataPoint(label: "Recovery", value: 68, icon: "heart.fill"),
                    RadarChart.RadarDataPoint(label: "HRV", value: 72, icon: "waveform.path.ecg"),
                    RadarChart.RadarDataPoint(label: "Stress", value: 82, icon: "brain.head.profile"),
                    RadarChart.RadarDataPoint(label: "Consistency", value: 90, icon: "calendar"),
                    RadarChart.RadarDataPoint(label: "Nutrition", value: 75, icon: "fork.knife")
                ],
                fillColor: Color.health.hrv.opacity(0.25),
                strokeColor: Color.health.hrv
            )
            .frame(height: 300)
            
            Text("Foundation Score: 78/100")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    .padding()
    .background(Color.background.primary)
}
