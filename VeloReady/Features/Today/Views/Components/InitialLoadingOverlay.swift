import SwiftUI

/// Initial loading overlay shown on app launch
/// Shows animated rings with cached scores for smooth UX
/// Displays for minimum 1.5 seconds before fading out
struct InitialLoadingOverlay: View {
    let cachedRecoveryScore: Int?
    let cachedSleepScore: Int?
    let cachedStrainScore: Double?
    @Binding var isVisible: Bool
    
    @State private var hasShownMinimumDuration = false
    
    var body: some View {
        ZStack {
            Color.background.app
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Animated rings with cached scores
                HStack(spacing: Spacing.xxl) {
                    // Recovery ring
                    if let score = cachedRecoveryScore {
                        AnimatedRingWithScore(
                            score: score,
                            title: "Recovery",
                            color: RecoveryScore.RecoveryBand.optimal.colorToken,
                            delay: 0.0
                        )
                    } else {
                        AnimatedRingPlaceholder(delay: 0.0)
                    }
                    
                    // Sleep ring
                    if let score = cachedSleepScore {
                        AnimatedRingWithScore(
                            score: score,
                            title: "Sleep",
                            color: SleepScore.SleepBand.optimal.colorToken,
                            delay: 0.2
                        )
                    } else {
                        AnimatedRingPlaceholder(delay: 0.2)
                    }
                    
                    // Strain ring
                    if let score = cachedStrainScore {
                        AnimatedRingWithScore(
                            score: Int((score / 10) * 100),
                            title: "Strain",
                            color: StrainScore.StrainBand.moderate.colorToken,
                            delay: 0.4
                        )
                    } else {
                        AnimatedRingPlaceholder(delay: 0.4)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                
                Spacer()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            Logger.info("🎬 [InitialLoadingOverlay] Appeared - showing animated rings")
            Logger.info("   Cached scores - Recovery: \(cachedRecoveryScore ?? -1), Sleep: \(cachedSleepScore ?? -1), Strain: \(cachedStrainScore ?? -1)")
            
            // Ensure minimum display duration of 1.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                await MainActor.run {
                    hasShownMinimumDuration = true
                    Logger.info("🎬 [InitialLoadingOverlay] Minimum duration complete - ready to hide")
                    checkIfShouldHide()
                }
            }
        }
        .onChange(of: isVisible) { newValue in
            Logger.info("🎬 [InitialLoadingOverlay] isVisible changed to: \(newValue)")
        }
    }
    
    private func checkIfShouldHide() {
        if hasShownMinimumDuration && !isVisible {
            Logger.info("🎬 [InitialLoadingOverlay] Hiding overlay - fading to main UI")
        }
    }
}

// MARK: - Animated Ring Components

private struct AnimatedRingWithScore: View {
    let score: Int
    let title: String
    let color: Color
    let delay: Double
    
    @State private var progress: CGFloat = 0
    @State private var showScore = false
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Animated progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                // Score text
                if showScore {
                    Text("\(score)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .transition(.opacity)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            // Animate ring fill
            withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                progress = CGFloat(score) / 100.0
            }
            
            // Show score after ring animation
            withAnimation(.easeIn(duration: 0.2).delay(delay + 0.6)) {
                showScore = true
            }
        }
    }
}

private struct AnimatedRingPlaceholder: View {
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        Color.gray.opacity(0.5),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            Text("...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    InitialLoadingOverlay(
        cachedRecoveryScore: 91,
        cachedSleepScore: 88,
        cachedStrainScore: 2.4,
        isVisible: .constant(true)
    )
}

