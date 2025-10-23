import SwiftUI

/// Composable metric display - consistent across all cards
/// Shows value, label, and optional change indicator
struct CardMetric: View {
    let value: String
    let label: String
    let change: Change?
    let size: Size
    
    struct Change {
        let value: String
        let direction: Direction
        
        enum Direction {
            case up
            case down
            case neutral
            
            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .neutral: return .gray
                }
            }
            
            var icon: String {
                switch self {
                case .up: return "arrow.up"
                case .down: return "arrow.down"
                case .neutral: return "minus"
                }
            }
        }
    }
    
    enum Size {
        case large
        case medium
        case small
        
        var valueFont: Font {
            switch self {
            case .large: return .system(size: 48, weight: .bold, design: .rounded)
            case .medium: return .system(size: 32, weight: .bold, design: .rounded)
            case .small: return .system(size: 24, weight: .semibold, design: .rounded)
            }
        }
        
        var labelFont: Font {
            switch self {
            case .large: return .system(size: 15)
            case .medium: return .system(size: 13)
            case .small: return .system(size: 11)
            }
        }
        
        var changeFont: Font {
            switch self {
            case .large: return .system(size: 14, weight: .semibold)
            case .medium: return .system(size: 12, weight: .semibold)
            case .small: return .system(size: 10, weight: .semibold)
            }
        }
    }
    
    init(
        value: String,
        label: String,
        change: Change? = nil,
        size: Size = .medium
    ) {
        self.value = value
        self.label = label
        self.change = change
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(size.valueFont)
                    .foregroundColor(.primary)
                
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change.direction.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(change.value)
                            .font(size.changeFont)
                    }
                    .foregroundColor(change.direction.color)
                }
            }
            
            Text(label)
                .font(size.labelFont)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview("Sizes") {
    VStack(spacing: 40) {
        CardMetric(
            value: "92",
            label: "Recovery Score",
            change: .init(value: "+5", direction: .up),
            size: .large
        )
        
        CardMetric(
            value: "7.2h",
            label: "Sleep Duration",
            change: .init(value: "-0.3h", direction: .down),
            size: .medium
        )
        
        CardMetric(
            value: "65",
            label: "RHR",
            size: .small
        )
    }
    .padding()
}

#Preview("Change Directions") {
    HStack(spacing: 30) {
        CardMetric(
            value: "92",
            label: "Improving",
            change: .init(value: "+8", direction: .up),
            size: .medium
        )
        
        CardMetric(
            value: "68",
            label: "Declining",
            change: .init(value: "-5", direction: .down),
            size: .medium
        )
        
        CardMetric(
            value: "75",
            label: "Stable",
            change: .init(value: "0", direction: .neutral),
            size: .medium
        )
    }
    .padding()
}

#Preview("Multiple Metrics") {
    VStack(spacing: 20) {
        // Recovery card example
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(
                title: "Recovery Score",
                badge: .init(text: "OPTIMAL", style: .success)
            )
            
            CardMetric(
                value: "92",
                label: "Optimal Recovery",
                change: .init(value: "+5", direction: .up),
                size: .large
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        
        // Training load card example
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(
                title: "Training Load",
                subtitle: "Last 7 days"
            )
            
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    .padding()
}

#Preview("No Change Indicator") {
    HStack(spacing: 30) {
        CardMetric(
            value: "65 bpm",
            label: "Resting Heart Rate",
            size: .medium
        )
        
        CardMetric(
            value: "42 ms",
            label: "HRV",
            size: .medium
        )
        
        CardMetric(
            value: "96",
            label: "Sleep Score",
            size: .medium
        )
    }
    .padding()
}
