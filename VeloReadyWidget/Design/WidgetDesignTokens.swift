//
//  WidgetDesignTokens.swift
//  VeloReadyWidget
//
//  Design tokens specific to widgets
//

import SwiftUI

enum WidgetDesignTokens {
    
    // MARK: - Ring Styling
    
    enum Ring {
        static let width: CGFloat = 5
        static let sizeSmall: CGFloat = 75
        static let sizeMedium: CGFloat = 80
        static let sizeLarge: CGFloat = 100
        static let backgroundOpacity: Double = 0.2
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let titleSize: CGFloat = 13  // .caption
        static let scoreSize: CGFloat = 24
        static let bandSize: CGFloat = 11   // .caption2
        static let strainScoreSize: CGFloat = 20  // Smaller for decimal
        static let sparkleSize: CGFloat = 7
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let ringSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 6
        static let padding: CGFloat = 16
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let duration: Double = 0.84
        static let initialDelay: Double = 0.14
        static let staggerDelay: Double = 0.1
        static let numberFadeDuration: Double = 0.28
        static let numberFadeStartPercent: Double = 0.7
    }
    
    // MARK: - Colors
    
    /// Recovery score colors
    static func recoveryColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    /// Sleep score colors
    static func sleepColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    /// Strain score colors
    static func strainColor(for strain: Double) -> Color {
        switch strain {
        case 0..<4: return .green
        case 4..<10: return .yellow
        case 10..<14: return .orange
        case 14..<18: return .red
        default: return .purple
        }
    }
    
    // MARK: - Semantic Colors
    
    enum Colors {
        static let background = Color.gray.opacity(Ring.backgroundOpacity)
        static let placeholder = Color.gray
        static let title = Color.white
        static let band = Color.secondary
        static let sparkle = Color.purple
    }
}
