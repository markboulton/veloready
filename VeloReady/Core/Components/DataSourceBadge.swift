import SwiftUI

/// Small badge showing which data source an item came from
struct DataSourceBadge: View {
    let source: DataSource
    let style: BadgeStyle
    
    enum BadgeStyle {
        case icon       // Just the icon
        case compact    // Icon + abbreviation
        case full       // Icon + full name
    }
    
    var body: some View {
        Group {
            switch style {
            case .icon:
                iconView
                
            case .compact:
                HStack(spacing: Spacing.xs) {
                    iconView
                    Text(abbreviation)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(source.color.opacity(0.1))
                .cornerRadius(6)
                
            case .full:
                HStack(spacing: 6) {
                    iconView
                    Text(source.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(source.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var iconView: some View {
        Image(systemName: source.icon)
            .foregroundColor(source.color)
            .font(.caption)
    }
    
    private var abbreviation: String {
        switch source {
        case .intervalsICU: return "INT"
        case .strava: return "STR"
        case .appleHealth: return "AH"
        }
    }
}

// MARK: - Preview

struct DataSourceBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(DataSource.allCases) { source in
                HStack(spacing: 20) {
                    DataSourceBadge(source: source, style: .icon)
                    DataSourceBadge(source: source, style: .compact)
                    DataSourceBadge(source: source, style: .full)
                }
            }
        }
        .padding()
    }
}
