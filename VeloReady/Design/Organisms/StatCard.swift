import SwiftUI

/// Universal stat card for displaying metrics with optional trends
/// Usage: MetricStatCard(title: "Steps", value: "8,543", subtitle: "Today", trend: .up("+12%"))
struct MetricStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let trend: Trend?
    let badge: CardHeader.Badge?
    let action: (() -> Void)?
    
    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)
        
        var direction: CardMetric.Change.Direction {
            switch self {
            case .up: return .up
            case .down: return .down
            case .neutral: return .neutral
            }
        }
        
        var text: String {
            switch self {
            case .up(let val), .down(let val), .neutral(let val):
                return val
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        trend: Trend? = nil,
        badge: CardHeader.Badge? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.badge = badge
        self.action = action
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
            style: .compact
        ) {
            HStack(spacing: 16) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 40)
                }
                
                CardMetric(
                    value: value,
                    label: subtitle ?? title,
                    change: trend.map { .init(value: $0.text, direction: $0.direction) },
                    size: .medium
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview("Steps") {
    MetricStatCard(
        title: "Steps",
        value: "8,543",
        subtitle: "Today",
        icon: "figure.walk",
        trend: .up("+12%")
    )
    .padding()
}

#Preview("Calories") {
    MetricStatCard(
        title: "Calories",
        value: "2,345",
        subtitle: "Total burned",
        icon: "flame.fill",
        badge: .init(text: "GOAL MET", style: .success)
    )
    .padding()
}

#Preview("Sleep Debt") {
    MetricStatCard(
        title: "Sleep Debt",
        value: "2.5h",
        subtitle: "Accumulated",
        icon: "bed.double.fill",
        trend: .down("+0.5h"),
        badge: .init(text: "HIGH", style: .warning),
        action: { print("View details") }
    )
    .padding()
}

#Preview("Recovery Debt") {
    MetricStatCard(
        title: "Recovery Debt",
        value: "3 days",
        subtitle: "Below optimal",
        icon: "arrow.clockwise",
        trend: .up("-1 day"),
        badge: .init(text: "IMPROVING", style: .success)
    )
    .padding()
}

#Preview("Multiple Stats") {
    VStack(spacing: 16) {
        MetricStatCard(
            title: "Steps",
            value: "8,543",
            subtitle: "Today",
            icon: "figure.walk",
            trend: .up("+12%")
        )
        
        MetricStatCard(
            title: "Active Calories",
            value: "456",
            subtitle: "Today",
            icon: "flame.fill",
            trend: .up("+23")
        )
        
        MetricStatCard(
            title: "Exercise Time",
            value: "45 min",
            subtitle: "Today",
            icon: "timer",
            badge: .init(text: "GOAL MET", style: .success)
        )
        
        MetricStatCard(
            title: "Sleep Debt",
            value: "2.5h",
            subtitle: "Accumulated",
            icon: "bed.double.fill",
            trend: .down("+0.5h"),
            badge: .init(text: "HIGH", style: .warning),
            action: { print("Details") }
        )
    }
    .padding()
}

#Preview("Grid Layout") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        MetricStatCard(
            title: "Steps",
            value: "8.5K",
            icon: "figure.walk",
            trend: .up("+12%")
        )
        
        MetricStatCard(
            title: "Calories",
            value: "456",
            icon: "flame.fill",
            trend: .up("+23")
        )
        
        MetricStatCard(
            title: "Exercise",
            value: "45m",
            icon: "timer",
            badge: .init(text: "✓", style: .success)
        )
        
        MetricStatCard(
            title: "Distance",
            value: "6.2K",
            icon: "arrow.right",
            trend: .neutral("0%")
        )
    }
    .padding()
}
