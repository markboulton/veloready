import SwiftUI
import Charts

/// Sleep stages bar chart with typical ranges AND time-based hypnogram
/// Shows both the duration/percentage of each stage and when they occurred throughout the night
struct SleepStagesDetailChart: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Sleep Architecture")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Bar chart with typical ranges
            stagesBarChart
            
            Divider()
            
            // Time-based hypnogram (like Apple Health)
            sleepHypnogram
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Sleep Stages Data
    
    private struct SleepStageData: Identifiable {
        let id = UUID()
        let name: String
        let duration: Double
        let percentage: Double
        let typicalRange: ClosedRange<Double>
        let color: Color
        let stage: Int // For hypnogram: 0=Awake, 1=REM, 2=Core, 3=Deep
    }
    
    private var stagesData: [SleepStageData] {
        guard let sleepDuration = sleepScore.inputs.sleepDuration,
              sleepDuration > 0 else { return [] }
        
        var stages: [SleepStageData] = []
        
        // Deep Sleep (15-25% is typical for athletes)
        if let deep = sleepScore.inputs.deepSleepDuration {
            stages.append(SleepStageData(
                name: "Deep",
                duration: deep,
                percentage: (deep / sleepDuration) * 100,
                typicalRange: 15...25,
                color: ColorScale.purpleAccent,
                stage: 3
            ))
        }
        
        // REM Sleep (20-25% is typical)
        if let rem = sleepScore.inputs.remSleepDuration {
            stages.append(SleepStageData(
                name: "REM",
                duration: rem,
                percentage: (rem / sleepDuration) * 100,
                typicalRange: 20...25,
                color: ColorPalette.purple,
                stage: 1
            ))
        }
        
        // Core/Light Sleep (45-55% is typical)
        if let core = sleepScore.inputs.coreSleepDuration {
            stages.append(SleepStageData(
                name: "Core",
                duration: core,
                percentage: (core / sleepDuration) * 100,
                typicalRange: 45...55,
                color: ColorPalette.blue,
                stage: 2
            ))
        }
        
        // Awake (<5% is optimal)
        if let awake = sleepScore.inputs.awakeDuration {
            stages.append(SleepStageData(
                name: "Awake",
                duration: awake,
                percentage: (awake / sleepDuration) * 100,
                typicalRange: 0...5,
                color: .orange,
                stage: 0
            ))
        }
        
        return stages
    }
    
    // MARK: - Bar Chart
    
    private var stagesBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration & Typical Ranges")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(stagesData) { stage in
                stageBar(stage: stage)
            }
        }
    }
    
    private func stageBar(stage: SleepStageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stage.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .leading)
                
                Text(formatDuration(stage.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Status indicator
                statusIndicator(for: stage)
                
                Text("\(Int(stage.percentage))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(stage.color)
                    .frame(width: 40, alignment: .trailing)
            }
            
            // Bar with typical range overlay
            ZStack(alignment: .leading) {
                // Background (typical range)
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let rangeStart = stage.typicalRange.lowerBound / 100
                    let rangeWidth = (stage.typicalRange.upperBound - stage.typicalRange.lowerBound) / 100
                    
                    Rectangle()
                        .fill(stage.color.opacity(0.15))
                        .frame(width: width * rangeWidth)
                        .offset(x: width * rangeStart)
                }
                
                // Actual value bar
                GeometryReader { geometry in
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [stage.color.opacity(0.7), stage.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * (stage.percentage / 100))
                }
            }
            .frame(height: 12)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }
    
    private func statusIndicator(for stage: SleepStageData) -> some View {
        let isInRange = stage.typicalRange.contains(stage.percentage)
        
        return Image(systemName: isInRange ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundColor(isInRange ? .green : .orange)
    }
    
    // MARK: - Sleep Hypnogram (Time-based)
    
    private var sleepHypnogram: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages Over Time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let bedtime = sleepScore.inputs.bedtime,
               let wakeTime = sleepScore.inputs.wakeTime {
                
                // Y-axis labels
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(["Awake", "REM", "Light", "Deep"].reversed(), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 30, alignment: .center)
                    }
                }
                .padding(.trailing, 8)
                
                // Hypnogram chart
                Chart {
                    // Generate mock sleep cycle data (in real app, this would come from HealthKit samples)
                    ForEach(generateSleepCycles(bedtime: bedtime, wakeTime: wakeTime)) { cycle in
                        AreaMark(
                            x: .value("Time", cycle.time),
                            y: .value("Stage", cycle.stageValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [cycle.color.opacity(0.3), cycle.color.opacity(0.6)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(stageName(for: intValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { value in
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 150)
                
                // Legend
                HStack(spacing: 16) {
                    legendItem(color: ColorScale.purpleAccent, label: "Deep")
                    legendItem(color: ColorPalette.blue, label: "Light")
                    legendItem(color: ColorPalette.purple, label: "REM")
                    legendItem(color: .orange, label: "Awake")
                }
                .font(.caption2)
                .padding(.top, 8)
            } else {
                Text("Sleep timing data not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
    }
    
    private func stageName(for value: Int) -> String {
        switch value {
        case 0: return "Deep"
        case 1: return "Light"
        case 2: return "REM"
        case 3: return "Awake"
        default: return ""
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Mock Sleep Cycles Generator
    
    private struct SleepCycle: Identifiable {
        let id = UUID()
        let time: Date
        let stage: String
        let stageValue: Int
        let color: Color
    }
    
    private func generateSleepCycles(bedtime: Date, wakeTime: Date) -> [SleepCycle] {
        // Generate realistic sleep cycle progression
        // Typically: Deep sleep dominates first 3-4 hours, then more REM in later cycles
        var cycles: [SleepCycle] = []
        let totalDuration = wakeTime.timeIntervalSince(bedtime)
        let interval: TimeInterval = 300 // 5-minute intervals
        
        for seconds in stride(from: 0, to: totalDuration, by: interval) {
            let time = bedtime.addingTimeInterval(seconds)
            let progress = seconds / totalDuration
            
            // Simulate sleep stages (simplified model)
            let (stage, stageValue, color) = determineSleepStage(progress: progress)
            
            cycles.append(SleepCycle(
                time: time,
                stage: stage,
                stageValue: stageValue,
                color: color
            ))
        }
        
        return cycles
    }
    
    private func determineSleepStage(progress: Double) -> (String, Int, Color) {
        // Simplified sleep cycle model:
        // - First half: more deep sleep
        // - Second half: more REM sleep
        // - Brief awake periods throughout
        
        let cyclePosition = (progress * 5).truncatingRemainder(dividingBy: 1) // 5 cycles
        
        if Double.random(in: 0...1) < 0.05 {
            // 5% chance of brief awake period
            return ("Awake", 3, .orange)
        } else if progress < 0.3 {
            // First 30%: mostly deep sleep
            return cyclePosition < 0.7 ? ("Deep", 0, ColorScale.purpleAccent) : ("Light", 1, ColorPalette.blue)
        } else if progress < 0.6 {
            // Middle: mixed stages
            if cyclePosition < 0.3 {
                return ("Deep", 0, ColorScale.purpleAccent)
            } else if cyclePosition < 0.6 {
                return ("Light", 1, ColorPalette.blue)
            } else {
                return ("REM", 2, ColorPalette.purple)
            }
        } else {
            // Last 40%: more REM sleep
            return cyclePosition < 0.4 ? ("Light", 1, ColorPalette.blue) : ("REM", 2, ColorPalette.purple)
        }
    }
    
}
