import SwiftUI

/// Reusable metric display component
/// Shows a value with an optional label below
struct MetricDisplay: View {
    let value: String
    let label: String?
    let icon: String?
    let size: MetricDisplaySize
    
    init(
        _ value: String,
        label: String? = nil,
        icon: String? = nil,
        size: MetricDisplaySize = .large
    ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.size = size
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .font(size.iconFont)
            }
            
            Text(value)
                .font(size.valueFont)
                .foregroundColor(.primary)
            
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

enum MetricDisplaySize {
    case large
    case medium
    case small
    
    var valueFont: Font {
        switch self {
        case .large: return .metric
        case .medium: return .title
        case .small: return .heading
        }
    }
    
    var iconFont: Font {
        switch self {
        case .large: return .system(size: TypeScale.lg)
        case .medium: return .system(size: TypeScale.md)
        case .small: return .system(size: TypeScale.sm)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        MetricDisplay("12,543", label: "Steps", icon: "figure.walk", size: .large)
        MetricDisplay("85", label: "Recovery Score", size: .medium)
        MetricDisplay("7.5", label: "Hours", size: .small)
    }
    .padding()
}
