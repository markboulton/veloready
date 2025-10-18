import SwiftUI
import HealthKit

/// Sleep hypnogram chart showing sleep stages over time with gradiated colors
/// Similar to iOS Sleep app visualization
struct SleepHypnogramChart: View {
    let sleepSamples: [SleepStageSample]
    let nightStart: Date
    let nightEnd: Date
    
    struct SleepStageSample: Identifiable {
        let id = UUID()
        let startDate: Date
        let endDate: Date
        let stage: SleepStage
        
        var duration: TimeInterval {
            endDate.timeIntervalSince(startDate)
        }
    }
    
    enum SleepStage: Int {
        case inBed = 0
        case awake = 1
        case core = 2
        case rem = 3
        case deep = 4
        
        var label: String {
            switch self {
            case .inBed: return "In Bed"
            case .awake: return "Awake"
            case .core: return "Core"
            case .rem: return "REM"
            case .deep: return "Deep"
            }
        }
        
        var color: Color {
            switch self {
            case .inBed: return ColorPalette.backgroundTertiary
            case .awake: return ColorPalette.recoveryPoor.opacity(0.4)
            case .core: return ColorPalette.sleepMetric.opacity(0.5)
            case .rem: return ColorPalette.respiratoryMetric.opacity(0.6)
            case .deep: return ColorPalette.sleepMetric.opacity(0.8)
            }
        }
        
        var yPosition: Double {
            // Higher stages appear higher on chart (like iOS)
            switch self {
            case .inBed: return 0.0
            case .awake: return 0.2
            case .core: return 0.5
            case .rem: return 0.75
            case .deep: return 1.0
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Time range
            HStack {
                Text(formatTime(nightStart))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorPalette.labelSecondary)
                Spacer()
                Text(formatTime(nightEnd))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorPalette.labelSecondary)
            }
            
            // Hypnogram
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background grid lines
                    ForEach([0.2, 0.5, 0.75, 1.0], id: \.self) { yPos in
                        Path { path in
                            let y = geometry.size.height * (1 - yPos)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(Color.text.tertiary.opacity(0.1), lineWidth: 1)
                    }
                    
                    // Sleep stage segments
                    ForEach(sleepSamples) { sample in
                        sleepSegment(
                            sample: sample,
                            geometry: geometry,
                            totalDuration: nightEnd.timeIntervalSince(nightStart)
                        )
                    }
                    
                    // Stage labels on left
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        stageLabel("Deep", color: SleepStage.deep.color)
                        Spacer()
                        stageLabel("REM", color: SleepStage.rem.color)
                        Spacer()
                        stageLabel("Core", color: SleepStage.core.color)
                        Spacer()
                        stageLabel("Awake", color: SleepStage.awake.color)
                        Spacer()
                    }
                    .frame(height: geometry.size.height)
                }
            }
            .frame(height: 180)
            
            // Duration summary
            HStack(spacing: Spacing.md) {
                stageSummary(stage: .deep, samples: sleepSamples)
                stageSummary(stage: .rem, samples: sleepSamples)
                stageSummary(stage: .core, samples: sleepSamples)
                stageSummary(stage: .awake, samples: sleepSamples)
            }
            .font(.caption)
        }
    }
    
    private func sleepSegment(
        sample: SleepStageSample,
        geometry: GeometryProxy,
        totalDuration: TimeInterval
    ) -> some View {
        let startOffset = sample.startDate.timeIntervalSince(nightStart)
        let xStart = (startOffset / totalDuration) * geometry.size.width
        let width = (sample.duration / totalDuration) * geometry.size.width
        let yPos = sample.stage.yPosition
        let y = geometry.size.height * (1 - yPos)
        
        return Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        sample.stage.color,
                        sample.stage.color.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: max(2, width), height: 40)
            .position(x: xStart + width / 2, y: y)
    }
    
    private func stageLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: TypeScale.xxs, weight: .medium))
            .foregroundColor(color)
    }
    
    private func stageSummary(stage: SleepStage, samples: [SleepStageSample]) -> some View {
        let totalDuration = samples
            .filter { $0.stage == stage }
            .reduce(0) { $0 + $1.duration }
        
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return HStack(spacing: 4) {
            Circle()
                .fill(stage.color)
                .frame(width: 8, height: 8)
            
            if hours > 0 {
                Text("\(hours)h \(minutes)m")
                    .foregroundColor(.text.secondary)
            } else {
                Text("\(minutes)m")
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Helper to convert HKCategorySample to SleepStageSample

extension SleepHypnogramChart.SleepStageSample {
    init?(from hkSample: HKCategorySample) {
        let stage: SleepHypnogramChart.SleepStage
        
        switch hkSample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            stage = .inBed
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            stage = .awake
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
             HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            stage = .core
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            stage = .rem
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            stage = .deep
        default:
            return nil
        }
        
        self.init(
            startDate: hkSample.startDate,
            endDate: hkSample.endDate,
            stage: stage
        )
    }
}

// MARK: - Preview

#Preview {
    Card(style: .flat) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sleep Hypnogram")
                .font(.heading)
            
            SleepHypnogramChart(
                sleepSamples: generateMockHypnogramData(),
                nightStart: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
                nightEnd: Date()
            )
            
            Text("Last night: 7.2h total sleep")
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    .padding()
    .background(Color.background.primary)
}

func generateMockHypnogramData() -> [SleepHypnogramChart.SleepStageSample] {
    let now = Date()
    let nightStart = Calendar.current.date(byAdding: .hour, value: -8, to: now)!
    var samples: [SleepHypnogramChart.SleepStageSample] = []
    var currentTime = nightStart
    
    // Simulate a night of sleep with various stages
    let pattern: [(SleepHypnogramChart.SleepStage, TimeInterval)] = [
        (.inBed, 600), // 10min in bed
        (.core, 3600), // 1h core
        (.deep, 1800), // 30min deep
        (.core, 1800), // 30min core
        (.rem, 1200), // 20min REM
        (.core, 3600), // 1h core
        (.awake, 300), // 5min awake
        (.rem, 1800), // 30min REM
        (.core, 1800), // 30min core
        (.deep, 1200), // 20min deep
        (.core, 2400), // 40min core
        (.awake, 600) // 10min awake before waking
    ]
    
    for (stage, duration) in pattern {
        let endTime = currentTime.addingTimeInterval(duration)
        samples.append(.init(
            startDate: currentTime,
            endDate: endTime,
            stage: stage
        ))
        currentTime = endTime
    }
    
    return samples
}
