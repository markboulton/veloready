import SwiftUI

/// Atomic text component - all text should use this for consistency
/// Usage: VRText("Hello", style: .headline)
struct VRText: View {
    let text: String
    let style: Style
    let color: Color?
    
    enum Style {
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case body
        case bodySecondary
        case caption
        case caption2
        
        var font: Font {
            switch self {
            case .largeTitle: return .system(size: 34, weight: .bold)
            case .title: return .system(size: 28, weight: .bold)
            case .title2: return .system(size: 22, weight: .bold)
            case .title3: return .system(size: 20, weight: .semibold)
            case .headline: return .system(size: 17, weight: .semibold)
            case .body: return .system(size: 17, weight: .regular)
            case .bodySecondary: return .system(size: 15, weight: .regular)
            case .caption: return .system(size: 13, weight: .regular)
            case .caption2: return .system(size: 11, weight: .regular)
            }
        }
        
        var defaultColor: Color {
            switch self {
            case .bodySecondary, .caption, .caption2:
                return .secondary
            default:
                return .primary
            }
        }
    }
    
    init(_ text: String, style: Style = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(color ?? style.defaultColor)
    }
}

// MARK: - Preview
#Preview("All Styles") {
    VStack(alignment: .leading, spacing: 16) {
        VRText("Large Title", style: .largeTitle)
        VRText("Title", style: .title)
        VRText("Title 2", style: .title2)
        VRText("Title 3", style: .title3)
        VRText("Headline", style: .headline)
        VRText("Body Text", style: .body)
        VRText("Secondary Body", style: .bodySecondary)
        VRText("Caption", style: .caption)
        VRText("Caption 2", style: .caption2)
    }
    .padding()
}

#Preview("Colors") {
    VStack(alignment: .leading, spacing: 16) {
        VRText("Primary (Default)", style: .headline)
        VRText("Custom Green", style: .headline, color: .green)
        VRText("Custom Red", style: .headline, color: .red)
        VRText("Custom Blue", style: .headline, color: .blue)
    }
    .padding()
}
