import SwiftUI

/// Reusable section header with consistent styling
/// Level 2 typography (heading), always foreground color
struct SectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let style: Style
    
    enum Style {
        case standard       // Default heading style
        case monthYear      // Month/year grouping style (sticky-compatible)
        
        var font: Font {
            switch self {
            case .standard:
                return .heading
            case .monthYear:
                // Use caption typography: 15pt, regular weight
                return TypeScale.font(size: TypeScale.sm, weight: .regular)
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .standard:
                return .semibold
            case .monthYear:
                return .semibold
            }
        }
        
        var color: Color {
            switch self {
            case .standard:
                return .primary
            case .monthYear:
                return Color.text.secondary
            }
        }
        
        var textCase: Text.Case? {
            switch self {
            case .standard:
                return nil
            case .monthYear:
                return .uppercase
            }
        }
        
        var tracking: CGFloat {
            switch self {
            case .standard:
                return 0
            case .monthYear:
                return 0.5
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .standard:
                return .clear
            case .monthYear:
                return Color.background.app
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil,
        style: Style = .standard
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
    }
    
    var body: some View {
        Group {
            switch style {
            case .standard:
                standardHeader
            case .monthYear:
                monthYearHeader
            }
        }
        .trackComponent(.sectionHeader)
    }
    
    private var standardHeader: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.heading)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: Icons.System.chevronRight)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var monthYearHeader: some View {
        Text(title)
            .font(style.font)
            .fontWeight(style.fontWeight)
            .foregroundColor(style.color)
            .textCase(style.textCase)
            .tracking(style.tracking)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xl)
            .background(style.backgroundColor)
    }
}

#Preview("Standard Headers") {
    VStack(spacing: 20) {
        SectionHeader("Simple Header")
        SectionHeader("With Icon", icon: "heart.fill")
        SectionHeader("With Action", action: {})
    }
    .padding()
}

#Preview("Month/Year Headers") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(0..<5) { index in
                    Text("Activity \(index + 1)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.background.card)
                        .cornerRadius(12)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.xs)
                }
            } header: {
                SectionHeader("October 2024", style: .monthYear)
            }
            
            Section {
                ForEach(0..<5) { index in
                    Text("Activity \(index + 1)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.background.card)
                        .cornerRadius(12)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.xs)
                }
            } header: {
                SectionHeader("September 2024", style: .monthYear)
            }
        }
    }
    .background(Color.background.app)
}
