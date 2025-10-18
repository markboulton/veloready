import SwiftUI

/// Circular clock chart showing circadian rhythm patterns
/// Displays when the athlete typically sleeps, trains, and recovers
struct CircadianClockChart: View {
    let sleepWindow: TimeWindow
    let trainingWindows: [TimeWindow]
    let consistency: Double // 0-100
    
    struct TimeWindow: Identifiable {
        let id = UUID()
        let startHour: Double // 0-24 in fractional hours (e.g., 22.5 = 10:30 PM)
        let endHour: Double
        let label: String
        let color: Color
        let icon: String
    }
    
    init(
        sleepWindow: TimeWindow,
        trainingWindows: [TimeWindow] = [],
        consistency: Double
    ) {
        self.sleepWindow = sleepWindow
        self.trainingWindows = trainingWindows
        self.consistency = consistency
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.75
            
            ZStack {
                // Clock circle
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                
                // Hour markers
                ForEach(0..<24) { hour in
                    let angle = angleForHour(Double(hour))
                    let position = pointOnCircle(center: center, radius: radius, angle: angle)
                    
                    if hour % 6 == 0 {
                        // Major hour labels (12am, 6am, 12pm, 6pm)
                        Text(hourLabel(hour))
                            .font(.system(size: TypeScale.xs, weight: .semibold))
                            .foregroundColor(.text.primary)
                            .position(position)
                    } else if hour % 3 == 0 {
                        // Minor hour labels (3am, 9am, 3pm, 9pm)
                        Circle()
                            .fill(Color.text.tertiary)
                            .frame(width: 4, height: 4)
                            .position(position)
                    }
                }
                
                // Sleep arc
                arcSegment(
                    center: center,
                    radius: radius * 0.85,
                    startHour: sleepWindow.startHour,
                    endHour: sleepWindow.endHour,
                    color: sleepWindow.color,
                    thickness: 20
                )
                
                // Sleep icon
                if let sleepIconPos = midpointOfArc(
                    center: center,
                    radius: radius * 0.85,
                    startHour: sleepWindow.startHour,
                    endHour: sleepWindow.endHour
                ) {
                    Image(systemName: sleepWindow.icon)
                        .font(.system(size: TypeScale.md))
                        .foregroundColor(sleepWindow.color)
                        .position(sleepIconPos)
                }
                
                // Training arcs
                ForEach(trainingWindows) { window in
                    arcSegment(
                        center: center,
                        radius: radius * 0.65,
                        startHour: window.startHour,
                        endHour: window.endHour,
                        color: window.color,
                        thickness: 16
                    )
                    
                    // Training icon
                    if let iconPos = midpointOfArc(
                        center: center,
                        radius: radius * 0.65,
                        startHour: window.startHour,
                        endHour: window.endHour
                    ) {
                        Image(systemName: window.icon)
                            .font(.system(size: TypeScale.sm))
                            .foregroundColor(window.color)
                            .position(iconPos)
                    }
                }
                
                // Center label
                VStack(spacing: 4) {
                    Text("Consistency")
                        .font(.system(size: TypeScale.xs))
                        .foregroundColor(.text.secondary)
                    Text("\(Int(consistency))/100")
                        .font(.system(size: TypeScale.lg, weight: .bold))
                        .foregroundColor(.text.primary)
                }
                .position(center)
            }
        }
    }
    
    private func angleForHour(_ hour: Double) -> Double {
        // Start at top (12am = 270°) and go clockwise
        return (270 + (hour / 24) * 360) * .pi / 180
    }
    
    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
    
    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour == 12 { return "12pm" }
        if hour < 12 { return "\(hour)am" }
        return "\(hour - 12)pm"
    }
    
    private func arcSegment(
        center: CGPoint,
        radius: Double,
        startHour: Double,
        endHour: Double,
        color: Color,
        thickness: Double
    ) -> some View {
        let startAngle = Angle(radians: angleForHour(startHour))
        let endAngle = Angle(radians: angleForHour(endHour))
        
        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .stroke(color, lineWidth: thickness)
    }
    
    private func midpointOfArc(
        center: CGPoint,
        radius: Double,
        startHour: Double,
        endHour: Double
    ) -> CGPoint? {
        let midHour = (startHour + endHour) / 2
        let angle = angleForHour(midHour)
        return pointOnCircle(center: center, radius: radius, angle: angle)
    }
}

// MARK: - Preview

#Preview {
    Card(style: .flat) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Rhythm Patterns")
                .font(.heading)
            
            CircadianClockChart(
                sleepWindow: .init(
                    startHour: 23.0,
                    endHour: 6.5,
                    label: "Sleep",
                    color: Color.blue,
                    icon: "moon.fill"
                ),
                trainingWindows: [
                    .init(
                        startHour: 12.0,
                        endHour: 13.5,
                        label: "Lunch Ride",
                        color: Color.workout.power,
                        icon: "figure.outdoor.cycle"
                    ),
                    .init(
                        startHour: 17.5,
                        endHour: 19.0,
                        label: "Evening Ride",
                        color: Color.workout.tss,
                        icon: "figure.outdoor.cycle"
                    )
                ],
                consistency: 87
            )
            .frame(height: 280)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bedtime variance: ±22 min")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                Text("Training time: Mostly afternoons")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    .padding()
    .background(Color.background.primary)
}
