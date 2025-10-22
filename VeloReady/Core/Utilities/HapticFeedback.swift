import UIKit
import SwiftUI

/// Centralized haptic feedback system
/// Provides consistent haptic feedback across the app
enum HapticFeedback {
    
    // MARK: - Feedback Types
    
    /// Light impact - for subtle interactions (taps, selections)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact - for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact - for significant interactions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Selection changed - for picker/segmented control changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Success notification
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    
    /// Add haptic feedback to tap gesture
    /// - Parameter style: The haptic style to use (default: .light)
    func hapticFeedback(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    switch style {
                    case .light:
                        HapticFeedback.light()
                    case .medium:
                        HapticFeedback.medium()
                    case .heavy:
                        HapticFeedback.heavy()
                    case .selection:
                        HapticFeedback.selection()
                    }
                }
        )
    }
    
    /// Add haptic feedback on value change
    /// - Parameters:
    ///   - value: The value to observe
    ///   - style: The haptic style to use
    func hapticOnChange<V: Equatable>(of value: V, style: HapticStyle = .selection) -> some View {
        self.onChange(of: value) { _, _ in
            switch style {
            case .light:
                HapticFeedback.light()
            case .medium:
                HapticFeedback.medium()
            case .heavy:
                HapticFeedback.heavy()
            case .selection:
                HapticFeedback.selection()
            }
        }
    }
}

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
    case selection
}
