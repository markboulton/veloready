import SwiftUI
import UIKit

/// Floating liquid glass tab bar with animations and transitions
/// Inspired by iOS floating menu design with translucent material
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    @Environment(\.colorScheme) var colorScheme
    @State private var indicatorOffset: CGFloat = 0
    @Namespace private var animation
    @State private var previousSelection: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == index,
                    namespace: animation
                ) {
                    withAnimation(FluidAnimation.bouncy) {
                        selectedTab = index
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            // White thin material background
            RoundedRectangle(cornerRadius: 32)
                .fill(.thinMaterial)
                .overlay(
                    // Very subtle edge definition
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.15),
            radius: 20,
            x: 0,
            y: 8
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                HapticFeedback.light()
                previousSelection = oldValue
            }
        }
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    @AccessibilityFocusState private var isAccessibilityFocused: Bool
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection pill background - elevated
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.background.elevated)
                            .matchedGeometryEffect(id: "tab_background", in: namespace)
                            .frame(width: 60, height: 36)
                    }
                    
                    // Icon - Using SF Symbol with iOS 17+ effects
                    Group {
                        if #available(iOS 17.0, *) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    isSelected
                                        ? ColorScale.blueAccent
                                        : Color.text.primary
                                )
                                .scaleEffect(isPressed ? 0.85 : 1.0)
                                .symbolEffect(.bounce, value: isSelected)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    isSelected
                                        ? ColorScale.blueAccent
                                        : Color.text.primary
                                )
                                .scaleEffect(isPressed ? 0.85 : 1.0)
                        }
                    }
                }
                
                // Label
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(Color.text.primary)
            }
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "" : "Double tap to switch to \(tab.title) tab")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Tab Item Model

struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        FloatingTabBar(
            selectedTab: .constant(0),
            tabs: [
                TabItem(title: "Today", icon: "house.fill"),
                TabItem(title: "Activities", icon: "figure.run"),
                TabItem(title: "Trends", icon: "chart.xyaxis.line"),
                TabItem(title: "Settings", icon: "gearshape.fill")
            ]
        )
    }
    .background(
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    )
}
