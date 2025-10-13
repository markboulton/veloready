import SwiftUI
import Charts

/// Chart showing accumulated sleep debt
/// Critical for athletes to understand recovery deficit
struct SleepDebtChart: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Debt")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Accumulated sleep deficit affecting recovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Current debt
            HStack(alignment: .bottom, spacing: 8) {
                Text(debtAmount)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(debtColor)
                
                Spacer()
                
                debtStatusBadge
            }
            
            // Debt meter
            debtMeter
            
            // Impact on performance
            performanceImpact
            
            // Recovery timeline
            recoveryTimeline
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
    
    private var sleepDebt: Double {
        // Simplified: just last night's deficit
        // In production, this would track cumulative debt over 7-14 days
        let target = sleepScore.inputs.sleepNeed ?? 28800
        let actual = sleepScore.inputs.sleepDuration ?? 0
        return max(target - actual, 0)
    }
    
    private var debtAmount: String {
        let hours = Int(sleepDebt) / 3600
        let minutes = Int(sleepDebt) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    private var debtColor: Color {
        switch sleepDebt {
        case 0..<1800: return .green  // < 30 min
        case 1800..<3600: return .orange  // 30-60 min
        default: return .red  // > 1 hour
        }
    }
    
    private var performanceImpactPercentage: Int {
        // Research shows ~1% performance decline per 30min sleep debt
        let halfHours = sleepDebt / 1800
        return min(Int(halfHours), 15) // Cap at 15%
    }
    
    private var nightsToRecover: Int {
        // Can repay ~25% of debt per night
        guard sleepDebt > 0 else { return 0 }
        return Int(ceil(sleepDebt / (sleepDebt * 0.25)))
    }
    
    // MARK: - Components
    
    private var debtStatusBadge: some View {
        let status: String
        let icon: String
        
        switch sleepDebt {
        case 0..<1800:
            status = "Minimal"
            icon = "checkmark.circle.fill"
        case 1800..<3600:
            status = "Moderate"
            icon = "exclamationmark.triangle.fill"
        default:
            status = "High"
            icon = "exclamationmark.octagon.fill"
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
        .background(debtColor)
        .cornerRadius(10)
    }
    
    private var debtMeter: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Debt indicator
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.green, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * min(sleepDebt / 7200, 1.0)) // 2 hours max
                        .cornerRadius(8)
                }
            }
            .frame(height: 12)
            
            // Scale markers
            HStack {
                Text("0h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("1h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("2h+")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var performanceImpact: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Est. Performance Impact")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("-\(performanceImpactPercentage)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(debtColor)
                    
                    Text("capacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundColor(debtColor.opacity(0.5))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var recoveryTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(ColorPalette.blue)
                
                Text("Recovery Timeline")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if sleepDebt > 0 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption)
                        .foregroundColor(ColorScale.purpleAccent)
                        .padding(.top, 2)
                    
                    Text(recoveryMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("No sleep debt - excellent sleep balance!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(ColorPalette.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var recoveryMessage: String {
        let nights = nightsToRecover
        if nights == 1 {
            return "Can be recovered tonight with recommended sleep duration. Aim to go to bed 30-60 minutes earlier."
        } else if nights <= 3 {
            return "Will take approximately \(nights) nights to fully recover. Prioritize consistent 8-9 hours sleep."
        } else {
            return "Significant sleep debt accumulated. Focus on sleep hygiene and aim for 9+ hours for the next week."
        }
    }
}
