import SwiftUI

/// Sheet and modal presentations with liquid glass styling

// MARK: - Glass Sheet Modifier

struct GlassSheet<Content: View>: ViewModifier {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func body(content: Content) -> some View {
        content
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(24)
            .presentationBackgroundInteraction(.enabled)
    }
}

// MARK: - Glass Navigation Bar

struct GlassNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Floating Panel

struct FloatingPanel<Content: View>: View {
    let content: Content
    let width: CGFloat?
    @Environment(\.colorScheme) var colorScheme
    
    init(width: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: width)
            .padding(20)
            .glassBackground(material: .regular, tint: nil, cornerRadius: 20)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
                radius: 20,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Glass Alert

struct GlassAlert<Content: View, Actions: View>: View {
    let title: String
    let message: String?
    let icon: String?
    let iconColor: Color?
    let content: Content
    let actions: Actions
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        title: String,
        message: String? = nil,
        icon: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() },
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
        self.actions = actions()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundColor(iconColor ?? .blue)
                    .padding(.top, 8)
            }
            
            // Title
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
            
            // Message
            if let message = message {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Custom content
            content
            
            // Actions
            actions
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassBackground(material: .thick, tint: nil, cornerRadius: 24)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.2),
            radius: 24,
            x: 0,
            y: 12
        )
    }
}

// MARK: - Toast Notification

struct GlassToast: View {
    let message: String
    let icon: String?
    let iconColor: Color?
    @Binding var isShowing: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var offset: CGFloat = -100
    
    init(
        message: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        isShowing: Binding<Bool>
    ) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self._isShowing = isShowing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor ?? .primary)
            }
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(16)
        .glassBackground(material: .thick, tint: nil, cornerRadius: 14)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
            radius: 12,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 16)
        .offset(y: isShowing ? 0 : offset)
        .animation(FluidAnimation.bouncy, value: isShowing)
        .onAppear {
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Bottom Sheet

struct GlassBottomSheet<Content: View>: View {
    let content: Content
    @Binding var isPresented: Bool
    let height: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    @State private var dragOffset: CGFloat = 0
    
    init(
        isPresented: Binding<Bool>,
        height: CGFloat = 400,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.height = height
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(FluidAnimation.flow) {
                            isPresented = false
                        }
                    }
                
                // Sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 36, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        // Content
                        content
                            .frame(height: height - 25)
                    }
                    .frame(maxWidth: .infinity)
                    .glassBackground(material: .thick, tint: nil, cornerRadius: 0)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                            .size(width: UIScreen.main.bounds.width, height: height)
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: -8
                    )
                    .offset(y: max(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    withAnimation(FluidAnimation.flow) {
                                        isPresented = false
                                    }
                                }
                                dragOffset = 0
                            }
                    )
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(FluidAnimation.flow, value: isPresented)
    }
}

// MARK: - Context Menu

struct GlassContextMenu<Content: View, MenuContent: View>: View {
    let content: Content
    let menuContent: MenuContent
    @State private var showingMenu = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.content = content()
        self.menuContent = menuContent()
    }
    
    var body: some View {
        content
            .contextMenu {
                menuContent
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass sheet styling
    func glassSheet() -> some View {
        modifier(GlassSheet(content: { self }))
    }
    
    /// Apply glass navigation bar
    func glassNavigationBar() -> some View {
        modifier(GlassNavigationBar())
    }
    
    /// Apply glass tab bar
    func glassTabBar() -> some View {
        modifier(GlassTabBar())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            Text("Liquid Glass Sheets")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            FloatingPanel(width: 300) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Floating Panel")
                        .font(.headline)
                    
                    Text("This is a floating panel with glass material and depth.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            GlassAlert(
                title: "Glass Alert",
                message: "This is a beautiful glass alert with liquid styling",
                icon: "checkmark.circle.fill",
                iconColor: .green
            ) {
                HStack(spacing: 12) {
                    Button("Cancel") {}
                        .secondaryGlassButton()
                    
                    Button("Confirm") {}
                        .primaryGlassButton()
                }
            }
        }
        .padding()
    }
}
