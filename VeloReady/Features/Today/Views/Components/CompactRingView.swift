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
    let animationTrigger: UUID // Triggers re-animation when changed
    
    @State private var animatedProgress: Double = 0.0
    @State private var numberOpacity: Double = 0.0
    
    private let ringWidth: CGFloat = 5
    private let size: CGFloat = 100
    private let initialDelay: Double = 0.14 // Global delay before animations start (30% faster)
    private let animationDuration: Double = 0.84 // Ring animation duration (30% faster than 1.2s)
    private let numberFadeDuration: Double = 0.28 // Number fade duration (30% faster than 0.4s)
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                if let score = score {
                    // Progress ring - draws in clockwise with ease-out animation
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            colorForBand(band),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90)) // Start from top (12 o'clock position)
                    
                    // Center content - use custom text if provided, otherwise show score
                    // Fades in as animation completes
                    Text(centerText ?? "\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(colorForBand(band))
                        .opacity(numberOpacity)
                } else {
                    // Missing data indicator
                    Text("?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(.systemGray3))
                }
            }
            
            // Title
            Text(title)
                .font(.smcaption)
                .fontWeight(.medium)
                .lineSpacing(Spacing.lineHeightRelaxed)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)  // ← Add 4pt padding to top
        }
        .onAppear {
            // Animate ring drawing on appear with delay and ease-out curve
            // Starts fast, slows down towards the end
            guard score != nil else { return }
            
            animateRing()
        }
        .onChange(of: score) { _, newScore in
            // Re-animate if score changes after initial load
            guard newScore != nil else {
                animatedProgress = 0.0
                numberOpacity = 0.0
                return
            }
            
            // Reset and re-animate
            animatedProgress = 0.0
            numberOpacity = 0.0
            
            animateRing()
        }
        .onChange(of: animationTrigger) { _, _ in
            // Re-animate when pull-to-refresh completes
            guard score != nil else { return }
            
            // Reset and re-animate
            animatedProgress = 0.0
            numberOpacity = 0.0
            
            animateRing()
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
    
    /// Animate the ring drawing and number fade-in
    private func animateRing() {
        let totalDelay = initialDelay + animationDelay
        let numberStartDelay = animationDuration * 0.7 // Start fade at 70% completion
        
        // Animate the ring drawing
        withAnimation(.easeOut(duration: animationDuration).delay(totalDelay)) {
            animatedProgress = progressValue
        }
        
        // Fade in the number as the ring completes
        withAnimation(.easeIn(duration: numberFadeDuration).delay(totalDelay + numberStartDelay)) {
            numberOpacity = 1.0
        }
    }
}

// MARK: - Preview

struct CompactRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            CompactRingView(score: 85, title: "Recovery", band: RecoveryScore.RecoveryBand.optimal, animationDelay: 0.0, action: {}, centerText: nil, animationTrigger: UUID())
            CompactRingView(score: 55, title: "Sleep Quality", band: SleepScore.SleepBand.good, animationDelay: 0.1, action: {}, centerText: nil, animationTrigger: UUID())
            CompactRingView(score: 70, title: "Good", band: StrainScore.StrainBand.good, animationDelay: 0.2, action: {}, centerText: "12.5", animationTrigger: UUID())
        }
        .padding()
    }
}
