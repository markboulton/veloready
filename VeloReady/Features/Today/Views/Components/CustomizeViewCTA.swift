import SwiftUI

/// Call-to-action button at bottom of Today page to customize layout
struct CustomizeViewCTA: View {
    @State private var navigateToSettings = false
    
    var body: some View {
        Button {
            navigateToSettings = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Customize This View")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text("Reorder cards or hide sections you don't need")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.text.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.text.tertiary)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.xl)
        .navigationDestination(isPresented: $navigateToSettings) {
            TodaySectionOrderView()
        }
    }
}

#Preview {
    NavigationStack {
        CustomizeViewCTA()
            .padding()
    }
}

