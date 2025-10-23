import SwiftUI

/// Atomic badge component - consistent badge styling across the app
/// Usage: VRBadge("NEW", style: .success)
struct VRBadge: View {
    let text: String
    let style: Style
    
    enum Style {
        case success
        case warning
        case error
        case info
        case neutral
        
        var backgroundColor: Color {
            switch self {
            case .success: return .green.opacity(0.2)
            case .warning: return .orange.opacity(0.2)
            case .error: return .red.opacity(0.2)
            case .info: return .blue.opacity(0.2)
            case .neutral: return .gray.opacity(0.2)
            }
        }
        
        var textColor: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            case .neutral: return .gray
            }
        }
    }
    
    init(_ text: String, style: Style = .neutral) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(style.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}

// MARK: - Preview
#Preview("All Styles") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            VRBadge("SUCCESS", style: .success)
            VRBadge("WARNING", style: .warning)
            VRBadge("ERROR", style: .error)
        }
        
        HStack(spacing: 12) {
            VRBadge("INFO", style: .info)
            VRBadge("NEUTRAL", style: .neutral)
        }
        
        HStack(spacing: 12) {
            VRBadge("OPTIMAL", style: .success)
            VRBadge("HIGH", style: .warning)
            VRBadge("LOW", style: .error)
        }
    }
    .padding()
}

#Preview("In Context") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("Recovery Score")
                .font(.headline)
            Spacer()
            VRBadge("OPTIMAL", style: .success)
        }
        
        HStack {
            Text("Training Load")
                .font(.headline)
            Spacer()
            VRBadge("HIGH", style: .warning)
        }
        
        HStack {
            Text("Sleep Quality")
                .font(.headline)
            Spacer()
            VRBadge("POOR", style: .error)
        }
    }
    .padding()
}
