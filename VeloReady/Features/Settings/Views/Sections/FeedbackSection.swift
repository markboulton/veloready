import SwiftUI

/// Help & Feedback section - visible to all users
struct FeedbackSection: View {
    @State private var showingFeedback = false
    
    var body: some View {
        Section {
            Button(action: { showingFeedback = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                        Text(SettingsContent.Feedback.sendFeedback)
                            .font(TypeScale.font(size: TypeScale.md))
                            .foregroundColor(ColorPalette.labelPrimary)
                        
                        Text(SettingsContent.Feedback.subtitle)
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: Icons.System.chevronRight)
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        } header: {
            Text(SettingsContent.helpSupportSection)
        } footer: {
            Text(SettingsContent.Feedback.footer)
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
    }
}

// MARK: - Preview

struct FeedbackSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FeedbackSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
