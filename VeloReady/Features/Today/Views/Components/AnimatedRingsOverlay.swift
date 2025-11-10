import SwiftUI

/// Animated rings overlay for app launch
/// Shows the same elegant animation as onboarding for consistency
struct AnimatedRingsOverlay: View {
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var rotation3: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.background.app
                .ignoresSafeArea()
            
            // Animated rings
            VStack(spacing: 40) {
                // Three rings stacked vertically (like the compact rings layout)
                AnimatedRing(rotation: rotation1, color: .green, delay: 0.0)
                AnimatedRing(rotation: rotation2, color: .blue, delay: 0.1)
                AnimatedRing(rotation: rotation3, color: .orange, delay: 0.2)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Smooth fade in and scale
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
                scale = 1.0
            }
            
            // Continuous rotation animation (like onboarding)
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                rotation2 = 360
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation3 = 360
            }
        }
    }
}

/// Single animated ring component
private struct AnimatedRing: View {
    let rotation: Double
    let color: Color
    let delay: Double
    
    @State private var startAnimation = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                color.opacity(0.3),
                style: StrokeStyle(
                    lineWidth: 12,
                    lineCap: .round
                )
            )
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))
            .opacity(startAnimation ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    startAnimation = true
                }
            }
    }
}

#Preview {
    AnimatedRingsOverlay()
}

