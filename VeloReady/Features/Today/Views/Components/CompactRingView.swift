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
    var isLoading: Bool = false // Shows grey ring with shimmer when true
    var isRefreshing: Bool = false // Shows "Calculating" status without grey ring (for refreshes)
    
    @State private var animatedProgress: Double = 0.0
    @State private var numberOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = 0
    
    private let ringWidth: CGFloat = ComponentSizes.ringWidthSmall
    private let size: CGFloat = ComponentSizes.ringDiameterSmall
    private let initialDelay: Double = 0.14 // Global delay before animations start (30% faster)
    private let animationDuration: Double = 0.84 // Ring animation duration (30% faster than 1.2s)
    private let numberFadeDuration: Double = 0.28 // Number fade duration (30% faster than 0.4s)
    
    var body: some View {
        let _ = Logger.info("🎨 [CompactRingView] Rendering - title: '\(title)', isLoading: \(isLoading), isRefreshing: \(isRefreshing), score: \(score?.description ?? "nil")")
        
        return VStack(spacing: Spacing.sm) {
            ZStack {
                if isLoading {
                    // Loading state: Grey ring with subtle shimmer
                    Circle()
                        .stroke(Color.text.tertiary.opacity(0.3), lineWidth: ringWidth)
                        .frame(width: size, height: size)
                    
                    // Subtle shimmer effect
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(
                                colors: [.clear, Color.text.tertiary.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(shimmerOffset))
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                shimmerOffset = 360
                            }
                        }
                } else {
                    // Normal state: Background ring
                    Circle()
                        .stroke(ColorPalette.backgroundTertiary, lineWidth: ringWidth)
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
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.text.primary)
                            .opacity(numberOpacity)
                    }
                }
            }
            
            // Title - show "Calculating" when loading or refreshing, otherwise show band
            if isLoading || isRefreshing {
                Text("Calculating")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.text.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            } else if score != nil {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.text.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            Logger.info("🎬 [CompactRingView] onAppear for '\(title)' - isLoading: \(isLoading), score: \(score?.description ?? "nil")")
            // Trigger animation when view appears with a score (not in loading state)
            guard !isLoading, score != nil else {
                Logger.info("🎬 [CompactRingView] Skipping onAppear animation for '\(title)' - isLoading: \(isLoading), score: \(score?.description ?? "nil")")
                return
            }
            
            Logger.info("🎬 [CompactRingView] Starting animation on appear for '\(title)' with score: \(score!)")
            // Small delay to ensure view is laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateRing()
            }
        }
        .onChange(of: animationTrigger) { oldValue, newValue in
            Logger.info("🎬 [CompactRingView] animationTrigger CHANGED for '\(title)' - \(oldValue) → \(newValue)")
            // Animate when trigger changes (for refreshes)
            guard score != nil else {
                Logger.info("🎬 [CompactRingView] Skipping onChange animation for '\(title)' - score is nil")
                return
            }
            
            Logger.info("🎬 [CompactRingView] Starting animation on change for '\(title)' with score: \(score!)")
            // Reset and animate
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
        VStack(spacing: Spacing.xl) {
            // Normal state
            HStack(spacing: Spacing.lg) {
                CompactRingView(score: 85, title: "Recovery", band: RecoveryScore.RecoveryBand.optimal, animationDelay: 0.0, action: {}, centerText: nil, animationTrigger: UUID(), isLoading: false)
                CompactRingView(score: 55, title: "Sleep Quality", band: SleepScore.SleepBand.good, animationDelay: 0.1, action: {}, centerText: nil, animationTrigger: UUID(), isLoading: false)
                CompactRingView(score: 70, title: "Moderate", band: StrainScore.StrainBand.moderate, animationDelay: 0.2, action: {}, centerText: "12.5", animationTrigger: UUID(), isLoading: false)
            }
            
            // Loading state
            HStack(spacing: Spacing.lg) {
                CompactRingView(score: nil, title: "Recovery", band: RecoveryScore.RecoveryBand.optimal, animationDelay: 0.0, action: {}, centerText: nil, animationTrigger: UUID(), isLoading: true)
                CompactRingView(score: nil, title: "Sleep Quality", band: SleepScore.SleepBand.good, animationDelay: 0.1, action: {}, centerText: nil, animationTrigger: UUID(), isLoading: true)
                CompactRingView(score: nil, title: "Moderate", band: StrainScore.StrainBand.moderate, animationDelay: 0.2, action: {}, centerText: nil, animationTrigger: UUID(), isLoading: true)
            }
        }
        .padding()
    }
}
