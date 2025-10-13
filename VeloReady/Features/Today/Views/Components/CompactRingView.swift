import SwiftUI

/// Compact circular ring graph for three-graph layout
/// Smaller version of RecoveryRingView for Today page with smooth animations
struct CompactRingView: View {
    let score: Int? // 0-100, nil for missing data
    let title: String
    let band: any ScoreBand
    let animationDelay: Double // Delay before starting animation
    let action: () -> Void
    let centerText: String? // Optional custom text for center (e.g., "12.5" for strain)
    
    private let ringWidth: CGFloat = 5
    private let size: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                if let score = score {
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
                    
                    // Center content - use custom text if provided, otherwise show score
                    Text(centerText ?? "\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(colorForBand(band))
                } else {
                    // Missing data indicator
                    Text("?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(.systemGray3))
                }
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
        guard let score = score else { return 0.0 }
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
            CompactRingView(score: 85, title: "Recovery", band: RecoveryScore.RecoveryBand.green, animationDelay: 0.0, action: {}, centerText: nil)
            CompactRingView(score: 55, title: "Sleep Quality", band: SleepScore.SleepBand.good, animationDelay: 0.1, action: {}, centerText: nil)
            CompactRingView(score: 70, title: "Moderate", band: StrainScore.StrainBand.moderate, animationDelay: 0.2, action: {}, centerText: "12.5")
        }
        .padding()
    }
}
