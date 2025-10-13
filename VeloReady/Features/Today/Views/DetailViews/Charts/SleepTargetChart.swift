import SwiftUI
import Charts

/// Chart showing tonight's recommended sleep target
/// Based on training load, recovery needs, and sleep debt
struct SleepTargetChart: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tonight's Sleep Target")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Personalized recommendation for optimal recovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Target bedtime
            HStack(spacing: 20) {
                targetTimeCard(
                    title: "Recommended Bedtime",
                    time: recommendedBedtime,
                    icon: "moon.fill",
                    color: ColorScale.purpleAccent
                )
                
                targetTimeCard(
                    title: "Target Duration",
                    time: formatDuration(targetSleepDuration),
                    icon: "clock.fill",
                    color: ColorPalette.blue
                )
            }
            
            // Visual timeline
            sleepTimeline
            
            // Adjustment reason
            adjustmentReason
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Calculations
    
    private var baseSleepNeed: Double {
        sleepScore.inputs.sleepNeed ?? 28800 // Default 8 hours
    }
    
    private var sleepDebt: Double {
        // Calculate accumulated sleep debt (simplified - would track over multiple days)
        let lastNightDeficit = baseSleepNeed - (sleepScore.inputs.sleepDuration ?? 0)
        return max(lastNightDeficit, 0)
    }
    
    private var targetSleepDuration: Double {
        var target = baseSleepNeed
        
        // Add extra time for sleep debt (can only repay ~25% per night)
        if sleepDebt > 0 {
            target += min(sleepDebt * 0.25, 3600) // Max 1 hour extra
        }
        
        // Add extra time for hard training (if HRV is low)
        if let hrv = sleepScore.inputs.hrvOvernight,
           let baseline = sleepScore.inputs.hrvBaseline,
           hrv < baseline * 0.9 { // HRV is >10% below baseline
            target += 1800 // Add 30 minutes
        }
        
        return min(target, 36000) // Cap at 10 hours
    }
    
    private var recommendedBedtime: String {
        // Assume wake time is consistent (use baseline or calculate from inputs)
        guard let wakeTime = sleepScore.inputs.wakeTime else {
            return "10:00 PM"
        }
        
        let calendar = Calendar.current
        let bedtime = calendar.date(byAdding: .second, value: -Int(targetSleepDuration), to: wakeTime) ?? Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedtime)
    }
    
    private var targetWakeTime: String {
        guard let wakeTime = sleepScore.inputs.wakeTime else {
            return "6:00 AM"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }
    
    // MARK: - Components
    
    private func targetTimeCard(title: String, time: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(time)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sleepTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timeline visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Sleep duration bar
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [ColorScale.purpleAccent, ColorPalette.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * 0.7, height: 8)
                        .cornerRadius(4)
                        .offset(x: geometry.size.width * 0.15)
                }
            }
            .frame(height: 8)
            
            // Time labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendedBedtime)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Bedtime")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(targetWakeTime)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Wake Up")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var adjustmentReason: some View {
        VStack(alignment: .leading, spacing: 8) {
            if sleepDebt > 1800 { // More than 30 min debt
                adjustmentRow(
                    icon: "plus.circle.fill",
                    text: "Added \(formatDuration(min(sleepDebt * 0.25, 3600))) to repay sleep debt",
                    color: .orange
                )
            }
            
            if let hrv = sleepScore.inputs.hrvOvernight,
               let baseline = sleepScore.inputs.hrvBaseline,
               hrv < baseline * 0.9 {
                adjustmentRow(
                    icon: "heart.fill",
                    text: "Added 30m for low HRV recovery",
                    color: .red
                )
            }
            
            if sleepDebt <= 1800 && (sleepScore.inputs.hrvOvernight ?? 0) >= (sleepScore.inputs.hrvBaseline ?? 0) * 0.9 {
                adjustmentRow(
                    icon: "checkmark.circle.fill",
                    text: "Standard sleep need - no adjustments needed",
                    color: .green
                )
            }
        }
    }
    
    private func adjustmentRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
