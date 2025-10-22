import SwiftUI

/// Standardized card component with consistent styling across the app
/// - 8% opacity background
/// - Rounded corners (16px)
/// - Full width with sm spacing (8px margins)
/// - md internal padding (16px)
/// - Optional header with icon, title, subtitle, and chevron
struct StandardCard<Content: View>: View {
    // Header elements
    let icon: String?
    let iconColor: Color?
    let title: String?
    let subtitle: String?
    let showChevron: Bool
    let onTap: (() -> Void)?
    
    // Content
    let content: Content
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        showChevron: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Optional header
            if icon != nil || title != nil || subtitle != nil || showChevron {
                header
                    .padding(.bottom, Spacing.md)
            }
            
            // Content
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.08))
        )
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxl / 2) // controls spacing top and bottom of card 
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Optional icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor ?? Color.text.secondary)
            }
            
            // Title and subtitle
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = title {
                        Text(title)
                            .font(.heading)
                            .foregroundColor(Color.text.primary)
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Optional chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.text.tertiary)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension StandardCard {
    /// Card with only content (no header)
    init(@ViewBuilder content: () -> Content) where Content: View {
        self.init(
            icon: nil,
            iconColor: nil,
            title: nil,
            subtitle: nil,
            showChevron: false,
            onTap: nil,
            content: content
        )
    }
    
    /// Card with icon and title
    init(
        icon: String,
        iconColor: Color? = nil,
        title: String,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: nil,
            showChevron: false,
            onTap: nil,
            content: content
        )
    }
    
    /// Card with title and chevron (tappable)
    init(
        title: String,
        showChevron: Bool = true,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            icon: nil,
            iconColor: nil,
            title: title,
            subtitle: nil,
            showChevron: showChevron,
            onTap: onTap,
            content: content
        )
    }
}

// MARK: - Preview

#Preview("All Features") {
    ScrollView {
        VStack(spacing: 0) {
            // Full header with all elements
            StandardCard(
                icon: "figure.run",
                iconColor: .blue,
                title: "Today's Ride",
                subtitle: "October 22, 2025",
                showChevron: true,
                onTap: { print("Tapped!") }
            ) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Distance: 45.2 km")
                        .font(.body)
                    Text("Duration: 1h 32m")
                        .font(.body)
                    Text("TSS: 87")
                        .font(.body)
                }
            }
            
            // Icon and title only
            StandardCard(
                icon: "heart.fill",
                iconColor: .red,
                title: "Recovery Score"
            ) {
                HStack {
                    Text("78%")
                        .font(.system(size: 48, weight: .bold))
                    Spacer()
                }
            }
            
            // Title and subtitle only
            StandardCard(
                icon: nil,
                title: "Sleep Quality",
                subtitle: "Last night"
            ) {
                Text("7h 32m of sleep")
                    .font(.body)
            }
            
            // Content only (no header)
            StandardCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Simple Card")
                        .font(.heading)
                    Text("This card has no header, just content")
                        .font(.body)
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            // Tappable with chevron
            StandardCard(
                title: "View Details",
                showChevron: true,
                onTap: { print("Navigate!") }
            ) {
                Text("Tap this card to navigate")
                    .font(.body)
            }
            
            // Icon only
            StandardCard(
                icon: "flame.fill",
                iconColor: .orange,
                title: nil
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories Burned")
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                    Text("2,450")
                        .font(.system(size: 32, weight: .bold))
                }
            }
        }
    }
    .background(Color.background.primary)
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: 0) {
            StandardCard(
                icon: "moon.stars.fill",
                iconColor: .purple,
                title: "Sleep Tracking",
                subtitle: "Last 7 days"
            ) {
                Text("Average: 7h 45m")
                    .font(.body)
            }
            
            StandardCard(
                icon: "bolt.fill",
                iconColor: .yellow,
                title: "Training Load"
            ) {
                Text("Moderate intensity week")
                    .font(.body)
            }
        }
    }
    .background(Color.background.primary)
    .preferredColorScheme(.dark)
}
