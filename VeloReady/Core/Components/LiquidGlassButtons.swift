import SwiftUI

/// Button styles using Liquid Glass design language

// MARK: - Primary Button Style

struct PrimaryGlassButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: isEnabled ? [
                            Color.blue,
                            Color.blue.opacity(0.8)
                        ] : [
                            Color.gray.opacity(0.5),
                            Color.gray.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Glass overlay
                    Color.white.opacity(0.15)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isEnabled ? Color.blue.opacity(0.3) : Color.clear,
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryGlassButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(Color.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .glassBackground(material: .thin, tint: nil, cornerRadius: 14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - Compact Glass Button

struct CompactGlassButton: ButtonStyle {
    let tintColor: Color?
    
    init(tintColor: Color? = nil) {
        self.tintColor = tintColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(tintColor ?? .blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassBackground(material: .thin, tint: nil, cornerRadius: 10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

struct IconGlassButton: ButtonStyle {
    let size: CGFloat
    let tintColor: Color?
    
    init(size: CGFloat = 44, tintColor: Color? = nil) {
        self.size = size
        self.tintColor = tintColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(tintColor ?? .primary)
            .frame(width: size, height: size)
            .glassBackground(material: .thin, tint: nil, cornerRadius: size / 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(FluidAnimation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: ButtonStyle {
    let color: Color
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(FluidAnimation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Pill Button Style

struct PillGlassButton: ButtonStyle {
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.1))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct DestructiveGlassButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Color.white.opacity(0.15)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        Color.white.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(FluidAnimation.snap, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply primary glass button style
    func primaryGlassButton() -> some View {
        buttonStyle(PrimaryGlassButton())
    }
    
    /// Apply secondary glass button style
    func secondaryGlassButton() -> some View {
        buttonStyle(SecondaryGlassButton())
    }
    
    /// Apply compact glass button style
    func compactGlassButton(tintColor: Color? = nil) -> some View {
        buttonStyle(CompactGlassButton(tintColor: tintColor))
    }
    
    /// Apply icon glass button style
    func iconGlassButton(size: CGFloat = 44, tintColor: Color? = nil) -> some View {
        buttonStyle(IconGlassButton(size: size, tintColor: tintColor))
    }
    
    /// Apply floating action button style
    func floatingActionButton(color: Color = .blue) -> some View {
        buttonStyle(FloatingActionButton(color: color))
    }
    
    /// Apply pill button style
    func pillGlassButton(color: Color = .blue) -> some View {
        buttonStyle(PillGlassButton(color: color))
    }
    
    /// Apply destructive button style
    func destructiveGlassButton() -> some View {
        buttonStyle(DestructiveGlassButton())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                Text("Liquid Glass Buttons")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button("Primary Button") {}
                        .primaryGlassButton()
                    
                    Button("Secondary Button") {}
                        .secondaryGlassButton()
                    
                    Button("Compact Button") {}
                        .compactGlassButton()
                    
                    HStack(spacing: 12) {
                        Button {
                        } label: {
                            Image(systemName: "heart.fill")
                        }
                        .iconGlassButton()
                        
                        Button {
                        } label: {
                            Image(systemName: "star.fill")
                        }
                        .iconGlassButton()
                        
                        Button {
                        } label: {
                            Image(systemName: "plus")
                        }
                        .floatingActionButton()
                    }
                    
                    HStack(spacing: 8) {
                        Button("Tag 1") {}
                            .pillGlassButton()
                        
                        Button("Tag 2") {}
                            .pillGlassButton(color: .green)
                        
                        Button("Tag 3") {}
                            .pillGlassButton(color: .orange)
                    }
                    
                    Button("Destructive Action") {}
                        .destructiveGlassButton()
                }
                .padding()
            }
            .padding()
        }
    }
}
