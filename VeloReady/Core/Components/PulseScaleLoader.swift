import SwiftUI

/// SVG-based pulse and scale loader animation
/// Translates CSS animation into SwiftUI with two concentric circles
/// - Outer circle: pulses (scales 1.0 → 1.2 → 1.0)
/// - Inner circle: scales up (0 → 1)
struct PulseScaleLoader: View {
    @State private var animationProgress: CGFloat = 0
    
    let size: CGFloat = 120
    let borderWidth: CGFloat = 5
    let outerColor: Color = .white
    let innerColor: Color = Color(white: 0.5)
    
    var outerScale: CGFloat {
        let normalized = animationProgress.truncatingRemainder(dividingBy: 1.0)
        if normalized < 0.6 || normalized >= 0.8 {
            return 1.0
        } else {
            let localProgress = (normalized - 0.6) / 0.2
            return 1.0 + (0.2 * sin(localProgress * .pi))
        }
    }
    
    var innerScale: CGFloat {
        let normalized = animationProgress.truncatingRemainder(dividingBy: 1.0)
        return normalized < 0.6 ? 0.0 : (normalized - 0.6) / 0.4
    }
    
    var body: some View {
        ZStack {
            // Outer circle - pulse animation
            Circle()
                .stroke(outerColor, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(outerScale)
            
            // Inner circle - scale up animation (grey)
            Circle()
                .stroke(innerColor, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(innerScale)
            
            // VeloReady icon in the center (300% larger = 120pt)
            VeloReadyIcon()
                .frame(width: 120, height: 120)
                .foregroundColor(.white)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Use continuous smooth animation like CSS
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
    }
}

// MARK: - VeloReady Icon

struct VeloReadyIcon: View {
    var body: some View {
        Canvas { context, size in
            // Scale the SVG paths to fit the canvas
            let scale = size.width / 80.0
            
            // First path (left arrow)
            var path1 = Path()
            path1.move(to: CGPoint(x: 0 * scale, y: -10.867 * scale))
            path1.addCurve(
                to: CGPoint(x: -0.631 * scale, y: -11.256 * scale),
                control1: CGPoint(x: -0.107 * scale, y: -11.08 * scale),
                control2: CGPoint(x: -0.391 * scale, y: -11.256 * scale)
            )
            path1.addLine(to: CGPoint(x: -5.229 * scale, y: -11.256 * scale))
            path1.addLine(to: CGPoint(x: -7.294 * scale, y: -7.123 * scale))
            path1.addLine(to: CGPoint(x: -3.185 * scale, y: -7.123 * scale))
            path1.addCurve(
                to: CGPoint(x: -2.554 * scale, y: -6.734 * scale),
                control1: CGPoint(x: -2.944 * scale, y: -7.123 * scale),
                control2: CGPoint(x: -2.661 * scale, y: -6.949 * scale)
            )
            path1.addLine(to: CGPoint(x: 1.008 * scale, y: 0.389 * scale))
            path1.addLine(to: CGPoint(x: 3.123 * scale, y: -3.842 * scale))
            path1.addCurve(
                to: CGPoint(x: 3.122 * scale, y: -4.621 * scale),
                control1: CGPoint(x: 3.229 * scale, y: -4.055 * scale),
                control2: CGPoint(x: 3.229 * scale, y: -4.407 * scale)
            )
            path1.closeSubpath()
            
            // Second path (right arrow)
            var path2 = Path()
            path2.move(to: CGPoint(x: 0 * scale, y: 3.379 * scale))
            path2.addCurve(
                to: CGPoint(x: -0.63 * scale, y: 2.989 * scale),
                control1: CGPoint(x: -0.239 * scale, y: 3.379 * scale),
                control2: CGPoint(x: -0.523 * scale, y: 3.204 * scale)
            )
            path2.addLine(to: CGPoint(x: -4.191 * scale, y: -4.133 * scale))
            path2.addLine(to: CGPoint(x: -6.307 * scale, y: 0.098 * scale))
            path2.addCurve(
                to: CGPoint(x: -6.307 * scale, y: 0.876 * scale),
                control1: CGPoint(x: -6.414 * scale, y: 0.311 * scale),
                control2: CGPoint(x: -6.414 * scale, y: 0.662 * scale)
            )
            path2.addLine(to: CGPoint(x: -3.184 * scale, y: 7.122 * scale))
            path2.addCurve(
                to: CGPoint(x: -2.554 * scale, y: 7.512 * scale),
                control1: CGPoint(x: -2.793 * scale, y: 7.512 * scale),
                control2: CGPoint(x: -2.793 * scale, y: 7.512 * scale)
            )
            path2.addLine(to: CGPoint(x: 2.044 * scale, y: 7.512 * scale))
            path2.addLine(to: CGPoint(x: 4.11 * scale, y: 3.379 * scale))
            path2.closeSubpath()
            
            // Draw paths centered
            let offsetX = size.width / 2 - (2 * scale)
            let offsetY = size.height / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.fill(path1, with: .color(.white))
            context.fill(path2, with: .color(.white))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        PulseScaleLoader()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background.primary)
}
