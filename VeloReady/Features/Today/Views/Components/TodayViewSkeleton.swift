import SwiftUI

/// Skeleton loading state for Today view
/// Shows layout placeholders with shimmer animation
/// Displayed after central branding animation, before real content
struct TodayViewSkeleton: View {
    @State private var shimmerOffset: CGFloat = -1
    @Binding var isVisible: Bool
    
    var body: some View {
        ZStack {
            Color.background.app
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    // Recovery Metrics Section (3 rings)
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.xxl) {
                            skeletonRing()
                            skeletonRing()
                            skeletonRing()
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
                    
                    // AI Brief skeleton
                    skeletonCard(height: 120)
                    
                    // Latest Activity skeleton
                    skeletonCard(height: 200)
                    
                    // Steps skeleton
                    skeletonCard(height: 100)
                    
                    // Calories skeleton
                    skeletonCard(height: 100)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            Logger.info("✨ [TodayViewSkeleton] Appeared - showing shimmer skeleton")
            startShimmerAnimation()
        }
        .onChange(of: isVisible) { newValue in
            Logger.info("✨ [TodayViewSkeleton] isVisible changed to: \(newValue)")
        }
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
            .fill(Color.background.secondary.opacity(0.5))
            .frame(width: 80, height: 80)
            .overlay(shimmerOverlay)
    }
    
    // MARK: - Shimmer Effect
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.15),
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
    TodayViewSkeleton(isVisible: .constant(true))
}

