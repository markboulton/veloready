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
/// Width matches CardContainer constraints (no external padding)
struct SkeletonActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 20)
            
            // Metadata row skeleton
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                    }
                    
                    if index != 3 {
                        Spacer()
                    }
                }
            }
            
            // Map skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 300)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background.card)
        )
        .onAppear {
            Logger.debug("🖥️ [Skeleton] Activity card skeleton rendered")
        }
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
