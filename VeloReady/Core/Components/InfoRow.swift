import SwiftUI

/// Reusable info row with multiple style variants
struct DataRow: View {
    let icon: String?
    let iconColor: Color?
    let title: String
    let value: String?
    let subtitle: String?
    let trailing: AnyView?
    
    init(
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String,
        value: String? = nil,
        subtitle: String? = nil,
        trailing: AnyView? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor ?? Color.text.secondary)
                    .font(.system(size: TypeScale.md))
                    .frame(width: 24)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(title)
                    .font(.system(size: TypeScale.sm))
                    .foregroundColor(Color.text.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: TypeScale.xs))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Spacer()
            
            // Value or custom trailing content
            if let trailing = trailing {
                trailing
            } else if let value = value {
                Text(value)
                    .font(.system(size: TypeScale.sm, weight: .semibold))
                    .foregroundColor(Color.text.primary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Convenience Initializers

extension DataRow {
    /// Icon + Title + Value
    static func iconTitleValue(
        icon: String,
        iconColor: Color? = nil,
        title: String,
        value: String
    ) -> DataRow {
        DataRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            value: value
        )
    }
    
    /// Icon + Title + Subtitle
    static func iconTitleSubtitle(
        icon: String,
        iconColor: Color? = nil,
        title: String,
        subtitle: String
    ) -> DataRow {
        DataRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle
        )
    }
    
    /// Title + Value + Subtitle
    static func titleValueSubtitle(
        title: String,
        value: String,
        subtitle: String
    ) -> DataRow {
        DataRow(
            title: title,
            value: value,
            subtitle: subtitle
        )
    }
    
    /// Title + Custom Trailing View
    static func titleTrailing<T: View>(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> T
    ) -> DataRow {
        DataRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            trailing: AnyView(trailing())
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Card {
                VStack(spacing: 0) {
                    DataRow.iconTitleValue(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Resting Heart Rate",
                        value: "65 bpm"
                    )
                    
                    Divider()
                    
                    DataRow.iconTitleValue(
                        icon: "waveform.path.ecg",
                        iconColor: .blue,
                        title: "Heart Rate Variability",
                        value: "45 ms"
                    )
                    
                    Divider()
                    
                    DataRow.iconTitleValue(
                        icon: "lungs.fill",
                        iconColor: .cyan,
                        title: "Respiratory Rate",
                        value: "16 bpm"
                    )
                }
            }
            
            Card {
                VStack(spacing: 0) {
                    DataRow.iconTitleSubtitle(
                        icon: "moon.fill",
                        iconColor: .purple,
                        title: "Sleep Duration",
                        subtitle: "8 hours 23 minutes"
                    )
                    
                    Divider()
                    
                    DataRow.iconTitleSubtitle(
                        icon: "bed.double.fill",
                        iconColor: .indigo,
                        title: "Deep Sleep",
                        subtitle: "2 hours 15 minutes (27%)"
                    )
                }
            }
            
            Card {
                VStack(spacing: 0) {
                    DataRow.titleValueSubtitle(
                        title: "Training Load",
                        value: "85",
                        subtitle: "High intensity"
                    )
                    
                    Divider()
                    
                    DataRow.titleTrailing(
                        icon: "flame.fill",
                        title: "Calories Burned",
                        subtitle: "Active: 456 cal"
                    ) {
                        VStack(alignment: .trailing, spacing: Spacing.xs / 2) {
                            Text("1,234")
                                .font(.system(size: TypeScale.sm, weight: .semibold))
                            Text(CommonContent.Labels.total)
                                .font(.system(size: TypeScale.xxs))
                                .foregroundColor(Color.text.secondary)
                        }
                    }
                    
                    Divider()
                    
                    DataRow.titleTrailing(
                        icon: "checkmark.circle.fill",
                        title: "Recovery Status"
                    ) {
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(Color.recovery.green)
                                .frame(width: 8, height: 8)
                            Text(CommonContent.Badges.ready)
                                .font(.system(size: TypeScale.xs, weight: .semibold))
                                .foregroundColor(Color.recovery.green)
                        }
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
