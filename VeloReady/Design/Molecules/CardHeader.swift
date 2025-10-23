import SwiftUI

/// Composable card header - used by all cards for consistency
/// Supports title, subtitle, badge, and action button
struct CardHeader: View {
    let title: String
    let subtitle: String?
    let badge: Badge?
    let action: Action?
    
    struct Badge {
        let text: String
        let style: VRBadge.Style
    }
    
    struct Action {
        let icon: String
        let action: () -> Void
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        badge: Badge? = nil,
        action: Action? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    VRText(title, style: .headline)
                    
                    if let badge = badge {
                        VRBadge(badge.text, style: badge.style)
                    }
                }
                
                if let subtitle = subtitle {
                    VRText(subtitle, style: .caption, color: .secondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action.action) {
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Simple") {
    VStack(spacing: 20) {
        CardHeader(title: "Recovery Score")
        
        CardHeader(
            title: "Sleep Quality",
            subtitle: "Last 7 days"
        )
    }
    .padding()
}

#Preview("With Badge") {
    VStack(spacing: 20) {
        CardHeader(
            title: "Recovery Score",
            badge: .init(text: "OPTIMAL", style: .success)
        )
        
        CardHeader(
            title: "Training Load",
            subtitle: "Last 7 days",
            badge: .init(text: "HIGH", style: .warning)
        )
        
        CardHeader(
            title: "Sleep Debt",
            subtitle: "Accumulated",
            badge: .init(text: "LOW", style: .error)
        )
    }
    .padding()
}

#Preview("With Action") {
    VStack(spacing: 20) {
        CardHeader(
            title: "Heart Rate",
            subtitle: "Overnight average",
            action: .init(icon: "chevron.right", action: {})
        )
        
        CardHeader(
            title: "Recent Activities",
            badge: .init(text: "5 NEW", style: .info),
            action: .init(icon: "chevron.right", action: {})
        )
    }
    .padding()
}

#Preview("In Card") {
    VStack(spacing: 20) {
        // Simulating how it looks in a real card
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(
                title: "Recovery Score",
                subtitle: "Based on HRV, RHR, and Sleep",
                badge: .init(text: "OPTIMAL", style: .success),
                action: .init(icon: "chevron.right", action: {})
            )
            
            Text("92")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            
            Text("Your body is well-recovered and ready for training")
                .font(.caption)
                .foregroundColor(.secondary)
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
