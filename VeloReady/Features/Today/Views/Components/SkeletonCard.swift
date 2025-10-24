import SwiftUI

/// Skeleton loading placeholder for cards
struct SkeletonCard: View {
    let height: CGFloat
    @State private var isAnimating = false
    
    init(height: CGFloat = 120) {
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(ColorPalette.backgroundSecondary)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                ColorPalette.backgroundTertiary.opacity(0.5),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .clipped()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton for steps/calories cards
struct SkeletonStatsCard: View {
    var body: some View {
        SkeletonCard(height: 100)
    }
}

/// Skeleton for activity card
/// Height matches LatestActivityCardV2 with map (~400px total)
struct SkeletonActivityCard: View {
    var body: some View {
        SkeletonCard(height: 400)
    }
}

/// Skeleton for recent activities section
struct SkeletonRecentActivities: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            SkeletonCard(height: 120)
            SkeletonCard(height: 120)
            SkeletonCard(height: 120)
        }
    }
}
