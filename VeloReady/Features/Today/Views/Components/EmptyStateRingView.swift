import SwiftUI

/// Empty state ring view for when HealthKit permissions are not granted
/// Shows grey rings with titles but no scores
struct EmptyStateRingView: View {
    let title: String
    let icon: String
    let animationDelay: Double
    
    private let ringWidth: CGFloat = 5
    private let size: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring - grey
                Circle()
                    .stroke(ColorPalette.neutral300, lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                // Center icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

struct EmptyStateRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            EmptyStateRingView(title: "Recovery", icon: "heart.fill", animationDelay: 0.0)
            EmptyStateRingView(title: "Sleep", icon: "moon.fill", animationDelay: 0.1)
            EmptyStateRingView(title: "Load", icon: "figure.walk", animationDelay: 0.2)
        }
        .padding()
    }
}
