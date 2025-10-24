import SwiftUI

/// SVG-based pulse and scale loader animation
/// Translates CSS animation into SwiftUI with two concentric circles
/// - Outer circle: pulses (scales 1.0 → 1.2 → 1.0)
/// - Inner circle: scales up (0 → 1)
struct PulseScaleLoader: View {
    @State private var outerScale: CGFloat = 1.0
    @State private var innerScale: CGFloat = 0.0
    
    let size: CGFloat = 48
    let borderWidth: CGFloat = 5
    let color: Color
    
    var body: some View {
        ZStack {
            // Outer circle - pulse animation
            Circle()
                .stroke(color, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(outerScale)
            
            // Inner circle - scale up animation
            Circle()
                .stroke(color, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(innerScale)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Outer circle animation: pulse
        // 0-60%: 1.0, 60-80%: 1.2, 80-100%: 1.0
        let outerSequence: [(duration: Double, scale: CGFloat)] = [
            (duration: 0.6, scale: 1.0),
            (duration: 0.2, scale: 1.2),
            (duration: 0.2, scale: 1.0)
        ]
        
        // Inner circle animation: scale up
        // 0-60%: 0, 60-100%: 1
        let innerSequence: [(duration: Double, scale: CGFloat)] = [
            (duration: 0.6, scale: 0.0),
            (duration: 0.4, scale: 1.0)
        ]
        
        animateOuter(sequence: outerSequence, index: 0)
        animateInner(sequence: innerSequence, index: 0)
    }
    
    private func animateOuter(sequence: [(duration: Double, scale: CGFloat)], index: Int) {
        let current = sequence[index % sequence.count]
        
        withAnimation(.linear(duration: current.duration)) {
            outerScale = current.scale
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + current.duration) {
            animateOuter(sequence: sequence, index: index + 1)
        }
    }
    
    private func animateInner(sequence: [(duration: Double, scale: CGFloat)], index: Int) {
        let current = sequence[index % sequence.count]
        
        withAnimation(.linear(duration: current.duration)) {
            innerScale = current.scale
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + current.duration) {
            animateInner(sequence: sequence, index: index + 1)
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
