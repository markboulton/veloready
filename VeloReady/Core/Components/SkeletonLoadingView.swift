import SwiftUI

/// Skeleton loading placeholder with shimmer effect
struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 100, cornerRadius: CGFloat = 12) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.background.tertiary,
                        ColorScale.gray300,
                        Color.background.tertiary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .cornerRadius(cornerRadius)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(90))
                    .offset(x: isAnimating ? 400 : -400)
            )
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

/// Pre-made skeleton placeholders for common Today page components
struct SkeletonPlaceholders {
    
    /// Three ring skeleton placeholders
    static var recoveryRings: some View {
        HStack(spacing: Spacing.md) {
            ForEach(0..<3) { _ in
                VStack(spacing: Spacing.md) {
                    Circle()
                        .fill(Color.background.tertiary)
                        .frame(width: 100, height: 100)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.background.tertiary)
                        .frame(width: 60, height: 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    /// AI Brief skeleton
    static var aiBrief: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.background.tertiary)
                    .frame(width: 80, height: 16)
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.background.tertiary)
                .frame(height: 14)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.background.tertiary)
                .frame(height: 14)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.background.tertiary)
                .frame(width: 200, height: 14)
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    /// Latest ride skeleton
    static var latestRide: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.background.tertiary)
                    .frame(width: 120, height: 20)
                Spacer()
            }
            
            HStack(spacing: 20) {
                ForEach(0..<4) { _ in
                    VStack(spacing: Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.background.tertiary)
                            .frame(width: 50, height: 18)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.background.tertiary)
                            .frame(width: 40, height: 12)
                    }
                }
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    /// Activity list skeleton
    static var activityList: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<3) { _ in
                HStack(spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.background.tertiary)
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.background.tertiary)
                            .frame(width: 150, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.background.tertiary)
                            .frame(width: 100, height: 12)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.background.secondary)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview

struct SkeletonLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                SkeletonLoadingView(height: 100)
                SkeletonPlaceholders.recoveryRings
                SkeletonPlaceholders.aiBrief
                SkeletonPlaceholders.latestRide
                SkeletonPlaceholders.activityList
            }
            .padding()
        }
    }
}
