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
}

/// View extension for applying spacing tokens
extension View {
    
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }
    
    /// Apply standard card styling with 5% opacity background
    func cardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
    }
    
    /// Apply card styling with custom padding per edge and 5% opacity background
    func cardStyle(leading: CGFloat? = nil, trailing: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        self
            .padding(.leading, leading ?? Spacing.cardPadding)
            .padding(.trailing, trailing ?? Spacing.cardPadding)
            .padding(.top, top ?? Spacing.cardPadding)
            .padding(.bottom, bottom ?? Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
    }
}
