import SwiftUI

/// SVG-based pulse and scale loader animation
/// Translates CSS animation into SwiftUI with two concentric circles
/// - Outer circle: pulses (scales 1.0 → 1.2 → 1.0)
/// - Inner circle: scales up (0 → 1)
struct PulseScaleLoader: View {
    @State private var animationPhase: Double = 0
    
    let size: CGFloat = 48
    let borderWidth: CGFloat = 5
    let color: Color
    
    var body: some View {
        ZStack {
            // Outer circle - pulse animation
            Circle()
                .stroke(color, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(outerCircleScale)
            
            // Inner circle - scale up animation
            Circle()
                .stroke(color, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(innerCircleScale)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // Outer circle: pulse animation
    // 0-60%: scale 1.0, 60-80%: scale 1.2, 80-100%: scale 1.0
    private var outerCircleScale: CGFloat {
        let normalized = animationPhase.truncatingRemainder(dividingBy: 1.0)
        
        if normalized < 0.6 || normalized >= 0.8 {
            return 1.0
        } else {
            // 60-80%: interpolate from 1.0 to 1.2 to 1.0
            let localProgress = (normalized - 0.6) / 0.2
            return 1.0 + (0.2 * sin(localProgress * .pi))
        }
    }
    
    // Inner circle: scale up animation
    // 0-60%: scale 0, 60-100%: scale 1
    private var innerCircleScale: CGFloat {
        let normalized = animationPhase.truncatingRemainder(dividingBy: 1.0)
        
        if normalized < 0.6 {
            return 0.0
        } else {
            // 60-100%: interpolate from 0 to 1
            let localProgress = (normalized - 0.6) / 0.4
            return localProgress
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        PulseScaleLoader(color: .white)
        PulseScaleLoader(color: ColorPalette.blue)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background.primary)
}
