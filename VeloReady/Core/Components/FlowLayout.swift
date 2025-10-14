import SwiftUI

/// A layout that arranges views in a flowing horizontal pattern,
/// wrapping to the next line when needed (like tags or chips)
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    @State private var totalHeight: CGFloat = 0
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            // Hidden view to measure layout
            Color.clear
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: HeightPreferenceKey.self,
                            value: geo.size.height
                        )
                    }
                )
            
            // Actual content
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(extractViews().enumerated()), id: \.offset) { index, view in
                    view
                        .padding(.trailing, spacing)
                        .padding(.bottom, spacing)
                        .alignmentGuide(.leading) { dimensions in
                            if (abs(width - dimensions.width) > geometry.size.width) {
                                width = 0
                                height -= dimensions.height + spacing
                            }
                            let result = width
                            if index == extractViews().count - 1 {
                                width = 0
                            } else {
                                width -= dimensions.width + spacing
                            }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            height
                        }
                }
            }
        }
        .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
            totalHeight = newHeight
        }
    }
    
    private func extractViews() -> [AnyView] {
        var views: [AnyView] = []
        let mirror = Mirror(reflecting: content())
        
        if let children = mirror.children.first?.value {
            let childMirror = Mirror(reflecting: children)
            for child in childMirror.children {
                if let view = child.value as? any View {
                    views.append(AnyView(view))
                }
            }
        }
        
        return views
    }
}

// Height preference key for measuring the flow layout
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("Flow Layout Example")
            .font(.headline)
        
        FlowLayout(spacing: 8) {
            ForEach(["Push", "Pull", "Legs", "Core", "Conditioning", "Full Body"], id: \.self) { item in
                Text(item)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
    .padding()
}
