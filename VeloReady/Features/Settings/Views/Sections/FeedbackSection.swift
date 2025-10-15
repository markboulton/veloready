import SwiftUI

/// Help & Feedback section - visible to all users
struct FeedbackSection: View {
    @State private var showingFeedback = false
    
    var body: some View {
        Section {
            Button(action: { showingFeedback = true }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Send Feedback")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Report issues or suggest improvements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        } header: {
            Text("Help & Support")
        } footer: {
            Text("Send feedback, report bugs, or get help. Your feedback includes diagnostic logs to help us resolve issues faster.")
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
