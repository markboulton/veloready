import SwiftUI

/// Compact circular ring graph for three-graph layout
/// Smaller version of RecoveryRingView for Today page with smooth animations
struct CompactRingView: View {
    let score: Int // 0-100
    let title: String
    let band: any ScoreBand
    let animationDelay: Double // Delay before starting animation
    let action: () -> Void
    
    private let ringWidth: CGFloat = 5
    private let size: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                // Progress ring - directly bound to score, no animation state needed
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        colorForBand(band),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90)) // Start from top
                    .animation(.easeOut(duration: 0.8), value: score) // Animate when score changes
                
                // Center content
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(colorForBand(band))
            }
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Progress value for the ring (0.0 to 1.0)
    private var progressValue: Double {
        return Double(score) / 100.0
    }
    
    private func colorForBand(_ band: any ScoreBand) -> Color {
        return band.colorToken
    }
}

// MARK: - Preview

struct CompactRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            CompactRingView(score: 85, title: "Recovery", band: RecoveryScore.RecoveryBand.green, animationDelay: 0.0) { }
            CompactRingView(score: 55, title: "Sleep Quality", band: SleepScore.SleepBand.good, animationDelay: 0.1) { }
            CompactRingView(score: 25, title: "Strain", band: RecoveryScore.RecoveryBand.red, animationDelay: 0.2) { }
        }
        .padding()
    }
}
