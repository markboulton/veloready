import SwiftUI

// MARK: - Skeleton Loader Components
// Note: Shimmer effect is defined in WorkoutDetailView.swift

/// Skeleton rectangle with shimmer effect
struct SkeletonRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray6))
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// Skeleton card matching the Card component
struct SkeletonCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shimmer()
    }
}

/// Skeleton loader for recovery metrics (3 cards)
struct RecoveryMetricsSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    SkeletonRectangle(height: 60, cornerRadius: 30)
                    SkeletonRectangle(height: 16, cornerRadius: 4)
                    SkeletonRectangle(width: 80, height: 12, cornerRadius: 4)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Skeleton loader for latest ride panel
struct LatestRideSkeleton: View {
    var body: some View {
        SkeletonCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    SkeletonRectangle(width: 24, height: 24, cornerRadius: 12)
                    SkeletonRectangle(width: 120, height: 20, cornerRadius: 4)
                    Spacer()
                }
                
                // Title
                SkeletonRectangle(width: 200, height: 24, cornerRadius: 4)
                
                // Date
                SkeletonRectangle(width: 150, height: 16, cornerRadius: 4)
                
                // Metrics grid
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        SkeletonRectangle(height: 40, cornerRadius: 8)
                        SkeletonRectangle(height: 40, cornerRadius: 8)
                    }
                    HStack(spacing: 12) {
                        SkeletonRectangle(height: 40, cornerRadius: 8)
                        SkeletonRectangle(height: 40, cornerRadius: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Skeleton loader for AI brief
struct AIBriefSkeleton: View {
    var body: some View {
        SkeletonCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    SkeletonRectangle(width: 24, height: 24, cornerRadius: 12)
                    SkeletonRectangle(width: 100, height: 20, cornerRadius: 4)
                    Spacer()
                }
                
                // Content lines
                SkeletonRectangle(height: 16, cornerRadius: 4)
                SkeletonRectangle(width: 280, height: 16, cornerRadius: 4)
                SkeletonRectangle(width: 240, height: 16, cornerRadius: 4)
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Skeleton loader for activity list
struct ActivityListSkeleton: View {
    var body: some View {
        SkeletonCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    SkeletonRectangle(width: 24, height: 24, cornerRadius: 12)
                    SkeletonRectangle(width: 140, height: 20, cornerRadius: 4)
                    Spacer()
                }
                
                // Activity rows
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonRectangle(width: 40, height: 40, cornerRadius: 20)
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonRectangle(width: 180, height: 16, cornerRadius: 4)
                            SkeletonRectangle(width: 120, height: 14, cornerRadius: 4)
                        }
                        Spacer()
                        SkeletonRectangle(width: 60, height: 20, cornerRadius: 4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Skeleton loader for live activity (steps/calories)
struct LiveActivitySkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonRectangle(width: 80, height: 14, cornerRadius: 4)
                        SkeletonRectangle(width: 100, height: 28, cornerRadius: 4)
                        SkeletonRectangle(width: 60, height: 12, cornerRadius: 4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
