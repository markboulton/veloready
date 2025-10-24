import SwiftUI

/// Universal chart card for trends and historical data
/// Wraps any chart content with consistent header, footer, and styling
struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let badge: CardHeader.Badge?
    let footerText: String?
    let action: (() -> Void)?
    let styleType: StyleType
    let cardStyle: CardContainer<Content>.Style
    let chart: () -> Content
    
    enum StyleType {
        case standard
        case compact
        case hero
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        badge: CardHeader.Badge? = nil,
        footerText: String? = nil,
        action: (() -> Void)? = nil,
        style: StyleType = .standard,
        cardStyle: CardContainer<Content>.Style = .standard,
        @ViewBuilder chart: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.footerText = footerText
        self.action = action
        self.styleType = style
        self.cardStyle = cardStyle
        self.chart = chart
    }
    
    var body: some View {
        if let action = action {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
    
    private var cardContent: some View {
        CardContainer(
            header: CardHeader(
                title: title,
                subtitle: subtitle,
                badge: badge,
                action: action != nil ? .init(icon: "chevron.right", action: action!) : nil
            ),
            footer: footerText != nil ? CardFooter(text: footerText) : nil,
            style: cardStyle
        ) {
            chart()
        }
    }
}

// MARK: - Preview

#Preview("HRV Trend") {
    ChartCard(
        title: "HRV Trend",
        subtitle: "Last 7 days",
        badge: .init(text: "IMPROVING", style: .success),
        footerText: "Average: 45ms"
    ) {
        // Mock chart
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<7) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 40, height: CGFloat(30 + i * 10))
                }
            }
            
            HStack {
                VRText("Mon", style: .caption2, color: .secondary)
                Spacer()
                VRText("Sun", style: .caption2, color: .secondary)
            }
        }
        .frame(height: 120)
    }
    .padding()
}

#Preview("Recovery Trend") {
    ChartCard(
        title: "Recovery Trend",
        subtitle: "Last 30 days",
        badge: .init(text: "STABLE", style: .info),
        footerText: "Updated 5 min ago",
        action: { print("View details") }
    ) {
        // Mock line chart
        GeometryReader { geometry in
            Path { path in
                let points: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.9, 0.7]
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height * (1 - points[0])))
                for (index, point) in points.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(points.count - 1)
                    let y = height * (1 - point)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 3)
        }
        .frame(height: 150)
    }
    .padding()
}

#Preview("Training Load") {
    ChartCard(
        title: "Training Load",
        subtitle: "CTL vs ATL",
        badge: .init(text: "HIGH", style: .warning),
        footerText: "TSB: +12"
    ) {
        // Mock dual line chart
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                CardMetric(value: "245", label: "CTL", size: .small)
                CardMetric(value: "89", label: "ATL", size: .small)
                CardMetric(value: "+12", label: "TSB", size: .small)
            }
            
            // Simple bar representation
            HStack(spacing: 4) {
                ForEach(0..<14) { i in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange.opacity(0.6))
                            .frame(height: CGFloat(20 + i * 3))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.6))
                            .frame(height: CGFloat(15 + i * 2))
                    }
                    .frame(width: 20)
                }
            }
            .frame(height: 80)
        }
    }
    .padding()
}

#Preview("Multiple Charts") {
    ScrollView {
        VStack(spacing: 20) {
            ChartCard(
                title: "HRV Trend",
                subtitle: "Last 7 days",
                badge: .init(text: "IMPROVING", style: .success)
            ) {
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(height: 100)
                    .overlay(VRText("Chart content here", style: .caption))
            }
            
            ChartCard(
                title: "Sleep Quality",
                subtitle: "Last 30 days",
                badge: .init(text: "STABLE", style: .info),
                footerText: "Average: 88/100"
            ) {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(height: 120)
                    .overlay(VRText("Chart content here", style: .caption))
            }
            
            ChartCard(
                title: "Training Load",
                subtitle: "8 weeks",
                badge: .init(text: "HIGH", style: .warning),
                action: { print("Details") }
            ) {
                Rectangle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(height: 140)
                    .overlay(VRText("Chart content here", style: .caption))
            }
        }
        .padding()
    }
}
