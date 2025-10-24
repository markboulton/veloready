import SwiftUI

/// Design system spacing tokens
/// Centralized spacing values for consistent layout across the app
enum Spacing {
    
    // MARK: - Base Units
    static let xs: CGFloat = 4  /// Extra small spacing (4pt)
    static let sm: CGFloat = 8  /// Small spacing (8pt)
    static let md: CGFloat = 12  /// Medium spacing (12pt)
    static let lg: CGFloat = 16  /// Large spacing (16pt)
    static let xl: CGFloat = 20  /// Extra large spacing (20pt)
    static let xxl: CGFloat = 24  /// Extra extra large spacing (24pt)
    static let huge: CGFloat = 32  /// Huge spacing (32pt)
    
    // MARK: - Typography Spacing
    static let lineHeightTight: CGFloat = 2   /// Tight line spacing (2pt)
    static let lineHeightNormal: CGFloat = 3  /// Normal line spacing (3pt)
    static let lineHeightRelaxed: CGFloat = 5 /// Relaxed line spacing (5pt)
    
    // MARK: - Semantic Spacing
    static let cardPadding: CGFloat = lg  /// Padding inside cards/panels
    static let cardSpacing: CGFloat = lg  /// Spacing between cards
    static let sectionSpacing: CGFloat = xl  /// Spacing between sections
    static let cardContentSpacing: CGFloat = md  /// Spacing within a card's content
    static let cardCornerRadius: CGFloat = 12  /// Corner radius for cards
    static let buttonCornerRadius: CGFloat = 8  /// Corner radius for buttons
    
    // MARK: - Navigation Spacing
    static let navigationBarHeight: CGFloat = 96  /// Height of navigation bar area for gradient mask
    static let navigationGradientHeight: CGFloat = 60  /// Height of gradient fade below navigation bar
    static let sectionHeaderHeight: CGFloat = 40  /// Height of sticky section headers
    static let sectionHeaderGradientHeight: CGFloat = 20  /// Height of gradient fade on section headers
}

/// Design system opacity tokens
/// Centralized opacity values for consistent visual hierarchy
enum Opacity {
    // MARK: - Gradient Stops
    static let gradientFull: Double = 0.95      /// Nearly opaque gradient start
    static let gradientHigh: Double = 0.7       /// High opacity gradient stop
    static let gradientMedium: Double = 0.4     /// Medium opacity gradient stop
    static let gradientLow: Double = 0.0        /// Transparent gradient end
    
    // MARK: - UI Elements
    static let disabled: Double = 0.5           /// Disabled state opacity
    static let subtle: Double = 0.6             /// Subtle UI elements
    static let overlay: Double = 0.8            /// Overlay backgrounds
}

/// View extension for applying spacing tokens
extension View {
    
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }
    
    /// Apply standard card styling with adaptive card background
    func cardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.background.card)
            )
    }
    
    /// Apply card styling with custom padding per edge and adaptive card background
    func cardStyle(leading: CGFloat? = nil, trailing: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        self
            .padding(.leading, leading ?? Spacing.cardPadding)
            .padding(.trailing, trailing ?? Spacing.cardPadding)
            .padding(.top, top ?? Spacing.cardPadding)
            .padding(.bottom, bottom ?? Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.background.card)
            )
    }
}
