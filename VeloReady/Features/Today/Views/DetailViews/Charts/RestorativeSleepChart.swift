import SwiftUI
import Charts

/// Chart showing restorative sleep quality (Deep + REM sleep)
/// Critical for athletic recovery and performance
struct RestorativeSleepChart: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Restorative Sleep")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Deep + REM sleep for physical and mental recovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Main metric
            HStack(alignment: .bottom, spacing: 8) {
                Text(restorativeSleepTime)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(restorativeColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(restorativePercentage))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(restorativeColor)
                    
                    Text("of total sleep")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Breakdown
            VStack(spacing: 12) {
                restorativeBreakdownRow(
                    title: "Deep Sleep",
                    duration: sleepScore.inputs.deepSleepDuration ?? 0,
                    color: ColorScale.purpleAccent,
                    icon: "waveform.path.ecg"
                )
                
                restorativeBreakdownRow(
                    title: "REM Sleep",
                    duration: sleepScore.inputs.remSleepDuration ?? 0,
                    color: ColorPalette.purple,
                    icon: "brain.head.profile"
                )
            }
            
            // Insights
            insightsText
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
    
    private var restorativeDuration: Double {
        (sleepScore.inputs.deepSleepDuration ?? 0) + (sleepScore.inputs.remSleepDuration ?? 0)
    }
    
    private var restorativePercentage: Double {
        guard let total = sleepScore.inputs.sleepDuration, total > 0 else { return 0 }
        return (restorativeDuration / total) * 100
    }
    
    private var restorativeSleepTime: String {
        let hours = Int(restorativeDuration) / 3600
        let minutes = Int(restorativeDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var restorativeColor: Color {
        switch restorativePercentage {
        case 35...45: return .green  // Optimal range for athletes
        case 30..<35, 45..<50: return ColorPalette.blue  // Good
        case 25..<30, 50..<55: return .orange  // Moderate
        default: return .red  // Needs improvement
        }
    }
    
    private var statusBadge: some View {
        let status: String
        let icon: String
        
        switch restorativePercentage {
        case 35...45:
            status = "Optimal"
            icon = "checkmark.circle.fill"
        case 30..<35, 45..<50:
            status = "Good"
            icon = "checkmark.circle"
        case 25..<30, 50..<55:
            status = "Fair"
            icon = "exclamationmark.triangle.fill"
        default:
            status = "Low"
            icon = "exclamationmark.circle.fill"
        }
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(status)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(restorativeColor)
        .cornerRadius(10)
    }
    
    // MARK: - Components
    
    private func restorativeBreakdownRow(title: String, duration: Double, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(formatDuration(duration))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var insightsText: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(ColorPalette.blue)
                .padding(.top, 2)
            
            Text(insightMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ColorPalette.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var insightMessage: String {
        switch restorativePercentage {
        case 35...45:
            return "Excellent restorative sleep! Your deep and REM sleep are in the optimal range for athletic recovery."
        case 30..<35:
            return "Good restorative sleep, though slightly below optimal. Consider going to bed 15-30 minutes earlier."
        case 45..<50:
            return "Good restorative sleep, though slightly above typical. This may indicate recovery debt from hard training."
        case 25..<30:
            return "Restorative sleep is below optimal. Focus on sleep hygiene and aim for 7-9 hours total sleep."
        default:
            return "Restorative sleep is low. Prioritize sleep tonight - it's critical for recovery and performance."
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
