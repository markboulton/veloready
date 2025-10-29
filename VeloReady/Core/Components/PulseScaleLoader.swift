import SwiftUI

/// Pulse-scale loader animation matching CSS
/// - Outer circle: pulses (scales 1.0 → 1.2 → 1.0)
/// - Inner circle: scales up (0 → 1)
struct PulseScaleLoader: View {
    @State private var outerScale: CGFloat = 1.0
    @State private var innerScale: CGFloat = 0.0
    
    let size: CGFloat
    let borderWidth: CGFloat
    
    init(size: CGFloat = 80, borderWidth: CGFloat = 5) {
        self.size = size
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        ZStack {
            // Outer circle - pulse animation (adaptive: black in light mode, white in dark mode)
            Circle()
                .stroke(Color.text.primary, lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(outerScale)
            
            // Inner circle - scale up animation (grey)
            Circle()
                .stroke(Color(white: 0.5), lineWidth: borderWidth)
                .frame(width: size, height: size)
                .scaleEffect(innerScale)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Outer circle: pulse animation
        // 0-60%: 1.0, 80%: 1.2, 100%: 1.0
        animateOuterCircle()
        
        // Inner circle: scale up animation
        // 0-60%: 0, 60-100%: 1
        animateInnerCircle()
    }
    
    private func animateOuterCircle() {
        // 0-600ms: scale 1.0
        withAnimation(.linear(duration: 0.6)) {
            outerScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 600-800ms: scale 1.2
            withAnimation(.linear(duration: 0.2)) {
                outerScale = 1.2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 800-1000ms: scale 1.0
                withAnimation(.linear(duration: 0.2)) {
                    outerScale = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Loop
                    animateOuterCircle()
                }
            }
        }
    }
    
    private func animateInnerCircle() {
        // 0-600ms: scale 0
        withAnimation(.linear(duration: 0.6)) {
            innerScale = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 600-1000ms: scale 1
            withAnimation(.linear(duration: 0.4)) {
                innerScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Loop
                animateInnerCircle()
            }
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
