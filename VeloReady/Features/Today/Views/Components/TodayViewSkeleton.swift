import SwiftUI

/// Skeleton loading state for Today view
/// Shows immediately on app launch with cached scores and shimmer effect
/// Provides smooth transition to real content when ready
struct TodayViewSkeleton: View {
    let cachedRecoveryScore: Int?
    let cachedSleepScore: Int?
    let cachedStrainScore: Double?
    
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Recovery Metrics Section with cached scores
                recoveryMetricsSkeletonSection
                
                // AI Brief skeleton
                skeletonCard(height: 120)
                
                // Latest Activity skeleton
                skeletonCard(height: 200)
                
                // Steps skeleton
                skeletonCard(height: 100)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    // MARK: - Recovery Metrics Skeleton
    
    private var recoveryMetricsSkeletonSection: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.xxl) {
                // Recovery ring
                if let score = cachedRecoveryScore {
                    CompactRingView(
                        score: score,
                        title: "Optimal",
                        band: .optimal,
                        animationDelay: 0.0,
                        action: {},
                        centerText: nil,
                        animationTrigger: UUID(),
                        isLoading: false,
                        isRefreshing: false
                    )
                    .opacity(0.7) // Slightly dimmed to indicate loading
                } else {
                    skeletonRing()
                }
                
                // Sleep ring
                if let score = cachedSleepScore {
                    CompactRingView(
                        score: score,
                        title: "Optimal",
                        band: SleepScore.SleepBand.optimal,
                        animationDelay: 0.1,
                        action: {},
                        centerText: nil,
                        animationTrigger: UUID(),
                        isLoading: false,
                        isRefreshing: false
                    )
                    .opacity(0.7)
                } else {
                    skeletonRing()
                }
                
                // Strain ring
                if let score = cachedStrainScore {
                    CompactRingView(
                        score: Int((score / 10) * 100), // Convert to 0-100
                        title: "Light",
                        band: StrainScore.StrainBand.moderate,
                        animationDelay: 0.2,
                        action: {},
                        centerText: nil,
                        animationTrigger: UUID(),
                        isLoading: false,
                        isRefreshing: false
                    )
                    .opacity(0.7)
                } else {
                    skeletonRing()
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background.secondary)
                .overlay(shimmerOverlay)
        )
    }
    
    // MARK: - Skeleton Components
    
    private func skeletonCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.background.secondary)
            .frame(height: height)
            .overlay(shimmerOverlay)
    }
    
    private func skeletonRing() -> some View {
        Circle()
            .fill(Color.background.secondary)
            .frame(width: 80, height: 80)
            .overlay(shimmerOverlay)
    }
    
    // MARK: - Shimmer Effect
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: shimmerOffset * geometry.size.width)
        }
        .clipped()
    }
    
    private func startShimmerAnimation() {
        withAnimation(
            .linear(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 2
        }
    }
}

#Preview {
    TodayViewSkeleton(
        cachedRecoveryScore: 91,
        cachedSleepScore: 88,
        cachedStrainScore: 2.4
    )
}

