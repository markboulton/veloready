import SwiftUI

/// Universal card container - replaces StandardCard
/// Composable card wrapper that can be used for any card type
/// Supports header, footer, and custom content with different styles
struct CardContainer<Content: View>: View {
    let header: CardHeader?
    let footer: CardFooter?
    let style: Style
    let content: () -> Content
    
    enum Style {
        case standard
        case compact
        case hero
        
        var padding: EdgeInsets {
            switch self {
            case .standard: return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            case .compact: return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            case .hero: return EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .standard: return 16
            case .compact: return 12
            case .hero: return 20
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .standard: return 8
            case .compact: return 4
            case .hero: return 12
            }
        }
        
        var shadowY: CGFloat {
            switch self {
            case .standard: return 2
            case .compact: return 1
            case .hero: return 4
            }
        }
    }
    
    init(
        header: CardHeader? = nil,
        footer: CardFooter? = nil,
        style: Style = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.style = style
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let header = header {
                header
            }
            
            content()
            
            if let footer = footer {
                footer
            }
        }
        .padding(style.padding)
        .background(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(Color(uiColor: .systemBackground))
                .shadow(
                    color: .black.opacity(0.05),
                    radius: style.shadowRadius,
                    y: style.shadowY
                )
        )
    }
}

// MARK: - Preview
#Preview("Simple Card") {
    VStack(spacing: 20) {
        CardContainer {
            VRText("Simple card content", style: .body)
        }
        
        CardContainer {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                VRText("Card with icon", style: .body)
            }
        }
    }
    .padding()
}

#Preview("Card with Header") {
    VStack(spacing: 20) {
        CardContainer(
            header: CardHeader(title: "Recovery Score")
        ) {
            CardMetric(
                value: "92",
                label: "Optimal Recovery",
                size: .large
            )
        }
        
        CardContainer(
            header: CardHeader(
                title: "Sleep Quality",
                subtitle: "Last night"
            )
        ) {
            CardMetric(
                value: "96",
                label: "Excellent",
                change: .init(value: "+4", direction: .up),
                size: .large
            )
        }
    }
    .padding()
}

#Preview("Full Card") {
    VStack(spacing: 20) {
        CardContainer(
            header: CardHeader(
                title: "Training Load",
                subtitle: "Last 7 days",
                badge: .init(text: "HIGH", style: .warning),
                action: .init(icon: "chevron.right", action: {})
            ),
            footer: CardFooter(
                text: "Updated 5 min ago",
                action: .init(label: "View Details", action: {})
            )
        ) {
            HStack(spacing: 20) {
                CardMetric(
                    value: "245",
                    label: "CTL",
                    change: .init(value: "+12", direction: .up),
                    size: .medium
                )
                CardMetric(
                    value: "89",
                    label: "ATL",
                    change: .init(value: "-5", direction: .down),
                    size: .medium
                )
                CardMetric(
                    value: "+12",
                    label: "TSB",
                    change: .init(value: "+3", direction: .up),
                    size: .medium
                )
            }
        }
    }
    .padding()
}

#Preview("Different Styles") {
    VStack(spacing: 20) {
        CardContainer(
            header: CardHeader(title: "Compact Card"),
            style: .compact
        ) {
            VRText("Smaller padding and corner radius", style: .caption)
        }
        
        CardContainer(
            header: CardHeader(title: "Standard Card"),
            style: .standard
        ) {
            VRText("Default padding and corner radius", style: .body)
        }
        
        CardContainer(
            header: CardHeader(title: "Hero Card"),
            style: .hero
        ) {
            CardMetric(
                value: "92",
                label: "Larger padding for prominence",
                size: .large
            )
        }
    }
    .padding()
}

#Preview("Real World Examples") {
    ScrollView {
        VStack(spacing: 20) {
            // Recovery Card
            CardContainer(
                header: CardHeader(
                    title: "Recovery Score",
                    subtitle: "Based on HRV, RHR, Sleep",
                    badge: .init(text: "OPTIMAL", style: .success)
                ),
                footer: CardFooter(
                    text: "Updated 5 min ago",
                    action: .init(label: "Details", action: {})
                )
            ) {
                CardMetric(
                    value: "92",
                    label: "Ready for Hard Training",
                    change: .init(value: "+5", direction: .up),
                    size: .large
                )
            }
            
            // Sleep Card
            CardContainer(
                header: CardHeader(
                    title: "Sleep Quality",
                    subtitle: "Last night: 7.2 hours"
                ),
                footer: CardFooter(text: "Data from Apple Health")
            ) {
                VStack(spacing: 12) {
                    CardMetric(
                        value: "96",
                        label: "Excellent",
                        size: .large
                    )
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text("1.2h")
                                .font(.headline)
                            Text("Deep")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack {
                            Text("2.1h")
                                .font(.headline)
                            Text("REM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack {
                            Text("3.9h")
                                .font(.headline)
                            Text("Core")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Activity Summary
            CardContainer(
                header: CardHeader(
                    title: "Recent Activities",
                    badge: .init(text: "5 NEW", style: .info),
                    action: .init(icon: "chevron.right", action: {})
                ),
                footer: CardFooter(
                    text: "Showing 5 of 42",
                    action: .init(label: "View All", action: {})
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.outdoor.cycle")
                        Text("Evening Ride")
                        Spacer()
                        Text("2h 15m")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Morning Run")
                        Spacer()
                        Text("45m")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}
