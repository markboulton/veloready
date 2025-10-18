import SwiftUI

/// Heatmap calendar showing weekly training and recovery patterns
/// Visual representation of intensity distribution across the week
struct WeeklyHeatmap: View {
    let trainingData: [DayData]
    let sleepData: [DayData]
    
    struct DayData: Identifiable {
        let id = UUID()
        let dayOfWeek: Int // 1 = Monday, 7 = Sunday
        let timeOfDay: TimeOfDay
        let intensity: Intensity
        
        enum TimeOfDay: String {
            case am = "AM"
            case pm = "PM"
        }
        
        enum Intensity {
            case rest
            case easy
            case moderate
            case hard
            
            var color: Color {
                switch self {
                case .rest: return Color.text.tertiary.opacity(0.3)
                case .easy: return Color.green
                case .moderate: return Color.yellow
                case .hard: return Color.red
                }
            }
            
            var emoji: String {
                switch self {
                case .rest: return "⚫"
                case .easy: return "🟢"
                case .moderate: return "🟡"
                case .hard: return "🔴"
                }
            }
        }
    }
    
    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Training pattern
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Training Pattern")
                    .font(.system(size: TypeScale.sm, weight: .semibold))
                    .foregroundColor(.text.secondary)
                
                HStack(spacing: Spacing.xs) {
                    Text("   ")
                        .font(.system(size: TypeScale.xxs))
                        .frame(width: 24)
                    
                    ForEach(0..<7) { day in
                        Text(dayLabels[day])
                            .font(.system(size: TypeScale.xxs))
                            .foregroundColor(.text.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // AM row
                HStack(spacing: Spacing.xs) {
                    Text("AM")
                        .font(.system(size: TypeScale.xxs, weight: .medium))
                        .foregroundColor(.text.secondary)
                        .frame(width: 24)
                    
                    ForEach(1...7, id: \.self) { day in
                        intensityCell(for: day, timeOfDay: .am, data: trainingData)
                    }
                }
                
                // PM row
                HStack(spacing: Spacing.xs) {
                    Text("PM")
                        .font(.system(size: TypeScale.xxs, weight: .medium))
                        .foregroundColor(.text.secondary)
                        .frame(width: 24)
                    
                    ForEach(1...7, id: \.self) { day in
                        intensityCell(for: day, timeOfDay: .pm, data: trainingData)
                    }
                }
            }
            
            // Sleep pattern
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sleep Quality")
                    .font(.system(size: TypeScale.sm, weight: .semibold))
                    .foregroundColor(.text.secondary)
                
                HStack(spacing: Spacing.xs) {
                    Text("   ")
                        .font(.system(size: TypeScale.xxs))
                        .frame(width: 24)
                    
                    ForEach(1...7, id: \.self) { day in
                        if let sleepIntensity = sleepData.first(where: { $0.dayOfWeek == day })?.intensity {
                            Text(sleepIntensity.emoji)
                                .font(.system(size: TypeScale.md))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("⚫")
                                .font(.system(size: TypeScale.md))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: Spacing.lg) {
                legendItem(emoji: "🟢", label: "Easy/Good")
                legendItem(emoji: "🟡", label: "Moderate")
                legendItem(emoji: "🔴", label: "Hard/Poor")
                legendItem(emoji: "⚫", label: "Rest")
            }
            .font(.system(size: TypeScale.xxs))
            .foregroundColor(.text.secondary)
        }
    }
    
    private func intensityCell(for day: Int, timeOfDay: DayData.TimeOfDay, data: [DayData]) -> some View {
        let intensity = data.first(where: { $0.dayOfWeek == day && $0.timeOfDay == timeOfDay })?.intensity ?? .rest
        
        return Text(intensity.emoji)
            .font(.system(size: TypeScale.md))
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(intensity.color.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(ColorPalette.chartGridLine, lineWidth: 0.5)
            )
    }
    
    private func legendItem(emoji: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
            Text(label)
        }
    }
}

// MARK: - Preview

#Preview {
    Card(style: .flat) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Weekly Rhythm")
                .font(.heading)
            
            WeeklyHeatmap(
                trainingData: [
                    // Monday
                    .init(dayOfWeek: 1, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 1, timeOfDay: .pm, intensity: .moderate),
                    // Tuesday
                    .init(dayOfWeek: 2, timeOfDay: .am, intensity: .moderate),
                    .init(dayOfWeek: 2, timeOfDay: .pm, intensity: .easy),
                    // Wednesday
                    .init(dayOfWeek: 3, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 3, timeOfDay: .pm, intensity: .hard),
                    // Thursday
                    .init(dayOfWeek: 4, timeOfDay: .am, intensity: .rest),
                    .init(dayOfWeek: 4, timeOfDay: .pm, intensity: .moderate),
                    // Friday
                    .init(dayOfWeek: 5, timeOfDay: .am, intensity: .hard),
                    .init(dayOfWeek: 5, timeOfDay: .pm, intensity: .easy),
                    // Saturday
                    .init(dayOfWeek: 6, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 6, timeOfDay: .pm, intensity: .easy),
                    // Sunday
                    .init(dayOfWeek: 7, timeOfDay: .am, intensity: .rest),
                    .init(dayOfWeek: 7, timeOfDay: .pm, intensity: .moderate)
                ],
                sleepData: [
                    .init(dayOfWeek: 1, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 2, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 3, timeOfDay: .am, intensity: .moderate),
                    .init(dayOfWeek: 4, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 5, timeOfDay: .am, intensity: .easy),
                    .init(dayOfWeek: 6, timeOfDay: .am, intensity: .hard),
                    .init(dayOfWeek: 7, timeOfDay: .am, intensity: .easy)
                ]
            )
            
            Text("Well-distributed intensity with adequate recovery windows.")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    .padding()
    .background(Color.background.primary)
}
