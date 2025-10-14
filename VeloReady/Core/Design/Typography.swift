import SwiftUI

/// Rationalized typography system with 4 semantic levels
/// Enforces consistent type sizes and colors across the app
/// Built on top of TypeScale for foundational sizing
extension Font {
    
    // MARK: - Core 4 Type Levels (Design System)
    
    /// Level 1: Titles - Page titles and main headings (34pt, bold)
    /// Color: Always foreground
    static let title: Font = TypeScale.font(
        size: TypeScale.xl,
        weight: .bold
    )
    
    /// Level 2: Heading - Section headers and card titles (17pt, semibold)
    /// Color: Always foreground
    static let heading: Font = TypeScale.font(
        size: TypeScale.md,
        weight: .semibold
    )
    
    /// Level 3: Body - Main text content (15pt, regular)
    /// Color: Always foreground
    static let body: Font = TypeScale.font(
        size: TypeScale.sm,
        weight: .regular
    )
    
    /// Level 4: Caption - Small labels, secondary text, explainers (13pt, regular)
    /// Color: Grey (.secondary)
    static let caption: Font = TypeScale.font(
        size: TypeScale.xs,
        weight: .regular
    )
    
    // MARK: - Specialized Variants (build on core 4)
    
    /// Large metric display (uses title with rounded design)
    static let metric: Font = TypeScale.font(
        size: TypeScale.xl,
        weight: .bold,
        design: .rounded
    )
    
    /// Button text (uses heading)
    static let button: Font = .heading
    
    // MARK: - Legacy Aliases (for backwards compatibility during migration)
    
    @available(*, deprecated, renamed: "heading")
    static let cardTitle: Font = .heading
    
    @available(*, deprecated, renamed: "title")
    static let sectionTitle: Font = .title
    
    @available(*, deprecated, renamed: "heading")
    static let subsectionTitle: Font = .heading
    
    @available(*, deprecated, renamed: "body")
    static let bodyPrimary: Font = .body
    
    @available(*, deprecated, renamed: "body")
    static let bodySecondary: Font = .body
    
    @available(*, deprecated, renamed: "caption")
    static let bodySmall: Font = .caption
    
    @available(*, deprecated, renamed: "metric")
    static let metricLarge: Font = .metric
    
    @available(*, deprecated, renamed: "metric")
    static let metricMedium: Font = .metric
    
    @available(*, deprecated, renamed: "heading")
    static let metricSmall: Font = .heading
    
    @available(*, deprecated, renamed: "caption")
    static let labelPrimary: Font = .caption
    
    @available(*, deprecated, renamed: "caption")
    static let labelSecondary: Font = .caption
    
    @available(*, deprecated, renamed: "caption")
    static let labelTertiary: Font = .caption
    
    @available(*, deprecated, renamed: "metric")
    static let recoveryScore: Font = .metric
    
    @available(*, deprecated, renamed: "button")
    static let buttonSmall: Font = .button
}

/// Text style modifiers for semantic styling
extension Text {
    
    /// Apply title styling (Level 1)
    func titleStyle() -> some View {
        self
            .font(.title)
            .foregroundColor(.primary)
    }
    
    /// Apply heading styling (Level 2)
    func headingStyle() -> some View {
        self
            .font(.heading)
            .foregroundColor(.primary)
    }
    
    /// Apply body styling (Level 3)
    func bodyStyle() -> some View {
        self
            .font(.body)
            .foregroundColor(.primary)
    }
    
    /// Apply caption styling (Level 4) - grey text
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    /// Apply metric display styling
    func metricStyle() -> some View {
        self
            .font(.metric)
            .foregroundColor(.primary)
    }
}
