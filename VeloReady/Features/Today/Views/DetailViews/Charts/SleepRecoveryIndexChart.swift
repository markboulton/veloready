import SwiftUI
import Charts

/// **USP CHART**: Sleep-Recovery Index - Unique graph showing the relationship between
/// sleep quality, HRV changes, and athletic recovery readiness
/// 
/// Based on sport science research showing:
/// - Deep + REM sleep are critical for physical and cognitive recovery
/// - Overnight HRV changes indicate parasympathetic recovery
/// - Combined metric predicts next-day training readiness
///
/// References:
/// - Doherty et al. (2021) - Sleep and Recovery Practices of Athletes
/// - HRV as measure of autonomic balance and recovery capacity
struct SleepRecoveryIndexChart: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep-Recovery Index")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Your unique recovery readiness score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Recovery readiness badge
                recoveryBadge
            }
            
            // Main chart
            recoveryIndexChart
            
            // Key insights
            insightsRow
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Recovery Readiness Calculation
    
    /// Calculates recovery readiness based on:
    /// - Sleep quality (deep + REM %)
    /// - HRV change (overnight vs baseline)
    /// - Sleep efficiency
    private var recoveryReadiness: RecoveryState {
        let restorativeSleep = restorativeSleepPercentage
        let hrvChange = hrvChangePercentage
        let efficiency = sleepScore.inputs.timeInBed ?? 0 > 0 ?
            ((sleepScore.inputs.sleepDuration ?? 0) / (sleepScore.inputs.timeInBed ?? 1)) * 100 : 0
        
        // Weighted score: 40% restorative sleep, 40% HRV, 20% efficiency
        let score = (restorativeSleep * 0.4) + (hrvChange * 0.4) + (efficiency * 0.2)
        
        if score >= 80 {
            return .optimal
        } else if score >= 60 {
            return .good
        } else if score >= 40 {
            return .moderate
        } else {
            return .poor
        }
    }
    
    private var restorativeSleepPercentage: Double {
        guard let sleepDuration = sleepScore.inputs.sleepDuration, sleepDuration > 0 else { return 0 }
        let deepDuration = sleepScore.inputs.deepSleepDuration ?? 0
        let remDuration = sleepScore.inputs.remSleepDuration ?? 0
        return ((deepDuration + remDuration) / sleepDuration) * 100
    }
    
    private var hrvChangePercentage: Double {
        guard let overnight = sleepScore.inputs.hrvOvernight,
              let baseline = sleepScore.inputs.hrvBaseline,
              baseline > 0 else { return 50 }
        
        let change = ((overnight - baseline) / baseline) * 100
        // Normalize to 0-100 scale (±30% HRV change is significant)
        return min(max((change + 30) / 0.6, 0), 100)
    }
    
    // MARK: - Chart Components
    
    private var recoveryIndexChart: some View {
        VStack(spacing: 12) {
            // Three-bar comparison chart
            HStack(spacing: 20) {
                recoveryBar(
                    title: "Restorative\nSleep",
                    value: restorativeSleepPercentage,
                    color: ColorScale.purpleAccent,
                    optimalRange: 35...45
                )
                
                recoveryBar(
                    title: "HRV\nRecovery",
                    value: hrvChangePercentage,
                    color: ColorScale.purpleAccent,
                    optimalRange: 45...65
                )
                
                recoveryBar(
                    title: "Sleep\nEfficiency",
                    value: sleepScore.inputs.timeInBed ?? 0 > 0 ?
                        ((sleepScore.inputs.sleepDuration ?? 0) / (sleepScore.inputs.timeInBed ?? 1)) * 100 : 0,
                    color: ColorPalette.blue,
                    optimalRange: 85...95
                )
            }
            .frame(height: 180)
        }
    }
    
    private func recoveryBar(title: String, value: Double, color: Color, optimalRange: ClosedRange<Double>) -> some View {
        VStack(spacing: 8) {
            // Bar container
            ZStack(alignment: .bottom) {
                // Background optimal range indicator
                GeometryReader { geometry in
                    let height = geometry.size.height
                    let rangeHeight = (optimalRange.upperBound - optimalRange.lowerBound) / 100 * height
                    let rangeOffset = (100 - optimalRange.upperBound) / 100 * height
                    
                    Rectangle()
                        .fill(color.opacity(0.15))
                        .frame(height: rangeHeight)
                        .offset(y: rangeOffset)
                }
                
                // Actual value bar
                Rectangle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 140 * (value / 100))
            }
            .frame(height: 140)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Value label
            Text("\(Int(value))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            // Title
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var recoveryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: recoveryReadiness.icon)
                .font(.caption)
            Text(recoveryReadiness.title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(recoveryReadiness.color)
        .cornerRadius(12)
    }
    
    private var insightsRow: some View {
        HStack(spacing: 16) {
            insightCard(
                icon: "moon.stars.fill",
                value: "\(Int(restorativeSleepPercentage))%",
                label: "Restorative",
                color: ColorScale.purpleAccent
            )
            
            insightCard(
                icon: "heart.fill",
                value: hrvChangeText,
                label: "HRV Change",
                color: ColorScale.purpleAccent
            )
            
            insightCard(
                icon: "figure.run",
                value: recoveryReadiness.readinessText,
                label: "Training",
                color: recoveryReadiness.color
            )
        }
    }
    
    private func insightCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var hrvChangeText: String {
        guard let overnight = sleepScore.inputs.hrvOvernight,
              let baseline = sleepScore.inputs.hrvBaseline else {
            return "N/A"
        }
        let change = ((overnight - baseline) / baseline) * 100
        return String(format: "%+.0f%%", change)
    }
}

// MARK: - Recovery State

enum RecoveryState {
    case optimal
    case good
    case moderate
    case poor
    
    var title: String {
        switch self {
        case .optimal: return "Optimal"
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .poor: return "Low"
        }
    }
    
    var readinessText: String {
        switch self {
        case .optimal: return "Ready"
        case .good: return "Good"
        case .moderate: return "Light"
        case .poor: return "Rest"
        }
    }
    
    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .moderate: return "exclamationmark.triangle.fill"
        case .poor: return "moon.zzz.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .good: return ColorPalette.blue
        case .moderate: return .orange
        case .poor: return .red
        }
    }
}
