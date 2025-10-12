import SwiftUI

/// Design system typography tokens
/// Centralized font definitions for consistent styling across the app
/// Built on top of TypeScale for foundational sizing
extension Font {
    
    // MARK: - Headings
    
    /// Large section headers (e.g., "Your Health Today")
    static let sectionTitle: Font = TypeScale.font(
        size: TypeScale.mlg,
        weight: .bold
    )
    
    /// Card/panel titles (e.g., "Steps", "Calories", "Integrations", "Recent Activities")
    static let cardTitle: Font = TypeScale.font(
        size: TypeScale.md,
        weight: .semibold
    )
    
    /// Sub-section headers
    static let subsectionTitle: Font = TypeScale.font(
        size: TypeScale.sm,
        weight: .semibold
    )
    
    // MARK: - Body Text
    
    /// Primary body text
    static let bodyPrimary: Font = TypeScale.font(
        size: TypeScale.md,
        weight: .regular
    )
    
    /// Secondary body text
    static let bodySecondary: Font = TypeScale.font(
        size: TypeScale.sm,
        weight: .regular
    )
    
    /// Small body text
    static let bodySmall: Font = TypeScale.font(
        size: TypeScale.xs,
        weight: .regular
    )
    
    // MARK: - Data Display
    
    /// Large metric values (e.g., step count, calorie total)
    static let metricLarge: Font = TypeScale.font(
        size: TypeScale.xl,
        weight: .bold,
        design: .rounded
    )
    
    /// Medium metric values
    static let metricMedium: Font = TypeScale.font(
        size: TypeScale.lg,
        weight: .bold,
        design: .rounded
    )
    
    /// Small metric values
    static let metricSmall: Font = TypeScale.font(
        size: TypeScale.md,
        weight: .semibold
    )
    
    // MARK: - Labels
    
    /// Primary labels (e.g., integration names, metric labels)
    static let labelPrimary: Font = TypeScale.font(
        size: TypeScale.xs,
        weight: .regular
    )
    
    /// Secondary labels (smaller, less prominent)
    static let labelSecondary: Font = TypeScale.font(
        size: TypeScale.xxs,
        weight: .regular
    )
    
    /// Tertiary labels (smallest)
    static let labelTertiary: Font = TypeScale.font(
        size: TypeScale.tiny,
        weight: .regular
    )
    
    // MARK: - Special
    
    /// Recovery score display
    static let recoveryScore: Font = TypeScale.font(
        size: TypeScale.xxl,
        weight: .bold,
        design: .rounded
    )
    
    /// Button text
    static let button: Font = TypeScale.font(
        size: TypeScale.md,
        weight: .semibold
    )
    
    /// Small button text
    static let buttonSmall: Font = TypeScale.font(
        size: TypeScale.sm,
        weight: .medium
    )
}

/// Text style modifiers for common patterns
extension Text {
    
    /// Apply card title styling
    func cardTitleStyle() -> some View {
        self
            .font(.cardTitle)
            .foregroundColor(.primary)
    }
    
    /// Apply section title styling
    func sectionTitleStyle() -> some View {
        self
            .font(.sectionTitle)
            .foregroundColor(.primary)
    }
    
    /// Apply label styling (small grey text)
    func labelStyle() -> some View {
        self
            .font(.labelPrimary)
            .foregroundColor(.secondary)
    }
    
    /// Apply metric value styling
    func metricStyle(size: MetricSize = .medium) -> some View {
        self
            .font(size.font)
            .foregroundColor(.primary)
    }
}

/// Metric size variants
enum MetricSize {
    case large
    case medium
    case small
    
    var font: Font {
        switch self {
        case .large: return .metricLarge
        case .medium: return .metricMedium
        case .small: return .metricSmall
        }
    }
}
