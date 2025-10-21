import SwiftUI

/// Liquid Glass Design System
/// Inspired by visionOS glass materials and iOS modern design principles
/// Combines translucency, depth, and fluid motion for an elevated user experience

// MARK: - Glass Materials

enum GlassMaterial {
    case thin       // Light translucency, subtle blur
    case regular    // Standard glass effect
    case thick      // Heavy blur, more opacity
    case ultraThin  // Minimal effect, maximum content visibility
    
    var material: Material {
        switch self {
        case .thin:
            return .thin
        case .regular:
            return .regular
        case .thick:
            return .thick
        case .ultraThin:
            return .ultraThin
        }
    }
    
    var blur: CGFloat {
        switch self {
        case .ultraThin: return 8
        case .thin: return 16
        case .regular: return 24
        case .thick: return 32
        }
    }
    
    var opacity: Double {
        switch self {
        case .ultraThin: return 0.5
        case .thin: return 0.6
        case .regular: return 0.7
        case .thick: return 0.85
        }
    }
}

// MARK: - Glass Modifiers

struct GlassBackground: ViewModifier {
    let material: GlassMaterial
    let tint: Color?
    let cornerRadius: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base translucent layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            (tint ?? (colorScheme == .dark ? Color.black : Color.white))
                                .opacity(material.opacity)
                        )
                    
                    // Glass blur effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                // Subtle border for definition
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

struct GlassCard: ViewModifier {
    let material: GlassMaterial
    let elevation: GlassElevation
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .modifier(GlassBackground(
                material: material,
                tint: nil,
                cornerRadius: 16
            ))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                radius: isPressed ? elevation.shadowRadius * 0.5 : elevation.shadowRadius,
                x: 0,
                y: isPressed ? elevation.yOffset * 0.5 : elevation.yOffset
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Elevation System

enum GlassElevation {
    case flat       // No shadow
    case low        // Subtle elevation
    case medium     // Standard cards
    case high       // Prominent elements
    case floating   // Floating UI elements
    
    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .low: return 4
        case .medium: return 8
        case .high: return 16
        case .floating: return 24
        }
    }
    
    var yOffset: CGFloat {
        switch self {
        case .flat: return 0
        case .low: return 2
        case .medium: return 4
        case .high: return 8
        case .floating: return 12
        }
    }
}

// MARK: - Fluid Animations

enum FluidAnimation {
    /// Quick, snappy spring for UI feedback
    static let snap = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Smooth, flowing spring for transitions
    static let flow = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Gentle spring for subtle movements
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.9)
    
    /// Bouncy spring for playful interactions
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    
    /// Smooth ease for linear movements
    static let ease = Animation.easeInOut(duration: 0.3)
    
    /// Quick ease for state changes
    static let quick = Animation.easeOut(duration: 0.2)
}

// MARK: - Interactive States

struct InteractiveGlassButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

struct PressableGlassCard: ViewModifier {
    @State private var isPressed = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(FluidAnimation.snap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let speed: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(45))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: speed)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.3), radius: 4, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.2), radius: 8, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.1), radius: 16, x: 0, y: 0)
    }
}

// MARK: - Depth Layers

struct DepthLayer: ViewModifier {
    let depth: CGFloat
    @State private var offset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset.width * depth, y: offset.height * depth)
            .animation(FluidAnimation.gentle, value: offset)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass background with material and corner radius
    func glassBackground(
        material: GlassMaterial = .regular,
        tint: Color? = nil,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(GlassBackground(material: material, tint: tint, cornerRadius: cornerRadius))
    }
    
    /// Apply glass card style with elevation
    func glassCard(
        material: GlassMaterial = .regular,
        elevation: GlassElevation = .medium
    ) -> some View {
        modifier(GlassCard(material: material, elevation: elevation))
    }
    
    /// Make view pressable with glass effect
    func pressableGlass(action: @escaping () -> Void) -> some View {
        modifier(PressableGlassCard(action: action))
    }
    
    /// Add shimmer animation
    func shimmer(speed: Double = 2.0) -> some View {
        modifier(ShimmerEffect(speed: speed))
    }
    
    /// Add glow effect
    func glow(color: Color, intensity: CGFloat = 1.0) -> some View {
        modifier(GlowEffect(color: color, intensity: intensity))
    }
    
    /// Add depth layer parallax
    func depthLayer(_ depth: CGFloat = 0.05) -> some View {
        modifier(DepthLayer(depth: depth))
    }
    
    /// Fluid spring animation
    func fluidAnimation(value: some Equatable) -> some View {
        animation(FluidAnimation.flow, value: value)
    }
    
    /// Snap spring animation
    func snapAnimation(value: some Equatable) -> some View {
        animation(FluidAnimation.snap, value: value)
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    let material: GlassMaterial
    let tint: Color?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(material: GlassMaterial = .regular, tint: Color? = nil) {
        self.material = material
        self.tint = tint
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassBackground(material: material, tint: tint, cornerRadius: 12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - Glass Colors

/// Colors optimized for glass surfaces
struct GlassColors {
    /// Accent colors with reduced saturation for glass
    static let primaryAccent = Color.blue.opacity(0.8)
    static let secondaryAccent = Color.purple.opacity(0.8)
    static let successAccent = Color.green.opacity(0.8)
    static let warningAccent = Color.orange.opacity(0.8)
    static let errorAccent = Color.red.opacity(0.8)
    
    /// Tints for glass surfaces
    static let glassTintLight = Color.white.opacity(0.7)
    static let glassTintDark = Color.black.opacity(0.7)
    static let glassTintPurple = Color.purple.opacity(0.3)
    static let glassTintBlue = Color.blue.opacity(0.3)
}

// MARK: - Preview Helpers

#if DEBUG
struct LiquidGlassPreview: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Glass card examples
                Text("Liquid Glass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Text("Ultra Thin")
                        .padding()
                        .glassCard(material: .ultraThin, elevation: .low)
                    
                    Text("Thin")
                        .padding()
                        .glassCard(material: .thin, elevation: .medium)
                    
                    Text("Regular")
                        .padding()
                        .glassCard(material: .regular, elevation: .medium)
                    
                    Text("Thick")
                        .padding()
                        .glassCard(material: .thick, elevation: .high)
                }
                .padding()
                
                // Glass button
                Button("Glass Button") {}
                    .buttonStyle(GlassButtonStyle())
                
                // Glowing element
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .glow(color: .blue, intensity: 1.0)
            }
            .padding()
        }
    }
}

#Preview {
    LiquidGlassPreview()
}
#endif
