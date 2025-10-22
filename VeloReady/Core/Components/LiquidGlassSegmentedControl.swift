import SwiftUI

/// Liquid Glass styled segmented control with frosted glass effect
struct LiquidGlassSegmentedControl<T: Hashable>: View {
    let segments: [SegmentItem<T>]
    @Binding var selection: T
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Frosted glass background container
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(height: 40)
                
                // Animated selection indicator with liquid glass effect
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 2)
                    .frame(width: segmentWidth(containerWidth: geometry.size.width), height: 36)
                    .offset(x: selectedOffset(containerWidth: geometry.size.width))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selection)
                
                // Segment buttons
                HStack(spacing: 0) {
                    ForEach(segments, id: \.value) { segment in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = segment.value
                            }
                        }) {
                            segmentContent(for: segment)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(height: 40)
    }
    
    @ViewBuilder
    private func segmentContent(for segment: SegmentItem<T>) -> some View {
        let isSelected = selection == segment.value
        
        HStack(spacing: Spacing.xs) {
            if let icon = segment.icon {
                Image(systemName: icon)
                    .font(.system(size: TypeScale.xxs))
            }
            
            if let label = segment.label {
                Text(label)
                    .font(.system(size: TypeScale.xs, weight: isSelected ? .semibold : .medium))
            }
        }
        .foregroundColor(isSelected ? .white : Color.text.secondary)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func segmentWidth(containerWidth: CGFloat) -> CGFloat {
        let spacing: CGFloat = 4 // Internal padding
        return (containerWidth - spacing * 2) / CGFloat(segments.count)
    }
    
    private func selectedOffset(containerWidth: CGFloat) -> CGFloat {
        guard let selectedIndex = segments.firstIndex(where: { $0.value == selection }) else {
            return 2
        }
        let spacing: CGFloat = 2
        let segmentWidth = segmentWidth(containerWidth: containerWidth)
        return spacing + (segmentWidth * CGFloat(selectedIndex))
    }
}

// MARK: - Preview

#Preview("Liquid Glass Segmented Control") {
    VStack(spacing: 32) {
        LiquidGlassSegmentedControl(
            segments: [
                SegmentItem(value: 0, label: "7d"),
                SegmentItem(value: 1, label: "30d"),
                SegmentItem(value: 2, label: "60d")
            ],
            selection: .constant(0)
        )
        
        LiquidGlassSegmentedControl(
            segments: [
                SegmentItem(value: "mon", label: "Mon"),
                SegmentItem(value: "tue", label: "Tue"),
                SegmentItem(value: "wed", label: "Wed"),
                SegmentItem(value: "thu", label: "Thu")
            ],
            selection: .constant("mon")
        )
    }
    .padding()
    .background(Color.background.primary)
}
