import SwiftUI

/// Circular ring graph for recovery score visualization
/// Shows score as number in center with colored ring from red (0) to green (100)
struct RecoveryRingView: View {
    let score: Int // 0-100
    let band: RecoveryScore.RecoveryBand
    
    private let ringWidth: CGFloat = 12
    private let size: CGFloat = 160
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // Progress ring - solid color based on band
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    colorForBand(band),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Rotate so 0 is at top
                .animation(.easeOut(duration: 0.8), value: score) // Smooth animation when score changes
            
            // Center content
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(colorForBand(band))
                
                Text("Recovery")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Progress value for the ring (0.0 to 1.0)
    private var progressValue: Double {
        let value = Double(score) / 100.0
        print("📊 RecoveryRingView: score=\(score), progressValue=\(value), ringFill=\(Int(value * 100))%")
        return value
    }
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        return band.colorToken
    }
}

// MARK: - Preview

struct RecoveryRingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            RecoveryRingView(score: 85, band: .green)
            RecoveryRingView(score: 55, band: .amber)
            RecoveryRingView(score: 25, band: .red)
        }
        .padding()
    }
}
