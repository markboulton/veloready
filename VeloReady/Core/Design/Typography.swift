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
        size: TypeScale.md,
        weight: .regular
    )
    
    /// Level 4: Caption - labels, secondary text, explainers (15pt, regular)
    /// Color: Grey (.secondary)
    static let caption: Font = TypeScale.font(
        size: TypeScale.sm,
        weight: .regular
    )

    /// Level 5: Small Caption - Small labels, secondary text, explainers (13pt, regular)
    /// Color: Grey (.secondary)
    static let smcaption: Font = TypeScale.font(
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
            .lineSpacing(Spacing.lineHeightNormal)
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
