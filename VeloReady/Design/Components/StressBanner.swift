import SwiftUI

/// Banner for stress alerts - appears under the daily summary rings
/// Matches WellnessBanner design exactly
struct StressBanner: View {
    let alert: StressAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Warning icon with severity-based color
                Image(systemName: alert.severity.icon)
                    .font(.caption)
                    .foregroundColor(alert.severity.color)
                
                // Banner message
                Text(alert.bannerMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorScale.labelPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Chevron to indicate it's tappable
                Image(systemName: Icons.System.chevronRight)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(alert.severity.color.opacity(0.1))
                    .overlay(
                        Rectangle()
                            .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Elevated Stress") {
    VStack(spacing: Spacing.md) {
        StressBanner(
            alert: StressAlert(
                severity: .elevated,
                acuteStress: 72,
                chronicStress: 78,
                trend: .increasing,
                contributors: [],
                recommendation: "Test recommendation",
                detectedAt: Date()
            ),
            onTap: {}
        )
        .padding()
        
        StressBanner(
            alert: StressAlert(
                severity: .high,
                acuteStress: 85,
                chronicStress: 88,
                trend: .increasing,
                contributors: [],
                recommendation: "Test recommendation",
                detectedAt: Date()
            ),
            onTap: {}
        )
        .padding()
    }
    .background(Color.background.app)
}

