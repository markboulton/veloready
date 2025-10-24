import SwiftUI

/// iOS 26 toolbar styling helpers
/// In iOS 26, toolbars automatically get Liquid Glass effect
/// We should NOT apply custom backgrounds - let the system handle it
extension View {
    /// Apply toolbar background only on iOS < 26
    /// iOS 26+ automatically uses Liquid Glass - no custom background needed
    func adaptiveToolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                // iOS 26+ - Don't apply custom background
                // System automatically provides Liquid Glass effect
                self
                    .onAppear {
                        print("🎨 [Toolbar] iOS 26+ - using native Liquid Glass (no custom background)")
                    }
            } else {
                // iOS 25 and earlier - Apply custom background
                self
                    .modifier(ToolbarBackgroundModifier(visibility: visibility, bars: bars))
            }
        }
    }
    
    /// Apply toolbar color scheme only on iOS < 26
    /// iOS 26+ handles this automatically
    func adaptiveToolbarColorScheme(_ colorScheme: ColorScheme, for bars: ToolbarPlacement...) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                // iOS 26+ - Don't apply custom color scheme
                self
            } else {
                // iOS 25 and earlier - Apply custom color scheme
                self
                    .modifier(ToolbarColorSchemeModifier(colorScheme: colorScheme, bars: bars))
            }
        }
    }
}

// MARK: - Helper Modifiers

private struct ToolbarBackgroundModifier: ViewModifier {
    let visibility: Visibility
    let bars: [ToolbarPlacement]
    
    func body(content: Content) -> some View {
        var result = AnyView(content)
        for bar in bars {
            result = AnyView(result.toolbarBackground(visibility, for: bar))
        }
        return result
    }
}

private struct ToolbarColorSchemeModifier: ViewModifier {
    let colorScheme: ColorScheme
    let bars: [ToolbarPlacement]
    
    func body(content: Content) -> some View {
        var result = AnyView(content)
        for bar in bars {
            result = AnyView(result.toolbarColorScheme(colorScheme, for: bar))
        }
        return result
    }
}
