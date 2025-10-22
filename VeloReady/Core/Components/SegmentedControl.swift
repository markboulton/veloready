import SwiftUI

/// Reusable segmented control component with animated selection indicator
/// Supports 2-4 segments with text and/or icons
struct SegmentedControl<T: Hashable>: View {
    let segments: [SegmentItem<T>]
    @Binding var selection: T
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background container
                RoundedRectangle(cornerRadius: Spacing.sm)
                    .fill(Color.background.tertiary)
                    .frame(height: 36)
                
                // Animated selection indicator (grey background)
                RoundedRectangle(cornerRadius: Spacing.sm - 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: segmentWidth(containerWidth: geometry.size.width), height: 32)
                    .offset(x: selectedOffset(containerWidth: geometry.size.width))
                    .animation(FluidAnimation.bouncy, value: selection)
                
                // Segment buttons
                HStack(spacing: 0) {
                    ForEach(segments, id: \.value) { segment in
                        Button(action: {
                            if selection != segment.value {
                                HapticFeedback.light()
                                withAnimation(FluidAnimation.bouncy) {
                                    selection = segment.value
                                }
                            }
                        }) {
                            segmentContent(for: segment)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
        .frame(height: 36)
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
                    .font(.system(size: TypeScale.xs))
            }
        }
        .fontWeight(isSelected ? .semibold : .medium)
        .foregroundColor(isSelected ? Color.button.primary : Color.text.secondary)
    }
    
    private func segmentWidth(containerWidth: CGFloat) -> CGFloat {
        (containerWidth / CGFloat(segments.count)) - 4
    }
    
    private func selectedOffset(containerWidth: CGFloat) -> CGFloat {
        guard let selectedIndex = segments.firstIndex(where: { $0.value == selection }) else {
            return 2
        }
        let segmentWidth = containerWidth / CGFloat(segments.count)
        return CGFloat(selectedIndex) * segmentWidth + 2
    }
}

// MARK: - Segment Item

struct SegmentItem<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let label: String?
    let icon: String?
    
    init(value: T, label: String? = nil, icon: String? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.xl) {
        // Text-only segments
        SegmentedControlPreview()
        
        // Icon + text segments
        SegmentedControlIconPreview()
        
        // Icon-only segments
        SegmentedControlIconOnlyPreview()
    }
    .padding(Spacing.cardPadding)
}

struct SegmentedControlPreview: View {
    @State private var selection = "7d"
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(CommonContent.Preview.periodSelector)
                .font(.system(size: TypeScale.sm, weight: .semibold))
            
            SegmentedControl(
                segments: [
                    SegmentItem(value: "7d", label: "7 Days"),
                    SegmentItem(value: "30d", label: "30 Days"),
                    SegmentItem(value: "60d", label: "60 Days")
                ],
                selection: $selection
            )
            
            Text("Selected: \(selection)")
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
        }
    }
}

struct SegmentedControlIconPreview: View {
    @State private var selection = "chart"
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(CommonContent.Preview.viewType)
                .font(.system(size: TypeScale.sm, weight: .semibold))
            
            SegmentedControl(
                segments: [
                    SegmentItem(value: "chart", label: "Chart", icon: "chart.bar"),
                    SegmentItem(value: "list", label: "List", icon: "list.bullet"),
                    SegmentItem(value: "grid", label: "Grid", icon: "square.grid.2x2")
                ],
                selection: $selection
            )
            
            Text("Selected: \(selection)")
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
        }
    }
}

struct SegmentedControlIconOnlyPreview: View {
    @State private var selection = "day"
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(CommonContent.Preview.timeRange)
                .font(.system(size: TypeScale.sm, weight: .semibold))
            
            SegmentedControl(
                segments: [
                    SegmentItem(value: "day", icon: "sun.max"),
                    SegmentItem(value: "week", icon: "calendar"),
                    SegmentItem(value: "month", icon: "calendar.badge.clock"),
                    SegmentItem(value: "year", icon: "calendar.badge.checkmark")
                ],
                selection: $selection
            )
            
            Text("Selected: \(selection)")
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
        }
    }
}
