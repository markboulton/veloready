import SwiftUI

/// Draggable sheet that displays educational content
/// Can be presented at 50% height and dragged to full height or dismissed
struct LearnMoreSheet: View {
    let content: LearnMoreContent
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var currentDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(content.sections.enumerated()), id: \.offset) { index, section in
                        VStack(alignment: .leading, spacing: 12) {
                            if let heading = section.heading {
                                Text(heading)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.text.primary)
                            }
                            
                            Text(section.body)
                                .font(.body)
                                .foregroundColor(Color.text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if index < content.sections.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Inline "Learn More" link button
struct LearnMoreLink: View {
    let content: LearnMoreContent
    @State private var showingSheet = false
    
    var body: some View {
        Button(action: {
            showingSheet = true
        }) {
            Text("Learn more")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.button.primary)
        }
        .sheet(isPresented: $showingSheet) {
            LearnMoreSheet(content: content, isPresented: $showingSheet)
        }
    }
}

// MARK: - Preview

#Preview("Learn More Sheet") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            Color.clear
                .sheet(isPresented: $isPresented) {
                    LearnMoreSheet(
                        content: .adaptiveZones,
                        isPresented: $isPresented
                    )
                }
        }
    }
    
    return PreviewWrapper()
}

#Preview("Learn More Link") {
    LearnMoreLink(content: .adaptiveZones)
        .padding()
}
