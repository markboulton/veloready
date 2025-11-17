import SwiftUI

/// Design system gradients for consistent visual styling
enum Gradients {
    /// Chart area fill gradients
    enum ChartFill {
        /// Create a top-to-bottom gradient for chart area fills
        /// - Parameters:
        ///   - color: Base color for the gradient
        ///   - topOpacity: Opacity at the top (default: 0.2)
        ///   - bottomOpacity: Opacity at the bottom (default: 0.0)
        /// - Returns: Linear gradient for chart area fills
        static func areaGradient(
            color: Color,
            topOpacity: Double = 0.2,
            bottomOpacity: Double = 0.0
        ) -> LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(topOpacity),
                    color.opacity(bottomOpacity)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        /// FTP chart area gradient (purple)
        static var ftp: LinearGradient {
            areaGradient(color: ColorScale.purpleAccent)
        }
        
        /// VO2 Max chart area gradient (blue)
        static var vo2: LinearGradient {
            areaGradient(color: ColorScale.blueAccent)
        }
        
        /// Power chart area gradient (power color)
        static var power: LinearGradient {
            areaGradient(color: ColorScale.powerColor)
        }
        
        /// HRV chart area gradient (HRV color)
        static var hrv: LinearGradient {
            areaGradient(color: ColorScale.hrvColor)
        }
    }
    
    /// Background gradients
    enum Background {
        /// Subtle background gradient for cards
        static var card: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.background.secondary.opacity(0.5),
                    Color.background.secondary.opacity(0.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
