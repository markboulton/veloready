import SwiftUI

/// Circular ring graph for recovery score visualization
/// Shows score as number in center with colored ring from red (0) to green (100)
struct RecoveryRingView: View {
    let score: Int // 0-100
    let band: RecoveryScore.RecoveryBand
    let isPersonalized: Bool // Whether ML was used
    
    private let ringWidth: CGFloat = ComponentSizes.ringWidthLarge
    private let size: CGFloat = ComponentSizes.ringDiameterLarge
    
    var body: some View {
        ZStack {
            // Background ring - very subtle
            Circle()
                .stroke(ColorPalette.backgroundTertiary, lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // Progress ring - refined color based on score
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    ColorPalette.recoveryColor(for: Double(score)),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Rotate so 0 is at top
                .animation(.easeOut(duration: 0.8), value: score) // Smooth animation when score changes
            
            // Center content
            VStack(spacing: Spacing.xs) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(ColorPalette.recoveryColor(for: Double(score)))
                
                HStack(spacing: Spacing.xs) {
                    Text(CommonContent.ReadinessComponents.recoveryUpper)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ColorPalette.labelSecondary)
                        .textCase(.uppercase)
                    
                    if isPersonalized {
                        Image(systemName: Icons.System.sparkles)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Progress value for the ring (0.0 to 1.0)
    private var progressValue: Double {
        let value = Double(score) / 100.0
        Logger.data("RecoveryRingView: score=\(score), progressValue=\(value), ringFill=\(Int(value * 100))%")
        return value
    }
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        return band.colorToken
    }
}

// MARK: - Preview

struct RecoveryRingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.xxl) {
            RecoveryRingView(score: 90, band: .optimal, isPersonalized: true)
            RecoveryRingView(score: 75, band: .good, isPersonalized: false)
            RecoveryRingView(score: 55, band: .fair, isPersonalized: true)
            RecoveryRingView(score: 25, band: .payAttention, isPersonalized: false)
        }
        .padding()
    }
}
