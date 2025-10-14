import SwiftUI

/// Reusable section header with consistent styling
/// Level 2 typography (heading), always foreground color
struct SectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    
    init(
        _ title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.heading)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
        }
        .trackComponent(.sectionHeader)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader("Simple Header")
        SectionHeader("With Icon", icon: "heart.fill")
        SectionHeader("With Action", action: {})
    }
    .padding()
}
