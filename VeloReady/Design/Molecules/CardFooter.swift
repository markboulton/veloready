import SwiftUI

/// Composable card footer - optional text and action
/// Used consistently across all cards
struct CardFooter: View {
    let text: String?
    let action: Action?
    
    struct Action {
        let label: String
        let action: () -> Void
    }
    
    init(text: String? = nil, action: Action? = nil) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let text = text {
                VRText(text, style: .caption, color: .secondary)
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action.action) {
                    Text(action.label)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Text Only") {
    VStack(spacing: Spacing.xs) {
        CardFooter(text: "Updated 5 min ago")
        CardFooter(text: "Last synced: Today at 2:30 PM")
        CardFooter(text: "Data from HealthKit")
    }
    .padding()
}

#Preview("Action Only") {
    VStack(spacing: Spacing.xs) {
        CardFooter(action: .init(label: "View Details", action: {}))
        CardFooter(action: .init(label: "See All", action: {}))
        CardFooter(action: .init(label: "Learn More", action: {}))
    }
    .padding()
}

#Preview("Text + Action") {
    VStack(spacing: Spacing.xs) {
        CardFooter(
            text: "Updated 5 min ago",
            action: .init(label: "Refresh", action: {})
        )
        
        CardFooter(
            text: "7 days of data",
            action: .init(label: "View All", action: {})
        )
        
        CardFooter(
            text: "Based on your recent activities",
            action: .init(label: "Details", action: {})
        )
    }
    .padding()
}

#Preview("In Card Context") {
    VStack(spacing: Spacing.xs) {
        // Example 1: Simple footer
        VStack(alignment: .leading, spacing: Spacing.xs) {
            CardHeader(title: "Recovery Score")
            
            CardMetric(
                value: "92",
                label: "Optimal",
                size: .large
            )
            
            CardFooter(text: "Updated 5 min ago")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        
        // Example 2: Footer with action
        VStack(alignment: .leading, spacing: Spacing.xs) {
            CardHeader(
                title: "Recent Activities",
                badge: .init(text: "5 NEW", style: .info)
            )
            
            Text("Last ride: 2h 15m ago")
                .font(.subheadline)
            
            CardFooter(
                text: "Showing 5 of 42 activities",
                action: .init(label: "View All", action: {})
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    .padding()
}
